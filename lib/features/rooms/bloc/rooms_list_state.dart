import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

enum RoomsListStatus { loading, ready, noHome }

/// One list row: `<n> lights · <k> on`.
class RoomRow extends Equatable {
  final Room room;
  final int lightCount;
  final int onCount;
  const RoomRow({
    required this.room,
    required this.lightCount,
    required this.onCount,
  });
  @override
  List<Object?> get props => [room, lightCount, onCount];
}

sealed class RoomsNotice extends Equatable {
  const RoomsNotice();
}

/// "Room saved" / "`<name>` is empty — discover lights for it" (spec §10.6).
final class RoomSavedNotice extends RoomsNotice {
  final String name;
  const RoomSavedNotice(this.name);
  @override
  List<Object?> get props => [name];
}

final class RoomsError extends RoomsNotice {
  final String message;
  const RoomsError(this.message);
  @override
  List<Object?> get props => [message];
}

class RoomsListState extends Equatable {
  final RoomsListStatus status;
  final String? homeId;
  final List<RoomRow> rooms;
  final int lightCount;
  final RoomsNotice? notice;

  const RoomsListState({
    required this.status,
    required this.homeId,
    required this.rooms,
    required this.lightCount,
    this.notice,
  });

  static const RoomsListState initial = RoomsListState(
    status: RoomsListStatus.loading,
    homeId: null,
    rooms: [],
    lightCount: 0,
  );

  RoomsListState copyWith({
    RoomsListStatus? status,
    String? homeId,
    List<RoomRow>? rooms,
    int? lightCount,
    RoomsNotice? notice,
    bool clearNotice = false,
  }) => RoomsListState(
    status: status ?? this.status,
    homeId: homeId ?? this.homeId,
    rooms: rooms ?? this.rooms,
    lightCount: lightCount ?? this.lightCount,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, homeId, rooms, lightCount, notice];
}
