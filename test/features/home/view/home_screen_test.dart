import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  Widget screen(AppScope scope, HomeScreenBloc bloc) =>
      scope.wrap(BlocProvider.value(value: bloc, child: const HomeScreen()));

  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone: a bloc built in `setUp` runs its event handlers outside
  /// that zone, where `pump` never reaches them, and one closed outside the
  /// body deadlocks — `AppScope`'s doc has both halves.
  Future<void> withHome(
    Future<void> Function(AppScope scope, HomeScreenBloc bloc) body, {
    String? subnet = '192.168.1',
  }) async {
    var scope = AppScope(SeedHome(), subnet: subnet);
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
      await body(scope, bloc);
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  testWidgets(
    'shows the home, its summary, its rooms and the unreachable line',
    (tester) async {
      await withHome((scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc));
        await tester.pump();
        expect(find.text('Kaverappa House'), findsOneWidget);
        expect(find.text('3 rooms · 6 lights'), findsOneWidget);
        expect(find.text('ALL LIGHTS'), findsOneWidget);
        expect(find.text('3 of 6 on'), findsOneWidget);
        expect(find.text('1 light not answering'), findsOneWidget);
        expect(find.byType(RoomCard), findsNWidgets(3));
        expect(find.byType(WizStatusBanner), findsNothing);
      });
    },
  );

  testWidgets('taps navigate: a room card, the discover key', (tester) async {
    await withHome((scope, bloc) async {
      var router = await pumpRouted(
        tester,
        screen(scope, bloc),
        targets: [AppRoutes.roomPattern, AppRoutes.discover],
      );
      await tester.pump();
      await tester.tap(find.text('Living Room'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), '/rooms/living');
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Discover lights'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), AppRoutes.discover);
    });
  });

  testWidgets('the master toggle writes power to every light', (tester) async {
    await withHome((scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('All lights'));
      await tester.pump();
      await tester.pump();
      expect(scope.gateway.sends, hasLength(6));
      expect(scope.gateway.sends.every((s) => s.$2.state == false), isTrue);
      await tester.pump();
      expect(find.text('All off'), findsOneWidget);
    });
  });

  testWidgets('a room card\'s toggle writes that room only', (tester) async {
    await withHome((scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc));
      await tester.pump();
      var bedroomToggle = find.descendant(
        of: find.widgetWithText(RoomCard, 'Bedroom'),
        matching: find.byType(WizToggle),
      );
      await tester.tap(bedroomToggle);
      await tester.pump();
      await tester.pump();
      expect(scope.gateway.sends.map((s) => s.$1), [
        '192.168.1.115',
        '192.168.1.118',
      ]);
    });
  });

  testWidgets('off network shows the banner above the panel', (tester) async {
    await withHome(subnet: '10.0.0', (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc));
      await tester.pump();
      expect(find.byType(WizStatusBanner), findsOneWidget);
      expect(find.text('Not on the home network'), findsOneWidget);
    });
  });
}
