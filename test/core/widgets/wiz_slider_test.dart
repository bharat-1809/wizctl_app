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

  testWidgets('a slow drag opens one change, not one per recogniser', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var value = 10.0;
    var ended = <double>[];
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
                onChanged: (v) => setState(() => value = v),
                onChangeEnd: ended.add,
              );
            },
          ),
        ),
        feedback: feedback,
      ),
    );
    var rect = tester.getRect(_track);
    var half = Offset(rect.left + rect.width * 0.5, rect.center.dy);

    // Held past the tap recogniser's 100 ms deadline, so `onTapDown` fires
    // before the drag wins the arena, then wandering off the landing point
    // and back to it.
    var touch = await tester.startGesture(half);
    await tester.pump(const Duration(milliseconds: 150));
    await touch.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await touch.moveTo(half);
    await tester.pump(const Duration(milliseconds: 50));
    await touch.up();
    await tester.pumpAndSettle();

    expect(
      feedback.played.where((k) => k == FeedbackKind.press).length,
      1,
      reason: 'one touch is one press, whichever recogniser opened it',
    );
    expect(value, closeTo(55, 1));
    expect(
      ended,
      [55.0],
      reason: 'measured against where the touch landed, not where it wandered',
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
    // The number itself, not the token that sets it: 44 is the touch
    // target the spec promises, and a token that drifted would still have
    // to answer for it.
    expect(tester.getSize(_track).height, 44);
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
      const Size(300, 44),
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

  testWidgets('the first arrow key sounds like the second', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 50.0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) {
              return WizSlider(
                value: value,
                min: 0,
                max: 100,
                step: 5,
                onChanged: (v) => setState(() => value = v),
              );
            },
          ),
        ),
        feedback: feedback,
      ),
    );
    _focusNodeOf(tester).requestFocus();
    await tester.pump();

    // A twentieth of 0..100 is 5, so every step of 5 crosses a notch —
    // including the first, which had no gesture to open it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(feedback.played, [FeedbackKind.detent]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(feedback.played, [FeedbackKind.detent, FeedbackKind.detent]);
  });

  testWidgets('an empty range lays out rather than dividing by it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizSlider(value: 20, min: 20, max: 20, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_track).height, 44);
  });

  testWidgets('a step with nowhere to go ends no change', (tester) async {
    var changed = <double>[];
    var ended = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizSlider(
            value: 100,
            min: 0,
            max: 100,
            onChanged: changed.add,
            onChangeEnd: ended.add,
          ),
        ),
      ),
    );
    _focusNodeOf(tester).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changed, isEmpty);
    expect(ended, isEmpty, reason: 'a held arrow at max is not a change');
  });

  testWidgets('only the light-emitting fills glow, and a colour fill is it', (
    tester,
  ) async {
    Future<BoxDecoration> fillOf(WizSliderFill fill) async {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 300,
            child: WizSlider(
              value: 50,
              min: 0,
              max: 100,
              fill: fill,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
              .widget<DecoratedBox>(find.byKey(const Key('wiz-slider-fill')))
              .decoration
          as BoxDecoration;
    }

    expect(
      (await fillOf(WizSliderFill.brightness)).boxShadow,
      isNotEmpty,
      reason: 'brightness is light coming out of the rail',
    );
    expect(
      (await fillOf(WizSliderFill.speed)).boxShadow,
      anyOf(isNull, isEmpty),
      reason: 'speed is a rate, not an emission',
    );

    var colour = await fillOf(WizSliderFill.colour(WizColors.standard.hueTeal));
    expect((colour.gradient! as LinearGradient).colors, [
      WizColors.standard.hueTeal,
      WizColors.standard.hueTeal,
    ]);
    expect((colour.boxShadow ?? []), isEmpty);
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
          // A step reads out the number it would land on. The caller's
          // readout is one fixed string, so it cannot speak for all three.
          increasedValue: '51',
          decreasedValue: '49',
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
  testWidgets('a second touch reports even when the first was ignored', (
    tester,
  ) async {
    var changed = <double>[];
    await tester.pumpWidget(
      wizTestApp(
        // Uncontrolled: the rail keeps being told 10, so both taps land on a
        // value it is not showing and both are news to the caller.
        SizedBox(
          width: 300,
          child: WizSlider(value: 10, min: 0, max: 100, onChanged: changed.add),
        ),
      ),
    );
    var box = tester.getRect(_track);
    await tester.tapAt(Offset(box.left + box.width / 2, box.center.dy));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(box.left + box.width / 2, box.center.dy));
    await tester.pumpAndSettle();
    expect(changed, [
      50.0,
      50.0,
    ], reason: 'the dedupe is scoped to one touch, not to the widget');
  });

  testWidgets('a value arriving mid-drag does not make a still finger click', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    Widget rail(double value) => wizTestApp(
      SizedBox(
        width: 300,
        child: WizSlider(value: value, min: 0, max: 100, onChanged: (_) {}),
      ),
      feedback: feedback,
    );
    await tester.pumpWidget(rail(10));
    var box = tester.getRect(_track);
    var at = Offset(box.left + box.width * 0.1, box.center.dy);

    var finger = await tester.startGesture(at);
    // Past the slop, so the drag recogniser owns the gesture.
    await finger.moveBy(const Offset(40, 0));
    await tester.pump();
    feedback.played.clear();

    // Another source moves the light while the finger is still down.
    await tester.pumpWidget(rail(100));
    // The finger has not moved since.
    await finger.moveBy(Offset.zero);
    await tester.pump();
    expect(
      feedback.played,
      isEmpty,
      reason: 'the drag owns the notch while a finger is down',
    );

    await finger.up();
    await tester.pumpAndSettle();
  });
  testWidgets('a rail with no handler is inert and announced disabled', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 300,
          child: WizSlider(
            value: 50,
            min: 0,
            max: 100,
            label: 'Brightness',
            onChanged: null,
          ),
        ),
        feedback: feedback,
      ),
    );
    var rect = tester.getRect(_track);
    await tester.tapAt(Offset(rect.left + rect.width * 0.25, rect.center.dy));
    await tester.pumpAndSettle();
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
      reason: 'nowhere to report to is nothing to offer',
    );
    handle.dispose();
  });
  testWidgets('a value from elsewhere re-bases the next key step', (
    tester,
  ) async {
    var changed = <double>[];
    var ended = <double>[];
    Widget rail(double value) => wizTestApp(
      SizedBox(
        width: 300,
        child: WizSlider(
          value: value,
          min: 0,
          max: 100,
          onChanged: changed.add,
          onChangeEnd: ended.add,
        ),
      ),
    );

    await tester.pumpWidget(rail(50));
    _focusNodeOf(tester).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changed, [51.0]);
    expect(ended, [51.0]);

    // The owner takes the change; then another source puts the light back.
    await tester.pumpWidget(rail(51));
    await tester.pumpWidget(rail(50));
    changed.clear();
    ended.clear();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changed, [
      51.0,
    ], reason: 'the step is measured from what the rail is showing');
    expect(ended, [51.0]);
  });
}
