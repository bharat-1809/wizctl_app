import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_skeleton.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/discovery/widgets/discovery_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// A bulb the home has never seen, and the dome it already owns
/// (`SeedHome`'s `a8bb50f1c204`), which has to come back marked as saved.
const _rgb = DiscoveredLight(
  ip: '192.168.1.126',
  mac: 'newrgb',
  moduleName: 'ESP01_SHRGB1C_31',
);
const _known = DiscoveredLight(
  ip: '192.168.1.104',
  mac: 'a8bb50f1c204',
  moduleName: 'ESP01_SHRGB1C_31',
);

/// The phone (P58): 390 wide is the compact width class the screen's bar and
/// its bottom sheet are written for, and 844 is the phone's own height.
const Size _phone = Size(390, 844);

/// A desktop, where the bar is titled "Discovery" and carries Rescan.
const Size _desktop = Size(1200, 800);

/// Long enough for a run to finish against the fakes, and for a sheet to
/// rise.
///
/// Every wait here is a bounded pump. The screen never settles while a scan
/// is on show — the filament bar travels and the skeletons' sheen sweeps for
/// ever — and the found banner's live dot pulses for ever after it, so
/// `pumpAndSettle` would time out (`light_screen_test.dart` says the same).
const Duration _settled = Duration(milliseconds: 500);

/// How long the fake bulb takes to answer the read `RunDiscovery` takes from
/// every device it finds: long enough that a single frame lands mid-run, with
/// the scanning view on show.
const Duration _slowRead = Duration(seconds: 1);

/// How long the fake repository holds a save open: long enough that several
/// bounded pumps land while the row is still in flight. Every test that sets
/// it pumps it out again before returning, so no timer outlives the test.
const Duration _slowInsert = Duration(seconds: 5);

/// The addresses a /24 sweep walks, as the gateway reports them — the count
/// the found banner names after a sweep.
const int _subnetAddresses = 254;

