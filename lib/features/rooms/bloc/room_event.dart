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

/// One light's switch on the room's list. Prefixed `Room…`, as is
/// [RoomLightBrightnessChanged], because `LightBloc` owns the unprefixed
/// names: a screen holding both blocs has to be able to import both event
/// libraries without a prefix.
final class RoomLightPowerToggled extends RoomEvent {
  final String lightId;
  final bool on;
  const RoomLightPowerToggled(this.lightId, this.on);
  @override
  List<Object?> get props => [lightId, on];
}

/// One light's brightness rail on the room's list.
final class RoomLightBrightnessChanged extends RoomEvent {
  final String lightId;
  final int value;
  const RoomLightBrightnessChanged(this.lightId, this.value);
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
