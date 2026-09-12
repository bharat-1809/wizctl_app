import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_dial_disc.dart';

import '../../support/wiz_test_app.dart';

/// The arc's amber glow: the one circle-shaped shadow the disc draws.
final Finder _glowBox = find.descendant(
  of: find.byType(WizDialDisc),
  matching: find.byWidgetPredicate((w) {
    if (w is! DecoratedBox) return false;
    var d = w.decoration;
    return d is BoxDecoration &&
        d.shape == BoxShape.circle &&
        d.boxShadow?.length == 1 &&
        d.boxShadow!.single.blurRadius > 0;
  }),
);

double _glowAlpha(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(_glowBox).decoration as BoxDecoration)
        .boxShadow!
        .single
        .color
        .a;

Widget _disc(double pct) => WizDialDisc(
  diameter: 132,
  pct: pct,
  value: pct * 100,
  unit: '%',
  dragging: false,
);

void main() {
  testWidgets('the arc glow fades through its colour, not an opacity layer', (
    tester,
  ) async {
    await tester.pumpWidget(wizTestApp(_disc(0.5)));
    // An opacity layer over a lone blurred draw is the shape Impeller
    // mishandles (it pushes the opacity into the blur and logs every frame);
    // the glow must never be wrapped in one.
    expect(
      find.descendant(
        of: find.byType(WizDialDisc),
        matching: find.byWidgetPredicate(
          (w) => w is AnimatedOpacity || w is Opacity || w is FadeTransition,
        ),
      ),
      findsNothing,
    );
    expect(_glowBox, findsOneWidget);
    expect(_glowAlpha(tester), greaterThan(0));
  });

  testWidgets('the glow goes dark at zero and lights again above it', (
    tester,
  ) async {
    await tester.pumpWidget(wizTestApp(_disc(0.5)));
    var lit = _glowAlpha(tester);

    await tester.pumpWidget(wizTestApp(_disc(0)));
    await tester.pumpAndSettle();
    expect(_glowAlpha(tester), 0);

    await tester.pumpWidget(wizTestApp(_disc(0.2)));
    await tester.pumpAndSettle();
    expect(_glowAlpha(tester), closeTo(lit, 0.001));
  });
}
