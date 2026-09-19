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
final class RoomPowerToggled extends HomeScreenEvent {
  final String roomId;
  final bool on;
  const RoomPowerToggled(this.roomId, this.on);
  @override
  List<Object?> get props => [roomId, on];
}

/// Pull to refresh.
final class HomeRefreshRequested extends HomeScreenEvent {
  const HomeRefreshRequested();
}
