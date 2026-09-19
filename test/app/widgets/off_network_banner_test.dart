import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wizctl_app/app/blocs/network_cubit.dart';
import 'package:wizctl_app/app/widgets/off_network_banner.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';
import '../../support/wiz_test_app.dart';

void main() {
  late SeedHome seed;
  late FakeNetworkInfo info;
  late NetworkMonitor monitor;
  late NetworkCubit cubit;
  late ToastController toasts;

  setUp(() {
    seed = SeedHome();
    info = FakeNetworkInfo('10.0.0');
    monitor = NetworkMonitor(info);
    cubit = NetworkCubit(
      network: monitor,
      settings: seed.settings,
      homes: seed.homes,
    );
    toasts = ToastController();
  });

  tearDown(() async {
    await cubit.close();
    monitor.dispose();
    toasts.dispose();
    await seed.dispose();
  });

  // The toast controller is a `ChangeNotifier`, and `RepositoryProvider` is
  // a `Provider`, which asserts against Listenable values; what matters to
  // the banner is that `context.read<ToastController>()` resolves, which it
  // does from either.
  Widget subject() => BlocProvider.value(
    value: cubit,
    child: ChangeNotifierProvider<ToastController>.value(
      value: toasts,
      child: const OffNetworkBanner(),
    ),
  );

  /// Subscribes the cubit and pumps the banner.
  ///
  /// [NetworkCubit.subscribe] is called here, inside the tester's zone, so
  /// the monitor's subnet reaches the cubit as a fake microtask that `pump`
  /// flushes — and, since the monitor has already read the interfaces by
  /// then, `watchSubnet` replays it at once, as it does in the running app
  /// where the monitor is started before any screen is built.
  Future<void> pumpBanner(WidgetTester tester) async {
    cubit.subscribe();
    await tester.pumpWidget(wizTestApp(subject()));
    await tester.pump();
  }

  testWidgets('nothing is shown on the home network', (tester) async {
    info.subnet = '192.168.1';
    await monitor.refresh();
    await pumpBanner(tester);
    expect(find.byType(WizStatusBanner), findsNothing);
  });

  testWidgets('off network shows the banner with both subnets', (tester) async {
    await monitor.refresh();
    await pumpBanner(tester);
    expect(find.text(Strings.notOnHomeNetworkTitle), findsOneWidget);
    expect(
      find.text(
        'This device is on 10.0.0.0/24. Lights answer only on 192.168.1.0/24.',
      ),
      findsOneWidget,
    );
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('no address at all says so', (tester) async {
    info.subnet = null;
    await monitor.refresh();
    await pumpBanner(tester);
    expect(find.text(Strings.noLocalNetwork), findsOneWidget);
  });

  testWidgets('retry while still off pushes the still-on toast', (
    tester,
  ) async {
    await monitor.refresh();
    await pumpBanner(tester);
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await tester.pump();
    expect(toasts.toasts.single.title, 'Still on 10.0.0.0/24');
    expect(toasts.toasts.single.body, Strings.joinHomeNetwork);
    expect(cubit.state.notice, isNull, reason: 'consumed by the listener');
    // The toast's own 3.2 s dismiss clock is running; let it finish, or the
    // tester reports a timer still pending after the tree is gone.
    await tester.pump(ToastController.defaultDuration);
  });
}
