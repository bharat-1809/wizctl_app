import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/desktop_rail.dart';
import 'package:wizctl_app/app/shell/rail_item.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';
import '../../support/wiz_test_app.dart';

/// A desktop window: the rail shows from medium up (spec §14).
const Size _desktop = Size(1200, 800);

/// Two bounded pumps. Never `pumpAndSettle`: the home's poll timer ticks and
/// the rail's cap slides on every change.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  test('the location decides the lit item', () {
    expect(DesktopRail.itemFor(AppRoutes.home), const AllLightsRailItem());
    expect(
      DesktopRail.itemFor(AppRoutes.room('living')),
      const RoomRailItem('living'),
    );
    expect(
      DesktopRail.itemFor(AppRoutes.light('dome')),
      isNull,
      reason: 'Task 21 lights the room through the inspector',
    );
    expect(DesktopRail.itemFor(AppRoutes.modes), const ScenesRailItem());
    expect(DesktopRail.itemFor(AppRoutes.discover), const DiscoveryRailItem());
    expect(DesktopRail.itemFor(AppRoutes.settings), const SettingsRailItem());
    expect(
      DesktopRail.itemFor(AppRoutes.rooms),
      isNull,
      reason: 'the rooms list is a phone route; the rail names the rooms',
    );
    expect(
      DesktopRail.itemFor(AppRoutes.setup),
      isNull,
      reason: 'the first run is outside the shell, so no rail is mounted',
    );
    expect(
      DesktopRail.itemFor('/rooms/living/anything'),
      isNull,
      reason: 'only a room id, never a path under one',
    );
  });

  test('room items compare by id, the house items by kind', () {
    expect(const RoomRailItem('living'), const RoomRailItem('living'));
    expect(
      const RoomRailItem('living').hashCode,
      const RoomRailItem('living').hashCode,
    );
    expect(const RoomRailItem('living'), isNot(const RoomRailItem('bedroom')));
    expect(const AllLightsRailItem(), isNot(const ScenesRailItem()));
  });

  /// Builds the fixture and the rail's own `HomeScreenBloc`, runs [body] and
  /// tears both down inside the tester's zone (P56).
  Future<void> withRail(
    WidgetTester tester,
    Future<void> Function(AppScope scope, Widget rail) body, {
    bool collapsed = false,
  }) async {
    await setSurface(tester, _desktop);
    var scope = AppScope(SeedHome());
    await scope.start();
    var bloc = HomeScreenBloc(
      homes: scope.seed.homes,
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      settings: scope.seed.settings,
      setPower: scope.setPower,
      sync: scope.sync,
    )..add(const HomeScreenSubscribed());
    try {
      await body(
        scope,
        scope.wrap(
          BlocProvider.value(
            value: bloc,
            child: DesktopRail(collapsed: collapsed),
          ),
        ),
      );
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  testWidgets(
    'the rail lists the rooms with counts, the house and the footer',
    (tester) async {
      await withRail(tester, (scope, rail) async {
        var router = await pumpRouted(
          tester,
          rail,
          targets: [
            AppRoutes.roomPattern,
            AppRoutes.home,
            AppRoutes.modes,
            AppRoutes.discover,
            AppRoutes.settings,
          ],
          size: _desktop,
        );
        await settle(tester);

        expect(find.text(Strings.wordmark), findsOneWidget);
        expect(find.text('Kaverappa House'), findsOneWidget);
        expect(find.text('ROOMS'), findsOneWidget);
        expect(find.text('HOUSE'), findsOneWidget);
        expect(find.text('Living Room'), findsOneWidget);
        expect(
          find.text('3'),
          findsOneWidget,
          reason: "the living room's count",
        );
        expect(find.text(Strings.allLights), findsOneWidget);
        expect(
          find.text('6'),
          findsOneWidget,
          reason: 'every light of the home',
        );
        expect(find.text(Strings.tabScenes), findsOneWidget);
        expect(
          find.text('${sceneGradients.length}'),
          findsOneWidget,
          reason: 'the scene count',
        );
        expect(find.text(Strings.discovery), findsOneWidget);
        expect(find.text(Strings.settings), findsOneWidget);
        expect(find.text('3 on · udp 38899'), findsOneWidget);

        await tester.tap(find.text('Bedroom'));
        await settle(tester);
        expect(currentLocation(router), AppRoutes.room('bedroom'));

        router.go('/');
        await settle(tester);
        await tester.tap(find.text(Strings.settings));
        await settle(tester);
        expect(currentLocation(router), AppRoutes.settings);
      });
    },
  );

  testWidgets(
    'a collapsed rail drops the captions, the counts and the footer',
    (tester) async {
      await withRail(tester, collapsed: true, (scope, rail) async {
        await pumpRouted(tester, rail, size: _desktop);
        await settle(tester);

        expect(find.text(Strings.wordmark), findsNothing);
        expect(find.text('ROOMS'), findsNothing);
        expect(find.text('Living Room'), findsNothing);
        expect(find.text('3 on · udp 38899'), findsNothing);
        expect(
          find.byTooltip('Living Room'),
          findsOneWidget,
          reason: 'the sighted hint a collapsed row gets instead of its label',
        );
        expect(
          find.bySemanticsLabel('Living Room, 3'),
          findsOneWidget,
          reason: 'the row still says what it is and how many lights it holds',
        );
      });
    },
  );

  testWidgets('the home pill opens the homes sheet', (tester) async {
    await withRail(tester, (scope, rail) async {
      await pumpRouted(tester, rail, size: _desktop);
      await settle(tester);

      await tester.tap(find.bySemanticsLabel(Strings.homes));
      await settle(tester);
      expect(find.text(Strings.addHome.toUpperCase()), findsOneWidget);

      // Dismissed before the fixture goes, or the sheet outlives its blocs.
      Navigator.of(
        tester.element(find.text(Strings.addHome.toUpperCase())),
        rootNavigator: true,
      ).pop();
      await settle(tester);
    });
  });
}
