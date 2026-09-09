import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/theme/wiz_type.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_art.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';

import '../../support/wiz_test_app.dart';

/// The label scrim: the only [Container] the tile decorates with a gradient.
Container scrimOf(WidgetTester tester) => tester.widget<Container>(
  find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).gradient != null,
    description: 'the label scrim',
  ),
);

double scrimAlphaOf(WidgetTester tester) {
  var decoration = scrimOf(tester).decoration! as BoxDecoration;
  return (decoration.gradient! as LinearGradient).colors.last.a;
}

void main() {
  testWidgets('shows the scene name, a pip for dynamic scenes, and taps', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WizSceneTile(
                sceneId: 1,
                selected: false,
                height: 82,
                onTap: () => taps++,
              ),
              WizSceneTile(
                sceneId: 6,
                selected: true,
                height: 82,
                onTap: () {},
              ),
            ],
          ),
        ),
        feedback: feedback,
      ),
    );
    expect(find.text('Ocean'), findsOneWidget);
    expect(find.text('Cozy'), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-6')), findsOneWidget);
    expect(find.byKey(const Key('scene-pip-1')), findsOneWidget);
    expect(find.byKey(const Key('scene-pip-6')), findsNothing);
    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(feedback.played, [FeedbackKind.tick]);
  });

  testWidgets('a selected tile reports its state to assistive technology', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 160,
          height: 82,
          child: WizSceneTile(
            sceneId: 6,
            selected: true,
            height: 82,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(
      find.semantics.byLabel(RegExp('Cozy')),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the tab variant is the default: sheen, 20 px, 700, r4', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 160,
          child: WizSceneTile(
            sceneId: 1,
            selected: false,
            height: 82,
            onTap: () {},
          ),
        ),
      ),
    );
    var art = tester.widget<WizSceneArt>(find.byType(WizSceneArt));
    expect(art.sheen, isTrue);
    expect(
      art.radius,
      BorderRadius.circular(WizSpace.standard.r4),
      reason: 'tab tiles use --radius-4',
    );
    var style = tester.widget<Text>(find.text('Ocean')).style!;
    expect(style.fontSize, WizSceneTile.labelSizeTab);
    expect(style.fontWeight, FontWeight.w700);
    expect(style.fontFamily, WizType.familyDisplay);
    expect(scrimAlphaOf(tester), closeTo(.86, 0.001));
    expect(
      scrimOf(tester).padding,
      EdgeInsets.symmetric(horizontal: WizSpace.standard.s5, vertical: 10),
      reason: 'the tab scrim pads 10px 12px',
    );
    expect(
      style.height,
      WizType.standard.heading.height,
      reason: 'the reference sets no line-height, so the face\'s own stands',
    );
  });

  testWidgets('the sheet variant drops the sheen and tightens the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 110,
          child: WizSceneTile(
            sceneId: 1,
            selected: false,
            height: 82,
            variant: WizSceneTileVariant.sheet,
            onTap: () {},
          ),
        ),
      ),
    );
    var art = tester.widget<WizSceneArt>(find.byType(WizSceneArt));
    expect(art.sheen, isFalse);
    expect(
      art.radius,
      BorderRadius.circular(WizSpace.standard.r3),
      reason: 'sheet tiles use --radius-3',
    );
    var style = tester.widget<Text>(find.text('Ocean')).style!;
    expect(style.fontSize, WizSceneTile.labelSizeSheet);
    expect(style.fontWeight, FontWeight.w600);
    expect(scrimAlphaOf(tester), closeTo(.88, 0.001));
    expect(
      scrimOf(tester).padding,
      EdgeInsets.symmetric(
        horizontal: WizSpace.standard.s4,
        vertical: WizSpace.standard.s3,
      ),
      reason: 'the sheet scrim pads 6px 8px',
    );
  });

  testWidgets('the label tracks the display face, not the chip', (
    tester,
  ) async {
    for (var variant in WizSceneTileVariant.values) {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 160,
            child: WizSceneTile(
              sceneId: 1,
              selected: false,
              height: 82,
              variant: variant,
              onTap: () {},
            ),
          ),
        ),
      );
      var style = tester.widget<Text>(find.text('Ocean')).style!;
      expect(
        style.letterSpacing,
        style.fontSize! * WizType.sceneTileTracking,
        reason: '$variant tracks 0.02 em',
      );
    }
  });

  testWidgets('explicit arguments override the variant', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 160,
          child: WizSceneTile(
            sceneId: 1,
            selected: false,
            height: 82,
            variant: WizSceneTileVariant.sheet,
            sheen: true,
            labelSize: 17,
            radius: 9,
            onTap: () {},
          ),
        ),
      ),
    );
    var art = tester.widget<WizSceneArt>(find.byType(WizSceneArt));
    expect(art.sheen, isTrue);
    expect(art.radius, BorderRadius.circular(9));
    var style = tester.widget<Text>(find.text('Ocean')).style!;
    expect(style.fontSize, 17);
    expect(style.letterSpacing, 17 * WizType.sceneTileTracking);
  });

  testWidgets('scene art paints from a scene id', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 120,
          height: 120,
          child: WizSceneArt.scene(
            29,
            radius: const BorderRadius.all(Radius.circular(20)),
            sheen: true,
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(WizSceneArt),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is WizSceneArtPainter,
          description: "a CustomPaint driven by the art's own painter",
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
