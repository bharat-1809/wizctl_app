import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/mode_summarizer.dart';
import 'package:wizctl_app/domain/services/room_aggregates.dart';

LiveLight ll(String id, BulbClass? cls, LiveState s) => (
  light: Light(
    id: id,
    homeId: 'h',
    roomId: 'r',
    name: id,
    ip: id,
    mac: id,
    bulbClass: cls,
    fixture: Fixture.bulb,
    addedAt: DateTime(2026),
  ),
  state: s,
);

void main() {
  test('averages brightness over dimmable lights and kelvin over white-capable ones, snapped to 50', () {
    var a = RoomAggregates.of([
      ll(
        'a',
        BulbClass.rgb,
        LiveState.initial.copyWith(brightness: 70, kelvin: 2450, isOn: true),
      ),
      ll(
        'b',
        BulbClass.tw,
        LiveState.initial.copyWith(brightness: 30, kelvin: 4000),
      ),
      ll(
        'c',
        BulbClass.socket,
        LiveState.initial.copyWith(brightness: 100, isOn: true),
      ),
    ]);
    expect(a.brightness, 50);
    expect(a.kelvin, 3250);
    expect(a.canKelvin, isTrue);
    expect(a.kelvinNote, 'Colour temp reaches 2 of 3 bulbs.');
    expect(a.anyOn, isTrue);
    expect(a.onCount, 2);
  });

  test('no white channel at all', () {
    var a = RoomAggregates.of([
      ll('a', BulbClass.dw, LiveState.initial),
      ll('b', BulbClass.socket, LiveState.initial),
    ]);
    expect(a.canKelvin, isFalse);
    expect(a.kelvinNote, 'No bulb in this room has a white channel to tune.');
    expect(a.anyOn, isFalse);
  });

  test('all capable means no note; empty rooms default', () {
    expect(
      RoomAggregates.of([ll('a', BulbClass.rgb, LiveState.initial)]).kelvinNote,
      isNull,
    );
    var e = RoomAggregates.of([]);
    expect(e.brightness, minBrightness);
    expect(e.kelvin, 2700);
    expect(e.canKelvin, isFalse);
    expect(e.kelvinNote, isNull);
  });

  test('unreachable count', () {
    var a = RoomAggregates.of([
      ll('a', BulbClass.rgb, LiveState.initial.copyWith(reachable: false)),
      ll('b', BulbClass.rgb, LiveState.initial.copyWith(reachable: true)),
    ]);
    expect(a.unreachableCount, 1);
  });
}
