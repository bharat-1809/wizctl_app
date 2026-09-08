import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';

import '../../support/wiz_test_app.dart';

/// The amber ring a keyboard-focused dial draws (spec §11.2) — matched on
/// what it paints, not on how it is built.
final Finder _focusRing = find.descendant(
  of: find.byType(WizDial),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).border?.top.color ==
            WizColors.standard.focusRing,
  ),
);

/// The dial's own focus node, so keyboard focus can be driven from outside.
FocusNode _focusNodeOf(WidgetTester tester) => tester
    .widget<Focus>(
      find.descendant(of: find.byType(WizDial), matching: find.byType(Focus)),
    )
    .focusNode!;

void main() {
  testWidgets('dragging up raises the value and fires detents', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 50.0;
    var ended = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            return WizDial(
              value: value,
              min: 10,
              max: 100,
              size: 132,
              label: 'Brightness',
              onChanged: (v) => setState(() => value = v),
              onChangeEnd: ended.add,
            );
          },
        ),
        feedback: feedback,
      ),
    );
    expect(find.text('50'), findsOneWidget);
    await tester.timedDrag(
      find.byType(WizDial),
      const Offset(0, -80),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    // 80 px of 160 px travel is half the 90-unit range: 50 + 45.
    expect(value, closeTo(95, 1));
    expect(find.text('95'), findsOneWidget);
    expect(feedback.played.first, FeedbackKind.press);
    expect(
      feedback.played.where((k) => k == FeedbackKind.detent).length,
      greaterThan(5),
    );
    expect(ended, [value]);
  });

  testWidgets('values clamp to the range and snap to step', (tester) async {
    var value = 2700.0;
    await tester.pumpWidget(
      wizTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            return WizDial(
              value: value,
              min: 2200,
              max: 6500,
              step: 50,
              size: 132,
              unit: 'K',
              onChanged: (v) => setState(() => value = v),
            );
          },
        ),
      ),
    );
    await tester.timedDrag(
      find.byType(WizDial),
      const Offset(0, 400),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(value, 2200);
    await tester.timedDrag(
      find.byType(WizDial),
      const Offset(0, -33),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(value % 50, 0);
    expect(find.textContaining('K'), findsWidgets);
  });

  testWidgets('the dial is as wide as it is told and shows its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        WizDial(
          value: 30,
          min: 10,
          max: 100,
          size: 118,
          label: 'Brightness',
          onChanged: (_) {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(WizDial)).width, 118);
    expect(find.text('BRIGHTNESS'), findsOneWidget);
  });

  testWidgets('a size outside the design range is clamped to it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WizDial(value: 50, min: 0, max: 100, size: 400, onChanged: (_) {}),
            WizDial(value: 50, min: 0, max: 100, size: 10, onChanged: (_) {}),
          ],
        ),
      ),
    );
    var dials = tester.widgetList(find.byType(WizDial)).toList();
    expect(tester.getSize(find.byWidget(dials.first)).width, WizDial.maxSize);
    expect(tester.getSize(find.byWidget(dials.last)).width, WizDial.minSize);
  });

  testWidgets('a keyboard-focused dial draws the amber ring around its disc', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        WizDial(value: 50, min: 10, max: 100, size: 132, onChanged: (_) {}),
      ),
    );
    expect(_focusRing, findsNothing);
    _focusNodeOf(tester).requestFocus();
    await tester.pumpAndSettle();

    var border =
        (tester.widget<DecoratedBox>(_focusRing).decoration as BoxDecoration)
            .border!;
    expect(border.top.color, WizColors.standard.focusRing);
    expect(border.top.width, WizSpace.standard.focusRing);
    expect(
      tester.getSize(_focusRing),
      const Size(132, 132),
      reason: 'the ring traces the disc, not the label under it',
    );
  });

  testWidgets('an arrow key steps the value and ends the change', (
    tester,
  ) async {
    var value = 50.0;
    var ended = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            return WizDial(
              value: value,
              min: 10,
              max: 100,
              size: 132,
              onChanged: (v) => setState(() => value = v),
              onChangeEnd: ended.add,
            );
          },
        ),
      ),
    );
    _focusNodeOf(tester).requestFocus();
    await tester.pump();
    expect(_focusNodeOf(tester).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    // One arrow is a step of 1 times the five the design moves per key.
    expect(value, 55);
    expect(ended, [55.0]);
  });

  testWidgets('assistive tech sees a labelled slider that reports its value', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        wizTestApp(
          WizDial(
            value: 50,
            min: 10,
            max: 100,
            size: 132,
            label: 'Brightness',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.semantics.byLabel('Brightness'), findsOne);
      expect(
        find.semantics.byLabel('Brightness'),
        isSemantics(
          label: 'Brightness',
          value: '50%',
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
    } finally {
      handle.dispose();
    }
  });
}
