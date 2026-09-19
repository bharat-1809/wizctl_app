import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/room_event.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// The Room screen this file is about is the phone one (spec §10.3), and its
/// modes sheet is a bottom sheet rather than a centred dialog there, so every
/// case runs on a phone surface rather than the tester's 800×600 default,
/// which `WizLayoutScope` would classify as medium.
const Size _phone = Size(390, 844);

void main() {
  Widget screen(AppScope scope, RoomBloc bloc) =>
      scope.wrap(BlocProvider.value(value: bloc, child: const RoomScreen()));

  /// Builds the fixture on [roomId], runs [body] and tears it down, all
  /// inside the tester's zone: a bloc built in `setUp` runs its event
  /// handlers outside that zone, where `pump` never reaches them, and one
  /// closed outside the body deadlocks — `AppScope`'s doc has both halves.
  Future<void> withRoom(
    WidgetTester tester,
    String roomId,
    Future<void> Function(AppScope scope, RoomBloc bloc) body,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    var bloc = RoomBloc(
      roomId: roomId,
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      setPower: scope.setPower,
      setBrightness: scope.setBrightness,
      setKelvin: scope.setKelvin,
      sync: scope.sync,
    )..add(const RoomSubscribed());
    try {
      await body(scope, bloc);
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  testWidgets('the living room: bar, dials, mode row, three cards', (
    tester,
  ) async {
    await withRoom(tester, 'living', (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('3 lights'), findsOneWidget);
      expect(find.text('WHOLE ROOM'), findsOneWidget);
      expect(find.byType(WizDial), findsNWidgets(2));
      expect(find.text('58'), findsOneWidget);
      expect(find.text('3050'), findsOneWidget);
      expect(find.widgetWithText(ModeRow, 'Mixed'), findsOneWidget);
      expect(find.byType(LightCard), findsNWidgets(3));
      expect(
        find.text('Cozy'),
        findsOneWidget,
        reason: 'the dome is on the Cozy scene',
      );
      expect(
        find.text('Colour'),
        findsOneWidget,
        reason: 'the floor lamp shows a colour',
      );
      expect(find.text('4000K white'), findsOneWidget);
    });
  });

  testWidgets(
    'a room the temperature only half reaches says so, and an unreachable '
    'light shows its address',
    (tester) async {
      await withRoom(tester, 'bedroom', (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await tester.pump();
        expect(find.text('Colour temp reaches 1 of 2 bulbs.'), findsOneWidget);
        var hall = tester.widget<LightCard>(
          find.widgetWithText(LightCard, 'Hallway'),
        );
        expect(hall.unreachable, isTrue);
        expect(hall.meta, '192.168.1.118');
      });
    },
  );

  testWidgets('a plug gets no brightness rail, a bulb does', (tester) async {
    await withRoom(tester, 'kitchen', (scope, bloc) async {
      await scope.seed.lights.insert(
        Light(
          id: 'plug',
          homeId: 'h1',
          roomId: 'kitchen',
          name: 'Kettle plug',
          ip: '192.168.1.130',
          mac: 'a8bb50f24001',
          moduleName: null,
          bulbClass: BulbClass.socket,
          fixture: Fixture.socket,
          fwVersion: '1.25.0',
          sortIndex: 1,
          addedAt: scope.seed.added,
        ),
      );
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      expect(
        tester
            .widget<LightCard>(find.widgetWithText(LightCard, 'Kettle plug'))
            .control,
        WizBrightnessControl.none,
      );
      expect(
        tester
            .widget<LightCard>(
              find.widgetWithText(LightCard, 'Counter downlight'),
            )
            .control,
        WizBrightnessControl.rail,
      );
    });
  });

  testWidgets('tapping a card pushes the light; its switch does not', (
    tester,
  ) async {
    await withRoom(tester, 'living', (scope, bloc) async {
      await pumpRouted(
        tester,
        screen(scope, bloc),
        targets: [AppRoutes.lightPattern],
        size: _phone,
      );
      await tester.pump();
      var stripToggle = find.descendant(
        of: find.widgetWithText(LightCard, 'Shelf strip'),
        matching: find.byType(WizToggle),
      );
      await tester.tap(stripToggle);
      await tester.pump();
      await tester.pump();
      expect(scope.gateway.sends.single.$1, '192.168.1.111');
      expect(
        find.byType(LightCard),
        findsNWidgets(3),
        reason: 'the switch wrote power without leaving the room',
      );

      await tester.tap(find.text('Shelf strip'));
      await tester.pumpAndSettle();
      // `pumpRouted` draws each target as its own location. Asserted on the
      // screen rather than on `currentLocation`, because a `push` adds an
      // imperative match that leaves the match list's own uri where it was.
      expect(find.text(AppRoutes.light('strip')), findsOneWidget);
      expect(
        find.byType(LightCard, skipOffstage: false),
        findsNWidgets(3),
        reason: 'pushed onto the room, so Back comes back to it',
      );
    });
  });

  testWidgets('the room switch writes the whole room', (tester) async {
    await withRoom(tester, 'living', (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Living Room power'));
      await tester.pump();
      await tester.pump();
      expect(scope.gateway.sends, hasLength(3));
    });
  });

  testWidgets('an empty room shows the empty state that leads to discovery', (
    tester,
  ) async {
    await withRoom(tester, 'kitchen', (scope, bloc) async {
      await scope.seed.lights.delete('counter');
      var router = await pumpRouted(
        tester,
        screen(scope, bloc),
        targets: [AppRoutes.discover],
        size: _phone,
      );
      await tester.pump();
      expect(find.byType(WizEmptyState), findsOneWidget);
      expect(find.text('No lights in this room'), findsOneWidget);
      expect(find.byType(WizDial), findsNothing);
      await tester.tap(find.text('DISCOVER LIGHTS'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), AppRoutes.discover);
    });
  });

  testWidgets('the mode row opens the room\'s modes sheet', (tester) async {
    await withRoom(tester, 'living', (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      await tester.tap(find.byType(ModeRow));
      await tester.pumpAndSettle();
      expect(find.text('Light mode · Living Room'), findsOneWidget);
    });
  });

  testWidgets('a pull holds the filament until the refresh ends', (
    tester,
  ) async {
    await withRoom(tester, 'living', (scope, bloc) async {
      // Reads that do not land until this test lets them, so the loader can
      // be looked at while the refresh it is waiting on is still running.
      scope.gateway.readLatency = const Duration(milliseconds: 500);
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      expect(find.byType(WizFilamentBar), findsNothing);
      await tester.fling(find.text('Living Room'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WizFilamentBar), findsOneWidget);
      expect(scope.gateway.reads, isEmpty, reason: 'still reading');

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        scope.gateway.reads,
        hasLength(6),
        reason: 'a refresh reads the whole home, not only this room',
      );
      expect(
        find.byType(WizFilamentBar),
        findsNothing,
        reason: 'the bar goes when the refresh ends, not a microtask after it',
      );
    });
  });
}
