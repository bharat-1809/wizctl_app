import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:wizctl_app/core/icons/wiz_icon.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('all 49 glyphs are present and unique', () {
    expect(WizIcons.all, hasLength(49));
    expect(WizIcons.all.map((i) => i.name).toSet(), hasLength(49));
    expect(WizIcons.byName('lightbulb'), same(WizIcons.lightbulb));
    expect(WizIcons.byName('utensils-crossed'), same(WizIcons.utensilsCrossed));
    expect(WizIcons.lightbulb.path, startsWith('M'));
    expect(WizIcons.byName('nope'), isNull);
  });

  test('every glyph path parses', () {
    for (final icon in WizIcons.all) {
      expect(
        () => parseSvgPathData(icon.path),
        returnsNormally,
        reason: icon.name,
      );
    }
  });

  testWidgets('WizIcon sizes itself and paints', (tester) async {
    await tester.pumpWidget(
      wizTestApp(const WizIcon(WizIcons.power, size: 24)),
    );
    expect(tester.getSize(find.byType(WizIcon)), const Size(24, 24));
    expect(
      find.descendant(
        of: find.byType(WizIcon),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
