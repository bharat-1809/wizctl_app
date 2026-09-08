import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/layout/wiz_grid.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('columns come from the minimum tile width', () {
    expect(wizGridColumns(width: 350, minTile: 150, gap: 16), 2);
    expect(wizGridColumns(width: 280, minTile: 150, gap: 16), 1);
    expect(wizGridColumns(width: 1400, minTile: 340, gap: 14), 3);
    expect(wizGridColumns(width: 100, minTile: 150, gap: 16), 1);
    // Extra widths, per the column maths self-review requirement.
    expect(wizGridColumns(width: 700, minTile: 200, gap: 16), 3);
    expect(wizGridColumns(width: 0, minTile: 150, gap: 16), 1);
  });

  testWidgets('WizGrid lays children in rows of equal width', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: WizGrid(
            minTile: 150,
            gap: 16,
            children: List.generate(
              3,
              (i) => SizedBox(key: ValueKey(i), height: 40),
            ),
          ),
        ),
      ),
    );
    var first = tester.getRect(find.byKey(const ValueKey(0)));
    var second = tester.getRect(find.byKey(const ValueKey(1)));
    var third = tester.getRect(find.byKey(const ValueKey(2)));
    expect(first.width, closeTo(167, 0.5));
    expect(second.left, closeTo(first.right + 16, 0.5));
    expect(third.top, closeTo(first.bottom + 16, 0.5));
    expect(third.width, first.width);
  });

  testWidgets(
    'WizGrid renders inside a SingleChildScrollView without overflow',
    (tester) async {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 350,
            height: 120,
            child: SingleChildScrollView(
              child: WizGrid(
                minTile: 150,
                gap: 16,
                children: List.generate(
                  9,
                  (i) => SizedBox(key: ValueKey('cell$i'), height: 40),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // The scroll view, not the fixed 120px box, bounds the content, so the
      // last tile still exists in the tree even though it is offscreen.
      expect(find.byKey(const ValueKey('cell8')), findsOneWidget);
    },
  );

  testWidgets('mainAxisExtent fixes every tile to that height', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: WizGrid(
            minTile: 150,
            gap: 16,
            mainAxisExtent: 80,
            children: List.generate(2, (i) => SizedBox(key: ValueKey('mae$i'))),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(const ValueKey('mae0'))).height, 80);
    expect(tester.getRect(find.byKey(const ValueKey('mae1'))).height, 80);
  });

  testWidgets('childAspectRatio derives tile height from the tile width', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: WizGrid(
            minTile: 150,
            gap: 16,
            childAspectRatio: 2,
            children: List.generate(2, (i) => SizedBox(key: ValueKey('car$i'))),
          ),
        ),
      ),
    );
    // 2 columns of (350 - 16) / 2 = 167 wide; aspect ratio 2 -> 83.5 tall.
    var rect = tester.getRect(find.byKey(const ValueKey('car0')));
    expect(rect.width, closeTo(167, 0.5));
    expect(rect.height, closeTo(83.5, 0.5));
  });
}
