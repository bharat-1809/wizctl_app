import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

/// A light that answered discovery, before it has a name or a room.
class DiscoveredDevice extends Equatable {
  final String ip;
  final String mac;
  final String? moduleName;
  final BulbClass? bulbClass;
  final String? fwVersion;

  /// Its MAC already belongs to the active home.
  final bool alreadySaved;

  const DiscoveredDevice({
    required this.ip,
    required this.mac,
    this.moduleName,
    this.bulbClass,
    this.fwVersion,
    this.alreadySaved = false,
  });

  factory DiscoveredDevice.fromDiscovered(
    DiscoveredLight light, {
    bool alreadySaved = false,
  }) => DiscoveredDevice(
    ip: light.ip,
    mac: light.mac,
    moduleName: light.moduleName,
    bulbClass: light.bulbClass,
    fwVersion: light.fwVersion,
    alreadySaved: alreadySaved,
  );

  String get displayName => nameFor(bulbClass);

  static String nameFor(BulbClass? bulbClass) => switch (bulbClass) {
    BulbClass.rgb => 'WiZ RGB',
    BulbClass.tw => 'WiZ Tunable White',
    BulbClass.dw => 'WiZ Dimmable',
    BulbClass.socket => 'WiZ Smart Plug',
    BulbClass.fanDim => 'WiZ Fan Dimmer',
    null => 'WiZ device',
  };

  DiscoveredDevice copyWith({
    String? moduleName,
    BulbClass? bulbClass,
    String? fwVersion,
    bool? alreadySaved,
  }) => DiscoveredDevice(
    ip: ip,
    mac: mac,
    moduleName: moduleName ?? this.moduleName,
    bulbClass: bulbClass ?? this.bulbClass,
    fwVersion: fwVersion ?? this.fwVersion,
    alreadySaved: alreadySaved ?? this.alreadySaved,
  );

  /// A merge picked this device up under a fresh MAC (some sockets rotate
  /// theirs across reboots); keep the rest of the record and adopt it.
  DiscoveredDevice copyWithMac(String mac) => DiscoveredDevice(
    ip: ip,
    mac: mac,
    moduleName: moduleName,
    bulbClass: bulbClass,
    fwVersion: fwVersion,
    alreadySaved: alreadySaved,
  );

  @override
  List<Object?> get props => [
    ip,
    mac,
    moduleName,
    bulbClass,
    fwVersion,
    alreadySaved,
  ];
}
