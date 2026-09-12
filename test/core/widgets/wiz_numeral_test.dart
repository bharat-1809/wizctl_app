import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_numeral.dart';

import '../../support/wiz_test_app.dart';

const TextStyle _value = TextStyle(fontSize: 48, fontWeight: FontWeight.w800);
const TextStyle _unit = TextStyle(fontSize: 21, fontWeight: FontWeight.w600);

/// How far below its own top the text in [f] sits its alphabetic baseline.
/// Measured with a [TextPainter] over the span the paragraph actually
/// resolved, since `RenderBox.getDistanceToBaseline` may only be asked
/// during layout or paint.
double _ascentOf(WidgetTester tester, Finder f) {
  var painter = TextPainter(
    text: tester.renderObject<RenderParagraph>(f).text,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
}

void main() {
  testWidgets('the unit sits on the numeral\'s baseline, not its box', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const WizNumeral(
          value: '2700',
          unit: 'K',
          valueStyle: _value,
          unitStyle: _unit,
          gap: WizNumeral.unitGap,
        ),
      ),
    );
    // Sharing a baseline puts the small box lower down by exactly the
    // difference in the two ascents — not by half the difference in their
    // heights, which is where centring would leave it.
    var drop =
        _ascentOf(tester, find.text('2700')) -
        _ascentOf(tester, find.text('K'));
    expect(drop, greaterThan(0));
    expect(
      tester.getTopLeft(find.text('K')).dy -
          tester.getTopLeft(find.text('2700')).dy,
      moreOrLessEquals(drop),
    );
    expect(
      tester.getTopLeft(find.text('K')).dx -
          tester.getTopRight(find.text('2700')).dx,
      moreOrLessEquals(WizNumeral.unitGap),
    );
  });

  testWidgets('the unit is set in the style it is given', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const WizNumeral(
          value: '2700',
          unit: 'K',
          valueStyle: _value,
          unitStyle: _unit,
        ),
      ),
    );
    expect(tester.widget<Text>(find.text('2700')).style, _value);
    expect(tester.widget<Text>(find.text('K')).style, _unit);
  });

  testWidgets('a numeral with no unit renders the number alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(const WizNumeral(value: '2700', valueStyle: _value)),
    );
    expect(find.text('2700'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
