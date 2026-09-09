import 'dart:async';

import 'package:flutter/foundation.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_service.dart';

/// Toast.jsx `TOAST_TONES` (`design/reference/_ds_bundle.js:2418`).
enum WizToastTone { success, error, loading, info }

/// One toast in the queue. Immutable: [ToastController.update] replaces the
/// entry rather than mutating it, so a rebuild always sees a new object.
@immutable
class WizToastData {
  final String id;
  final WizToastTone tone;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WizToastData({
    required this.id,
    required this.tone,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  /// Every argument is a patch: null leaves the field as it was, which is
  /// what [ToastController.update]'s optional arguments mean.
  WizToastData copyWith({
    WizToastTone? tone,
    String? title,
    String? body,
    String? actionLabel,
    VoidCallback? onAction,
  }) => WizToastData(
    id: id,
    tone: tone ?? this.tone,
    title: title ?? this.title,
    body: body ?? this.body,
    actionLabel: actionLabel ?? this.actionLabel,
    onAction: onAction ?? this.onAction,
  );
}

/// The toast queue. Max three, 3.2 s each; loading toasts stay until updated
/// to a resolved tone, which is how a long action reports back. Success
/// plays confirm, error plays reject, info plays tick, loading is silent.
///
/// It holds no [BuildContext], so its defaults are compile-time constants
/// rather than theme tokens; [defaultDuration] mirrors `WizMotion.toast` and
/// a test pins the two together. Callers that have a context — the toast
/// layer's owner — pass `motion.toastDelay` to [pushAfter] instead.
class ToastController extends ChangeNotifier {
  /// How long a resolved toast stays up. Mirrors `WizMotion.toast`
  /// (spec §11.2, "max three; 3.2 s"; Toast.jsx `duration = 3200`,
  /// `design/reference/_ds_bundle.js:2569`).
  static const Duration defaultDuration = Duration(milliseconds: 3200);

  /// How many toasts stack before the oldest is dropped (spec §11.2,
  /// "max three"; Toast.jsx `max = 3`, `design/reference/_ds_bundle.js:2570`).
  static const int defaultMax = 3;

  final Duration duration;
  final int max;

  /// Null means silent: a queue driven by a test, or one built before the
  /// audio engine exists.
  final FeedbackService? feedback;

  final List<WizToastData> _toasts = [];

  /// Auto-dismiss timers for toasts that are up, by id.
  final Map<String, Timer> _expiry = {};

  /// Toasts armed by [pushAfter] that have not surfaced yet, by id.
  final Map<String, (Timer, WizToastData)> _pending = {};

  int _seq = 0;

  /// Set by [dispose]. A queue can outlive its layer by a moment — a command
  /// that reports back after the screen is gone — and a [push] or
  /// [pushAfter] arriving then would notify a disposed [ChangeNotifier], or
  /// arm a timer that nothing is left to cancel. After this every entry
  /// point is a no-op.
  bool _disposed = false;

  ToastController({
    this.duration = defaultDuration,
    this.max = defaultMax,
    this.feedback,
  });

  List<WizToastData> get toasts => List.unmodifiable(_toasts);

  /// The cue a tone plays when it appears or is resolved into, or null for
  /// loading, which is silent because the user is still waiting
  /// (Toast.jsx `TOAST_TONES[…].sound`,
  /// `design/reference/_ds_bundle.js:2422`, `:2427`, `:2432`, `:2437`).
  static FeedbackKind? soundFor(WizToastTone tone) => switch (tone) {
    WizToastTone.success => FeedbackKind.confirm,
    WizToastTone.error => FeedbackKind.reject,
    WizToastTone.info => FeedbackKind.tick,
    WizToastTone.loading => null,
  };

  String _nextId() => 't${_seq++}';

  void _show(WizToastData toast) {
    var sound = soundFor(toast.tone);
    if (sound != null) feedback?.play(sound);
    _toasts.add(toast);
    while (_toasts.length > max) {
      var dropped = _toasts.removeAt(0);
      _expiry.remove(dropped.id)?.cancel();
    }
    _arm(toast);
    notifyListeners();
  }

  /// (Re)starts the auto-dismiss clock. A loading toast has none: it stays
  /// until [update] resolves it or [dismiss] takes it away.
  void _arm(WizToastData toast) {
    _expiry.remove(toast.id)?.cancel();
    if (toast.tone == WizToastTone.loading) return;
    _expiry[toast.id] = Timer(duration, () => dismiss(toast.id));
  }

  String push({
    required WizToastTone tone,
    required String title,
    String? body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    var toast = WizToastData(
      id: _nextId(),
      tone: tone,
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    if (_disposed) return toast.id;
    _show(toast);
    return toast.id;
  }

  /// Show only if still unresolved after [delay]. A write that completes
  /// quickly never surfaces a toast; one still in flight after
  /// `WizMotion.toastDelay` does (spec §5.11, "the toast layer shows the
  /// loading toast only if the batch is still pending after 600 ms").
  String pushAfter(
    Duration delay, {
    required WizToastTone tone,
    required String title,
    String? body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    var toast = WizToastData(
      id: _nextId(),
      tone: tone,
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    if (_disposed) return toast.id;
    _pending[toast.id] = (
      Timer(delay, () {
        var entry = _pending.remove(toast.id);
        if (entry != null) _show(entry.$2);
      }),
      toast,
    );
    return toast.id;
  }

  /// Patches a toast in place. A new [tone] plays that tone's cue and
  /// re-arms the clock, which is how a loading toast resolves. A toast still
  /// waiting out its [pushAfter] delay surfaces immediately, patched.
  void update(
    String id, {
    WizToastTone? tone,
    String? title,
    String? body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (_disposed) return;
    var pending = _pending.remove(id);
    if (pending != null) {
      pending.$1.cancel();
      _show(
        pending.$2.copyWith(
          tone: tone,
          title: title,
          body: body,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      );
      return;
    }
    var index = _toasts.indexWhere((t) => t.id == id);
    if (index < 0) return;
    var next = _toasts[index].copyWith(
      tone: tone,
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
    );
    _toasts[index] = next;
    if (tone != null) {
      var sound = soundFor(tone);
      if (sound != null) feedback?.play(sound);
      _arm(next);
    }
    notifyListeners();
  }

  void dismiss(String id) {
    // Guarded like the three above, so "no-op after dispose" is the whole
    // contract rather than three quarters of it: a dismiss key tapped in the
    // frame the layer goes away would otherwise notify a dead notifier.
    if (_disposed) return;
    _pending.remove(id)?.$1.cancel();
    _expiry.remove(id)?.cancel();
    var before = _toasts.length;
    _toasts.removeWhere((t) => t.id == id);
    if (_toasts.length != before) notifyListeners();
  }

  /// Cancels every clock, armed or pending: a timer that outlived the
  /// controller would call [dismiss] and notify a disposed [ChangeNotifier].
  @override
  void dispose() {
    _disposed = true;
    for (var timer in _expiry.values) {
      timer.cancel();
    }
    _expiry.clear();
    for (var pending in _pending.values) {
      pending.$1.cancel();
    }
    _pending.clear();
    super.dispose();
  }
}
