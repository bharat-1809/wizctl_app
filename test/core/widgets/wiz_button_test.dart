import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_chip.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets(
    'buttons take their height from the size and uppercase the label',
    (tester) async {
      await tester.pumpWidget(
        wizTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WizButton(
                label: 'Create home',
                onPressed: () {},
                size: WizButtonSize.sm,
              ),
              WizButton(label: 'Create home', onPressed: () {}),
              WizButton(
                label: 'Create home',
                onPressed: () {},
                size: WizButtonSize.lg,
              ),
            ],
          ),
        ),
      );
      var boxes = tester
          .widgetList(find.byType(WizButton))
          .map((w) => tester.getSize(find.byWidget(w)).height)
          .toList();
      expect(boxes, [
        44,
        48,
        56,
      ], reason: 'the small cap is padded out to the touch minimum');
      var caps = find.descendant(
        of: find.byType(WizButton),
        matching: find.byType(WizSurface),
      );
      expect(List.generate(3, (i) => tester.getSize(caps.at(i)).height), [
        36,
        48,
        56,
      ], reason: 'the cap itself keeps the height its size calls for');
      expect(find.text('CREATE HOME'), findsNWidgets(3));
    },
  );

  testWidgets('primary fires confirm, danger fires reject, ghost fires press', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(
      wizTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WizButton(
              label: 'A',
              variant: WizButtonVariant.primary,
              onPressed: () {},
            ),
            WizButton(
              label: 'B',
              variant: WizButtonVariant.danger,
              onPressed: () {},
            ),
            WizButton(
              label: 'C',
              variant: WizButtonVariant.ghost,
              onPressed: () {},
            ),
          ],
        ),
        feedback: feedback,
      ),
    );
    await tester.tap(find.text('A'));
    await tester.tap(find.text('B'));
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(feedback.played, [
      FeedbackKind.confirm,
      FeedbackKind.reject,
      FeedbackKind.press,
    ]);
  });

  testWidgets('a full-width button fills its parent', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: WizButton(label: 'Go', fullWidth: true, onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(WizButton)).width, 300);
  });

  testWidgets('a button that is not full width shrink-wraps its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [WizButton(label: 'Go', onPressed: () {})],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(WizButton)).width,
      lessThan(300),
      reason: 'only fullWidth: true should fill the parent',
    );
  });

  testWidgets('a disabled button neither taps nor fires feedback', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        WizButton(label: 'Nope', enabled: false, onPressed: () => taps++),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizButton));
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(feedback.played, isEmpty);
  });

  testWidgets('icon keys are square and chips are pills', (tester) async {
    // Disposed in a finally, not a tear-down: flutter_test verifies that no
    // semantics handle is still open at the end of the test body, which runs
    // before any tear-down, and a failing expect must not leak one either.
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        wizTestApp(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              WizIconKey(
                icon: WizIcons.house,
                onPressed: () {},
                semanticsLabel: 'Homes',
              ),
              WizChip(label: 'Living Room', selected: true, onTap: () {}),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(WizIconKey)), const Size(44, 44));
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(WizChip),
                    matching: find.byType(WizSurface),
                  )
                  .first,
            )
            .height,
        WizSpace.standard.controlSm,
      );
      expect(find.bySemanticsLabel('Homes'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('the focus ring traces a circular icon key', (tester) async {
    var previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);

    await tester.pumpWidget(
      wizTestApp(
        WizIconKey(
          icon: WizIcons.house,
          onPressed: () {},
          semanticsLabel: 'Homes',
        ),
      ),
    );
    tester
        .widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(WizIconKey),
            matching: find.byType(FocusableActionDetector),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pumpAndSettle();

    var ring = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(WizIconKey),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((decoration) => decoration.border != null);
    expect(
      ring.borderRadius,
      BorderRadius.circular(WizSpace.standard.hitMin / 2),
      reason: 'a circular key gets a circular ring, not a rounded box',
    );
  });

  testWidgets('a chip keeps the full hit minimum around its 36 pt cap', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(WizChip(label: 'Living Room', onTap: () {})),
    );
    expect(
      tester.getSize(find.byType(WizChip)).height,
      WizSpace.standard.hitMin,
    );
  });

  testWidgets('a chip that is not full width shrink-wraps its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [WizChip(label: 'Den', onTap: () {})],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(WizChip)).width, lessThan(300));
  });
}
