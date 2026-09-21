import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet_route.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/lights/bloc/light_bloc.dart';
import 'package:wizctl_app/features/lights/bloc/light_event.dart';
import 'package:wizctl_app/features/lights/view/light_screen.dart';
import 'package:wizctl_app/features/lights/widgets/light_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// The Light screen is the phone one (spec §10.4), so the width stays the
/// compact class its bottom sheets need. The height is the tester's, not the
/// phone's: the screen's body is a lazy `ListView`, and on an 844-tall
/// surface the DEVICE panel at the bottom is never built — which reads
/// exactly like a panel that was never written. `gallery_test.dart` buys the
/// same guarantee the same way.
const Size _phone = Size(390, 2000);

/// Long enough for the sheet's rise, the hero's warm-up and a write to reach
/// the fake bulb.
///
/// Every wait here is a bounded pump: the Light screen never settles, because
/// the live badge's dot pulses and a lit hero breathes for ever, so
/// `pumpAndSettle` would time out (the gallery's tests say the same).
const Duration _settled = Duration(milliseconds: 500);

void main() {
  Widget screen(AppScope scope, LightBloc bloc) => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const LightNoticeListener(child: LightScreen()),
    ),
  );

  /// Builds the fixture on [lightId], runs [body] and tears it down, all
  /// inside the tester's zone: a bloc built in `setUp` runs its event
  /// handlers outside that zone, where `pump` never reaches them, and one
  /// closed outside the body deadlocks — `AppScope`'s doc has both halves.
  ///
  /// [script] runs before anything subscribes, which is where a test inserts
  /// a light or scripts a bulb: `AppScope` copies the seeded live states into
  /// the fake gateway in its constructor, and the bloc reads its own bulb as
  /// the screen opens (spec §5.8).
  Future<void> withLight(
    WidgetTester tester,
    String lightId,
    Future<void> Function(AppScope scope, LightBloc bloc) body, {
    void Function(AppScope scope)? script,
  }) async {
    var scope = AppScope(SeedHome());
    script?.call(scope);
    await scope.start();
    var bloc = LightBloc(
      lightId: lightId,
      lights: scope.seed.lights,
      rooms: scope.seed.rooms,
      store: scope.seed.store,
      setPower: scope.setPower,
      setBrightness: scope.setBrightness,
      setKelvin: scope.setKelvin,
      setSpeed: scope.setSpeed,
      setFixture: scope.setFixture,
      renameLight: scope.renameLight,
      forgetLight: scope.forgetLight,
      sync: scope.sync,
    )..add(const LightSubscribed());
    try {
      await body(scope, bloc);
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  Future<GoRouter> show(
    WidgetTester tester,
    AppScope scope,
    LightBloc bloc, {
    List<String> targets = const [],
  }) async {
    var router = await pumpRouted(
      tester,
      screen(scope, bloc),
      targets: targets,
      size: _phone,
    );
    await tester.pump(_settled);
    return router;
  }

  /// A sheet's own copy of a label the screen behind it also draws.
  Finder inSheet(String text) => find.descendant(
    of: find.byType(WizSheetRoute),
    matching: find.text(text),
  );

  Future<void> openSheet(WidgetTester tester, Finder key) async {
    await tester.tap(key);
    await tester.pump();
    await tester.pump(_settled);
  }

  testWidgets(
    'the dome: bar, live badge, hero, power key, tiles, dials, mode row, '
    'device facts',
    (tester) async {
      await withLight(tester, 'dome', (scope, bloc) async {
        await show(tester, scope, bloc);
        expect(find.text('Ceiling dome light'), findsOneWidget);
        expect(find.text('Living Room · RGB'), findsOneWidget);
        expect(tester.widget<WizBadge>(find.byType(WizBadge)).label, 'Live');
        expect(
          tester.widget<FixtureHero>(find.byType(FixtureHero)).fixture,
          WizFixture.dome,
        );
        expect(tester.widget<WizPowerKey>(find.byType(WizPowerKey)).on, isTrue);
        expect(find.byType(WizStatusBanner), findsNothing);
        expect(find.widgetWithText(WizStatTile, 'COLOUR TEMP'), findsOneWidget);
        expect(find.widgetWithText(WizStatTile, 'INTENSITY'), findsOneWidget);
        expect(find.byType(WizDial), findsNWidgets(2));
        expect(find.widgetWithText(ModeRow, 'Cozy'), findsOneWidget);
        expect(
          find.text('Cozy is a static scene — the bulb ignores speed.'),
          findsOneWidget,
        );
        expect(find.byType(WizSlider), findsNothing);
        expect(find.text('192.168.1.104:38899'), findsOneWidget);
        expect(find.text('a8bb50f1c204'), findsOneWidget);
        expect(find.text('-52 dBm'), findsOneWidget);
      });
    },
  );

  testWidgets('a dynamic scene shows the speed rail, which writes', (
    tester,
  ) async {
    await withLight(
      tester,
      'dome',
      (scope, bloc) async {
        await show(tester, scope, bloc);
        expect(find.byType(WizSlider), findsOneWidget);
        expect(find.text('SPEED'), findsOneWidget);
        expect(
          find.textContaining('static scene'),
          findsNothing,
          reason: 'the note is the static scene\'s, not the rail\'s',
        );
        await tester.drag(find.byType(WizSlider), const Offset(-60, 0));
        await tester.pump(_settled);
        expect(scope.gateway.sends.last.$2.speed, lessThan(150));
      },
      script: (scope) {
        // Both the store and the bulb: the bloc reads its light as the screen
        // opens, so a scene set only in the store would be overwritten by
        // whatever the bulb answers.
        scope.seed.store.update(
          'dome',
          (s) => s.copyWith(active: ActiveChannel.scene, sceneId: 1),
        );
        scope.gateway.states['192.168.1.104'] = const LightState(
          isOn: true,
          dimming: 70,
          sceneId: 1,
          speed: 150,
          rssi: -52,
        );
      },
    );
  });

  testWidgets(
    'the hallway: no reply banner, class tile, one dial and the dims note',
    (tester) async {
      await withLight(
        tester,
        'hall',
        (scope, bloc) async {
          await show(tester, scope, bloc);
          expect(
            tester.widget<WizBadge>(find.byType(WizBadge)).label,
            'No reply',
          );
          expect(find.text('No reply from this light'), findsOneWidget);
          expect(find.widgetWithText(WizStatTile, 'CLASS'), findsOneWidget);
          expect(find.byType(WizDial), findsOneWidget);
          expect(
            find.text('This bulb dims but has no white channel to tune.'),
            findsOneWidget,
          );
          expect(
            find.text('no reply'),
            findsOneWidget,
            reason: 'the signal fact',
          );

          int readsOfHall() =>
              scope.gateway.reads.where((ip) => ip == '192.168.1.118').length;
          var before = readsOfHall();
          await tester.tap(find.text('RETRY'));
          await tester.pump(_settled);
          expect(readsOfHall(), before + 1);
        },
        // Without this the bulb answers and the light is reachable: unlike
        // `RoomBloc`, `LightBloc` reads its own light as the screen opens.
        script: (scope) => scope.gateway.failing['192.168.1.118'] =
            const UnreachableFailure('192.168.1.118', 'no route to host'),
      );
    },
  );

  testWidgets('a plug: the note, the power tile, no dials and no mode row', (
    tester,
  ) async {
    await withLight(
      tester,
      'plug',
      (scope, bloc) async {
        await show(tester, scope, bloc);
        expect(
          find.text(
            'A plug switches power only. It has no brightness, colour or '
            'scene channel.',
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(WizStatTile, 'POWER'), findsOneWidget);
        expect(find.widgetWithText(WizStatTile, 'CLASS'), findsOneWidget);
        expect(find.byType(WizDial), findsNothing);
        expect(find.byType(ModeRow), findsNothing);
      },
      script: (scope) {
        scope.seed.lights.seed([
          Light(
            id: 'plug',
            homeId: 'h1',
            roomId: 'kitchen',
            name: 'Plug by the TV',
            ip: '192.168.1.140',
            mac: 'a8bb50f24001',
            bulbClass: BulbClass.socket,
            fixture: Fixture.socket,
            sortIndex: 9,
            addedAt: scope.seed.added,
          ),
        ]);
        scope.gateway.states['192.168.1.140'] = const LightState(isOn: false);
      },
    );
  });

  testWidgets('the brightness dial and the power key write', (tester) async {
    await withLight(tester, 'dome', (scope, bloc) async {
      await show(tester, scope, bloc);
      await tester.drag(find.byType(WizDial).first, const Offset(0, -40));
      await tester.pump(_settled);
      expect(scope.gateway.sends.last.$2.dimming, greaterThan(70));

      await tester.tap(find.byType(WizPowerKey));
      await tester.pump(_settled);
      expect(scope.gateway.sends.last.$2.state, isFalse);
    });
  });

  testWidgets("the mode row opens the light's modes sheet", (tester) async {
    await withLight(tester, 'dome', (scope, bloc) async {
      await show(tester, scope, bloc);
      await openSheet(tester, find.byType(ModeRow));
      expect(find.text('Light mode · Ceiling dome light'), findsOneWidget);

      // Dismissed rather than left up: closing the sheet is what runs the
      // `whenComplete(bloc.close)` inside `showModesSheet`, so the bloc it
      // built does not outlive this case.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(_settled);
      expect(find.text('Light mode · Ceiling dome light'), findsNothing);
    });
  });

  testWidgets('show it as, rename and forget through their sheets', (
    tester,
  ) async {
    await withLight(tester, 'strip', (scope, bloc) async {
      var router = await show(
        tester,
        scope,
        bloc,
        targets: [AppRoutes.room('living')],
      );
      // One tick per `go`, so "left exactly once" is pinned by the count and
      // not only by where it ended up: two leaves to the same location leave
      // `currentLocation` looking perfectly right.
      //
      // The *provider*, not `routerDelegate`: the delegate coalesces two
      // identical `go`s in one frame into a single rebuild and so cannot tell
      // them apart, which was checked by mutation rather than assumed. The
      // sheets do not show up here either way — `showWizSheet` pushes on the
      // root navigator, not through the router — so this counts leaves alone.
      var navigations = 0;
      router.routeInformationProvider.addListener(() => navigations++);

      await openSheet(tester, find.text('SHOW IT AS'));
      expect(
        find.text(
          'This only changes how the light is drawn here. It does not change '
          'what the bulb supports.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Lamp'));
      await tester.pump();
      await tester.pump(_settled);
      expect(
        tester.widget<FixtureHero>(find.byType(FixtureHero)).fixture,
        WizFixture.desk,
      );

      await openSheet(tester, find.text('RENAME'));
      var saveAlias = find.widgetWithText(WizButton, 'SAVE ALIAS');
      expect(tester.widget<WizButton>(saveAlias).enabled, isTrue);
      await tester.enterText(find.byType(WizTextField), '   ');
      await tester.pump();
      expect(
        tester.widget<WizButton>(saveAlias).enabled,
        isFalse,
        reason: 'a blank alias saves nothing',
      );
      await tester.enterText(find.byType(WizTextField), 'Bookshelf strip');
      await tester.pump();
      await tester.tap(saveAlias);
      await tester.pump();
      await tester.pump(_settled);
      expect(find.text('Bookshelf strip'), findsOneWidget);

      await openSheet(tester, find.text('FORGET'));
      expect(find.text('Forget Bookshelf strip?'), findsOneWidget);
      await tester.tap(inSheet('FORGET'));
      await tester.pump();
      await tester.pump(_settled);
      expect(scope.toasts.toasts, hasLength(1), reason: 'one leave, one toast');
      expect(scope.toasts.toasts.single.title, 'Bookshelf strip forgotten');
      expect(
        scope.toasts.toasts.single.body,
        "Removed from this home's config file",
      );
      expect(
        currentLocation(router),
        AppRoutes.room('living'),
        reason: 'left the detail for its room: nothing beneath to pop to',
      );
      expect(
        navigations,
        1,
        reason:
            'the forget notice leaves; the screen\'s own gone-leave stands '
            'down for a state carrying a LightForgottenNotice',
      );
    });
  });

  testWidgets('cancelling keeps the light; a forget that fails says so', (
    tester,
  ) async {
    await withLight(
      tester,
      'strip',
      (scope, bloc) async {
        var router = await show(
          tester,
          scope,
          bloc,
          targets: [AppRoutes.room('living')],
        );
        await openSheet(tester, find.text('FORGET'));
        await tester.tap(inSheet('CANCEL'));
        await tester.pump();
        await tester.pump(_settled);
        expect(scope.toasts.toasts, isEmpty);
        expect(await scope.seed.lights.get('strip'), isNotNull);

        await openSheet(tester, find.text('FORGET'));
        await tester.tap(inSheet('FORGET'));
        await tester.pump();
        await tester.pump(_settled);
        expect(scope.toasts.toasts.single.title, 'A name is required.');
        expect(await scope.seed.lights.get('strip'), isNotNull);
        expect(find.text('Shelf strip'), findsOneWidget);
        expect(currentLocation(router), '/', reason: 'nothing was forgotten');

        // Again, and it must say so again. `LightError` is the one notice the
        // listener clears, and this is what that clearing buys: an equal
        // notice is only a *change* — and so only reaches the listener — once
        // the last one has been dropped.
        await openSheet(tester, find.text('FORGET'));
        await tester.tap(inSheet('FORGET'));
        await tester.pump();
        await tester.pump(_settled);
        expect(scope.toasts.toasts.map((t) => t.title), [
          'A name is required.',
          'A name is required.',
        ]);
      },
      // `DomainException` is sealed, so a test cannot invent a kind; this one
      // is borrowed for its message alone, which is all the screen shows.
      script: (scope) =>
          scope.seed.lights.deleteError = const EmptyNameException(),
    );
  });

  testWidgets('an unknown id leaves for the home', (tester) async {
    await withLight(tester, 'nope', (scope, bloc) async {
      var router = await show(
        tester,
        scope,
        bloc,
        targets: [AppRoutes.home, AppRoutes.room('living')],
      );
      expect(currentLocation(router), AppRoutes.home);
      expect(scope.gateway.reads, isEmpty, reason: 'no bulb to read');
      expect(scope.toasts.toasts, isEmpty, reason: 'the user did nothing');
    });
  });

  testWidgets('a light deleted elsewhere leaves for its room', (tester) async {
    await withLight(tester, 'strip', (scope, bloc) async {
      var router = await show(
        tester,
        scope,
        bloc,
        targets: [AppRoutes.room('living')],
      );
      expect(find.text('Shelf strip'), findsOneWidget);
      await scope.seed.lights.delete('strip');
      await tester.pump();
      await tester.pump(_settled);
      expect(
        currentLocation(router),
        AppRoutes.room('living'),
        reason: 'the blank body has no bar and so no Back of its own',
      );
      expect(scope.toasts.toasts, isEmpty, reason: 'nothing the user did');
    });
  });

  testWidgets('Back leaves for the room when nothing is beneath', (
    tester,
  ) async {
    await withLight(tester, 'strip', (scope, bloc) async {
      var router = await show(
        tester,
        scope,
        bloc,
        targets: [AppRoutes.room('living')],
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(_settled);
      expect(currentLocation(router), AppRoutes.room('living'));
    });
  });
}
