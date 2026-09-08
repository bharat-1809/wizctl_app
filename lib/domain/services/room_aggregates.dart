import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'capability_rules.dart';
import 'live_state_mapper.dart';
import 'mode_summarizer.dart';

/// The whole-room panel's numbers and note (spec §5.4).
class RoomAggregates {
  final int brightness;
  final int kelvin;
  final bool canKelvin;
  final String? kelvinNote;
  final bool anyOn;
  final int onCount;
  final int unreachableCount;

  const RoomAggregates({
    required this.brightness,
    required this.kelvin,
    required this.canKelvin,
    required this.kelvinNote,
    required this.anyOn,
    required this.onCount,
    required this.unreachableCount,
  });

  static const String noWhiteChannel =
      'No bulb in this room has a white channel to tune.';

  static RoomAggregates of(List<LiveLight> lights) {
    var dimmable = lights
        .where((l) => CapabilityRules.brightness(l.light.bulbClass))
        .toList();
    var tunable = lights
        .where((l) => CapabilityRules.kelvin(l.light.bulbClass))
        .toList();
    var brightness = dimmable.isEmpty
        ? minBrightness
        : (dimmable.map((l) => l.state.brightness).reduce((a, b) => a + b) /
                  dimmable.length)
              .round();
    var kelvin = tunable.isEmpty
        ? LiveState.defaultKelvin
        : LiveStateMapper.snapKelvin(
            (tunable.map((l) => l.state.kelvin).reduce((a, b) => a + b) /
                    tunable.length)
                .round(),
          );
    String? note;
    if (lights.isNotEmpty && tunable.isEmpty) {
      note = noWhiteChannel;
    } else if (tunable.length < lights.length) {
      note = 'Colour temp reaches ${tunable.length} of ${lights.length} bulbs.';
    }
    var on = lights.where((l) => l.state.isOn).length;
    return RoomAggregates(
      brightness: brightness,
      kelvin: kelvin,
      canKelvin: tunable.isNotEmpty,
      kelvinNote: note,
      anyOn: on > 0,
      onCount: on,
      unreachableCount: lights.where((l) => !l.state.reachable).length,
    );
  }
}
