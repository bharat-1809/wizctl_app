import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/compact_shell.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';

/// One screen fade (300 ms) and the frames after it, so a branch switch, a
/// redirect or a screen's own leave has landed. Bounded, not `pumpAndSettle`:
/// the cards breathe and the poll timer ticks for ever.
const Duration _settled = Duration(milliseconds: 400);

/// Two bounded pumps, the way an onboarding step change needs two (Task 17):
/// the first frame lands the navigation and starts the fade, and until the
/// fade has finished the page that is leaving is still on top and opaque —
/// which leaves the page underneath offstage, where finders do not look.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(_settled);
  await tester.pump(_settled);
}

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
