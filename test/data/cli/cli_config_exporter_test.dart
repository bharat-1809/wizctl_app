import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/cli/cli_config_exporter.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  final rooms = [
    const Room(
      id: 'r1',
      homeId: 'h',
      name: 'Living Room',
      glyph: RoomGlyph.sofa,
    ),
    const Room(id: 'r2', homeId: 'h', name: 'Bedroom', glyph: RoomGlyph.bed),
  ];
  final lights = [
    Light(
      id: 'a',
      homeId: 'h',
      roomId: 'r1',
      name: 'Ceiling dome light',
      ip: '192.168.1.104',
      mac: 'aa',
      fixture: Fixture.dome,
      addedAt: DateTime(2026),
    ),
    Light(
      id: 'b',
      homeId: 'h',
      roomId: 'r1',
      name: 'Corner floor lamp',
      ip: '192.168.1.107',
      mac: 'bb',
      fixture: Fixture.desk,
      addedAt: DateTime(2026),
    ),
    Light(
      id: 'c',
      homeId: 'h',
      roomId: 'r2',
      name: 'Bedside bulb',
      ip: '192.168.1.115',
      mac: 'cc',
      fixture: Fixture.bulb,
      addedAt: DateTime(2026),
    ),
  ];

  test('json matches the CLI config shape', () {
    var json = CliConfigExporter.toJson(lights: lights, rooms: rooms);
    expect(json['lights'], {
      '192.168.1.104': {'alias': 'Ceiling dome light', 'mac': 'aa'},
      '192.168.1.107': {'alias': 'Corner floor lamp', 'mac': 'bb'},
      '192.168.1.115': {'alias': 'Bedside bulb', 'mac': 'cc'},
    });
    expect(json['groups'], {
      'Living Room': ['192.168.1.104', '192.168.1.107'],
      'Bedroom': ['192.168.1.115'],
    });
  });

  test('writes atomically into HOME/.config/wizctl/config.json', () async {
    var home = await Directory.systemTemp.createTemp('wizctl-home');
    addTearDown(() => home.delete(recursive: true));
    var exporter = CliConfigExporter(homeDirectory: () => home);
    await exporter.export(lights: lights, rooms: rooms);
    var file = File('${home.path}/.config/wizctl/config.json');
    expect(file.existsSync(), isTrue);
    var parsed = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect((parsed['groups'] as Map)['Bedroom'], ['192.168.1.115']);
    expect(
      Directory('${home.path}/.config/wizctl')
          .listSync()
          .where((f) => f.path.endsWith('.tmp')),
      isEmpty,
    );
    expect(exporter.file.path, file.path);
  });
}
