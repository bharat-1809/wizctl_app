import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/screen_scroll.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('gutters, a gap between children, and the bottom inset', (
    tester,
  ) async {
    // `wizTestApp`'s `size:` only pins the MediaQuery; the gutter comes from
    // the width class, which `WizLayoutScope` measures off the real surface.
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(
      wizTestApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: 124),
          ),
          child: const WizLayoutScope(
            child: ScreenScroll(
              children: [
                SizedBox(key: Key('a'), height: 40),
                SizedBox(key: Key('b'), height: 40),
              ],
            ),
          ),
        ),
        size: const Size(390, 844),
      ),
    );
    var a = tester.getRect(find.byKey(const Key('a')));
    var b = tester.getRect(find.byKey(const Key('b')));
    expect(a.left, 20, reason: 'the compact gutter');
    expect(a.width, 350);
    expect(a.top, 47 + 8, reason: 'top inset plus the prototype\'s 8');
    expect(b.top - a.bottom, 16, reason: 'space.s6 between children');
    var list = tester.widget<ListView>(find.byType(ListView));
    expect(
      (list.padding! as EdgeInsets).bottom,
      124 + 24,
      reason: 'the reported bottom inset plus s8',
    );
  });
}
