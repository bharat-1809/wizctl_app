import 'dart:async';

import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'clock.dart';
import 'device_gateway.dart';
import 'id_generator.dart';
import 'live_state_store.dart';
import 'network_monitor.dart';

class CommandItem {
  final Light light;
  final ControlSignal signal;
  final LiveState Function(LiveState current) patch;

  const CommandItem({
    required this.light,
    required this.signal,
    required this.patch,
  });
}

class CommandBatch {
  final List<CommandItem> items;
  final String? description;

  /// Batches sharing a key coalesce while one is in flight (dial drags).
  final String? throttleKey;

  const CommandBatch({required this.items, this.description, this.throttleKey});
}

/// A light's signal, the store state it had before the optimistic patch, and
/// the state the patch produced — kept so a failure can be reverted (but
/// only if nothing else has since changed the light) and, later, retried.
class _Attempt {
  final CommandItem item;
  final LiveState previous;
  final LiveState optimistic;
  const _Attempt(this.item, this.previous, this.optimistic);
}

/// A batch that lost the race for its throttle key, waiting to be sent once
/// the in-flight one (and the throttle window) clears. Its attempts were
/// already computed — previous/optimistic snapshots and all — when it was
/// queued, so re-sending it never re-reads or re-patches the store.
typedef _Queued = ({List<_Attempt> attempts, String description});

/// Every write goes through here: optimistic in the store, honest in the
/// reports (spec §5.11).
class DeviceCommandPipeline {
  /// Coalescing window for batches sharing a [CommandBatch.throttleKey]
  /// (spec §5.11): send immediately if idle; otherwise keep only the latest
  /// queued batch and send it once the in-flight send finishes and this much
  /// time has passed since the previous send for that key.
  static const Duration defaultThrottle = Duration(milliseconds: 120);

  final DeviceGateway _gateway;
  final LiveStateStore _store;
  final NetworkMonitor _network;
  final Future<String?> Function() _homeSubnet;
  final Clock _clock;
  final IdGenerator _ids;
  final Duration throttle;

  final StreamController<CommandReport> _reports = StreamController.broadcast();

  /// Every light that failed in a report, keyed by that report's id, so
  /// [retry] can re-send all of them (not just the last one to fail).
  final Map<String, List<_Attempt>> _failed = {};
  final Set<String> _inFlight = {};
  final Map<String, _Queued> _waiting = {};
  final Map<String, DateTime> _lastSent = {};

  // A named parameter can't start with `_` (that's a compile error, not a
  // style choice), so `this._gateway` etc. can't be used here while keeping
  // the public `gateway:`/`store:`/… names the API requires — the fields
  // stay private, assigned explicitly instead. See the fix report for the
  // `dart analyze` evidence behind these `ignore`s.
  DeviceCommandPipeline({
    required DeviceGateway gateway,
    required LiveStateStore store,
    required NetworkMonitor network,
    required Future<String?> Function() homeSubnet,
    required Clock clock,
    required IdGenerator ids,
    this.throttle = defaultThrottle,
  }) : _gateway = gateway, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _network = network, // ignore: prefer_initializing_formals
       _homeSubnet = homeSubnet, // ignore: prefer_initializing_formals
       _clock = clock, // ignore: prefer_initializing_formals
       _ids = ids; // ignore: prefer_initializing_formals

  Stream<CommandReport> get reports => _reports.stream;

  String _describe(CommandBatch batch) =>
      batch.description ??
      (batch.items.length == 1
          ? 'Sending to ${batch.items.single.light.name}'
          : 'Sending to ${batch.items.length} lights');

  /// Patches [batch] into the store immediately, then sends it — coalescing
  /// with any other batch sharing [CommandBatch.throttleKey] that's already
  /// in flight. Off network, this fails fast with a single [CommandFailed]
  /// and touches neither the store nor the gateway. This returns once this
  /// call's own send (and, if something coalesced behind it, the throttle
  /// wait) has been dealt with — a resend for the same key may still be in
  /// flight when it does.
  Future<void> run(CommandBatch batch) async {
    if (batch.items.isEmpty) return;
    var home = await _homeSubnet();
    if (_network.isOffNetwork(home)) {
      var first = batch.items.first.light;
      _emit(
        CommandFailed(
          _ids.next(),
          first.id,
          first.name,
          first.ip,
          OffNetworkFailure(home, _network.current),
        ),
      );
      return;
    }
    // Optimistic: the UI shows the new value at once, whatever happens next.
    var attempts = <_Attempt>[];
    for (var item in batch.items) {
      var previous = _store.of(item.light.id);
      var optimistic = item.patch(previous);
      attempts.add(_Attempt(item, previous, optimistic));
      _store.put(item.light.id, optimistic);
    }
    var key = batch.throttleKey;
    var description = _describe(batch);
    if (key != null && _inFlight.contains(key)) {
      // Last value wins: replace whatever was already waiting.
      _waiting[key] = (attempts: attempts, description: description);
      return;
    }
    if (key != null) _inFlight.add(key);
    await _sendAndDrain(key, attempts, description);
  }

