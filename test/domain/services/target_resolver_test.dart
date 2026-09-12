import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';

import '../../support/fakes.dart';

void main() {
  Light light(String id, String room) => Light(
    id: id,
    homeId: 'h1',
    roomId: room,
    name: id,
    ip: id,
    mac: id,
    bulbClass: BulbClass.rgb,
    fixture: Fixture.bulb,
    addedAt: DateTime(2026),
  );

  test('resolves whole home, room and light targets', () async {
    var lights = FakeLightRepository()
      ..seed([light('a', 'r1'), light('b', 'r1'), light('c', 'r2')]);
    var resolver = TargetResolver(lights);
    expect(
      (await resolver.resolve(const WholeHomeTarget('h1'))).map((l) => l.id),
      ['a', 'b', 'c'],
    );
    expect((await resolver.resolve(const RoomTarget('r1'))).map((l) => l.id), [
      'a',
      'b',
    ]);
    expect((await resolver.resolve(const LightTarget('c'))).map((l) => l.id), [
      'c',
    ]);
    expect(await resolver.resolve(const LightTarget('zzz')), isEmpty);
  });
}
