// Shown rather than imported whole: drift's `isNull` column expression and
// `flutter_test`'s null matcher share the name.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/app/blocs/inspector_cubit.dart';
import 'package:wizctl_app/app/dependencies.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/desktop_rail.dart';
import 'package:wizctl_app/app/shell/rail_item.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_rail.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet_route.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_toast_layer.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/desktop/view/grid_screen.dart';
import 'package:wizctl_app/features/desktop/view/inspector_body.dart';
import 'package:wizctl_app/features/desktop/view/inspector_panel.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';

import '../support/fakes.dart';
import '../support/wiz_test_app.dart';

/// The phone (spec §9, §10): 390 wide is the compact width class the shell's
/// tab bar and every screen here are written for.
const Size _phone = Size(390, 844);

/// A desktop window: from medium up the shell draws the rail instead of the
/// tab bar, and `/home` and a room draw the grid instead of the phone screens.
const Size _desktop = Size(1200, 800);

/// A medium window (spec §14, 720–1100): the rail collapses to its glyphs
/// and there is no room for the inspector column, so a selection opens the
/// inspector as a dialog instead.
const Size _medium = Size(900, 700);

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
    Size size = _phone,
  }) async {
    var services = await _services(tester, FakeGateway(), withHome: withHome);
    try {
      await setSurface(tester, size);
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
    await withApp(tester, withHome: false, (_) async {
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(WizTabBar<ShellBranch>), findsNothing);
      expect(find.text(Strings.nameThisHome), findsOneWidget);
    });
  });

  testWidgets('a fresh install titles the window for the setup it is on', (
    tester,
  ) async {
    await withApp(tester, withHome: false, (_) async {
      expect(
        tester.widget<Title>(find.byType(Title)).title,
        Strings.windowSetup,
      );
    });
  });

  testWidgets('with a home: home, the tabs, a room and back, then discovery', (
    tester,
  ) async {
    await withApp(tester, (_) async {
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

  testWidgets('the toast stack sits above the root navigator', (tester) async {
    await withApp(tester, (_) async {
      // Structural rather than a paint check: the layer is installed by
      // `MaterialApp.builder`, which wraps the router's own navigator, so it
      // paints over every route — and the kit's sheets are root-navigator
      // routes (spec §11.2). A layer *inside* a navigator would be covered by
      // the next route pushed onto it.
      expect(find.byType(WizToastLayer), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(WizToastLayer),
          matching: find.byType(Navigator),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('a wide window gets the rail and the grid; shrinking it keeps '
      'the route and the bloc', (tester) async {
    await withApp(tester, size: _desktop, (_) async {
      expect(find.byType(DesktopRail), findsOneWidget);
      expect(find.byType(GridScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(WizTabBar<ShellBranch>), findsNothing);

      await tester.tap(find.text('Living Room'));
      await settle(tester);
      expect(find.text('WHOLE ROOM'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DesktopRail),
          matching: find.text('Living Room'),
        ),
        findsOneWidget,
        reason:
            "the shell's bloc outlives a navigation, so the rail keeps its "
            'rooms — and the room name on screen twice is the rail plus the '
            "grid's own title",
      );
      // The room's own bloc, read through the grid that is drawing it: the
      // room id to check the rail against, and the object the resize below
      // has to keep.
      var before = BlocProvider.of<RoomBloc>(
        tester.element(find.byType(GridScreen)),
      );
      expect(
        tester.widget<WizRail<RailItem>>(find.byType(WizRail<RailItem>)).value,
        RoomRailItem(before.roomId),
        reason:
            'the rail lights the row it went to — the same room the '
            'content column is drawing — not only the one it left',
      );

      await setSurface(tester, _phone);
      await settle(tester);
      expect(find.byType(DesktopRail), findsNothing);
      expect(find.byType(WizTabBar<ShellBranch>), findsOneWidget);
      expect(
        find.byType(RoomScreen),
        findsOneWidget,
        reason: 'same route, phone chrome',
      );
      expect(
        BlocProvider.of<RoomBloc>(tester.element(find.byType(RoomScreen))),
        same(before),
        reason:
            "the branch's navigator is global-keyed, so its pages — and "
            'the blocs they provide — are reparented, not rebuilt',
      );
    });
  });

  testWidgets('the window title follows the home', (tester) async {
    await withApp(tester, (_) async {
      expect(
        tester.widget<Title>(find.byType(Title)).title,
        Strings.windowTitle('Kaverappa House'),
      );
    });
  });

  testWidgets('a medium window collapses the rail and opens the inspector as '
      'a dialog', (tester) async {
    await withApp(tester, size: _medium, (_) async {
      expect(
        tester.widget<DesktopRail>(find.byType(DesktopRail)).collapsed,
        isTrue,
      );
      expect(
        find.byType(InspectorPanel),
        findsNothing,
        reason: 'a medium window is too narrow for the third column',
      );

      await tester.tap(find.text('Ceiling dome light'));
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(WizSheetRoute),
          matching: find.byType(InspectorBody),
        ),
        findsOneWidget,
        reason: 'selecting a card opens the inspector as a dialog instead',
      );
      expect(
        tester.widget<WizSheetRoute>(find.byType(WizSheetRoute)).title,
        Strings.inspector,
        reason: 'the sheet is titled for the panel, not for the light (P82)',
      );
      expect(
        find.descendant(
          of: find.byType(WizSheetRoute),
          matching: find.text('Ceiling dome light'),
        ),
        findsOneWidget,
        reason: "so the body's live heading is the one place the name is shown",
      );

      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      expect(find.byType(InspectorBody), findsNothing);
      expect(
        BlocProvider.of<InspectorCubit>(tester.element(find.byType(GridScreen)))
            .state,
        isNull,
        reason: 'closing the dialog clears the selection it was opened for',
      );
    });
  });

  testWidgets("a light's route on a wide window shows its room with the light "
      'selected', (tester) async {
    await withApp(tester, size: _desktop, (services) async {
      // The one light the graph was seeded with. Read through `runAsync`, like
      // the writes that made it: the database answers off real async.
      var lights = (await tester.runAsync(
        () => services.deps.lights.getByHome(services.homes.single.id),
      ))!;
      GoRouter.of(tester.element(find.byType(GridScreen)))
          .go(AppRoutes.light(lights.single.id));
      // Four frames, not the usual two: the page, then its `LightBloc`'s first
      // emission — which is what names the room to draw — then the selection
      // reaching the column after that frame, then the column's own bloc's
      // first emission.
      await settle(tester);
      await settle(tester);
      expect(find.text('WHOLE ROOM'), findsOneWidget, reason: 'the room grid');
      expect(
        find.byType(InspectorBody),
        findsOneWidget,
        reason: 'the route selected the light into the inspector column',
      );
      expect(find.text('RENAME'), findsOneWidget);
    });
  });
}
