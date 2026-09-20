import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/widgets/unreachable_banner.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';

void main() {
  testWidgets('one light: the singular line names it; the action rescans', (
    tester,
  ) async {
    // Built and torn down inside the body (P56); `AppScope`'s cubits are
    // zone-safe, so the tear-down is awaited there.
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      var router = await pumpRouted(
        tester,
        scope.wrap(const UnreachableBanner()),
        targets: [AppRoutes.discover],
      );
      await tester.pump();
      expect(find.text('One light did not answer'), findsOneWidget);
      expect(
        find.text(
          'Hallway may be switched off at the wall, or the router changed '
          'its address.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('RESCAN'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), AppRoutes.discover);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('several lights: the count, and the first one named; none: '
      'nothing', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      scope.seed.store.update('dome', (s) => s.copyWith(reachable: false));
      await pumpRouted(tester, scope.wrap(const UnreachableBanner()));
      await tester.pump();
      expect(find.text('2 lights did not answer'), findsOneWidget);
      expect(
        find.textContaining('Ceiling dome light may be switched off'),
        findsOneWidget,
      );
      scope.seed.store.update('dome', (s) => s.copyWith(reachable: true));
      scope.seed.store.update('hall', (s) => s.copyWith(reachable: true));
      // Settled rather than one frame: `LiveStateStore.watchAll` is a
      // generator, so a change reaches the cubit a microtask hop or two after
      // the call, and the frame that drops the banner is the one after that.
      await tester.pumpAndSettle();
      expect(find.byType(WizStatusBanner), findsNothing);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('given ids, it counts and names only those lights', (
    tester,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      // The living room answers; the silent light is the bedroom's hallway.
      await pumpRouted(
        tester,
        scope.wrap(
          const UnreachableBanner(lightIds: {'dome', 'floor', 'strip'}),
        ),
      );
      await tester.pump();
      expect(
        find.byType(WizStatusBanner),
        findsNothing,
        reason: 'the whole home has a silent light, but none of these three',
      );
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('given ids that include the silent one, it names it', (
    tester,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      scope.seed.store.update('dome', (s) => s.copyWith(reachable: false));
      await pumpRouted(
        tester,
        scope.wrap(const UnreachableBanner(lightIds: {'bedside', 'hall'})),
      );
      await tester.pump();
      expect(
        find.text(Strings.oneLightDidNotAnswer),
        findsOneWidget,
        reason: "the dome is silent too, but it is not in this room's set",
      );
      expect(find.text(Strings.mayBeOffAtWallNamed('Hallway')), findsOneWidget);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('an empty id set is nothing to report', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await pumpRouted(
        tester,
        scope.wrap(const UnreachableBanner(lightIds: {})),
      );
      await tester.pump();
      expect(find.byType(WizStatusBanner), findsNothing);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('no active home: nothing at all', (tester) async {
    var scope = AppScope(SeedHome(active: false));
    await scope.start();
    try {
      await pumpRouted(tester, scope.wrap(const UnreachableBanner()));
      await tester.pump();
      expect(find.byType(WizStatusBanner), findsNothing);
    } finally {
      await scope.dispose();
    }
  });
}
