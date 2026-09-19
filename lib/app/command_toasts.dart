import 'dart:async';

import '../core/copy/strings.dart';
import '../core/widgets/toast_controller.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/services/device_command_pipeline.dart';

/// Turns the pipeline's reports into toasts (spec §5.11.6, §15).
///
/// A pending batch arms a loading toast that surfaces only if the batch is
/// still in flight after [delay]; success takes it away again (the control
/// already shows the new value, and a toast never says what the UI shows);
/// each failed light resolves it — or pushes its own — as the error with a
/// Retry key; a retry shows `"Retrying <name>"` until it succeeds or reports
/// "Still no reply". Off network is one error with nothing to retry.
class CommandToastListener {
  final ToastController toasts;
  final DeviceCommandPipeline pipeline;
  final LightRepository lights;

  /// `WizMotion.toastDelay`, handed in because this class has no context.
  final Duration delay;

  /// The toast standing for each report id, once one exists.
  final Map<String, String> _toastFor = {};

  /// Report ids that resolved before their loading toast could be armed
  /// (a fast send completes while the address is still being read).
  final Set<String> _settled = {};

  StreamSubscription<CommandReport>? _subscription;

  CommandToastListener({
    required this.toasts,
    required this.pipeline,
    required this.lights,
    required this.delay,
  });

  void start() {
    _subscription ??= pipeline.reports.listen(_onReport);
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
    String? body;
    if (report.lightIds.length == 1) {
      var light = await lights.get(report.lightIds.single);
      if (light != null) body = Strings.udpAddress(light.ip);
    }
    if (_settled.remove(report.id)) return;
    _toastFor[report.id] = toasts.pushAfter(
      delay,
      tone: WizToastTone.loading,
      title: report.description,
      body: body,
    );
  }

  void _succeeded(String id) {
    var toast = _toastFor.remove(id);
    if (toast == null) {
      _settled.add(id);
      return;
    }
    toasts.dismiss(toast);
  }

  void _failed(CommandFailed report) {
    if (report.failure case OffNetworkFailure(:var homeSubnet)) {
      toasts.push(
        tone: WizToastTone.error,
        title: Strings.noRoute,
        body: homeSubnet == null
            ? Strings.noLocalNetwork
            : Strings.notOnHomeNetwork(homeSubnet),
      );
      return;
    }
    var title = Strings.noResponseAfterTries;
    var body = Strings.didNotAnswer(report.ip);
    var pending = _toastFor.remove(report.id);
    void retry() => _retry(report);
    if (pending != null) {
      // Resolved in place: the loading toast becomes the error.
      toasts.update(
        pending,
        tone: WizToastTone.error,
        title: title,
        body: body,
        actionLabel: Strings.retry,
        onAction: retry,
      );
      return;
    }
    _settled.add(report.id);
    toasts.push(
      tone: WizToastTone.error,
      title: title,
      body: body,
      actionLabel: Strings.retry,
      onAction: retry,
    );
  }

  /// A fresh loading toast rather than an update: `copyWith` keeps a field
  /// its argument leaves null, so the Retry key could not be cleared in
  /// place.
  void _retry(CommandFailed report) {
    for (var entry in toasts.toasts) {
      if (entry.onAction != null &&
          entry.title == Strings.noResponseAfterTries &&
          entry.body == Strings.didNotAnswer(report.ip)) {
        toasts.dismiss(entry.id);
      }
    }
    _toastFor[report.id] = toasts.push(
      tone: WizToastTone.loading,
      title: Strings.retrying(report.lightName),
    );
    unawaited(pipeline.retry(report.id));
  }

  void _retryFailed(CommandRetryFailed report) {
    var pending = _toastFor.remove(report.id);
    if (pending != null) {
      toasts.update(
        pending,
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
}
