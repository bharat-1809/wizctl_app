import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/gallery_page.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';

import '../support/app_scope.dart';
import '../support/router_harness.dart';
import '../support/seed.dart';

/// One screen fade (300 ms) and the frame that follows it, so a redirect has
/// landed and nothing is mid-transition. Bounded, not `pumpAndSettle`: an
/// active home arms the poll timer and the screens animate on.
const Duration _settled = Duration(milliseconds: 400);

/// The gallery's own settling: it mounts every kit section behind a load-in
/// stagger, so its timers take longer to drain than a screen's. Two pumps,
/// because until the fade has finished the page underneath is offstage, where
/// finders do not look.
Future<void> settleGallery(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pump(const Duration(milliseconds: 1500));
}

void main() {
  test('branches map to paths and back', () {
    expect(ShellBranch.home.path, AppRoutes.home);
    expect(ShellBranch.rooms.path, AppRoutes.rooms);
    expect(ShellBranch.modes.path, AppRoutes.modes);
    expect(ShellBranch.settings.path, AppRoutes.settings);
    expect(ShellBranch.discover.path, AppRoutes.discover);
    for (var b in ShellBranch.values) {
      expect(ShellBranch.of(b.index), b);
    }
  });

  test('the four tabs are the branches that have one, in order', () {
    expect(ShellBranch.tabs.map((t) => t.value).toList(), [
      ShellBranch.home,
      ShellBranch.rooms,
      ShellBranch.modes,
      ShellBranch.settings,
    ], reason: 'discovery is a branch without a tab');
  });

  testWidgets('with no home, every location redirects to setup', (
    tester,
  ) async {
    var scope = AppScope(SeedHome.empty());
    try {
      var router = await pumpAppRouter(tester, scope);
      expect(currentLocation(router), AppRoutes.setup);

      router.go(AppRoutes.rooms);
      await tester.pump(_settled);
      expect(
        currentLocation(router),
        AppRoutes.setup,
        reason: 'there is nothing to show in a shell without a home',
      );
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('with a home, the app opens on home and setup is unreachable', (
    tester,
  ) async {
    var scope = AppScope(SeedHome());
    try {
      await scope.start();
      // The homes projection lands before the router is built, the way
      // `HomesState.snapshot` gives the real app its first frame (spec §9).
      await tester.pump();
      expect(scope.homes.state.hasHome, isTrue);

      var router = await pumpAppRouter(tester, scope);
      expect(currentLocation(router), AppRoutes.home);

      router.go(AppRoutes.setup);
      await tester.pump(_settled);
      expect(
        currentLocation(router),
        AppRoutes.home,
        reason: 'the first run is over; its screen must not come back',
      );
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('the debug gallery is a route of its own, with a way back', (
    tester,
  ) async {
    var scope = AppScope(SeedHome());
    try {
      await scope.start();
      await tester.pump();
      var router = await pumpAppRouter(tester, scope);

      // What the Settings row does (spec §18): pushed over whatever is on
      // show, rather than a branch of its own.
      router.push(AppRoutes.gallery);
      await settleGallery(tester);
      expect(find.byType(GalleryPage), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.back));
      await settleGallery(tester);
      expect(find.byType(GalleryPage), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    } finally {
      await scope.dispose();
    }
  });

  testWidgets('a home written under the router leaves setup for home', (
    tester,
  ) async {
    var scope = AppScope(SeedHome.empty());
    try {
      var router = await pumpAppRouter(tester, scope);
      expect(currentLocation(router), AppRoutes.setup);

      // What finishing the first run does to the database. The router wakes on
      // the homes bloc rather than on the screen that wrote it.
      scope.homes.add(const HomesSubscribed());
      await scope.seed.homes.insert(scope.seed.home);
      await scope.seed.settings.save(
        (await scope.seed.settings.get()).copyWith(activeHomeId: 'h1'),
      );
      await tester.pump(_settled);
      expect(currentLocation(router), AppRoutes.home);
    } finally {
      await scope.dispose();
    }
  });
}
