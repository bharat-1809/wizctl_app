import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/copy/strings.dart';
import '../core/widgets/toast_controller.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/services/device_command_pipeline.dart';

/// What one report id has on screen, and what a Retry for it would resend.
///
/// [loading] is the batch's one loading toast — armed by a pending report or
/// pushed by a retry — [errors] the toasts its failed lights pushed, and
/// [failures] those failures, which is how a Retry knows how many lights the
/// pipeline is about to resend.
class _Batch {
  String? loading;
  final List<String> errors = [];
  final List<CommandFailed> failures = [];
}

/// Turns the pipeline's reports into toasts (spec §5.11.6, §15).
///
/// A pending batch arms a loading toast that surfaces only if the batch is
/// still in flight after [delay]; success takes it away again (the control
/// already shows the new value, and a toast never says what the UI shows);
/// each failed light resolves it — or pushes its own — as the error with a
/// Retry key. Retry is per batch, because [DeviceCommandPipeline.retry] is:
/// whichever error toast of a batch is tapped, every error toast of that
/// batch goes away and one loading toast (`Retrying <name>`, or
/// `Retrying <n> lights`) stands for the whole resend, until it succeeds or
/// reports `Still no reply` once. Off network is one error with nothing to
/// retry.
class CommandToastListener {
  final ToastController toasts;
  final DeviceCommandPipeline pipeline;
  final LightRepository lights;

  /// `WizMotion.toastDelay`, handed in because this class has no context.
  final Duration delay;

  /// The toasts and failures standing for each report id, once any exist.
  final Map<String, _Batch> _batches = {};

  /// Report ids that succeeded before their loading toast could be armed
  /// (a fast send completes while the address is still being read). Nothing
  /// else writes here, and [_pending] always takes the id back out: the
  /// pending report is emitted before the sends, so a success that beat it
  /// beat a [_pending] call that is still awaiting its read.
  final Set<String> _settled = {};

  StreamSubscription<CommandReport>? _subscription;

  CommandToastListener({
    required this.toasts,
    required this.pipeline,
    required this.lights,
    required this.delay,
  });

  void start() {
    // `onError`, and it keeps listening: a `Stream.listen` with no error
    // handler turns anything the pipeline's stream carries into an unhandled
    // async error, which in release is a crash and in a test is a failure a
    // long way from its cause. Cancelling instead would leave every later
    // command with no toasts at all, silently, for the life of the app.
    _subscription ??= pipeline.reports.listen(
      _onReport,
      onError: (Object error, StackTrace stack) => FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'wizctl_app',
          context: ErrorDescription('listening to the command pipeline'),
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onReport(CommandReport report) async {
    switch (report) {
      case CommandPending p:
        await _pending(p);
      case CommandSucceeded s:
        _succeeded(s.id);
      case CommandFailed f:
        _failed(f);
      case CommandRetryFailed f:
        _retryFailed(f);
    }
  }

  Future<void> _pending(CommandPending report) async {
    var single = report.lightIds.length == 1;
    Light? light;
    // Guarded: a read that fails is not a reason for the batch to go silent.
    // The name is all this read was for, so a failure falls through to the
    // count title below — which is why a failed read is kept apart from a
    // light that is simply gone.
    var read = true;
    if (single) {
      try {
        light = await lights.get(report.lightIds.single);
      } catch (error, stack) {
        read = false;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'wizctl_app',
            context: ErrorDescription(
              'reading the light a loading toast would name',
            ),
          ),
        );
      }
    }
    // The read above is a suspension point: the batch may have resolved while
    // it was in flight, and arming a toast for a batch that has already
    // reported would surface it with nothing left to say.
    if (_settled.remove(report.id)) return;
    var batch = _batches[report.id];
    if (batch != null && batch.errors.isNotEmpty) return;
    if (single && read && light == null) {
      // Gone from the repository between the send and this read: no name and
      // no address, and a count of one light would read as a lie. The entry is
      // still recorded, so a failure for this batch still pushes its error
      // toast — the failure path does not need a loading toast — and its
      // success is not mistaken for one that beat this read.
      _batches.putIfAbsent(report.id, _Batch.new);
      return;
    }
    (_batches[report.id] ??= _Batch()).loading = toasts.pushAfter(
      delay,
      tone: WizToastTone.loading,
      title: light != null
          ? Strings.sendingTo(light.name)
          : Strings.sendingToLights(report.lightIds.length),
      body: light != null ? Strings.udpAddress(light.ip) : null,
    );
  }

