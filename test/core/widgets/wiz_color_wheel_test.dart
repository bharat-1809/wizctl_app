import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';

import 'package:wizctl_app/core/widgets/wiz_color_wheel_disc.dart';

import '../../support/wiz_test_app.dart';

/// The amber ring a keyboard-focused wheel draws (spec §11.2) — matched on
/// the colour it paints, since the 8 px char-900 rim inside the disc is a
/// bordered box too.
final Finder _focusRing = find.descendant(
  of: find.byType(WizColorWheel),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).border?.top.color ==
            WizColors.standard.focusRing,
  ),
);

/// The centre wash: the one radial gradient the disc paints.
final Finder _wash = find.descendant(
  of: find.byType(WizColorWheel),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).gradient is RadialGradient,
  ),
);

/// Where a 200 px wheel puts [hue] at [saturation], as a global offset from
/// the disc's [centre]: the same maths the puck rides, so a gesture aimed
/// here lands on that colour. The usable radius is 100 − the 18 px margin.
Offset _at(Offset centre, double hue, double saturation) {
  var radians = (hue - 90) * math.pi / 180;
  var reach = (100 - WizColorWheel.radiusMargin) * saturation;
  return centre + Offset(math.cos(radians) * reach, math.sin(radians) * reach);
}

/// The wheel's own focus node, so keyboard focus can be driven from outside.
FocusNode _focusNodeOf(WidgetTester tester) => tester
    .widget<Focus>(
      find.descendant(
        of: find.byType(WizColorWheel),
        matching: find.byType(Focus),
      ),
    )
    .focusNode!;

