import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

/// One swipe step. Small enough that three of them are swallowed by the drag
/// slop, so the tests exercise the real hand-over out of the gesture arena.
const double _swipeStep = 8;

/// The one toggle the single-toggle tests put on screen.
final Finder _toggle = find.byType(WizToggle);

/// The well the cap rides in, inside [toggle]: the surface the switcher
/// cross-fades from one state to the other.
Finder _trackOf(Finder toggle) => find.descendant(
  of: find.descendant(of: toggle, matching: find.byType(AnimatedSwitcher)),
  matching: find.byType(WizSurface),
);

/// The rocker's cap, inside [toggle]: the surface that slides along the track.
Finder _capOf(Finder toggle) => find.descendant(
  of: find.descendant(of: toggle, matching: find.byType(AnimatedPositioned)),
  matching: find.byType(WizSurface),
);

final Finder _track = _trackOf(_toggle);
final Finder _cap = _capOf(_toggle);

/// The amber ring the press recipe draws around a keyboard-focused part
/// (spec §11.2) — matched on what it paints, not on how it is built.
final Finder _focusRing = find.descendant(
  of: _toggle,
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).border?.top.color ==
            WizColors.standard.focusRing,
  ),
);

/// Swipes the toggle: every leg of [legs] is covered in [_swipeStep] px moves
/// [gap] apart, starting at [from] or the toggle's centre, then the finger
/// lifts. [whileHeld] runs on the last frame before it does.
///
/// [gap] is what separates a drag from a flick over identical geometry. The
/// default 100 ms is wider than the velocity tracker's sampling window, so
/// the release reports no velocity and the cap's resting position alone
/// decides the commit. A few milliseconds instead, and the same throw lands
/// with a real one.
Future<void> _swipe(
  WidgetTester tester,
  List<double> legs, {
  Duration gap = const Duration(milliseconds: 100),
  Offset? from,
  VoidCallback? whileHeld,
}) async {
  var gesture = await tester.startGesture(from ?? tester.getCenter(_toggle));
  var clock = Duration.zero;
  Future<void> tick(Future<void> Function(Duration at) send) async {
    clock += gap;
    await send(clock);
    await tester.pump(gap);
  }

  for (var leg in legs) {
    var step = Offset(_swipeStep * leg.sign, 0);
    for (var i = 0; i < (leg.abs() / _swipeStep).round(); i++) {
      await tick((at) => gesture.moveBy(step, timeStamp: at));
    }
  }
  whileHeld?.call();
  await tick((at) => gesture.up(timeStamp: at));
  await tester.pumpAndSettle();
}

/// Asserts where the cap has got to against the midpoint the commit's
/// position branch uses — which is the toggle's own centre line.
void _expectCap(WidgetTester tester, Matcher against, {required String why}) {
  expect(tester.getCenter(_cap).dx, against, reason: why);
}

