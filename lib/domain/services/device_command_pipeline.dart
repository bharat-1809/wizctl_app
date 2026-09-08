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

/// A light's signal and the store state it had before the optimistic patch,
/// kept so a failure can be reverted and, later, retried.
class _Attempt {
  final CommandItem item;
  final LiveState previous;
  const _Attempt(this.item, this.previous);
}

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
  final Map<String, CommandBatch> _waiting = {};
  final Map<String, DateTime> _lastSent = {};

  // Named initializing formals can't start with `_` (a named parameter
  // can't be private), so the public `gateway`/`store`/… names are assigned
  // to the private fields explicitly instead.
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
    var attempts = [
      for (var item in batch.items) _Attempt(item, _store.of(item.light.id)),
    ];
    for (var a in attempts) {
      _store.update(a.item.light.id, a.item.patch);
    }
    var key = batch.throttleKey;
    if (key != null && _inFlight.contains(key)) {
      _waiting[key] = batch;
      return;
    }
    if (key != null) _inFlight.add(key);
    try {
      await _send(attempts, _describe(batch), key);
    } finally {
      if (key != null) {
        _inFlight.remove(key);
        var next = _waiting.remove(key);
        if (next != null) {
          var since = _clock.now().difference(_lastSent[key] ?? _clock.now());
          if (since < throttle) await _clock.delay(throttle - since);
          // Re-run resolves the latest value for this key; its patches were
          // already applied when it was queued, so re-applying is harmless.
          unawaited(run(next));
        }
      }
    }
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
    var light = a.item.light;
    try {
      await _gateway.send(light.ip, a.item.signal);
      _store.update(
        light.id,
        (s) => s.copyWith(reachable: true, updatedAt: _clock.now()),
      );
      return true;
    } on DeviceException catch (e) {
      _store.put(light.id, a.previous.copyWith(reachable: false));
      (_failed[id] ??= <_Attempt>[]).add(a);
      _emit(CommandFailed(id, light.id, light.name, light.ip, e.failure));
      return false;
    } catch (e) {
      _store.put(light.id, a.previous.copyWith(reachable: false));
      (_failed[id] ??= <_Attempt>[]).add(a);
      _emit(
        CommandFailed(
          id,
          light.id,
          light.name,
          light.ip,
          UnreachableFailure(light.ip, '$e'),
        ),
      );
      return false;
    }
  }

  /// Re-sends every light that failed under [reportId], once each, then
  /// forgets the entry (spec §5.11.7).
  Future<void> retry(String reportId) async {
    var attempts = _failed.remove(reportId);
    if (attempts == null || attempts.isEmpty) return;
    for (var a in attempts) {
      _store.update(a.item.light.id, a.item.patch);
    }
    var results = await Future.wait(
      attempts.map((a) => _retryOne(reportId, a)),
    );
    if (results.every((ok) => ok)) _emit(CommandSucceeded(reportId));
  }

  Future<bool> _retryOne(String reportId, _Attempt a) async {
    var light = a.item.light;
    try {
      await _gateway.send(light.ip, a.item.signal);
      _store.update(
        light.id,
        (s) => s.copyWith(reachable: true, updatedAt: _clock.now()),
      );
      return true;
    } catch (_) {
      _store.put(light.id, a.previous.copyWith(reachable: false));
      _emit(CommandRetryFailed(reportId, light.id, light.name));
      return false;
    }
  }

  void _emit(CommandReport report) {
    if (!_reports.isClosed) _reports.add(report);
  }

  void dispose() => _reports.close();
}
