import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

/// "Show it as": cosmetic only. It picks the shape drawn on the hero and
/// never gates a control; what a bulb supports comes from its class.
enum Fixture {
  bulb('Bulb', 'lightbulb'),
  dome('Ceiling light', 'lamp-ceiling'),
  desk('Lamp', 'lamp-desk'),
  strip('Light strip', 'waves-horizontal'),
  socket('Plug', 'power');

  final String label;
  final String iconName;
  const Fixture(this.label, this.iconName);

  static Fixture parse(String value) =>
      values.firstWhere((f) => f.name == value, orElse: () => Fixture.bulb);

  /// A discovered socket defaults to Plug; everything else to Bulb.
  static Fixture defaultFor(BulbClass? bulbClass) =>
      bulbClass == BulbClass.socket ? Fixture.socket : Fixture.bulb;
}

class Light extends Equatable {
  final String id;
  final String homeId;
  final String roomId;

  /// The user's alias. It replaces the address everywhere.
  final String name;
  final String ip;
  final String mac;
  final String? moduleName;
  final BulbClass? bulbClass;
  final Fixture fixture;
  final String? fwVersion;
  final int sortIndex;
  final DateTime addedAt;

  const Light({
    required this.id,
    required this.homeId,
    required this.roomId,
    required this.name,
    required this.ip,
    required this.mac,
    this.moduleName,
    this.bulbClass,
    required this.fixture,
    this.fwVersion,
    this.sortIndex = 0,
    required this.addedAt,
  });

  String get className => bulbClass?.displayName ?? 'Unknown';

  Light copyWith({
    String? roomId,
    String? name,
    String? ip,
    String? moduleName,
    BulbClass? bulbClass,
    bool clearBulbClass = false,
    Fixture? fixture,
    String? fwVersion,
    int? sortIndex,
  }) => Light(
    id: id,
    homeId: homeId,
    roomId: roomId ?? this.roomId,
    name: name ?? this.name,
    ip: ip ?? this.ip,
    mac: mac,
    moduleName: moduleName ?? this.moduleName,
    bulbClass: clearBulbClass ? null : (bulbClass ?? this.bulbClass),
    fixture: fixture ?? this.fixture,
    fwVersion: fwVersion ?? this.fwVersion,
    sortIndex: sortIndex ?? this.sortIndex,
    addedAt: addedAt,
  );

  @override
  List<Object?> get props => [
    id,
    homeId,
    roomId,
    name,
    ip,
    mac,
    moduleName,
    bulbClass,
    fixture,
    fwVersion,
    sortIndex,
    addedAt,
  ];
}
