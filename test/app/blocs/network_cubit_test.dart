import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/network_cubit.dart';
import 'package:wizctl_app/app/blocs/network_state.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeNetworkInfo info;
  late NetworkMonitor monitor;

  NetworkCubit build() => NetworkCubit(
    network: monitor,
    settings: seed.settings,
    homes: seed.homes,
  );

  setUp(() {
    seed = SeedHome();
    info = FakeNetworkInfo('192.168.1');
    monitor = NetworkMonitor(info);
  });

  tearDown(() async {
    monitor.dispose();
    await seed.dispose();
  });

  blocTest<NetworkCubit, NetworkState>(
    'on the home subnet nothing is wrong',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await monitor.refresh();
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.offNetwork, isFalse);
      expect(cubit.state.homeSubnet, '192.168.1');
      expect(cubit.state.currentSubnet, '192.168.1');
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'a different subnet is off network, and retry says so while it lasts',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = '10.0.0';
      await monitor.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cubit.retry();
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.offNetwork, isTrue);
      expect(cubit.state.currentSubnet, '10.0.0');
      expect(cubit.state.notice, const StillOffNotice('10.0.0'));
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'no address at all is off network too',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = null;
      await monitor.refresh();
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.offNetwork, isTrue);
      expect(cubit.state.currentSubnet, isNull);
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'a home without a subnet is never off network, and learning one flips it',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = '10.0.0';
      await monitor.refresh();
      await seed.homes.update(seed.home.copyWith(subnet: '10.0.0'));
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.homeSubnet, '10.0.0');
      expect(cubit.state.offNetwork, isFalse);
    },
  );

  // The hazard P55 removed. `watchSubnet` used to be an `async*` generator,
  // and cancelling one suspended in `yield*` never completes inside the
  // tester's fake-async zone: this body hung for ever, with no output and no
  // test timeout, and so did every widget test whose tear-down closed a cubit
  // subscribed here. No `runAsync` flush anywhere — reaching the end is the
  // assertion.
  testWidgets('a subscription taken inside the tester zone cancels', (
    tester,
  ) async {
    var raw = monitor.watchSubnet().listen((_) {});
    var cubit = build()..subscribe();
    await monitor.refresh();
    await tester.pump();
    expect(cubit.state.currentSubnet, '192.168.1');
    await raw.cancel();
    await cubit.close();
  });

  blocTest<NetworkCubit, NetworkState>(
    'switching home re-reads the subnet it compares against',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = '10.0.0';
      await monitor.refresh();
      await cubit.retry();
      cubit.clearNotice();
      await seed.settings.save(
        (await seed.settings.get()).copyWith(activeHomeId: 'h2'),
      );
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.homeSubnet, isNull, reason: 'the Studio has none');
      expect(cubit.state.offNetwork, isFalse);
      expect(cubit.state.notice, isNull);
    },
  );
}
