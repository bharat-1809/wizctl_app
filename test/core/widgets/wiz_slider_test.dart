import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';

import '../../support/wiz_test_app.dart';

/// The interactive box: everything the finger may land on, not just the
/// 14 px rail drawn inside it.
final Finder _track = find.byKey(const Key('wiz-slider-track'));

/// The amber ring a keyboard-focused slider draws (spec §11.2) — matched on
/// what it paints, not on how it is built.
final Finder _focusRing = find.descendant(
  of: find.byType(WizSlider),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).border?.top.color ==
            WizColors.standard.focusRing,
  ),
);

/// The slider's own focus node, so keyboard focus can be driven from outside.
FocusNode _focusNodeOf(WidgetTester tester) => tester
    .widget<Focus>(
      find.descendant(of: find.byType(WizSlider), matching: find.byType(Focus)),
    )
    .focusNode!;

void main() {
  testWidgets('tapping the rail sets the value proportionally', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 10.0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) {
              return WizSlider(
                value: value,
                min: 10,
                max: 100,
                label: 'Speed',
                readout: '$value',
                onChanged: (v) => setState(() => value = v),
              );
            },
          ),
        ),
        feedback: feedback,
      ),
    );
    var rect = tester.getRect(_track);
    await tester.tapAt(Offset(rect.left + rect.width * 0.5, rect.center.dy));
    await tester.pumpAndSettle();
    expect(value, closeTo(55, 1));
    expect(feedback.played.first, FeedbackKind.press);
  });

  testWidgets('dragging fires detents and reports the end value', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var value = 10.0;
    double? ended;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) {
              return WizSlider(
                value: value,
                min: 10,
                max: 200,
                fill: WizSliderFill.speed,
                onChanged: (v) => setState(() => value = v),
                onChangeEnd: (v) => ended = v,
              );
            },
          ),
        ),
        feedback: feedback,
      ),
    );
    var rect = tester.getRect(_track);
    await tester.timedDrag(
      _track,
      Offset(rect.width, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(value, 200);
    expect(ended, 200);
    expect(
      feedback.played.where((k) => k == FeedbackKind.detent).length,
      greaterThan(3),
    );
  });

  testWidgets('a tap that lands on the current value ends no change', (
    tester,
  ) async {
    var changed = <double>[];
    var ended = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizSlider(
            value: 50,
            min: 0,
            max: 100,
            onChanged: changed.add,
            onChangeEnd: ended.add,
          ),
        ),
      ),
    );
    var rect = tester.getRect(_track);
    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();
    expect(changed, isEmpty);
    expect(ended, isEmpty, reason: 'nothing moved, so nothing ended');
  });

  testWidgets('label is uppercase and readout shows', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 200,
          child: WizSlider(
            value: 50,
            min: 10,
            max: 100,
            label: 'Brightness',
            readout: '50%',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('BRIGHTNESS'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('the rail is thin but the finger gets a full touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizSlider(value: 50, min: 0, max: 100, onChanged: (_) {}),
        ),
      ),
    );
    expect(tester.getSize(_track).height, WizSpace.standard.hitMin);
  });

  testWidgets('a keyboard-focused slider draws the amber ring around its box', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizSlider(value: 50, min: 0, max: 100, onChanged: (_) {}),
        ),
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
      Size(300, WizSpace.standard.hitMin),
      reason: 'the ring traces the box the finger lands on',
    );
  });

  testWidgets('a disabled slider neither moves nor takes focus', (
    tester,
  ) async {
    // Semantics on: a disabled slider still builds a node, and one that
    // reads out an increase it cannot perform would trip the framework.
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    var changed = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizSlider(
            value: 50,
            min: 0,
            max: 100,
            label: 'Brightness',
            enabled: false,
            onChanged: changed.add,
          ),
        ),
        feedback: feedback,
      ),
    );
    var rect = tester.getRect(_track);
    await tester.tapAt(Offset(rect.left + rect.width * 0.25, rect.center.dy));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      _track,
      Offset(rect.width, 0),
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
      find.semantics.byLabel('Brightness'),
      isSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
      reason: 'a disabled slider offers assistive tech no step either',
    );
    handle.dispose();
  });

  testWidgets('an arrow key steps the value and ends the change', (
    tester,
  ) async {
    var value = 2700.0;
    var ended = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) {
              return WizSlider(
                value: value,
                min: 2200,
                max: 6500,
                step: 50,
                onChanged: (v) => setState(() => value = v),
                onChangeEnd: ended.add,
              );
            },
          ),
        ),
      ),
    );
    _focusNodeOf(tester).requestFocus();
    await tester.pump();
    expect(_focusNodeOf(tester).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 2750);
    expect(ended, [2750.0]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 2700);
    expect(ended, [2750.0, 2700.0]);
  });

  testWidgets('assistive tech sees a labelled slider that reports its value', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 300,
            child: WizSlider(
              value: 50,
              min: 0,
              max: 100,
              label: 'Brightness',
              readout: '50%',
              onChanged: (_) {},
            ),
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
          // A synthetic scroll drives the drag with a global position the
          // widget would read as a local one, so the rail offers its two
          // steps and nothing else.
          hasScrollLeftAction: false,
          hasScrollRightAction: false,
        ),
      );
    } finally {
      handle.dispose();
    }
  });
}
