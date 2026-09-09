import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_art.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('shows the label, name and art; taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: ModeRow(
            art: const SceneModeArt(6),
            name: 'Cozy',
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('LIGHT MODE'), findsOneWidget);
    expect(find.text('Cozy'), findsOneWidget);
    expect(find.byType(WizSceneArt), findsOneWidget);
    await tester.tap(find.text('Cozy'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('solid and flat art render without a scene', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModeRow(
                art: const SolidModeArt(Color(0xFFFFC98D)),
                name: '2700K white',
                onTap: () {},
              ),
              ModeRow(art: const FlatModeArt(), name: 'Mixed', onTap: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(WizSceneArt), findsNothing);
    expect(find.text('Mixed'), findsOneWidget);
    // Both faces fill the art square. The switcher stacks its children
    // loosely, so a face that only painted a decoration would lay out at
    // nothing and the swatch would never be seen.
    const square = Size(ModeRow.artSize, ModeRow.artSize);
    expect(
      tester.getSize(find.byKey(const ValueKey(Color(0xFFFFC98D)))),
      square,
    );
    expect(tester.getSize(find.byKey(ModeRow.flatArtKey)), square);
  });

  testWidgets('the row is one button naming itself once', (tester) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: ModeRow(
            art: const SceneModeArt(6),
            name: 'Cozy',
            onTap: () {},
          ),
        ),
      ),
    );
    var node = tester.getSemantics(find.byType(ModeRow));
    expect(
      node,
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: true),
    );
    // The caps label and the name each name the button exactly once: the
    // row carries no `semanticsLabel` of its own, so a second copy would
    // mean the pressable and the copy inside it were both labelling it.
    expect('LIGHT MODE'.allMatches(node.label), hasLength(1));
    expect('Cozy'.allMatches(node.label), hasLength(1));
    handle.dispose();
  });

  testWidgets('a tap plays the press cue and opens the sheet', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: ModeRow(
            art: const FlatModeArt(),
            name: 'Nothing set',
            onTap: () => taps++,
          ),
        ),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(ModeRow));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(feedback.played, [FeedbackKind.press]);
    // The art square alone is taller than the touch floor, so the row needs
    // no minimum of its own — but the floor still has to hold.
    expect(
      tester.getSize(find.byType(ModeRow)).height,
      greaterThanOrEqualTo(WizSpace.standard.hitMin),
    );
  });

  testWidgets('the art cross-fades over the panel duration', (tester) async {
    Widget row(int sceneId) => wizTestApp(
      SizedBox(
        width: 350,
        child: ModeRow(art: SceneModeArt(sceneId), name: 'Cozy', onTap: () {}),
      ),
    );
    var panel = WizMotion.standard.panel;
    await tester.pumpWidget(row(6));
    expect(find.byType(WizSceneArt), findsOneWidget);

    await tester.pumpWidget(row(12));
    await tester.pump();
    // Half way through, both arts are on screen: the old one fading out
    // under the new one fading in.
    await tester.pump(panel ~/ 2);
    expect(find.byType(WizSceneArt), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byType(WizSceneArt), findsOneWidget);
  });

  testWidgets('reduced motion swaps the art without a cross-fade', (
    tester,
  ) async {
    Widget row(int sceneId) => wizTestApp(
      MediaQuery(
        // The platform's "reduce motion" switch, over the harness's own
        // MediaQuery.
        data: const MediaQueryData(disableAnimations: true),
        child: SizedBox(
          width: 350,
          child: ModeRow(
            art: SceneModeArt(sceneId),
            name: 'Cozy',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpWidget(row(6));
    await tester.pumpWidget(row(12));
    // The same pump sequence the cross-fade test uses to catch two arts on
    // screen finds only the new one here.
    await tester.pump();
    expect(find.byType(WizSceneArt), findsOneWidget);
  });
}
