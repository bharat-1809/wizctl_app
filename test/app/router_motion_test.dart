import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';

import '../support/app_scope.dart';
import '../support/router_harness.dart';
import '../support/seed.dart';
import '../support/wiz_test_app.dart';

/// The transition of the page the router is showing.
///
/// Read through `ModalRoute.of` rather than off the root navigator's pages: a
/// screen inside the shell's branches lives in a nested navigator, so the
/// root's last page is the shell's, not the screen's.
Duration _pageFade(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byType(HomeScreen)))!.transitionDuration;

void main() {
  testWidgets('the router fades its pages over screenEnter', (tester) async {
    var scope = AppScope(SeedHome());
    try {
      await scope.start();
      await tester.pump();
      await pumpAppRouter(tester, scope);

      expect(_pageFade(tester), scope.motion.screenEnter);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('under reduced motion the router fades over no time at all', (
    tester,
  ) async {
    var scope = AppScope(SeedHome());
    try {
      await scope.start();
      await tester.pump();
      // Switched on before the first pump, never onto a live tree: a page's
      // durations are fixed when the route is created, so a flip afterwards
      // would leave the route that is already showing on its old timing and
      // the assertion would read a stale number.
      await pumpAppRouter(tester, scope, wrap: (child) => reducedMotion(child));

      expect(_pageFade(tester), Duration.zero);
    } finally {
      await scope.dispose();
    }
  });
}
