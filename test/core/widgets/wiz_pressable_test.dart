import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/widgets/wiz_pressable.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a press sinks the child, fires feedback and taps', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    late WizPressState seen;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          feedback: FeedbackKind.tick,
          onTap: () => taps++,
          builder: (context, state) {
            seen = state;
            return const SizedBox(width: 60, height: 44, key: Key('k'));
          },
        ),
        feedback: feedback,
      ),
    );
    var before = tester.getTopLeft(find.byKey(const Key('k')));
    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('k'))),
    );
    // A bare pump first so the sink tween has started before the frame the
    // travel is measured on.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(seen.pressed, isTrue);
    expect(feedback.played, [FeedbackKind.tick]);
    var during = tester.getTopLeft(find.byKey(const Key('k')));
    expect(during.dy, greaterThan(before.dy));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(seen.pressed, isFalse);
    expect(taps, 1);
  });

  testWidgets('disabled pressables neither sink nor tap', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          enabled: false,
          onTap: () => taps++,
          builder: (_, _) => const SizedBox(width: 60, height: 44),
        ),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizPressable));
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(feedback.played, isEmpty);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(WizPressable),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      WizColors.disabledAlpha,
    );
  });

  testWidgets('hovering brightens an enabled pressable', (tester) async {
    var previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);

    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          onTap: () {},
          builder: (_, _) => const SizedBox(width: 60, height: 44),
        ),
      ),
    );
    var filter = find.descendant(
      of: find.byType(WizPressable),
      matching: find.byType(ColorFiltered),
    );
    expect(filter, findsNothing);

    var mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byType(WizPressable)));
    await tester.pumpAndSettle();
    expect(filter, findsOneWidget);
  });

  testWidgets('Enter and Space activate a focused pressable', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          onTap: () => taps++,
          semanticsLabel: 'Go',
          builder: (_, _) => const SizedBox(width: 60, height: 44),
        ),
        feedback: feedback,
      ),
    );
    var detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byType(WizPressable),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();
    expect(detector.focusNode!.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
    expect(feedback.played, [FeedbackKind.press]);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
    expect(feedback.played, [FeedbackKind.press, FeedbackKind.press]);
  });

  testWidgets('a keyboard-focused pressable draws the focus ring', (
    tester,
  ) async {
    // The focus highlight only shows when the last interaction was a key, so
    // the mode is pinned rather than inferred from a synthetic key event.
    var previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);

    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          onTap: () {},
          builder: (_, state) =>
              SizedBox(width: 60, height: 44, key: Key('${state.focused}')),
        ),
      ),
    );
    var detector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byType(WizPressable),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    detector.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('true')), findsOneWidget);

    var borders = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(WizPressable),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.border)
        .whereType<Border>();
    expect(
      borders.map((border) => border.top.color),
      contains(WizColors.standard.focusRing),
    );
  });

  testWidgets('a plain pressable sinks even when a child wins the tap', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var parentSank = false;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          feedback: FeedbackKind.detent,
          onTap: () {},
          builder: (context, state) {
            parentSank = parentSank || state.pressed;
            return WizPressable(
              feedback: FeedbackKind.tick,
              onTap: () {},
              builder: (_, _) =>
                  const SizedBox(width: 60, height: 44, key: Key('child')),
            );
          },
        ),
        feedback: feedback,
      ),
    );
    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('child'))),
    );
    await tester.pump();
    expect(parentSank, isTrue);
    expect(feedback.played, contains(FeedbackKind.detent));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('an arenaResolved pressable leaves the press to the arena', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var parentSank = false;
    var childTaps = 0;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          arenaResolved: true,
          feedback: FeedbackKind.detent,
          onTap: () {},
          builder: (context, state) {
            parentSank = parentSank || state.pressed;
            return WizPressable(
              feedback: FeedbackKind.tick,
              onTap: () => childTaps++,
              builder: (_, _) =>
                  const SizedBox(width: 60, height: 44, key: Key('child')),
            );
          },
        ),
        feedback: feedback,
      ),
    );
    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('child'))),
    );
    await tester.pump();
    expect(
      parentSank,
      isFalse,
      reason:
          'the same gesture that sinks a plain parent must not sink this '
          'one: the child is still in the arena',
    );
    expect(feedback.played, [FeedbackKind.tick]);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(childTaps, 1);
    expect(parentSank, isFalse);
    expect(feedback.played, [FeedbackKind.tick]);
  });

  testWidgets('an arenaResolved pressable still presses and taps on its own', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    var sank = false;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          arenaResolved: true,
          onTap: () => taps++,
          builder: (context, state) {
            sank = sank || state.pressed;
            return const SizedBox(width: 60, height: 44, key: Key('k'));
          },
        ),
        feedback: feedback,
      ),
    );
    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('k'))),
    );
    await tester.pump();
    expect(sank, isTrue, reason: 'nothing else is competing for the gesture');
    expect(feedback.played, [FeedbackKind.press]);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('an arenaResolved pressable stays sunk through a long press', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var longPresses = 0;
    var pressed = false;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          arenaResolved: true,
          onTap: () {},
          onLongPress: () => longPresses++,
          builder: (context, state) {
            pressed = state.pressed;
            return const SizedBox(width: 60, height: 44, key: Key('k'));
          },
        ),
        feedback: feedback,
      ),
    );
    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('k'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(pressed, isTrue);
    // Past kLongPressTimeout: the long press wins the arena and the tap
    // recogniser is rejected under it.
    await tester.pump(const Duration(milliseconds: 400));
    expect(longPresses, 1);
    expect(
      pressed,
      isTrue,
      reason: 'the finger has not lifted, so the part must still be down',
    );
    expect(feedback.played, [FeedbackKind.press], reason: 'one press, one cue');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pressed, isFalse);
  });

  testWidgets('the semantics tap action activates exactly once', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        WizPressable(
          onTap: () => taps++,
          semanticsLabel: 'Go',
          builder: (_, _) => const SizedBox(width: 60, height: 44),
        ),
        feedback: feedback,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Go'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(feedback.played, [FeedbackKind.press]);
    handle.dispose();
  });
}
