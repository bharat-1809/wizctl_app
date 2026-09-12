import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

import 'rgb.dart';

/// Which channel the bulb is currently showing. Writing a colour sets
/// colour; a kelvin or the temp dial sets white; a scene sets scene.
enum ActiveChannel { white, colour, scene }

/// What a light is doing right now. Every channel keeps its last value so
/// the modes sheet can show the last colour or kelvin.
class LiveState extends Equatable {
  final bool isOn;
  final int brightness;
  final int kelvin;
  final Rgb rgb;
  final int sceneId;
  final int speed;
  final ActiveChannel active;
  final bool reachable;
  final int? rssi;
  final DateTime? updatedAt;

  const LiveState({
    required this.isOn,
    required this.brightness,
    required this.kelvin,
    required this.rgb,
    required this.sceneId,
    required this.speed,
    required this.active,
    required this.reachable,
    this.rssi,
    this.updatedAt,
  });

  /// WiZ's warm-white default kelvin; wizctl has no constant for it.
  static const int defaultKelvin = 2700;

  /// A light never read yet (prototype defaults).
  static const LiveState initial = LiveState(
    isOn: false,
    brightness: 60,
    kelvin: defaultKelvin,
    rgb: Rgb.warm,
    sceneId: 6,
    speed: defaultSpeed,
    active: ActiveChannel.white,
    reachable: false,
  );

  LiveState copyWith({
    bool? isOn,
    int? brightness,
    int? kelvin,
    Rgb? rgb,
    int? sceneId,
    int? speed,
    ActiveChannel? active,
    bool? reachable,
    int? rssi,
    DateTime? updatedAt,
  }) => LiveState(
    isOn: isOn ?? this.isOn,
    brightness: brightness ?? this.brightness,
    kelvin: kelvin ?? this.kelvin,
    rgb: rgb ?? this.rgb,
    sceneId: sceneId ?? this.sceneId,
    speed: speed ?? this.speed,
    active: active ?? this.active,
    reachable: reachable ?? this.reachable,
    rssi: rssi ?? this.rssi,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    isOn,
    brightness,
    kelvin,
    rgb,
    sceneId,
    speed,
    active,
    reachable,
    rssi,
    updatedAt,
  ];
}
