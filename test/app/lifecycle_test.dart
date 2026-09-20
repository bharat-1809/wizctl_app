import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/lifecycle.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';

import '../support/app_scope.dart';
import '../support/seed.dart';

/// Long enough for the homes bloc's first projection to land and for a launch
/// read to run against the fakes. Bounded, not `pumpAndSettle`: an active home
/// arms the coordinator's poll timer, so the tree never settles.
const Duration _settled = Duration(milliseconds: 20);

/// A coordinator that counts the two lifecycle calls. Pausing is idempotent
/// and a resume is not otherwise distinguishable from a poll, so the only way
/// to hold the driver to *exactly one* of each is to count them where they
/// arrive.
class _CountingSync extends SyncCoordinator {
  int pauses = 0;
  int resumes = 0;

  _CountingSync(AppScope scope)
    : super(
        refresh: scope.refresh,
        lights: scope.seed.lights,
        settings: scope.seed.settings,
      );

  @override
  void onPaused() {
    pauses++;
    super.onPaused();
  }

  @override
  Future<void> onResumed() {
    resumes++;
    return super.onResumed();
  }
}

void main() {
  /// The addresses the active home's lights answer on — what a launch read
  /// covers.
  Set<String> homeAddresses(AppScope scope) =>
      scope.seed.all.where((l) => l.homeId == 'h1').map((l) => l.ip).toSet();

  /// Builds the fixture and an unstarted driver, runs [body] and tears it all
  /// down inside the tester's zone: an active home arms a periodic timer, and
  /// the tester checks for pending timers when the body returns — before any
  /// `addTearDown` would have run. `AppScope`'s own doc has the other half,
  /// why a bloc may not be built outside the body.
  Future<void> withDriver(
    WidgetTester tester,
    Future<void> Function(
      AppScope scope,
      _CountingSync sync,
      AppLifecycleDriver driver,
    )
    body,
  ) async {
    var scope = AppScope(SeedHome());
    var sync = _CountingSync(scope);
    await scope.monitor.refresh();
    scope.homes.add(const HomesSubscribed());
    var driver = AppLifecycleDriver(
      sync: sync,
      network: scope.monitor,
      homes: scope.homes,
    );
    try {
      await body(scope, sync, driver);
    } finally {
      driver.dispose();
      sync.dispose();
      await scope.dispose();
    }
  }

  testWidgets('a cold start reads the active home', (tester) async {
    await withDriver(tester, (scope, sync, driver) async {
      driver.start();
      await tester.pump(_settled);
      expect(
        scope.gateway.reads.toSet(),
        homeAddresses(scope),
        reason: 'rescan on launch is on by default',
      );
    });
  });

  testWidgets('hiding pauses once and coming back resumes once', (
    tester,
  ) async {
    await withDriver(tester, (scope, sync, driver) async {
      // The app is in the foreground before the driver starts, so the listener
      // is born knowing it and the transitions below are the only ones it
      // sees.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      driver.start();
      await tester.pump(_settled);
      scope.gateway.reads.clear();
      var subnetReads = scope.networkInfo.calls;

      // Going away: a real hide passes through `inactive`, and the driver
      // must pause on the hide alone rather than on both.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      expect(sync.pauses, 1);
      expect(sync.resumes, 0);
      expect(scope.gateway.reads, isEmpty, reason: 'nothing is read away');

      // Coming back: `hidden → inactive` is a show and `inactive → resumed` a
      // resume. Only one of the two refreshes.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(_settled);
      expect(sync.pauses, 1);
      expect(sync.resumes, 1);
      expect(
        scope.networkInfo.calls,
        subnetReads + 1,
        reason: 'the subnet is re-read once, for the off-network banner',
      );
      expect(
        scope.gateway.reads.toSet(),
        homeAddresses(scope),
        reason: 'coming back reads the home again',
      );
    });
  });

  testWidgets('switching home activates it for polling', (tester) async {
    await withDriver(tester, (scope, sync, driver) async {
      driver.start();
      await tester.pump(_settled);
      scope.gateway.reads.clear();

      scope.homes.add(const HomeSwitched('h2'));
      await tester.pump(_settled);
      await sync.refreshAll();
      expect(scope.gateway.reads, [
        '10.0.0.42',
      ], reason: 'the Studio is the active home now');
    });
  });
}
