import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/app/dependencies.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';

import '../support/fakes.dart';
import '../support/wiz_test_app.dart';

/// The phone (spec §9, §10): 390 wide is the compact width class the shell's
/// tab bar and every screen here are written for.
const Size _phone = Size(390, 844);

/// One screen fade (300 ms) with room for the load-in staggers.
const Duration _frame = Duration(milliseconds: 600);

/// Two bounded pumps: the first lands the navigation and starts the fade, and
/// until the fade has finished the page that is leaving is still on top and
/// opaque, which leaves the one underneath offstage where finders do not look.
///
/// Bounded throughout: a lit card breathes, the filament sweeps and the live
/// badge pulses for ever, so `pumpAndSettle` would time out.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(_frame);
  await tester.pump(_frame);
}

/// The whole graph over an in-memory database, with one home, one room and one
/// light when [withHome] — what a second launch finds — and nothing at all
/// otherwise, which is a fresh install.
///
/// The writes go through `runAsync`: the database opens, migrates and answers
/// off the fake clock.
Future<AppServices> _services(
  WidgetTester tester,
  FakeGateway gateway, {
  required bool withHome,
}) async {
  var deps = (await tester.runAsync(
    () => AppDependencies.build(
      database: AppDatabase.inMemory(),
      gateway: gateway,
      networkInfo: FakeNetworkInfo('192.168.1'),
      exportCli: false,
      clock: FakeClock(),
      ids: SequenceIds(),
    ),
  ))!;
  if (withHome) {
    await tester.runAsync(() async {
      var home = await deps.createHome('Kaverappa House', subnet: '192.168.1');
      var room = await deps.addRoom(home.id, 'Living Room', RoomGlyph.sofa);
      await deps.saveDiscoveredLight(
        homeId: home.id,
        roomId: room.id,
        device: const DiscoveredDevice(
          ip: '192.168.1.104',
          mac: 'aa',
          bulbClass: BulbClass.rgb,
        ),
        alias: 'Ceiling dome light',
        fixture: Fixture.dome,
      );
    });
    gateway.states['192.168.1.104'] = const LightState(isOn: true, dimming: 70);
  }
  return AppServices(
    feedback: NoopFeedbackService(),
    toasts: ToastController(),
    deps: deps,
    homes: await deps.homes.getAll(),
    settings: await deps.settings.get(),
  );
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  /// Builds the graph, pumps the real app on a phone, runs [body], then takes
  /// the tree and the graph down — all inside the tester's body.
  ///
  /// The tree is unmounted here rather than left to the tester: the app closes
  /// its blocs on the way out, drift cancels the query streams they held and
  /// schedules a zero-duration timer per stream to close it, and the pumps
  /// below are what run those. Left to the automatic teardown they would still
  /// be pending when the tester checks. The database then closes through
  /// `runAsync`, off the fake clock.
  Future<void> withApp(
    WidgetTester tester,
    Future<void> Function(AppServices services) body, {
    bool withHome = true,
  }) async {
    var services = await _services(tester, FakeGateway(), withHome: withHome);
    try {
      await setSurface(tester, _phone);
      await tester.pumpWidget(WizCtlApp(services: services));
      await settle(tester);
      await body(services);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      services.toasts.dispose();
      await tester.runAsync(services.deps.dispose);
    }
  }

  testWidgets('a fresh install opens on setup with no tab bar', (tester) async {
    await withApp(tester, withHome: false, (services) async {
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(WizTabBar<ShellBranch>), findsNothing);
      expect(find.text(Strings.nameThisHome), findsOneWidget);
    });
  });

  testWidgets('a fresh install titles the window for the setup it is on', (
    tester,
  ) async {
    await withApp(tester, withHome: false, (services) async {
      expect(
        tester.widget<Title>(find.byType(Title)).title,
        Strings.windowSetup,
      );
    });
  });

  testWidgets('with a home: home, the tabs, a room and back, then discovery', (
    tester,
  ) async {
    await withApp(tester, (services) async {
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Kaverappa House'), findsOneWidget);
      expect(find.byType(WizTabBar<ShellBranch>), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.rooms));
      await settle(tester);
      expect(find.byType(RoomsScreen), findsOneWidget);

      await tester.tap(find.text('Living Room'));
      await settle(tester);
      expect(find.byType(RoomScreen), findsOneWidget);
      expect(
        find.byType(WizTabBar<ShellBranch>),
        findsOneWidget,
        reason: 'a room opens inside the Rooms branch, under the bar',
      );

      await tester.tap(find.bySemanticsLabel(Strings.back));
      await settle(tester);
      expect(
        find.byType(RoomsScreen),
        findsOneWidget,
        reason: 'Back pops to the Rooms list',
      );

      await tester.tap(find.bySemanticsLabel(Strings.tabHome));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.discoverLights));
      await settle(tester);
      expect(find.byType(DiscoveryScreen), findsOneWidget);
      expect(find.byType(WizTabBar<ShellBranch>), findsNothing);
    });
  });

  testWidgets('the window title follows the home', (tester) async {
    await withApp(tester, (services) async {
      expect(
        tester.widget<Title>(find.byType(Title)).title,
        Strings.windowTitle('Kaverappa House'),
      );
    });
  });
}
