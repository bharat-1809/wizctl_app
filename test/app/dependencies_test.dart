import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/dependencies.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../support/fakes.dart';

/// An in-memory database and fakes throughout: `exportCli: false` so the
/// real home directory is never touched.
Future<AppDependencies> _build(FakeGateway gateway) => AppDependencies.build(
  database: AppDatabase.inMemory(),
  gateway: gateway,
  networkInfo: FakeNetworkInfo('192.168.1'),
  exportCli: false,
  clock: FakeClock(),
  ids: SequenceIds(),
);

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('wires the whole logic layer end to end', () async {
    var gateway = FakeGateway();
    var deps = await _build(gateway);
    addTearDown(deps.dispose);

    var home = await deps.createHome('Kaverappa House', subnet: '192.168.1');
    var room = await deps.addRoom(home.id, 'Living Room', RoomGlyph.sofa);
    var light = await deps.saveDiscoveredLight(
      homeId: home.id,
      roomId: room.id,
      device: const DiscoveredDevice(
        ip: '192.168.1.104',
        mac: 'aa',
        bulbClass: BulbClass.rgb,
      ),
      alias: 'Ceiling dome light',
      fixture: Fixture.dome,
    );
    expect((await deps.settings.get()).activeHomeId, home.id);

    gateway.states['192.168.1.104'] = const LightState(
      isOn: true,
      dimming: 70,
      temperature: 2700,
    );
    await deps.refreshStates.forHome(home.id);
    expect(deps.store.of(light.id).isOn, isTrue);
    expect(deps.store.of(light.id).reachable, isTrue);

    await deps.setBrightness(RoomTarget(room.id), 40);
    expect(gateway.sends.last.$2.dimming, 40);
    expect(deps.store.of(light.id).brightness, 40);

    var reports = <CommandReport>[];
    var sub = deps.pipeline.reports.listen(reports.add);
    await deps.setPower(LightTarget(light.id), false);
    await Future<void>.delayed(Duration.zero);
    expect(reports.last, isA<CommandSucceeded>());
    await sub.cancel();
  });

  test('dispose closes everything', () async {
    var deps = await _build(FakeGateway());

    await deps.dispose();

    await expectLater(
      Future(() => deps.database.select(deps.database.homes).get()),
      throwsA(anything),
    );
    await expectLater(deps.dispose(), completes);
  });
}
