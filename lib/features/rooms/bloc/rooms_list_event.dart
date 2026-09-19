import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

sealed class RoomsListEvent extends Equatable {
  const RoomsListEvent();
  @override
  List<Object?> get props => const [];
}

final class RoomsListSubscribed extends RoomsListEvent {
  const RoomsListSubscribed();
}

final class RoomAdded extends RoomsListEvent {
  final String name;
  final RoomGlyph glyph;
  const RoomAdded(this.name, this.glyph);
  @override
  List<Object?> get props => [name, glyph];
}

final class RoomRenamed extends RoomsListEvent {
  final String roomId;
  final String name;
  const RoomRenamed(this.roomId, this.name);
  @override
  List<Object?> get props => [roomId, name];
}

final class RoomDeleted extends RoomsListEvent {
  final String roomId;
  const RoomDeleted(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

final class RoomsNoticeCleared extends RoomsListEvent {
  const RoomsNoticeCleared();
}
