import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/app/dependencies.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('the app builds and the debug gallery is home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var toasts = ToastController();
    addTearDown(toasts.dispose);

    // An in-memory graph: this test never touches a database file, a real
    // network gateway or the CLI exporter.
    var deps = (await tester.runAsync(
      () => AppDependencies.build(
        database: AppDatabase.inMemory(),
        gateway: FakeGateway(),
        networkInfo: FakeNetworkInfo('192.168.1'),
        exportCli: false,
        clock: FakeClock(),
        ids: SequenceIds(),
      ),
    ))!;
    addTearDown(deps.dispose);

    // Never `bootstrap()`: that starts the real audio engine and renders the
    // grain tile. The services it would build are handed in silent instead.
    await tester.pumpWidget(
      WizCtlApp(
        services: AppServices(
          feedback: NoopFeedbackService(),
          toasts: toasts,
          deps: deps,
          homes: const [],
          settings: const AppSettings(),
        ),
      ),
    );

    // The gallery loops for ever (badge dot pulse, skeleton sheen, spinner,
    // the lit hero's breathe, the indeterminate filament), so the tree never
    // settles and `pumpAndSettle` would time out. Bounded pumps only, long
    // enough to drain every `RiseIn` stagger timer.
    await tester.pump(const Duration(milliseconds: 1500));

    // `kDebugMode` is true under `flutter test`, so the gallery is home.
    expect(find.text('Gallery'), findsOneWidget);
  });
}