/// A toggle wired to a local value the tests can read back.
Widget _liveToggle(bool Function() read, void Function(bool) write) {
  return StatefulBuilder(
    builder: (context, setState) => WizToggle(
      value: read(),
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
        .map((w) => tester.getSize(_trackOf(find.byWidget(w))))
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
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.tap(_toggle);
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
    await tester.fling(_toggle, const Offset(40, 0), 800);
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
    await tester.fling(_toggle, const Offset(-40, 0), 800);
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
    await _swipe(
      tester,
      [64],
      whileHeld: () => _expectCap(
        tester,
        greaterThan(tester.getCenter(_toggle).dx),
        why: 'the cap follows the finger, it does not wait for the release',
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
    await _swipe(tester, [64, -64]);
    expect(value, isFalse, reason: 'the cap came home, so nothing changed');
    expect(feedback.played, isEmpty, reason: 'a cue only ever means a commit');
    expect(tester.getTopLeft(_cap).dx, moreOrLessEquals(parked, epsilon: 0.5));
  });

  // Both `fling` tests above carry the cap past the midpoint, so the position
  // branch alone would pass them. These two throw 32 px — 24 of which the
  // drag slop swallows, leaving the cap short of the midpoint, as `whileHeld`
  // asserts — so only the velocity branch can commit them.
  testWidgets('a flick commits from short of the midpoint', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await _swipe(
      tester,
      [32],
      gap: const Duration(milliseconds: 5),
      whileHeld: () => _expectCap(
        tester,
        lessThan(tester.getCenter(_toggle).dx),
        why: 'the cap is short of the midpoint: only the velocity commits it',
      ),
    );
    expect(value, isTrue);
    expect(feedback.played, [FeedbackKind.toggleOn]);
  });

  testWidgets('a flick back commits from past the midpoint', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = true;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await _swipe(
      tester,
      [-32],
      gap: const Duration(milliseconds: 5),
      whileHeld: () => _expectCap(
        tester,
        greaterThan(tester.getCenter(_toggle).dx),
        why: 'the cap is still past the midpoint: only the velocity opens it',
      ),
    );
    expect(value, isFalse);
    expect(feedback.played, [FeedbackKind.toggleOff]);
  });

  testWidgets('the same throw crawled leaves the switch alone', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(
      wizTestApp(
        _liveToggle(() => value, (v) => value = v),
        feedback: feedback,
      ),
    );
    await _swipe(tester, [32]);
    expect(
      value,
      isFalse,
      reason: 'without the velocity, 32 px never reaches the midpoint',
    );
    expect(feedback.played, isEmpty);
  });

  testWidgets('a drag that starts in the hit padding still moves the cap', (
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
    // Two pixels below the track, inside the padding that takes the toggle
    // out to its 44 hit area.
    var below = Offset(
      tester.getCenter(_toggle).dx,
      tester.getBottomLeft(_track).dy + 2,
    );
    expect(
      below.dy,
      lessThan(tester.getBottomLeft(_toggle).dy),
      reason: 'the drag has to start inside the toggle to mean anything',
    );
    await _swipe(
      tester,
      [64],
      from: below,
      whileHeld: () => _expectCap(
        tester,
        greaterThan(tester.getCenter(_toggle).dx),
        why: 'the padding is part of the control, not a dead zone',
      ),
    );
    expect(value, isTrue);
    expect(feedback.played, [FeedbackKind.toggleOn]);
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
    await tester.tap(_toggle);
    await tester.pumpAndSettle();
    await tester.fling(_toggle, const Offset(40, 0), 800);
    await tester.pumpAndSettle();
    expect(changed, isFalse);
    expect(feedback.played, isEmpty);
  });

  testWidgets('a toggle with no handler is disabled however it is asked', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    try {
      await tester.pumpWidget(
        wizTestApp(
          const WizToggle(value: false, onChanged: null, semanticsLabel: 'x'),
          feedback: feedback,
        ),
      );
      await tester.tap(_toggle);
      await tester.pumpAndSettle();
      await tester.fling(_toggle, const Offset(40, 0), 800);
      await tester.pumpAndSettle();
      expect(feedback.played, isEmpty);
      expect(
        find.semantics.byLabel('x'),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('the focus ring traces the track, not the hit area', (
    tester,
  ) async {
    // The highlight only shows when the last interaction was a key.
    var previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);

    await tester.pumpWidget(
      wizTestApp(
        WizToggle(value: false, onChanged: (_) {}, semanticsLabel: 'Power'),
      ),
    );
    expect(_focusRing, findsNothing);
    var detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: _toggle,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(
      tester.getSize(_focusRing),
      const Size(60, 33),
      reason: 'the ring traces the rocker, not the padding around it',
    );
    expect(tester.getSize(_toggle), const Size(60, 44));
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
        of: _toggle,
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
      // Addressed by label rather than by widget: the drag detector now sits
      // above the pressable, so the toggle's outermost render object is no
      // longer the one that owns the semantics node. One node, though —
      // nothing above the pressable contributes a second.
      expect(find.semantics.byLabel('Power'), findsOne);
      expect(
        find.semantics.byLabel('Power'),
        isSemantics(
          label: 'Power',
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
          isEnabled: true,
          // The node still covers the whole hit area, not just the track.
          size: const Size(60, 44),
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Power'));
      await tester.pumpAndSettle();
      expect(value, isFalse);
      expect(find.semantics.byLabel('Power'), isSemantics(isToggled: false));
    } finally {
      handle.dispose();
    }
  });
}
