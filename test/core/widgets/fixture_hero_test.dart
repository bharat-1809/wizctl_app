import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/fixture_hero_painter.dart';

import '../../support/wiz_test_app.dart';

/// Tungsten amber, the colour a lit light emits by default (`amber500`).
const litColour = Color(0xFFFFB020);

/// The painter behind the hero. Everything a test needs to know about what
/// the hero is drawing — the tweened emission and the breathe factor — is a
/// public field on it, so no test-only hook has to hang off the widget.
FixtureHeroPainter painterOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(FixtureHero),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<FixtureHeroPainter>()
    .single;

Widget hero(
  WizFixture fixture,
  WizEmission emission, {
  double width = 350,
  bool compact = false,
}) => SizedBox(
  width: width,
  child: FixtureHero(fixture: fixture, emission: emission, compact: compact),
);

void main() {
  test('emission maths follow the spec', () {
    var lit = WizEmission.lit(color: litColour, brightness: 100);
    expect(lit.alpha, closeTo(0.92, 0.001));
    expect(lit.bloom, closeTo(0.80, 0.001));
    var dim = WizEmission.lit(color: litColour, brightness: 10);
    expect(dim.alpha, closeTo(0.362, 0.001));
    expect(WizEmission.off.alpha, 0);
    expect(WizEmission.off.filament, 0.06);
    var mid = WizEmission.lerp(WizEmission.off, lit, 0.5);
    expect(mid.alpha, closeTo(0.46, 0.001));

    // The ends of the ramp are the ends themselves, so a settled tween
    // paints exactly what it was handed.
    expect(WizEmission.lerp(WizEmission.off, lit, 0), WizEmission.off);
    expect(WizEmission.lerp(WizEmission.off, lit, 1), lit);
  });

  testWidgets('the hero scales to its width for every fixture', (tester) async {
    for (var fixture in WizFixture.values) {
      await tester.pumpWidget(
        wizTestApp(
          hero(fixture, WizEmission.lit(color: litColour, brightness: 70)),
        ),
      );
      // A lit hero breathes forever, so this is a bounded pump rather than
      // the brief's `pumpAndSettle`.
      await tester.pump();
      expect(
        tester.getSize(find.byType(FixtureHero)),
        const Size(350, 236),
        reason: '$fixture',
      );
    }
    await tester.pumpWidget(
      wizTestApp(hero(WizFixture.bulb, WizEmission.off, width: 175)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FixtureHero)), const Size(175, 118));
    await tester.pumpWidget(
      wizTestApp(
        hero(WizFixture.dome, WizEmission.off, width: 304, compact: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(FixtureHero)).height,
      closeTo(132 * 304 / 350, 0.5),
    );
  });

  testWidgets('the emission breathes while lit and parks when off', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        hero(
          WizFixture.bulb,
          WizEmission.lit(color: litColour, brightness: 100),
        ),
      ),
    );
    await tester.pump();
    var start = painterOf(tester).breath;
    await tester.pump(const Duration(seconds: 1));
    expect(
      painterOf(tester).breath,
      isNot(closeTo(start, 0.001)),
      reason: 'a lit hero breathes',
    );

    await tester.pumpWidget(wizTestApp(hero(WizFixture.bulb, WizEmission.off)));
    // Returning at all is the assertion: a still-looping breathe would time
    // this out.
    await tester.pumpAndSettle();
    expect(painterOf(tester).breath, 1, reason: 'parked at full emission');
  });

  testWidgets('reduced motion never starts the breathe', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          // Compact and lit, which is also the only place the inspector
          // well's own bloom gets painted.
          child: hero(
            WizFixture.dome,
            WizEmission.lit(color: litColour, brightness: 100),
            compact: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(painterOf(tester).breath, 1);
  });

  testWidgets('a change of emission eases over the light duration', (
    tester,
  ) async {
    var lit = WizEmission.lit(color: litColour, brightness: 100);
    await tester.pumpWidget(wizTestApp(hero(WizFixture.bulb, WizEmission.off)));
    await tester.pumpAndSettle();
    expect(painterOf(tester).emission.alpha, 0);

    await tester.pumpWidget(wizTestApp(hero(WizFixture.bulb, lit)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    var midway = painterOf(tester).emission.alpha;
    expect(midway, greaterThan(0));
    expect(midway, lessThan(lit.alpha));

    // 420 ms in, it has arrived.
    await tester.pump(const Duration(milliseconds: 300));
    expect(painterOf(tester).emission.alpha, closeTo(lit.alpha, 0.001));

    // Dispose the tree so the breathe's ticker does not outlive the test.
    await tester.pumpWidget(wizTestApp(const SizedBox()));
  });
}
