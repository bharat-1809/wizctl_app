import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_art.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';

import '../../support/wiz_test_app.dart';

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
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
