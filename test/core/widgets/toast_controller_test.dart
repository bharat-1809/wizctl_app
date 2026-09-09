import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';

void main() {
  test('the queue default cannot drift from the motion token', () {
    expect(ToastController.defaultDuration, WizMotion.standard.toast);
  });

  test('each tone maps to its cue, and loading to none', () {
    expect(
      ToastController.soundFor(WizToastTone.success),
      FeedbackKind.confirm,
    );
    expect(ToastController.soundFor(WizToastTone.error), FeedbackKind.reject);
    expect(ToastController.soundFor(WizToastTone.info), FeedbackKind.tick);
    expect(ToastController.soundFor(WizToastTone.loading), isNull);
  });

  test('pushes, caps at three, and expires after 3.2 s', () {
    fakeAsync((async) {
      var feedback = RecordingFeedbackService();
      var c = ToastController(feedback: feedback);
      c.push(tone: WizToastTone.success, title: 'A');
      c.push(tone: WizToastTone.info, title: 'B');
      c.push(tone: WizToastTone.error, title: 'C');
      c.push(tone: WizToastTone.success, title: 'D');
      expect(c.toasts.map((t) => t.title), ['B', 'C', 'D']);
      expect(feedback.played, [
        FeedbackKind.confirm,
        FeedbackKind.tick,
        FeedbackKind.reject,
        FeedbackKind.confirm,
      ]);
      async.elapse(const Duration(milliseconds: 3300));
      expect(c.toasts, isEmpty);
      c.dispose();
    });
  });

  test('loading toasts stay until updated, then expire', () {
    fakeAsync((async) {
      var feedback = RecordingFeedbackService();
      var c = ToastController(feedback: feedback);
      var id = c.push(tone: WizToastTone.loading, title: 'Sending to Hallway');
      async.elapse(const Duration(seconds: 10));
      expect(c.toasts, hasLength(1));
      expect(feedback.played, isEmpty);
      c.update(
        id,
        tone: WizToastTone.error,
        title: 'No response after 3 tries',
        actionLabel: 'Retry',
        onAction: () {},
      );
      expect(c.toasts.single.title, 'No response after 3 tries');
      expect(c.toasts.single.actionLabel, 'Retry');
      expect(feedback.played, [FeedbackKind.reject]);
      async.elapse(const Duration(milliseconds: 3300));
      expect(c.toasts, isEmpty);
      c.dispose();
    });
  });

  test('pushAfter shows only if still pending after the delay', () {
    fakeAsync((async) {
      var c = ToastController();
      var early = c.pushAfter(
        const Duration(milliseconds: 600),
        tone: WizToastTone.loading,
        title: 'Sending',
      );
      c.dismiss(early);
      async.elapse(const Duration(milliseconds: 700));
      expect(c.toasts, isEmpty);

      var late = c.pushAfter(
        const Duration(milliseconds: 600),
        tone: WizToastTone.loading,
        title: 'Sending',
      );
      async.elapse(const Duration(milliseconds: 700));
      expect(c.toasts.single.title, 'Sending');

      var resolved = c.pushAfter(
        const Duration(milliseconds: 600),
        tone: WizToastTone.loading,
        title: 'Sending',
      );
      c.update(resolved, tone: WizToastTone.success, title: 'Saved');
      expect(c.toasts.map((t) => t.title), contains('Saved'));
      expect(late, isNot(resolved));
      c.dispose();
    });
  });

  test('an update that resolves a pending toast plays its cue at once', () {
    fakeAsync((async) {
      var feedback = RecordingFeedbackService();
      var c = ToastController(feedback: feedback);
      var id = c.pushAfter(
        WizMotion.standard.toastDelay,
        tone: WizToastTone.loading,
        title: 'Saving Bedside bulb',
      );
      // The write came back inside the delay: nothing was ever shown, and
      // nothing was heard.
      async.elapse(const Duration(milliseconds: 100));
      expect(c.toasts, isEmpty);
      expect(feedback.played, isEmpty);
      c.update(
        id,
        tone: WizToastTone.success,
        title: 'Bedside bulb saved',
        body: '192.168.1.24 added to this home',
      );
      expect(c.toasts.single.body, '192.168.1.24 added to this home');
      expect(feedback.played, [FeedbackKind.confirm]);
      // It is resolved and armed now; the cancelled delay must not show it a
      // second time after it has expired.
      async.elapse(const Duration(milliseconds: 3300));
      expect(c.toasts, isEmpty);
      c.dispose();
    });
  });

  test('a queue with no feedback service is silent, not a crash', () {
    fakeAsync((async) {
      var c = ToastController();
      for (var tone in WizToastTone.values) {
        c.push(tone: tone, title: tone.name);
      }
      expect(c.toasts, hasLength(ToastController.defaultMax));
      async.elapse(const Duration(milliseconds: 3300));
      expect(c.toasts.single.tone, WizToastTone.loading);
      c.dispose();
    });
  });

  test('dispose cancels every armed and pending timer', () {
    fakeAsync((async) {
      var feedback = RecordingFeedbackService();
      var c = ToastController(feedback: feedback);
      c.push(tone: WizToastTone.success, title: 'armed');
      c.pushAfter(
        WizMotion.standard.toastDelay,
        tone: WizToastTone.loading,
        title: 'pending',
      );
      expect(async.pendingTimers, hasLength(2));
      c.dispose();
      expect(async.pendingTimers, isEmpty);
      // Nothing left to fire: a timer that outlived the controller would
      // notify a disposed ChangeNotifier and throw here.
      async.flushTimers();
      expect(feedback.played, [FeedbackKind.confirm]);
    });
  });
}