  void _succeeded(String id) {
    var batch = _batches.remove(id);
    if (batch == null) {
      _settled.add(id);
      return;
    }
    var loading = batch.loading;
    if (loading != null) toasts.dismiss(loading);
  }

  void _failed(CommandFailed report) {
    _prune(report.id);
    if (report.failure case OffNetworkFailure(
      :var homeSubnet,
      :var currentSubnet,
    )) {
      // Amendment P7: no `_settled` entry. The pipeline mints a fresh id for
      // this report that never had a pending toast, so nothing would ever
      // remove it again. No local IPv4 address at all is the real "no local
      // network"; a null home subnet cannot reach here (a home without a
      // subnet is never off network) but reads the same way if it ever does.
      toasts.push(
        tone: WizToastTone.error,
        title: Strings.noRoute,
        body: currentSubnet == null || homeSubnet == null
            ? Strings.noLocalNetwork
            : Strings.notOnHomeNetwork(homeSubnet),
      );
      return;
    }
    var batch = _batches[report.id] ??= _Batch();
    batch.failures.add(report);
    var loading = batch.loading;
    batch.loading = null;
    void retry() => _retry(report.id);
    if (loading != null) {
      // Resolved in place: the loading toast becomes the first error.
      toasts.update(
        loading,
        tone: WizToastTone.error,
        title: Strings.noResponseAfterTries,
        body: Strings.didNotAnswer(report.ip),
        actionLabel: Strings.retry,
        onAction: retry,
      );
      batch.errors.add(loading);
      return;
    }
    batch.errors.add(
      toasts.push(
        tone: WizToastTone.error,
        title: Strings.noResponseAfterTries,
        body: Strings.didNotAnswer(report.ip),
        actionLabel: Strings.retry,
        onAction: retry,
      ),
    );
  }

  /// One resend for the whole batch, however many of its error toasts are up
  /// and whichever one was tapped: [DeviceCommandPipeline.retry] resends every
  /// light that failed under this id at once, and a second call for the same
  /// id would do nothing while orphaning a second loading toast.
  ///
  /// A fresh push rather than an update of an error toast: `copyWith` keeps a
  /// field its argument leaves null, so the Retry key could not be cleared in
  /// place.
  void _retry(String id) {
    var batch = _batches[id];
    if (batch == null) return;
    // Already retrying — a second tap on the same toast inside the frame that
    // takes it away.
    if (batch.loading != null) return;
    for (var toast in batch.errors) {
      toasts.dismiss(toast);
    }
    batch.errors.clear();
    batch.loading = toasts.push(
      tone: WizToastTone.loading,
      title: batch.failures.length == 1
          ? Strings.retrying(batch.failures.single.lightName)
          : Strings.retryingLights(batch.failures.length),
    );
    unawaited(pipeline.retry(id));
  }

  /// One toast per retried batch: the pipeline reports every light that failed
  /// again, and the first of those answers for the whole resend. Taking the
  /// entry away is what makes the rest of them no-ops.
  void _retryFailed(CommandRetryFailed report) {
    var batch = _batches.remove(report.id);
    if (batch == null) return;
    var loading = batch.loading;
    if (loading != null) {
      toasts.update(
        loading,
        tone: WizToastTone.error,
        title: Strings.stillNoReply,
        body: Strings.checkWallSwitch,
      );
      return;
    }
    toasts.push(
      tone: WizToastTone.error,
      title: Strings.stillNoReply,
      body: Strings.checkWallSwitch,
    );
  }

  /// Forgets batches with nothing left on screen, so a long-lived listener
  /// does not keep every failure it ever reported. An error toast
  /// auto-dismisses, so most failures are never retried; [keep] is the id
  /// whose failure is arriving right now, whose toast does not exist yet.
  ///
  /// Only entries that had an error toast and have none left are candidates,
  /// and that is complete. An entry holding a loading toast is always cleared
  /// by the batch's own terminal report — a pending batch by its success
  /// (removed) or by its first failure (which consumes the loading toast into
  /// [_Batch.errors]), a retried one by its success or its first retry failure
  /// (both removed) — and a `pushAfter` toast that has not surfaced yet is
  /// legitimately absent from [ToastController.toasts] anyway. An entry with
  /// neither is a pending that declined to arm one, and its terminal report
  /// clears it the same way.
  void _prune(String keep) {
    var live = toasts.toasts.map((t) => t.id).toSet();
    _batches.removeWhere(
      (id, batch) =>
          id != keep &&
          batch.loading == null &&
          batch.errors.isNotEmpty &&
          !batch.errors.any(live.contains),
    );
  }
}
