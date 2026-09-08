import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  test('room glyphs round-trip through storage names and map to icons', () {
    for (var g in RoomGlyph.values) {
      expect(RoomGlyph.parse(g.storageName), g);
    }
    expect(RoomGlyph.utensils.iconName, 'utensils-crossed');
    expect(RoomGlyph.lampDesk.iconName, 'lamp-desk');
    expect(RoomGlyph.parse('garbage'), RoomGlyph.sofa);
  });

  test('fixtures have labels, icons and class defaults', () {
    expect(Fixture.dome.label, 'Ceiling light');
    expect(Fixture.strip.iconName, 'waves-horizontal');
    expect(Fixture.defaultFor(BulbClass.socket), Fixture.socket);
    expect(Fixture.defaultFor(BulbClass.rgb), Fixture.bulb);
    expect(Fixture.defaultFor(null), Fixture.bulb);
    expect(Fixture.parse('desk'), Fixture.desk);
    expect(Fixture.parse('nope'), Fixture.bulb);
  });

  test('a light reports its class name, Unknown when unclassified', () {
    var light = Light(
      id: 'l',
      homeId: 'h',
      roomId: 'r',
      name: 'Bedside bulb',
      ip: '192.168.1.115',
      mac: 'a8bb50f21177',
      bulbClass: BulbClass.rgb,
      fixture: Fixture.bulb,
      sortIndex: 0,
      addedAt: DateTime(2026, 9, 8),
    );
    expect(light.className, 'RGB');
    expect(
      light.copyWith(bulbClass: null, clearBulbClass: true).className,
      'Unknown',
    );
    expect(light.copyWith(name: 'Lamp'), isNot(equals(light)));
    expect(light.copyWith(), equals(light));
  });

  test('initial live state matches the prototype defaults', () {
    const s = LiveState.initial;
    expect(s.isOn, isFalse);
    expect(s.brightness, 60);
    expect(s.kelvin, LiveState.defaultKelvin);
    expect(s.rgb, Rgb.warm);
    expect(s.sceneId, 6);
    expect(s.speed, defaultSpeed);
    expect(s.active, ActiveChannel.white);
    expect(s.reachable, isFalse);
  });

  test('discovered devices are named from their class', () {
    expect(DiscoveredDevice.nameFor(BulbClass.rgb), 'WiZ RGB');
    expect(DiscoveredDevice.nameFor(BulbClass.tw), 'WiZ Tunable White');
    expect(DiscoveredDevice.nameFor(BulbClass.dw), 'WiZ Dimmable');
    expect(DiscoveredDevice.nameFor(BulbClass.socket), 'WiZ Smart Plug');
    expect(DiscoveredDevice.nameFor(BulbClass.fanDim), 'WiZ Fan Dimmer');
    expect(DiscoveredDevice.nameFor(null), 'WiZ device');
    var d = DiscoveredDevice.fromDiscovered(
      const DiscoveredLight(
        ip: '192.168.1.126',
        mac: 'abc',
        moduleName: 'ESP01_SHRGB1C_31',
        fwVersion: '1.25.0',
      ),
    );
    expect(d.bulbClass, BulbClass.rgb);
    expect(d.displayName, 'WiZ RGB');
    expect(d.alreadySaved, isFalse);
  });

  test('discovered device copyWithMac replaces the mac only', () {
    const d = DiscoveredDevice(
      ip: '192.168.1.126',
      mac: 'old-mac',
      moduleName: 'ESP01_SHRGB1C_31',
    );
    var updated = d.copyWithMac('new-mac');
    expect(updated.mac, 'new-mac');
    expect(updated.ip, d.ip);
    expect(updated.moduleName, d.moduleName);
  });

  test('targets have stable keys', () {
    expect(const WholeHomeTarget('h1').key, 'home:h1');
    expect(const RoomTarget('r1').key, 'room:r1');
    expect(const LightTarget('l1').key, 'light:l1');
    expect(const RoomTarget('r1'), const RoomTarget('r1'));
  });

  test('failures carry readable messages', () {
    expect(
      const TimeoutFailure('192.168.1.5', 3).message,
      contains('192.168.1.5'),
    );
    expect(
      const OffNetworkFailure('192.168.1', '10.0.0').message,
      contains('10.0.0'),
    );
    expect(
      DeviceException(const TimeoutFailure('x', 1)).toString(),
      contains('x'),
    );
  });

  test('settings and flags have defaults', () {
    expect(AppSettings.defaults.feedbackEnabled, isTrue);
    expect(AppSettings.defaults.rescanOnLaunch, isTrue);
    expect(AppSettings.defaults.activeHomeId, isNull);
    expect(DebugFlags.none.forceTimeout, isFalse);
    expect(ModeSummary.mixed.name, 'Mixed');
    expect(ModeSummary.nothingSet.art, const FlatArt());
  });
}
