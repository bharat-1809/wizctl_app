import 'package:wizctl/wizctl.dart';

import '../../domain/entities/entities.dart';
import '../db/app_database.dart';

extension HomeRowMapper on HomeRow {
  Home toDomain() => Home(
    id: id,
    name: name,
    subnet: subnet,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    sortIndex: sortIndex,
  );
}

extension HomeMapper on Home {
  HomeRow toRow() => HomeRow(
    id: id,
    name: name,
    subnet: subnet,
    createdAt: createdAt.millisecondsSinceEpoch,
    sortIndex: sortIndex,
  );
}

extension RoomRowMapper on RoomRow {
  Room toDomain() => Room(
    id: id,
    homeId: homeId,
    name: name,
    glyph: RoomGlyph.parse(glyph),
    sortIndex: sortIndex,
  );
}

extension RoomMapper on Room {
  RoomRow toRow() => RoomRow(
    id: id,
    homeId: homeId,
    name: name,
    glyph: glyph.storageName,
    sortIndex: sortIndex,
  );
}

extension LightRowMapper on LightRow {
  Light toDomain() => Light(
    id: id,
    homeId: homeId,
    roomId: roomId,
    name: name,
    ip: ip,
    mac: mac,
    moduleName: moduleName,
    bulbClass: bulbClass == null
        ? null
        : BulbClass.values.where((c) => c.name == bulbClass).firstOrNull,
    fixture: Fixture.parse(fixture),
    fwVersion: fwVersion,
    sortIndex: sortIndex,
    addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
  );
}

extension LightMapper on Light {
  LightRow toRow() => LightRow(
    id: id,
    homeId: homeId,
    roomId: roomId,
    name: name,
    ip: ip,
    mac: mac,
    moduleName: moduleName,
    bulbClass: bulbClass?.name,
    fixture: fixture.name,
    fwVersion: fwVersion,
    sortIndex: sortIndex,
    addedAt: addedAt.millisecondsSinceEpoch,
  );
}

extension LightStateRowMapper on LightStateRow {
  /// Loaded states are stale: [LiveState.reachable] stays false until a
  /// refresh proves the bulb is there.
  LiveState toDomain() => LiveState(
    isOn: isOn,
    brightness: brightness,
    kelvin: kelvin,
    rgb: Rgb(r, g, b),
    sceneId: sceneId,
    speed: speed,
    active: ActiveChannel.values.firstWhere(
      (a) => a.name == active,
      orElse: () => ActiveChannel.white,
    ),
    reachable: false,
    rssi: rssi,
    updatedAt: updatedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(updatedAt!),
  );
}

extension LiveStateMapperRow on LiveState {
  LightStateRow toRow(String lightId) => LightStateRow(
    lightId: lightId,
    isOn: isOn,
    brightness: brightness,
    kelvin: kelvin,
    r: rgb.r,
    g: rgb.g,
    b: rgb.b,
    sceneId: sceneId,
    speed: speed,
    active: active.name,
    rssi: rssi,
    updatedAt: updatedAt?.millisecondsSinceEpoch,
  );
}
