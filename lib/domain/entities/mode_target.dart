import 'package:equatable/equatable.dart';

/// What a light-mode write or a scene applies to.
sealed class ModeTarget extends Equatable {
  const ModeTarget();

  String get key;

  @override
  List<Object?> get props => [key];
}

final class WholeHomeTarget extends ModeTarget {
  final String homeId;
  const WholeHomeTarget(this.homeId);

  @override
  String get key => 'home:$homeId';
}

final class RoomTarget extends ModeTarget {
  final String roomId;
  const RoomTarget(this.roomId);

  @override
  String get key => 'room:$roomId';
}

final class LightTarget extends ModeTarget {
  final String lightId;
  const LightTarget(this.lightId);

  @override
  String get key => 'light:$lightId';
}
