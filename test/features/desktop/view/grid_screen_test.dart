import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/features/desktop/view/grid_screen.dart';
import 'package:wizctl_app/features/desktop/widgets/grid_room_panel.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/room_event.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

/// The grid is the desktop reading (spec §10.9), so every case runs on a
/// desktop surface: `WizLayoutScope` classifies 1200 as expanded, which is
/// what puts the desktop gutter and three grid columns on screen.
const Size _desktop = Size(1200, 800);

/// One screen fade with room for the cards' load-in stagger. Bounded, never
/// `pumpAndSettle`: a lit card breathes and the poll timer ticks for ever.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone (P56): a bloc built in `setUp` runs its handlers where
  /// `pump` never reaches them, and one closed outside the body deadlocks.
  Future<void> withScope(
    WidgetTester tester,
    Future<void> Function(AppScope scope) body,
  ) async {
    await setSurface(tester, _desktop);
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await body(scope);
    } finally {
      await scope.dispose();
    }
  }

  testWidgets('All lights: the bar, the tiles, the meter cards, selection', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var bloc = HomeScreenBloc(
        homes: scope.seed.homes,
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        settings: scope.seed.settings,
        setPower: scope.setPower,
        sync: scope.sync,
      )..add(const HomeScreenSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.allLights()),
        ),
        size: _desktop,
      );
      await settle(tester);

      expect(find.text(Strings.allLights), findsOneWidget);
      expect(find.text('6 lights · 3 on'), findsOneWidget);
      expect(find.widgetWithText(WizStatTile, 'LIGHTS ON'), findsOneWidget);
      expect(find.text('3 / 6'), findsOneWidget);
      expect(find.widgetWithText(WizStatTile, 'NOT ANSWERING'), findsOneWidget);
      expect(
        find.text(Strings.oneLightDidNotAnswer),
        findsOneWidget,
        reason: 'the hallway is silent, so the grid carries the banner too',
      );
      expect(find.text('LIGHTS'), findsOneWidget);
      expect(find.byType(LightCard), findsNWidgets(6));
      expect(
        tester
            .widgetList<LightCard>(find.byType(LightCard))
            .every((c) => c.control == WizBrightnessControl.meter),
        isTrue,
        reason: 'the desktop grid reads brightness, it does not drag it',
      );
      expect(find.text('ADD ROOM'), findsOneWidget);

      await tester.tap(find.text('Bedside bulb'));
      await settle(tester);
      expect(scope.inspector.state, 'bedside');
      expect(
        tester
            .widget<LightCard>(find.widgetWithText(LightCard, 'Bedside bulb'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<LightCard>(find.widgetWithText(LightCard, 'Hallway'))
            .selected,
        isFalse,
        reason: 'one light at a time',
      );
    });
  });

  testWidgets('a home with no lights draws the bar and the tiles, no cards', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      for (var light in scope.seed.all) {
        await scope.seed.lights.delete(light.id);
      }
      var bloc = HomeScreenBloc(
        homes: scope.seed.homes,
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        settings: scope.seed.settings,
        setPower: scope.setPower,
        sync: scope.sync,
      )..add(const HomeScreenSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.allLights()),
        ),
        size: _desktop,
      );
      await settle(tester);

      expect(find.text('0 lights · 0 on'), findsOneWidget);
      expect(find.text('0 / 0'), findsOneWidget);
      expect(find.byType(LightCard), findsNothing);
      expect(
        find.text(Strings.oneLightDidNotAnswer),
        findsNothing,
        reason: 'nothing to be silent',
      );
      expect(find.text('ADD ROOM'), findsOneWidget);
    });
  });

  testWidgets('a light\'s switch on the grid writes that light only', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var bloc = HomeScreenBloc(
        homes: scope.seed.homes,
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        settings: scope.seed.settings,
        setPower: scope.setPower,
        sync: scope.sync,
      )..add(const HomeScreenSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.allLights()),
        ),
        size: _desktop,
      );
      await settle(tester);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(LightCard, 'Shelf strip'),
          matching: find.byType(WizToggle),
        ),
      );
      await settle(tester);
      expect(scope.gateway.sends.single.$1, '192.168.1.111');
      expect(
        scope.inspector.state,
        isNull,
        reason: 'the switch is its own control, not a selection',
      );
    });
  });

  testWidgets('the bar\'s Add room key opens the sheet and saves a room', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var bloc = HomeScreenBloc(
        homes: scope.seed.homes,
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        settings: scope.seed.settings,
        setPower: scope.setPower,
        sync: scope.sync,
      )..add(const HomeScreenSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.allLights()),
        ),
        size: _desktop,
      );
      await settle(tester);

      // The key is built above the `BlocBuilder`, so its callbacks close over
      // the screen's own context: this is what proves that context can still
      // reach `HomesBloc`, `AddRoom`, the toasts and a navigator.
      await tester.tap(find.text('ADD ROOM'));
      await settle(tester);
      expect(find.text(Strings.roomName.toUpperCase()), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Study');
      await settle(tester);
      await tester.tap(find.text(Strings.saveRoom.toUpperCase()));
      await settle(tester);
      expect(
        (await scope.seed.rooms.getByHome('h1')).map((r) => r.name),
        contains('Study'),
      );
      var toast = scope.toasts.toasts.single;
      expect(toast.title, Strings.roomSaved);
      expect(toast.body, Strings.roomIsEmpty('Study'));
    });
  });

  testWidgets('a room: the whole-room panel, the switch, the room\'s cards', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var bloc = RoomBloc(
        roomId: 'living',
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        setPower: scope.setPower,
        setBrightness: scope.setBrightness,
        setKelvin: scope.setKelvin,
        sync: scope.sync,
      )..add(const RoomSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.room()),
        ),
        size: _desktop,
      );
      await settle(tester);

      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('3 lights'), findsOneWidget);
      expect(find.text('WHOLE ROOM'), findsOneWidget);
      expect(find.byType(WizDial), findsNWidgets(2));
      expect(
        tester.getSize(find.byType(WizDial).first).width,
        GridScreen.dialSize,
        reason: 'the desktop draws the room dials a size up from the phone',
      );
      expect(find.widgetWithText(ModeRow, 'Mixed'), findsOneWidget);
      expect(find.byType(LightCard), findsNWidgets(3));
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.roomPower('Living Room')));
      await settle(tester);
      expect(scope.gateway.sends, hasLength(3));
    });
  });

  testWidgets('the panel\'s right column carries the colour-temperature note', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var bloc = RoomBloc(
        roomId: 'bedroom',
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        setPower: scope.setPower,
        setBrightness: scope.setBrightness,
        setKelvin: scope.setKelvin,
        sync: scope.sync,
      )..add(const RoomSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.room()),
        ),
        size: _desktop,
      );
      await settle(tester);

      var note = find.text('Colour temp reaches 1 of 2 bulbs.');
      expect(note, findsOneWidget);
      expect(
        find.ancestor(of: note, matching: find.byType(GridRoomPanel)),
        findsOneWidget,
        reason: 'the desktop reads the note under the mode row, not the dials',
      );
      expect(
        tester.getCenter(note).dx,
        greaterThan(tester.getCenter(find.byType(WizDial).first).dx),
        reason: 'the right column',
      );
      expect(find.text('0 / 2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget, reason: 'the hallway is silent');
    });
  });

  testWidgets('an empty room on a desktop uses the desktop line', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      await scope.seed.lights.delete('counter');
      var bloc = RoomBloc(
        roomId: 'kitchen',
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        setPower: scope.setPower,
        setBrightness: scope.setBrightness,
        setKelvin: scope.setKelvin,
        sync: scope.sync,
      )..add(const RoomSubscribed());
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.room()),
        ),
        size: _desktop,
      );
      await settle(tester);

      expect(find.byType(WizEmptyState), findsOneWidget);
      expect(find.text(Strings.discoverThenSave), findsOneWidget);
      expect(
        find.byType(WizDial),
        findsNothing,
        reason: 'nothing to dial in an empty room',
      );
    });
  });

  testWidgets('a room that is gone offers to make one, and never flashes it', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var bloc = RoomBloc(
        roomId: 'nowhere',
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        setPower: scope.setPower,
        setBrightness: scope.setBrightness,
        setKelvin: scope.setKelvin,
        sync: scope.sync,
      );
      addTearDown(() => unawaited(bloc.close()));
      await pumpRouted(
        tester,
        scope.wrap(
          BlocProvider.value(value: bloc, child: const GridScreen.room()),
        ),
        size: _desktop,
      );
      expect(
        find.text(Strings.noRoom),
        findsNothing,
        reason: 'the first read is still in flight; the desktop shows nothing',
      );

      bloc.add(const RoomSubscribed());
      await settle(tester);
      expect(find.text(Strings.noRoom), findsOneWidget);
      expect(find.text(Strings.createRoomToGroup), findsOneWidget);
    });
  });
}
