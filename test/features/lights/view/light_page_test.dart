import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet_route.dart';
import 'package:wizctl_app/features/desktop/view/inspector_panel.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// `/lights/:id` on a desktop window, over the real router: the reading that
/// selects the light into the inspector column instead of showing a detail
/// screen, and leaves when its light has gone (P83).
///
/// 1400 tall, not 800: the inspector is one scroll from the name to the Forget
/// key, which is drawn outside a real window's viewport where a tap cannot reach
/// it (`inspector_panel_test.dart` buys the same guarantee the same way).
const Size _expanded = Size(1200, 1400);

/// Two bounded pumps: a route page and its bloc's first emission each need a
/// frame, and `pumpAndSettle` never returns with a poll timer running.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  Finder inSheet(String text) => find.descendant(
    of: find.byType(WizSheetRoute),
    matching: find.text(text),
  );

  testWidgets('forgetting the route\'s light from the inspector leaves for its '
      'room, once', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      var router = await pumpAppRouter(tester, scope, size: _expanded);
      await settle(tester);
      router.go(AppRoutes.light('dome'));
      // Four frames: the page, its bloc's first emission — which names the room
      // to draw — the selection reaching the column after that frame, and the
      // column's own bloc's first emission.
      await settle(tester);
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(InspectorPanel),
          matching: find.text('Ceiling dome light'),
        ),
        findsOneWidget,
        reason: 'the route put its light in the column',
      );

      // One tick per navigation, so "left exactly once" is pinned by the count
      // and not only by where it ended up.
      var navigations = 0;
      router.routeInformationProvider.addListener(() => navigations++);

      await tester.tap(find.text('FORGET'));
      await settle(tester);
      await tester.tap(inSheet('FORGET'));
      await settle(tester);
      expect(currentLocation(router), AppRoutes.room('living'));
      expect(
        navigations,
        1,
        reason:
            "the route's own leave is the only navigator on this reading — the "
            'inspector listens with navigate: false',
      );
      expect(scope.inspector.state, isNull);
      expect(scope.toasts.toasts.single.title, 'Ceiling dome light forgotten');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await scope.dispose();
    }
  });

  testWidgets('a light id that names nothing ends at Home', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      var router = await pumpAppRouter(tester, scope, size: _expanded);
      await settle(tester);
      router.go(AppRoutes.light('no-such'));
      await settle(tester);
      await settle(tester);
      expect(
        currentLocation(router),
        AppRoutes.home,
        reason: 'no room to name, so the light\'s parent is Home',
      );
      expect(
        scope.inspector.state,
        isNull,
        reason: 'and the column drops the id it could not resolve',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await scope.dispose();
    }
  });
}
