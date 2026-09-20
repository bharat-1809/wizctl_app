import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/motion/rise_in.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/discovery/widgets/skeleton_rows.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_state.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';
import 'package:wizctl_app/features/onboarding/widgets/assign_card.dart';
import 'package:wizctl_app/features/onboarding/widgets/keep_row.dart';
import 'package:wizctl_app/features/onboarding/widgets/onboarding_notice_listener.dart';
import 'package:wizctl_app/features/onboarding/widgets/radar.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

/// Two devices no home has ever seen: an RGB bulb and a plug.
const _rgb = DiscoveredLight(
  ip: '192.168.1.126',
  mac: 'newrgb',
  moduleName: 'ESP01_SHRGB1C_31',
);
const _plug = DiscoveredLight(
  ip: '192.168.1.140',
  mac: 'newplug',
  moduleName: 'ESP01_SOCKET_01',
);

/// The phone (P58): 390 wide is the compact width class the steps are
/// written for. The height is the phone's 844 stretched (P69) — step 3 draws
/// two assign cards, each with a field, four room chips and five fixture
/// keys, and `tester.tap` on something below the surface's bottom edge lands
/// on whatever is at those coordinates instead of on the target.
const Size _phone = Size(390, 2000);

/// A desktop, where the steps sit in the centred column.
const Size _desktop = Size(1200, 800);

/// Long enough for a run to finish against the fakes and for the step
/// switcher's 300 ms cross-fade to end, so no finder sees two steps at once.
///
/// Every wait here is a bounded pump. The radar's rings, the filament bar,
/// the skeletons' sheen and the found banner's live dot all animate for
/// ever, so `pumpAndSettle` would time out.
const Duration _settled = Duration(milliseconds: 500);

/// How long the fake bulb holds the read `RunDiscovery` takes from every
/// device it finds: long enough that a frame lands mid-run, with the radar
/// and the skeletons on show.
const Duration _slowRead = Duration(seconds: 1);

/// How long the fake repository holds the first light's write open: long
/// enough that several bounded pumps land while the finish is still in
/// flight. Every test that sets it pumps it out again before returning, so no
/// timer outlives the test.
const Duration _slowInsert = Duration(seconds: 5);

/// The alias typed into the first card. Deliberately not the bulb
/// placeholder, so the field's own text can be told from its hint.
const String _alias = 'Reading lamp';

