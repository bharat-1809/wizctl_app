import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/mode_summarizer.dart';

enum HomeScreenStatus { loading, ready, noHome }

/// One room card: `<n> lights · <k> on` and its switch.
class RoomTile extends Equatable {
  final Room room;
  final int lightCount;
  final int onCount;
  const RoomTile({
    required this.room,
    required this.lightCount,
    required this.onCount,
  });
  bool get anyOn => onCount > 0;
  @override
  List<Object?> get props => [room, lightCount, onCount];
}

class HomeScreenState extends Equatable {
  final HomeScreenStatus status;
  final Home? home;
  final List<RoomTile> rooms;

  /// Every light of the home with its live state, in repository order; the
  /// desktop "All lights" grid draws these (spec §10.9).
  final List<LiveLight> lights;

  const HomeScreenState({
    required this.status,
    required this.home,
    required this.rooms,
    required this.lights,
  });

  static const HomeScreenState initial = HomeScreenState(
    status: HomeScreenStatus.loading,
    home: null,
    rooms: [],
    lights: [],
  );

  int get lightCount => lights.length;
  int get onCount => lights.where((l) => l.state.isOn).length;
  int get unreachableCount => lights.where((l) => !l.state.reachable).length;
  bool get anyOn => onCount > 0;

  @override
  List<Object?> get props => [status, home, rooms, lights];
}
