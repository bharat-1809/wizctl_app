import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_art.dart';

import 'package:wizctl_app/core/copy/strings.dart';

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
    // `:220` `gap:13px`, spent between every child alike — the `Row`'s own
    // `spacing`, so measuring it once beside the art measures it beside the
    // chevron too.
    var space = WizSpace.standard;
    expect(
      tester.getTopLeft(find.text('LIGHT MODE')).dx -
          tester.getTopRight(find.byType(WizSceneArt)).dx,
      space.s5 + space.s1 / 2,
    );
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
    // And the hairline is drawn *inside* that footprint, over the art: the
    // ring runs from the tile's own edge exactly one hairline inwards, so
    // the painted tile is 48 to the pixel. `:221` is an inset shadow; a
    // spread shadow would ring the outside instead, wider and curving
    // tighter than the art it traces.
    var space = WizSpace.standard;
    var edge = space.hairline;
    Radius radius(double r) => Radius.circular(r);
    expect(
      find
          .ancestor(
            of: find.byKey(ModeRow.flatArtKey),
            matching: find.byType(DecoratedBox),
          )
          .first,
      paints..drrect(
        outer: RRect.fromLTRBR(
          0,
          0,
          ModeRow.artSize,
          ModeRow.artSize,
          radius(space.r2),
        ),
        inner: RRect.fromLTRBR(
          edge,
          edge,
          ModeRow.artSize - edge,
          ModeRow.artSize - edge,
          radius(space.r2 - edge),
        ),
        color: WizColors.standard.shadowBase.withValues(
          alpha: ModeRow.artShadowAlpha,
        ),
      ),
    );
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
      reducedMotion(
        SizedBox(
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

  testWidgets('rebuilding on the same scene does not restart the fade', (
    tester,
  ) async {
    Widget row(int sceneId) => wizTestApp(
      SizedBox(
        width: 350,
        child: ModeRow(art: SceneModeArt(sceneId), name: 'Cozy', onTap: () {}),
      ),
    );
    await tester.pumpWidget(row(6));
    // A fresh widget carrying the same art. The switcher keys on the art's
    // identity, not on the instance, so a rebuild from any other change
    // must not cross-fade the tile against itself.
    await tester.pumpWidget(row(6));
    await tester.pump();
    await tester.pump(WizMotion.standard.panel ~/ 2);
    expect(find.byType(WizSceneArt), findsOneWidget);
  });

  testWidgets('two solid colours cross-fade like two scenes', (tester) async {
    const warm = Color(0xFFFFC98D);
    const cool = Color(0xFFBFD9FF);
    Widget row(Color color) => wizTestApp(
      SizedBox(
        width: 350,
        child: ModeRow(
          art: SolidModeArt(color),
          name: '2700K white',
          onTap: () {},
        ),
      ),
    );
    await tester.pumpWidget(row(warm));
    await tester.pumpWidget(row(cool));
    await tester.pump();
    await tester.pump(WizMotion.standard.panel ~/ 2);
    // The colour is the identity a solid face fades on, so both swatches are
    // on screen at once.
    expect(find.byKey(const ValueKey(warm)), findsOneWidget);
    expect(find.byKey(const ValueKey(cool)), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(warm)), findsNothing);
    expect(find.byKey(const ValueKey(cool)), findsOneWidget);
  });

  testWidgets('a row with no callback is a disabled button', (tester) async {
    var handle = tester.ensureSemantics();
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: ModeRow(art: FlatModeArt(), name: 'Nothing set', onTap: null),
        ),
        feedback: feedback,
      ),
    );
    expect(
      tester.getSemantics(find.byType(ModeRow)),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );
    // The pressable dims what it disables, and a touch neither sinks the
    // row nor plays a cue.
    expect(
      find.byWidgetPredicate(
        (w) => w is Opacity && w.opacity == WizColors.disabledAlpha,
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(ModeRow), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(feedback.played, isEmpty);
    handle.dispose();
  });
  testWidgets('scene art for an id the design has none for is the flat face', (
    tester,
  ) async {
    // `ModeRow(SceneModeArt(0))` reaches the row straight from a bulb with
    // no scene set; a rhythm id past the 1000 the library knows arrives the
    // same way.
    for (var id in [0, 1001]) {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 350,
            child: ModeRow(
              art: SceneModeArt(id),
              name: Strings.nothingSet,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'scene $id threw');
      expect(find.byType(WizSceneArt), findsOneWidget);

      var art = tester
          .widget<CustomPaint>(
            find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is WizSceneArtPainter,
            ),
          )
          .painter!;
      expect(
        art,
        isA<WizSceneArtPainter>()
            .having((p) => p.from, 'from', WizColors.standard.char800)
            .having((p) => p.to, 'to', WizColors.standard.char900),
      );
    }
  });
}