void main() {
  Widget screen(
    AppScope scope,
    OnboardingBloc onboarding,
    DiscoveryBloc discovery,
  ) => scope.wrap(
    // The shell the router puts this screen in carries the `Scaffold`
    // (Task 19), and step 1's field is a `TextField`, which needs the
    // `Material` inside one; the screen itself adds neither.
    Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<OnboardingBloc>.value(value: onboarding),
          BlocProvider<DiscoveryBloc>.value(value: discovery),
        ],
        child: const OnboardingNoticeListener(child: OnboardingScreen()),
      ),
    ),
  );

  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone: a bloc built in `setUp` runs its handlers outside that
  /// zone, where `pump` never reaches them, and one closed outside the body
  /// deadlocks (P56, and `AppScope`'s own doc).
  ///
  /// [script] runs after `start()` and before anything subscribes, which is
  /// where a test scripts the wire — the discovering step runs a real
  /// `RunDiscovery` over `FakeGateway`, so `broadcastResult` and friends have
  /// to be in place before the first `DiscoveryStarted`.
  Future<void> withOnboarding(
    WidgetTester tester,
    Future<void> Function(
      AppScope scope,
      OnboardingBloc onboarding,
      DiscoveryBloc discovery,
    )
    body, {
    void Function(AppScope scope)? script,
  }) async {
    var scope = AppScope(SeedHome.empty());
    await scope.start();
    scope.gateway.broadcastResult = [_rgb, _plug];
    scope.gateway.states['192.168.1.126'] = const LightState(
      isOn: true,
      dimming: 40,
    );
    scope.gateway.states['192.168.1.140'] = const LightState(isOn: false);
    script?.call(scope);
    var onboarding = OnboardingBloc(
      finishOnboarding: scope.finishOnboarding,
      ids: scope.ids,
    );
    var discovery = DiscoveryBloc(
      onboarding: true,
      runDiscovery: scope.runDiscovery,
      saveDiscoveredLight: scope.saveDiscoveredLight,
      learnHomeSubnet: scope.learnHomeSubnet,
      sync: scope.sync,
    );
    try {
      await body(scope, onboarding, discovery);
    } finally {
      unawaited(onboarding.close());
      unawaited(discovery.close());
      await scope.dispose();
    }
  }

  bool keyEnabled(WidgetTester tester, String label) =>
      tester.widget<WizButton>(find.widgetWithText(WizButton, label)).enabled;

  /// Pumps past a step change: the frame that mounts the next step and starts
  /// whatever it runs, then a bounded wait.
  ///
  /// Two pumps, not one long one. The switcher's cross-fade is driven by a
  /// ticker, and a ticker reports zero elapsed on the first frame it is called
  /// on — which is the frame after the step changed. A single `pump(500ms)`
  /// therefore leaves the step that is leaving still mounted, stacked and
  /// centred behind the one arriving, where it doubles every finder and
  /// swallows taps aimed at the new step's own controls.
  Future<void> settleStep(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(_settled);
  }

  /// Names the home and runs the broadcast to its end, leaving step 2 on the
  /// found view.
  Future<void> nameHomeAndScan(WidgetTester tester) async {
    await tester.enterText(find.byType(WizTextField), 'Kaverappa House');
    await tester.pump();
    await tester.tap(find.text('CREATE HOME'));
    await settleStep(tester);
  }

  testWidgets('the whole first run, on a phone', (tester) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      var router = await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        targets: [AppRoutes.home],
        size: _phone,
      );

      // Step 1.
      expect(find.text('WIZCTL'), findsOneWidget);
      expect(find.text('Name this home'), findsOneWidget);
      expect(
        find.text(
          'No account, no cloud. Lights are reached over UDP on port 38899 '
          'on your own network.',
        ),
        findsOneWidget,
      );
      expect(keyEnabled(tester, 'CREATE HOME'), isFalse);
      await tester.enterText(find.byType(WizTextField), '   ');
      await tester.pump();
      expect(
        keyEnabled(tester, 'CREATE HOME'),
        isFalse,
        reason: 'whitespace is not a name',
      );

      // Step 2 runs the broadcast on entry.
      await nameHomeAndScan(tester);
      expect(find.text('Discovering'), findsOneWidget);
      expect(find.text('2 lights answered'), findsOneWidget);
      expect(find.text('Broadcast on 192.168.1.0/24'), findsOneWidget);
      expect(find.byType(KeepRow), findsNWidgets(2));
      expect(find.text('SAVE 2 LIGHTS'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Keep this light'),
        findsNWidgets(2),
        reason: 'each row is its own keep switch',
      );
      expect(
        find.bySemanticsLabel('Blink this light'),
        findsNWidgets(2),
        reason: 'the flash key stays its own node inside the row',
      );
      await tester.tap(find.text('WiZ Smart Plug'));
      await tester.pump();
      expect(find.text('SAVE 1 LIGHT'), findsOneWidget);
      await tester.tap(find.text('WiZ Smart Plug'));
      await tester.pump();
      await tester.tap(find.text('SAVE 2 LIGHTS'));
      await settleStep(tester);

      // Step 3.
      expect(find.text('Name your lights'), findsOneWidget);
      expect(find.text('A name replaces the address'), findsOneWidget);
      expect(find.byType(AssignCard), findsNWidgets(2));
      expect(
        find.text('Living Room'),
        findsNWidgets(2),
        reason: 'the first room is the default on both cards',
      );
      expect(keyEnabled(tester, 'FINISH SETUP'), isFalse);
      var fields = find.byType(WizTextField);
      await tester.enterText(fields.at(0), _alias);
      await tester.enterText(fields.at(1), 'Plug by the TV');
      await tester.pump();
      await tester.tap(find.text('Bedroom').last);
      await tester.pump();
      expect(keyEnabled(tester, 'FINISH SETUP'), isTrue);
      await tester.tap(find.text('FINISH SETUP'));
      await tester.pump(_settled);

      expect(scope.toasts.toasts.single.tone, WizToastTone.success);
      expect(scope.toasts.toasts.single.title, 'Kaverappa House is set up');
      expect(scope.toasts.toasts.single.body, '2 lights in 2 rooms');
      expect(currentLocation(router), AppRoutes.home);
      expect(await scope.seed.homes.getAll(), hasLength(1));
      var written = await scope.seed.lights.getByHome(
        (await scope.seed.homes.getAll()).single.id,
      );
      expect(
        written.map((l) => l.name),
        containsAll([_alias, 'Plug by the TV']),
      );
    });
  });

  testWidgets('the scanning step draws the radar, the filament and the '
      'skeletons', (tester) async {
    await withOnboarding(
      tester,
      (scope, onboarding, discovery) async {
        await pumpRouted(
          tester,
          screen(scope, onboarding, discovery),
          size: _phone,
        );
        await tester.enterText(find.byType(WizTextField), 'Kaverappa House');
        await tester.pump();
        await tester.tap(find.text('CREATE HOME'));
        await tester.pump();
        await tester.pump();
        expect(find.byType(Radar), findsOneWidget);
        expect(find.text('LISTENING FOR LIGHTS'), findsOneWidget);
        expect(find.byType(SkeletonRows), findsOneWidget);
        // Let the held reads land, so nothing is pending at teardown.
        scope.gateway.readLatency = Duration.zero;
        await tester.pump(_slowRead);
        await tester.pump(_settled);
        expect(find.byType(Radar), findsNothing);
      },
      // Held after `start()`, so the harness's own refresh is not stalled.
      script: (scope) => scope.gateway.readLatency = _slowRead,
    );
  });

  testWidgets('a scan that finds nothing offers the sweep', (tester) async {
    await withOnboarding(
      tester,
      (scope, onboarding, discovery) async {
        await pumpRouted(
          tester,
          screen(scope, onboarding, discovery),
          size: _phone,
        );
        await nameHomeAndScan(tester);
        expect(find.text('No response on the local network'), findsOneWidget);
        await tester.tap(find.text('SCAN SUBNET'));
        await tester.pump(_settled);
        expect(scope.gateway.sweepCalls, hasLength(1));
        expect(
          find.text(
            'Make sure the lights are powered on, then sweep the subnet one '
            'address at a time.',
          ),
          findsOneWidget,
        );
      },
      script: (scope) {
        scope.gateway.broadcastResult = [];
        scope.gateway.sweepEvents = [const ScanDone([])];
      },
    );
  });

  testWidgets('a row the user drops is not carried into naming', (
    tester,
  ) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        size: _phone,
      );
      await nameHomeAndScan(tester);
      await tester.tap(find.text('WiZ Smart Plug'));
      await tester.pump();
      await tester.tap(find.text('WiZ RGB'));
      await tester.pump();
      expect(
        keyEnabled(tester, 'SAVE 0 LIGHTS'),
        isFalse,
        reason: 'there is nothing to name',
      );
      await tester.tap(find.text('WiZ RGB'));
      await tester.pump();
      await tester.tap(find.text('SAVE 1 LIGHT'));
      await settleStep(tester);
      expect(find.byType(AssignCard), findsOneWidget);
      expect(onboarding.state.kept.single.device.ip, '192.168.1.126');
      expect(onboarding.state.assignments.keys, ['192.168.1.126']);
    });
  });

  testWidgets('going back and forward again keeps what was named', (
    tester,
  ) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        size: _phone,
      );
      await nameHomeAndScan(tester);
      await tester.tap(find.text('SAVE 2 LIGHTS'));
      await settleStep(tester);
      await tester.enterText(find.byType(WizTextField).at(0), _alias);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Back'));
      await settleStep(tester);
      expect(
        find.byType(KeepRow),
        findsNWidgets(2),
        reason: 'the rows the scan found are still there',
      );
      await tester.tap(find.text('SAVE 2 LIGHTS'));
      await settleStep(tester);
      expect(find.text(_alias), findsOneWidget);
      expect(onboarding.state.assignments['192.168.1.126']?.alias, _alias);
    });
  });

  testWidgets('a New room chip creates a custom room and gives it the light', (
    tester,
  ) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        size: _phone,
      );
      await nameHomeAndScan(tester);
      await tester.tap(find.text('SAVE 2 LIGHTS'));
      await settleStep(tester);
      await tester.tap(find.text('New room').first);
      await tester.pump(_settled);
      expect(
        find.text('New room'),
        findsNWidgets(3),
        reason: 'two chips and the sheet title',
      );
      await tester.enterText(find.byType(WizTextField).last, 'Study');
      await tester.pump();
      await tester.tap(find.text('CREATE ROOM'));
      await tester.pump(_settled);
      expect(onboarding.state.setupRooms.last.name, 'Study');
      expect(
        onboarding.state.assignments['192.168.1.126']?.roomTempId,
        onboarding.state.setupRooms.last.tempId,
      );
      expect(
        find.text('Study'),
        findsNWidgets(2),
        reason: 'a chip on each card',
      );
    });
  });

  testWidgets('a finish that is refused toasts and offers Finish again', (
    tester,
  ) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      var router = await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        targets: [AppRoutes.home],
        size: _phone,
      );
      await nameHomeAndScan(tester);
      await tester.tap(find.text('SAVE 2 LIGHTS'));
      await settleStep(tester);
      await tester.enterText(find.byType(WizTextField).at(0), _alias);
      await tester.enterText(find.byType(WizTextField).at(1), 'Plug by the TV');
      await tester.pump();
      scope.seed.lights.insertError = StateError('database closed');
      await tester.tap(find.text('FINISH SETUP'));
      await tester.pump(_settled);
      expect(scope.toasts.toasts.single.tone, WizToastTone.error);
      expect(scope.toasts.toasts.single.title, contains('database closed'));
      expect(currentLocation(router), '/', reason: 'the flow has not left');
      expect(
        keyEnabled(tester, 'FINISH SETUP'),
        isTrue,
        reason: 'a refused finish can be tried again',
      );
    });
  });

  testWidgets('a finish in flight takes Back and Finish away', (tester) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      var router = await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        targets: [AppRoutes.home],
        size: _phone,
      );
      await nameHomeAndScan(tester);
      await tester.tap(find.text('SAVE 2 LIGHTS'));
      await settleStep(tester);
      await tester.enterText(find.byType(WizTextField).at(0), _alias);
      await tester.enterText(find.byType(WizTextField).at(1), 'Plug by the TV');
      await tester.pump();
      // The first light's write is held open, so the finish is in flight for
      // the length of the pumps below.
      scope.seed.lights.insertLatency = _slowInsert;
      await tester.tap(find.text('FINISH SETUP'));
      await tester.pump(_settled);
      expect(keyEnabled(tester, 'FINISH SETUP'), isFalse);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      expect(
        onboarding.state.step,
        OnboardingStep.nameLights,
        reason: 'the flow is over; Back has nothing to go back to (P75)',
      );
      expect(find.text('Name your lights'), findsOneWidget);
      // Let the held write land, so nothing is pending at teardown.
      scope.seed.lights.insertLatency = Duration.zero;
      await tester.pump(_slowInsert);
      await tester.pump(_settled);
      expect(currentLocation(router), AppRoutes.home);
    });
  });

  testWidgets('on a wide surface the steps sit in a centred 560 column', (
    tester,
  ) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        screen(scope, onboarding, discovery),
        size: _desktop,
      );
      expect(
        tester.getSize(find.byKey(OnboardingScreen.columnKey)).width,
        OnboardingScreen.desktopColumn,
      );
    });
  });

  testWidgets('reduced motion puts step one on screen at rest', (tester) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        reducedMotion(screen(scope, onboarding, discovery)),
        size: _phone,
      );
      expect(
        tester
            .widget<Opacity>(
              find
                  .descendant(
                    of: find.byType(RiseIn).first,
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        1,
        reason: 'nothing waits for a stagger',
      );
    });
  });
}