void main() {
  Widget screen(AppScope scope, DiscoveryBloc bloc) => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const DiscoveryNoticeListener(child: DiscoveryScreen()),
    ),
  );

  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone: a bloc built in `setUp` runs its handlers outside that
  /// zone, where `pump` never reaches them, and one closed outside the body
  /// deadlocks — `AppScope`'s doc has both halves (P56).
  ///
  /// [script] runs before anything subscribes, which is where a test scripts
  /// the wire: the screen runs a real `RunDiscovery` over `FakeGateway`, so
  /// `broadcastResult`, `probeEvents` and `sweepEvents` have to be in place
  /// before the first `DiscoveryStarted`.
  Future<void> withDiscovery(
    WidgetTester tester,
    Future<void> Function(AppScope scope, DiscoveryBloc bloc) body, {
    void Function(AppScope scope)? script,
  }) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    scope.gateway.probeEvents = [const ScanDone([])];
    scope.gateway.broadcastResult = [_rgb, _known];
    scope.gateway.states['192.168.1.126'] = const LightState(
      isOn: true,
      dimming: 40,
    );
    script?.call(scope);
    var bloc = DiscoveryBloc(
      homeId: 'h1',
      runDiscovery: scope.runDiscovery,
      saveDiscoveredLight: scope.saveDiscoveredLight,
      learnHomeSubnet: scope.learnHomeSubnet,
      sync: scope.sync,
    );
    try {
      await body(scope, bloc);
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  /// Pumps the screen and runs a quick scan to completion.
  Future<void> discover(WidgetTester tester) async {
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pump(_settled);
  }

  testWidgets('idle offers the empty state whose key starts a run', (
    tester,
  ) async {
    await withDiscovery(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      expect(find.text('Discover lights'), findsOneWidget);
      expect(find.text('Local network'), findsOneWidget);
      expect(find.text('Nothing found yet'), findsOneWidget);
      await discover(tester);
      expect(find.byType(WizStatusBanner), findsOneWidget);
      expect(find.text('2 lights answered'), findsOneWidget);
      expect(find.text('Broadcast on 192.168.1.0/24'), findsOneWidget);
      expect(find.byType(WizListRow), findsNWidgets(2));
      expect(find.text('192.168.1.126 · RGB'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(
        find.text('SAVED'),
        findsOneWidget,
        reason: 'the dome is already in the home',
      );
      expect(find.text('SCAN AGAIN'), findsOneWidget);
      expect(find.text('SWEEP SUBNET'), findsOneWidget);
    });
  });

  testWidgets('while scanning: the loading banner, the filament and three '
      'skeletons', (tester) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await tester.tap(find.text('DISCOVER LIGHTS'));
        await tester.pump();
        expect(find.text('Listening for lights'), findsOneWidget);
        expect(find.text('Broadcast'), findsOneWidget);
        expect(find.byType(WizFilamentBar), findsOneWidget);
        expect(find.text('DISCOVERING'), findsOneWidget);
        expect(
          find.byType(WizSkeleton),
          findsNWidgets(9),
          reason: 'three rows of a well and two bars',
        );
        // Let the held read land, so nothing is still pending at teardown.
        scope.gateway.readLatency = Duration.zero;
        await tester.pump(_slowRead);
        await tester.pump(_settled);
      },
      // Held after `start()`, so the harness's own activate-home refresh is
      // not stalled with it.
      script: (scope) => scope.gateway.readLatency = _slowRead,
    );
  });

  testWidgets('nothing found: the empty state offers the sweep and the '
      'stale-IP note', (tester) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await discover(tester);
        expect(find.text('No response on the local network'), findsOneWidget);
        expect(
          find.text(
            'Broadcast finds most lights. When an access point filters it, '
            'sweep the subnet one address at a time.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'The IP shown in the Philips app can be stale — it talks to the '
            "cloud. Your router's DHCP client list is the reliable source.",
          ),
          findsOneWidget,
        );
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

  testWidgets('the found banner names the run that just happened', (
    tester,
  ) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await discover(tester);
        expect(find.text('Broadcast on 192.168.1.0/24'), findsOneWidget);
        await tester.tap(find.text('SWEEP SUBNET'));
        await tester.pump(_settled);
        expect(
          find.text('Swept 192.168.1.0/24 · $_subnetAddresses addresses'),
          findsOneWidget,
        );
        await tester.tap(find.text('SCAN AGAIN'));
        await tester.pump(_settled);
        expect(
          find.text('Broadcast on 192.168.1.0/24'),
          findsOneWidget,
          // P74: `sweptOnce` latches, so keying the banner on it would leave
          // this rescan claiming to have swept 0 addresses.
          reason: 'a quick rescan after a sweep is not a sweep',
        );
      },
      script: (scope) => scope.gateway.sweepEvents = [
        const ScanProgress(
          addressesProbed: _subnetAddresses,
          addressCount: _subnetAddresses,
          fraction: 1,
          subnet: '192.168.1',
        ),
        const ScanFound(_rgb),
        const ScanDone([]),
      ],
    );
  });

  testWidgets('a run that fails offers both a retry and a subnet scan', (
    tester,
  ) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await discover(tester);
        // P91 (amended): the package falls back to an ephemeral port when
        // 38899 is taken, so no failure that reaches the app is a port
        // conflict; the copy says what the user can see and act on.
        expect(find.text('Could not search this network'), findsOneWidget);
        expect(
          find.text(
            'The broadcast did not go out. Scan the subnet to try each '
            'address in turn.',
          ),
          findsOneWidget,
        );
        expect(find.text('TRY AGAIN'), findsOneWidget);
        expect(
          find.text('SCAN SUBNET'),
          findsOneWidget,
          reason: 'the sweep learns its own range, so the key needs no subnet',
        );
      },
      script: (scope) => scope.gateway.failing['broadcast'] =
          const UnreachableFailure('broadcast', 'busy'),
    );
  });

  testWidgets('the subnet-scan key on the error view starts a sweep', (
    tester,
  ) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await discover(tester);
        await tester.tap(find.text('SCAN SUBNET'));
        await tester.pump();
        // The run the key starts is short here (no scripted probe events), so
        // what it leaves behind is what proves it ran: only a sweep sets
        // `sweptOnce`.
        expect(bloc.state.sweptOnce, isTrue);
      },
      script: (scope) => scope.gateway.failing['broadcast'] =
          const UnreachableFailure('broadcast', 'busy'),
    );
  });

  testWidgets('a run refused off the home network says which network to join', (
    tester,
  ) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await discover(tester);
        expect(find.text('Not on the home network'), findsOneWidget);
        expect(
          find.text('Join the home network, then scan again.'),
          findsOneWidget,
        );
        expect(
          find.text('Could not search this network'),
          findsNothing,
          reason: 'the copy is keyed on the failure type, not its message',
        );
      },
      // P71: the view reads the type, never `failure.message` — which for
      // this one would name both subnets in the domain's own words.
      script: (scope) => scope.gateway.failing['broadcast'] =
          const OffNetworkFailure('192.168.1', '10.0.0'),
    );
  });

  testWidgets('saving a row: sheet, loading toast, then the saved toast', (
    tester,
  ) async {
    await withDiscovery(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await discover(tester);
      await tester.tap(find.text('SAVE'));
      await tester.pump(_settled);
      expect(find.text('Name this light'), findsOneWidget);
      expect(
        find.text('192.168.1.126 · RGB'),
        findsNWidgets(2),
        reason: 'the row behind the sheet, and the sheet',
      );
      expect(
        tester
            .widget<WizButton>(find.widgetWithText(WizButton, 'SAVE LIGHT'))
            .enabled,
        isFalse,
        reason: 'nothing is typed yet',
      );
      await tester.enterText(find.byType(WizTextField), 'Reading lamp');
      await tester.pump();
      // No pump between the chip and the key, deliberately: the chip sets its
      // notifier at once but the footer rebuilds on the next frame, so a key
      // that read the room its own build closed over would still save the
      // first room. This pins the press-time read.
      await tester.tap(find.text('Kitchen'));
      scope.seed.lights.insertLatency = _slowInsert;
      await tester.tap(find.text('SAVE LIGHT'));
      await tester.pump(_settled);
      expect(scope.toasts.toasts.single.tone, WizToastTone.loading);
      expect(scope.toasts.toasts.single.title, 'Saving Reading lamp');
      expect(
        tester
            .widget<WizButton>(find.widgetWithText(WizButton, 'SAVE'))
            .enabled,
        isFalse,
        reason: 'a second tap would save the light twice',
      );
      await tester.pump(_slowInsert);
      await tester.pump(_settled);
      expect(scope.toasts.toasts.single.tone, WizToastTone.success);
      expect(scope.toasts.toasts.single.title, 'Reading lamp saved');
      expect(
        scope.toasts.toasts.single.body,
        '192.168.1.126 added to this home',
      );
      expect(find.text('SAVED'), findsNWidgets(2));
      var saved = await scope.seed.lights.getByMac('h1', 'newrgb');
      expect(saved?.roomId, 'kitchen');
      expect(saved?.name, 'Reading lamp');
    });
  });

  testWidgets('a save that fails names the light and keeps the row savable', (
    tester,
  ) async {
    await withDiscovery(
      tester,
      (scope, bloc) async {
        await pumpRouted(tester, screen(scope, bloc), size: _phone);
        await discover(tester);
        await tester.tap(find.text('SAVE'));
        await tester.pump(_settled);
        await tester.enterText(find.byType(WizTextField), 'Reading lamp');
        await tester.pump();
        await tester.tap(find.text('SAVE LIGHT'));
        await tester.pump(_settled);
        expect(scope.toasts.toasts.single.tone, WizToastTone.error);
        expect(
          scope.toasts.toasts.single.title,
          'Could not save Reading lamp',
          reason: 'the raw error is never the title',
        );
        expect(scope.toasts.toasts.single.body, contains('database closed'));
        expect(
          find.text('SAVE'),
          findsOneWidget,
          reason: 'the row can be tried again',
        );
      },
      script: (scope) =>
          scope.seed.lights.insertError = StateError('database closed'),
    );
  });

  testWidgets('a save in flight when the screen leaves takes its toast with '
      'it', (tester) async {
    await withDiscovery(tester, (scope, bloc) async {
      await pumpRouted(
        tester,
        screen(scope, bloc),
        targets: [AppRoutes.home],
        size: _phone,
      );
      await discover(tester);
      await tester.tap(find.text('SAVE'));
      await tester.pump(_settled);
      await tester.enterText(find.byType(WizTextField), 'Reading lamp');
      await tester.pump();
      await tester.tap(find.text('SAVE LIGHT'));
      await tester.pump(_settled);
      expect(scope.toasts.toasts.single.tone, WizToastTone.loading);
      await tester.tap(find.bySemanticsLabel('Back'));
      // Two frames: the first runs the leaving route's transition out, the
      // second is where the navigator finalizes it and the subtree unmounts.
      await tester.pump(_settled);
      await tester.pump(_settled);
      expect(
        scope.toasts.toasts,
        isEmpty,
        reason: 'a loading toast waits to be resolved and never times out',
      );
      // Drain the write the screen walked away from.
      await tester.pump(_slowInsert);
    }, script: (scope) => scope.seed.lights.insertLatency = _slowInsert);
  });

  testWidgets('on a desktop the bar is titled Discovery with a Rescan key', (
    tester,
  ) async {
    await withDiscovery(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _desktop);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('RESCAN'), findsOneWidget);
      await tester.tap(find.text('RESCAN'));
      await tester.pump(_settled);
      expect(find.text('2 lights answered'), findsOneWidget);
    });
  });

  testWidgets('back goes home when there is nothing to pop', (tester) async {
    await withDiscovery(tester, (scope, bloc) async {
      var router = await pumpRouted(
        tester,
        screen(scope, bloc),
        targets: [AppRoutes.home],
        size: _phone,
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump(_settled);
      expect(currentLocation(router), AppRoutes.home);
    });
  });
}
