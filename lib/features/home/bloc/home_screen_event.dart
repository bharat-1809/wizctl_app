import 'dart:async';

import 'package:equatable/equatable.dart';

sealed class HomeScreenEvent extends Equatable {
  const HomeScreenEvent();
  @override
  List<Object?> get props => const [];
}

final class HomeScreenSubscribed extends HomeScreenEvent {
  const HomeScreenSubscribed();
}

/// The master toggle (spec §10.2).
final class AllPowerToggled extends HomeScreenEvent {
  final bool on;
  const AllPowerToggled(this.on);
  @override
  List<Object?> get props => [on];
}

/// A room card's switch.
final class HomeRoomPowerToggled extends HomeScreenEvent {
  final String roomId;
  final bool on;
  const HomeRoomPowerToggled(this.roomId, this.on);
  @override
  List<Object?> get props => [roomId, on];
}

/// One light's switch on the desktop "All lights" grid (spec §10.9).
///
/// Prefixed `Home…`, like [HomeRoomPowerToggled]: `RoomBloc` owns
/// `RoomLightPowerToggled` and `LightBloc` the unprefixed `LightPowerToggled`,
/// so a view holding two of these blocs can import both event libraries
/// without a prefix.
final class HomeLightPowerToggled extends HomeScreenEvent {
  final String lightId;
  final bool on;
  const HomeLightPowerToggled(this.lightId, this.on);
  @override
  List<Object?> get props => [lightId, on];
}

/// Pull to refresh.
final class HomeRefreshRequested extends HomeScreenEvent {
  /// Completed once the refresh has ended, so a pull can hold its loader for
  /// exactly as long as the read takes rather than dropping it on the next
  /// microtask. Deliberately absent from [props]: what the event asks for is
  /// the same whoever is waiting on it, and a `Completer` has no equality.
  final Completer<void>? done;

  const HomeRefreshRequested({this.done});
}
