import 'package:equatable/equatable.dart';

import 'discovered_device.dart';
import 'live_state.dart';

/// A device that answered discovery, the first read taken from it, and
/// whether the run is keeping it — onboarding lets the user drop rows
/// before any of them are saved (spec §10.8).
class FoundDevice extends Equatable {
  final DiscoveredDevice device;

  /// What the bulb reported when it was found, if it answered a read; the
  /// save seeds the store with it so a new light is never blank.
  final LiveState? initial;
  final bool kept;

  const FoundDevice({required this.device, this.initial, this.kept = true});

  /// [initial] cannot be cleared: a row that is re-read keeps the state it
  /// arrived with rather than losing it to a later read that failed.
  FoundDevice copyWith({
    DiscoveredDevice? device,
    LiveState? initial,
    bool? kept,
  }) => FoundDevice(
    device: device ?? this.device,
    initial: initial ?? this.initial,
    kept: kept ?? this.kept,
  );

  @override
  List<Object?> get props => [device, initial, kept];
}
