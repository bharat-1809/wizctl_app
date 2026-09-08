import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

/// One crawl step. Small enough that several land before the drag
/// recogniser claims the gesture, so the tests exercise the real hand-over.
const double _crawlStep = 8;

/// Drags the only [WizToggle] on screen slowly: every leg of [legs] is
/// crawled in [_crawlStep] moves 100 ms apart, then the finger lifts.
///
/// The moves are spaced wider than the velocity tracker's sampling window,
/// so by the release it has no usable estimate and reports zero velocity —
/// which is the point: these are drags, and the cap's resting position
/// alone decides the commit. A flick is tested with [WidgetTester.fling].
Future<void> _crawl(
  WidgetTester tester,
  List<double> legs, {
  VoidCallback? whileHeld,
}) async {
  var gesture = await tester.startGesture(
    tester.getCenter(find.byType(WizToggle)),
  );
  var clock = Duration.zero;
  Future<void> tick(Future<void> Function(Duration at) send) async {
    clock += const Duration(milliseconds: 100);
    await send(clock);
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (var leg in legs) {
    var step = Offset(_crawlStep * leg.sign, 0);
    for (var i = 0; i < (leg.abs() / _crawlStep).round(); i++) {
      await tick((at) => gesture.moveBy(step, timeStamp: at));
    }
  }
  whileHeld?.call();
  await tick((at) => gesture.up(timeStamp: at));
  await tester.pumpAndSettle();
}

/// The rocker's cap: the only circle the toggle draws.
final Finder _cap = find.descendant(
  of: find.byType(WizToggle),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle,
  ),
);

/// A toggle wired to a local [value] the tests can read back.
Widget _liveToggle(
  bool Function() read,
  void Function(bool) write, {
  bool enabled = true,
}) {
  return StatefulBuilder(
    builder: (context, setState) => WizToggle(
      value: read(),
      enabled: enabled,
      onChanged: (v) => setState(() => write(v)),
      semanticsLabel: 'Power',
    ),
  );
}

void main() {
  testWidgets('the track keeps the rocker geometry inside a 44 hit area', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WizToggle(
              value: false,
              onChanged: (_) {},
              size: WizToggleSize.sm,
              semanticsLabel: 'a',
            ),
            WizToggle(value: false, onChanged: (_) {}, semanticsLabel: 'b'),
          ],
        ),
      ),
    );
    var toggles = tester.widgetList(find.byType(WizToggle)).toList();
    var tracks = toggles
        .map(
          (w) => tester.getSize(
            find.descendant(
              of: find.byWidget(w),
              matching: find.byType(WizSurface),
            ),
          ),
        )
        .toList();
    expect(tracks, [const Size(46, 27), const Size(60, 33)]);
    // Spec §14: the visual stays small, the touch target never does.
    var outer = toggles.map((w) => tester.getSize(find.byWidget(w))).toList();
    expect(outer, [const Size(46, 44), const Size(60, 44)]);
  });

  testWidgets('tap toggles and plays toggleOn then toggleOff', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(feedback.played, [FeedbackKind.toggleOn, FeedbackKind.toggleOff]);
  });

  testWidgets('a flick to the right turns it on', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await tester.fling(find.byType(WizToggle), const Offset(40, 0), 800);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(feedback.played, [FeedbackKind.toggleOn]);
  });

  testWidgets('a flick to the left turns it off', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = true;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await tester.fling(find.byType(WizToggle), const Offset(-40, 0), 800);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(feedback.played, [FeedbackKind.toggleOff]);
  });

  testWidgets('dragging the cap past the midpoint commits', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await _crawl(
      tester,
      [64],
      whileHeld: () => expect(
        tester.getCenter(_cap).dx,
        greaterThan(tester.getCenter(find.byType(WizToggle)).dx),
        reason: 'the cap follows the finger, it does not wait for the release',
      ),
    );
    expect(value, isTrue);
    expect(feedback.played, [FeedbackKind.toggleOn]);
  });

  testWidgets('dragging the cap back where it started commits nothing', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    var parked = tester.getTopLeft(_cap).dx;
    await _crawl(tester, [64, -64]);
    expect(value, isFalse, reason: 'the cap came home, so nothing changed');
    expect(feedback.played, isEmpty, reason: 'a cue only ever means a commit');
    expect(tester.getTopLeft(_cap).dx, moreOrLessEquals(parked, epsilon: 0.5));
  });

  testWidgets('disabled toggles ignore taps and flicks', (tester) async {
    var feedback = RecordingFeedbackService();
    var changed = false;
    await tester.pumpWidget(
      wizTestApp(
        WizToggle(
          value: false,
          enabled: false,
          onChanged: (_) => changed = true,
          semanticsLabel: 'x',
        ),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(WizToggle), const Offset(40, 0), 800);
    await tester.pumpAndSettle();
    expect(changed, isFalse);
    expect(feedback.played, isEmpty);
  });

  testWidgets('Space toggles a focused switch', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    var detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byType(WizToggle),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();
    expect(detector.focusNode!.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(feedback.played, [
      FeedbackKind.toggleOn,
    ], reason: 'the switch closing is the cue, not a key press');
  });

  testWidgets('assistive tech sees a labelled switch that reports its state', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var value = true;
    try {
      await tester.pumpWidget(
        wizTestApp(
          _liveToggle(() => value, (v) {
            value = v;
          }),
        ),
      );
      expect(
        tester.getSemantics(find.byType(WizToggle)),
        isSemantics(
          label: 'Power',
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
          isEnabled: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Power'));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      expect(
        tester.getSemantics(find.byType(WizToggle)),
        isSemantics(isToggled: false),
      );
    } finally {
      handle.dispose();
    }
  });
}