void main() {
  testWidgets(
    'tapping to the right of centre gives hue 90 at full saturation',
    (tester) async {
      var feedback = RecordingFeedbackService();
      WizHsv? got;
      await tester.pumpWidget(
        wizTestApp(
          WizColorWheel(
            hue: 30,
            saturation: 0,
            size: 200,
            onChanged: (v) => got = v,
          ),
          feedback: feedback,
        ),
      );
      var center = tester.getCenter(find.byType(WizColorWheel));
      await tester.tapAt(center + const Offset(90, 0));
      await tester.pump();
      expect(got, isNotNull);
      expect(got!.hue, closeTo(90, 1));
      expect(got!.saturation, closeTo(1, 0.02));
      expect(feedback.played.first, FeedbackKind.press);
    },
  );

  testWidgets('the centre is white and dragging around fires detents', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    WizHsv? got;
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(
          hue: 0,
          saturation: 1,
          size: 200,
          onChanged: (v) => got = v,
        ),
        feedback: feedback,
      ),
    );
    var center = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(center);
    await tester.pump();
    expect(got!.saturation, closeTo(0, 0.02));
    expect(got!.color, const Color(0xFFFFFFFF));
    await tester.timedDrag(
      find.byType(WizColorWheel),
      const Offset(0, 80),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(
      feedback.played.where((k) => k == FeedbackKind.detent).length,
      greaterThan(0),
      // The touch lands dead centre, where `atan2(0, 0)` reads hue 90 (notch
      // 6); one pixel down the angle is straight below the centre, hue 180
      // (notch 12). That crossing is the detent — the rest of the drag stays
      // on the same radius and so stays silent.
      reason: 'leaving the centre downwards crosses from hue 90 to hue 180',
    );
  });

  testWidgets('crossing 12 o\'clock sounds one detent, not two', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 345, saturation: 1, size: 200, onChanged: (_) {}),
        feedback: feedback,
      ),
    );
    var centre = tester.getCenter(find.byType(WizColorWheel));
    // Down inside notch 23, then straight out to the rim — 49 px, enough for
    // the pan to win its arena, and all of it at one hue — and only then
    // across the seam. 356° and 2° are both inside the notch that spans 12
    // o'clock, so the ring notches once on the way into it and not again on
    // the way out.
    var touch = await tester.startGesture(_at(centre, 345, 0.4));
    await touch.moveTo(_at(centre, 345, 1));
    await tester.pump();
    await touch.moveTo(_at(centre, 356, 1));
    await tester.pump();
    await touch.moveTo(_at(centre, 2, 1));
    await tester.pump();
    await touch.up();
    await tester.pumpAndSettle();
    expect(
      feedback.played.where((k) => k == FeedbackKind.detent).length,
      1,
      reason: 'the notch at the top is one notch, not both 0 and 24',
    );
  });

  testWidgets('a drag ends once, on the colour it settled on', (tester) async {
    var value = const WizHsv(0, 1);
    var changed = <WizHsv>[];
    var ended = <WizHsv>[];
    await tester.pumpWidget(
      wizTestApp(
        StatefulBuilder(
          builder: (context, setState) => WizColorWheel(
            hue: value.hue,
            saturation: value.saturation,
            size: 200,
            onChanged: (v) {
              changed.add(v);
              setState(() => value = v);
            },
            onChangeEnd: ended.add,
          ),
        ),
      ),
    );
    await tester.timedDrag(
      find.byType(WizColorWheel),
      const Offset(0, 80),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    // Straight down from the centre is hue 180, and 80 of the 82 usable
    // pixels out is saturation 0.976.
    expect(ended, [const WizHsv(180, 0.976)]);
    expect(
      ended.single,
      changed.last,
      reason: 'the change that ended is the last one it reported',
    );
  });

  testWidgets('a second touch reports even when the first was ignored', (
    tester,
  ) async {
    var changed = <WizHsv>[];
    await tester.pumpWidget(
      wizTestApp(
        // Uncontrolled: the wheel keeps being told hue 0, so both taps land
        // on a colour it is not showing and both are news to the caller.
        WizColorWheel(hue: 0, saturation: 1, size: 200, onChanged: changed.add),
      ),
    );
    var centre = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(_at(centre, 90, 1));
    await tester.pumpAndSettle();
    await tester.tapAt(_at(centre, 90, 1));
    await tester.pumpAndSettle();
    expect(changed, [
      const WizHsv(90, 1),
      const WizHsv(90, 1),
    ], reason: 'the dedupe is scoped to one touch, not to the widget');
  });

  testWidgets('a tap on the puck changes nothing and ends nothing', (
    tester,
  ) async {
    var changed = <WizHsv>[];
    var ended = <WizHsv>[];
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(
          hue: 180,
          saturation: 1,
          size: 200,
          onChanged: changed.add,
          onChangeEnd: ended.add,
        ),
      ),
    );
    var centre = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(_at(centre, 180, 1));
    await tester.pumpAndSettle();
    expect(changed, isEmpty);
    expect(ended, isEmpty, reason: 'nothing moved, so nothing ended');
  });

  testWidgets('the wheel never grows past the width a phone gives it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 0, saturation: 1, size: 400, onChanged: (_) {}),
      ),
    );
    // The numbers themselves, not the tokens that set them: 228 is what
    // spec §14 promises and 44 the touch target it will not go below, and a
    // token that drifted would still have to answer for both.
    expect(tester.getSize(find.byType(WizColorWheel)), const Size(228, 228));

    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 0, saturation: 1, size: 10, onChanged: (_) {}),
      ),
    );
    expect(tester.getSize(find.byType(WizColorWheel)), const Size(44, 44));
  });

  testWidgets('the centre wash reaches the corner of its box', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 30, saturation: 1, size: 200, onChanged: (_) {}),
      ),
    );
    var gradient =
        (tester.widget<DecoratedBox>(_wash).decoration as BoxDecoration)
                .gradient!
            as RadialGradient;
    // CSS sizes a `radial-gradient` to the farthest corner; Flutter measures
    // `radius` against the shortest side, so the square wash box needs √2/2
    // to put the 62 % stop where the design does.
    expect(gradient.radius, math.sqrt2 / 2);
    expect(gradient.stops, <double>[0, WizColorWheel.whiteStop]);
  });

  testWidgets('a keyboard-focused wheel draws the amber ring round its disc', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 30, saturation: 1, size: 200, onChanged: (_) {}),
      ),
    );
    expect(_focusRing, findsNothing);
    _focusNodeOf(tester).requestFocus();
    await tester.pumpAndSettle();

    var decoration =
        tester.widget<DecoratedBox>(_focusRing).decoration as BoxDecoration;
    expect(decoration.border!.top.color, WizColors.standard.focusRing);
    expect(decoration.border!.top.width, WizSpace.standard.focusRing);
    expect(
      decoration.shape,
      BoxShape.circle,
      reason: 'the ring traces the disc, not a box around it',
    );
    expect(tester.getSize(_focusRing), const Size(200, 200));
  });

  testWidgets('a disabled wheel neither moves nor takes focus', (tester) async {
    // Semantics on: a disabled wheel still builds a node, and one that reads
    // out an increase it cannot perform would trip the framework.
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    var changed = <WizHsv>[];
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(
          hue: 30,
          saturation: 0.5,
          size: 200,
          enabled: false,
          onChanged: changed.add,
        ),
        feedback: feedback,
      ),
    );
    var center = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(center + const Offset(90, 0));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.byType(WizColorWheel),
      const Offset(0, 80),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(changed, isEmpty);
    expect(feedback.played, isEmpty);

    var node = _focusNodeOf(tester);
    expect(node.canRequestFocus, isFalse);
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(node.hasFocus, isFalse);
    expect(_focusRing, findsNothing);

    expect(
      find.semantics.byLabel('Colour wheel'),
      isSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
      reason: 'a disabled wheel offers assistive tech no step either',
    );
    handle.dispose();
  });

  testWidgets(
    'an arrow key turns the wheel by one detent and ends the change',
    (tester) async {
      var feedback = RecordingFeedbackService();
      var value = const WizHsv(30, 1);
      var ended = <WizHsv>[];
      await tester.pumpWidget(
        wizTestApp(
          StatefulBuilder(
            builder: (context, setState) => WizColorWheel(
              hue: value.hue,
              saturation: value.saturation,
              size: 200,
              onChanged: (v) => setState(() => value = v),
              onChangeEnd: ended.add,
            ),
          ),
          feedback: feedback,
        ),
      );
      _focusNodeOf(tester).requestFocus();
      await tester.pump();
      expect(_focusNodeOf(tester).hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(value.hue, 45);
      expect(ended, [const WizHsv(45, 1)]);
      expect(feedback.played, [FeedbackKind.detent]);

      // The other axis moves saturation, and crosses no hue notch on the way.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(value, const WizHsv(45, 0.95));
      expect(ended, [const WizHsv(45, 1), const WizHsv(45, 0.95)]);
      expect(feedback.played, [
        FeedbackKind.detent,
      ], reason: 'saturation crosses no hue notch, so it sounds no detent');
    },
  );

  testWidgets('a step that lands where the last one did ends no change', (
    tester,
  ) async {
    var ended = <WizHsv>[];
    await tester.pumpWidget(
      wizTestApp(
        // Uncontrolled on purpose: the wheel is told hue 30 whatever it
        // reports, so the second arrow key recomputes the same 45 the first
        // one settled on.
        WizColorWheel(
          hue: 30,
          saturation: 1,
          size: 200,
          onChanged: (_) {},
          onChangeEnd: ended.add,
        ),
      ),
    );
    _focusNodeOf(tester).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(ended, [
      const WizHsv(45, 1),
    ], reason: 'the wheel never left 45, so only the move onto it ended');
  });

  testWidgets('the wheel reads its colour out and offers a step either way', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 30, saturation: 0.5, size: 200, onChanged: (_) {}),
      ),
    );
    expect(
      find.semantics.byLabel('Colour wheel'),
      isSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: true,
        value: 'Hue 30°, saturation 50%',
        increasedValue: 'Hue 45°, saturation 50%',
        decreasedValue: 'Hue 15°, saturation 50%',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    handle.dispose();
  });
  testWidgets('a wheel in a narrow box paints and reads at the box width', (
    tester,
  ) async {
    var changed = <WizHsv>[];
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 120,
          child: WizColorWheel(
            hue: 0,
            saturation: 0,
            size: 228,
            onChanged: changed.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(WizColorWheelDisc)),
      const Size(120, 120),
      reason: 'the disc paints at the width its parent has, not past it',
    );

    // Half way out on a 120 disc is (60 - 18) / 2 = 21 px above the centre,
    // which is hue 0 at saturation .5. Read against the 228 the wheel was
    // asked for, the same touch would be a fifth of the way out instead.
    var centre = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(centre + const Offset(0, -21));
    await tester.pumpAndSettle();
    expect(changed, [const WizHsv(0, 0.5)]);
  });
  testWidgets('a wheel with no handler is inert and announced disabled', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(
      wizTestApp(
        const WizColorWheel(hue: 30, saturation: 1, size: 200, onChanged: null),
        feedback: feedback,
      ),
    );
    var centre = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(_at(centre, 200, 1));
    await tester.pumpAndSettle();
    expect(feedback.played, isEmpty);

    var node = _focusNodeOf(tester);
    expect(node.canRequestFocus, isFalse);
    node.requestFocus();
    await tester.pumpAndSettle();
    expect(node.hasFocus, isFalse);
    expect(_focusRing, findsNothing);

    expect(
      find.semantics.byLabel('Colour wheel'),
      isSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
      reason: 'nowhere to report to is nothing to offer',
    );
    handle.dispose();
  });
}
