import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/compact_shell.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/lights/view/light_screen.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';

void main() {
  test('the tab bar shows on every branch but discovery', () {
    for (var b in ShellBranch.values) {
      expect(CompactShell.showsTabBar(b.index), b != ShellBranch.discover);
    }
  });

  /// Starts the fixture, pumps the app's own router on a phone, runs [body]
  /// and tears the fixture down — all inside the tester's body, because the
  /// coordinator's poll timer must be cancelled before the tester looks for
  /// pending timers (`AppScope`'s doc has the rest).
  Future<void> withApp(
    WidgetTester tester,
    Future<void> Function(AppScope scope, GoRouter router) body,
  ) async {
    var scope = AppScope(SeedHome());
    try {
      await scope.start();
      await tester.pump();
      var router = await pumpAppRouter(tester, scope);
      await settle(tester);
      await body(scope, router);
    } finally {
      await scope.dispose();
    }
  }

  testWidgets('the bar stays over a room and goes on discovery', (
    tester,
  ) async {
    await withApp(tester, (scope, router) async {
      router.go(AppRoutes.room('living'));
      await settle(tester);
      expect(find.byType(RoomScreen), findsOneWidget);
      expect(find.byType(WizTabBar<ShellBranch>), findsOneWidget);

      router.go(AppRoutes.discover);
      await settle(tester);
      expect(find.byType(DiscoveryScreen), findsOneWidget);
      expect(find.byType(WizTabBar<ShellBranch>), findsNothing);
    });
  });

  testWidgets('a light opens over its room, under the bar, and Back returns', (
    tester,
  ) async {
    await withApp(tester, (scope, router) async {
      router.go(AppRoutes.room('living'));
      await settle(tester);

      // What the room's card does: a push, so Back pops to the room rather
      // than going somewhere by name. The first card, because the last one on
      // this phone sits under the floating bar until the list is scrolled.
      await tester.tap(find.text('Ceiling dome light'));
      await settle(tester);
      expect(currentLocation(router), AppRoutes.light('dome'));
      expect(find.byType(LightScreen), findsOneWidget);
      expect(
        find.byType(WizTabBar<ShellBranch>),
        findsOneWidget,
        reason: 'a light lives in the Rooms branch, under the bar',
      );

      await tester.tap(find.bySemanticsLabel(Strings.back));
      await settle(tester);
      expect(currentLocation(router), AppRoutes.room('living'));
      expect(find.byType(RoomScreen), findsOneWidget);
    });
  });

  testWidgets('a light opened cold goes back to its own room', (tester) async {
    await withApp(tester, (scope, router) async {
      // A deep link, or the address bar on the web: nothing underneath to pop,
      // so Back takes `popOr`'s fallback — `lightParent`, which is the light's
      // own room.
      router.go(AppRoutes.light('strip'));
      await settle(tester);
      expect(find.byType(LightScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.back));
      await settle(tester);
      expect(currentLocation(router), AppRoutes.room('living'));
      expect(find.byType(RoomScreen), findsOneWidget);
    });
  });

  testWidgets('a room deleted while its screen is on show ends at the list', (
    tester,
  ) async {
    await withApp(tester, (scope, router) async {
      router.go(AppRoutes.room('living'));
      await settle(tester);
      expect(find.byType(RoomScreen), findsOneWidget);

      await scope.seed.rooms.delete('living');
      await settle(tester);
      expect(currentLocation(router), AppRoutes.rooms);
      expect(find.byType(RoomsScreen), findsOneWidget);
    });
  });

  testWidgets('an id that names no room ends at the list', (tester) async {
    await withApp(tester, (scope, router) async {
      router.go(AppRoutes.room('no-such-room'));
      await settle(tester);
      expect(
        currentLocation(router),
        AppRoutes.rooms,
        reason:
            'the bloc is built in the route, so the listener sees the '
            'first state it emits',
      );
      expect(find.byType(RoomsScreen), findsOneWidget);
    });
  });
}