  /// Sends [attempts], then — for a keyed batch — keeps [key] marked as
  /// in flight through the whole coalescing cycle: if something queued
  /// behind this send, waits out the throttle window and hands the next
  /// send off in the background, only releasing [key] once nothing is left
  /// waiting. A [run] arriving at any point in that cycle (including during
  /// the throttle wait) sees [key] as in flight and queues instead of
  /// jumping ahead of the coalesced resend.
  Future<void> _sendAndDrain(
    String? key,
    List<_Attempt> attempts,
    String description,
  ) async {
    await _send(attempts, description, key);
    if (key == null) return;
    var next = _waiting.remove(key);
    if (next == null) {
      _inFlight.remove(key);
      return;
    }
    var since = _clock.now().difference(_lastSent[key] ?? _clock.now());
    if (since < throttle) await _clock.delay(throttle - since);
    // A run arriving during that wait replaced (or re-replaced) what's
    // queued — re-check rather than send the value captured before we
    // waited, so the batch actually sent is always the latest one.
    var latest = _waiting.remove(key) ?? next;
    unawaited(_sendAndDrain(key, latest.attempts, latest.description));
  }

  Future<void> _send(
    List<_Attempt> attempts,
    String description,
    String? key,
  ) async {
    var id = _ids.next();
    _emit(
      CommandPending(id, [
        for (var a in attempts) a.item.light.id,
      ], description),
    );
    if (key != null) _lastSent[key] = _clock.now();
    var results = await Future.wait(attempts.map((a) => _sendOne(id, a)));
    if (results.every((ok) => ok)) _emit(CommandSucceeded(id));
  }

  Future<bool> _sendOne(String id, _Attempt a) async {
    var failure = await _sendSignal(a);
    if (failure == null) return true;
    var light = a.item.light;
    (_failed[id] ??= <_Attempt>[]).add(a);
    _emit(CommandFailed(id, light.id, light.name, light.ip, failure));
    return false;
  }

  /// Re-sends every light that failed under [reportId], once each, then
  /// forgets the entry (spec §5.11.7).
  Future<void> retry(String reportId) async {
    var failed = _failed.remove(reportId);
    if (failed == null || failed.isEmpty) return;
    var home = await _homeSubnet();
    if (_network.isOffNetwork(home)) {
      for (var a in failed) {
        var light = a.item.light;
        _emit(CommandRetryFailed(reportId, light.id, light.name));
      }
      return;
    }
    var attempts = <_Attempt>[];
    for (var a in failed) {
      var previous = _store.of(a.item.light.id);
      var optimistic = a.item.patch(previous);
      attempts.add(_Attempt(a.item, previous, optimistic));
      _store.put(a.item.light.id, optimistic);
    }
    var results = await Future.wait(
      attempts.map((a) => _retryOne(reportId, a)),
    );
    if (results.every((ok) => ok)) _emit(CommandSucceeded(reportId));
  }

  Future<bool> _retryOne(String reportId, _Attempt a) async {
    var failure = await _sendSignal(a);
    if (failure == null) return true;
    var light = a.item.light;
    _emit(CommandRetryFailed(reportId, light.id, light.name));
    return false;
  }

  /// Sends [a]'s signal, returning `null` on success or the [DeviceFailure]
  /// on failure. A failure reverts the light — but only if it still holds
  /// the optimistic value this very attempt applied; if something else has
  /// since changed it (a concurrent unkeyed batch on the same light), that
  /// value is left alone and only its `reachable` flag is corrected.
  Future<DeviceFailure?> _sendSignal(_Attempt a) async {
    var light = a.item.light;
    try {
      await _gateway.send(light.ip, a.item.signal);
      _store.update(
        light.id,
        (s) => s.copyWith(reachable: true, updatedAt: _clock.now()),
      );
      return null;
    } on DeviceException catch (e) {
      _revert(a);
      return e.failure;
    } catch (e) {
      _revert(a);
      return UnreachableFailure(light.ip, '$e');
    }
  }

  void _revert(_Attempt a) {
    var light = a.item.light;
    if (_store.of(light.id) == a.optimistic) {
      _store.put(light.id, a.previous.copyWith(reachable: false));
    } else {
      _store.update(light.id, (s) => s.copyWith(reachable: false));
    }
  }

  void _emit(CommandReport report) {
    if (!_reports.isClosed) _reports.add(report);
  }

  void dispose() {
    _reports.close();
    _waiting.clear();
    _failed.clear();
  }
}
