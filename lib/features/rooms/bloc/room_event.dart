import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class RoomEvent extends Equatable {
  const RoomEvent();
  @override
  List<Object?> get props => const [];
}

final class RoomSubscribed extends RoomEvent {
  const RoomSubscribed();
}

/// The whole-room brightness dial, on every move and on release.
final class RoomBrightnessChanged extends RoomEvent {
  final int value;
  const RoomBrightnessChanged(this.value);
  @override
  List<Object?> get props => [value];
}

final class RoomKelvinChanged extends RoomEvent {
  final int kelvin;
  const RoomKelvinChanged(this.kelvin);
  @override
  List<Object?> get props => [kelvin];
}

final class RoomPowerToggled extends RoomEvent {
  final bool on;
  const RoomPowerToggled(this.on);
  @override
  List<Object?> get props => [on];
}

final class LightPowerToggled extends RoomEvent {
  final String lightId;
  final bool on;
  const LightPowerToggled(this.lightId, this.on);
  @override
  List<Object?> get props => [lightId, on];
}

final class LightBrightnessChanged extends RoomEvent {
  final String lightId;
  final int value;
  const LightBrightnessChanged(this.lightId, this.value);
  @override
  List<Object?> get props => [lightId, value];
}

/// Pull to refresh.
final class RoomRefreshRequested extends RoomEvent {
  /// Completed once the refresh has ended, so a pull can hold its loader for
  /// exactly as long as the read takes rather than dropping it on the next
  /// microtask. Deliberately absent from [props]: what the event asks for is
  /// the same whoever is waiting on it, and a `Completer` has no equality.
  final Completer<void>? done;

  const RoomRefreshRequested({this.done});
}
