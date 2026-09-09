import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';

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

  testWidgets('the wheel never grows past the width a phone gives it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        WizColorWheel(hue: 0, saturation: 1, size: 400, onChanged: (_) {}),
      ),
    );
    // The number itself, not the token that sets it: 228 is what spec §14
    // promises, and a token that drifted would still have to answer for it.
    expect(tester.getSize(find.byType(WizColorWheel)), const Size(228, 228));
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
}
