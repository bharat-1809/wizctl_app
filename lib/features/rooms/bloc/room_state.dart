import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/room_aggregates.dart';

enum RoomStatus { loading, ready, gone }

class RoomState extends Equatable {
  final RoomStatus status;
  final Room? room;
  final List<LiveLight> lights;
  final RoomAggregates? aggregates;
  final ModeSummary summary;

  const RoomState({
    required this.status,
    required this.room,
    required this.lights,
    required this.aggregates,
    required this.summary,
  });

  static const RoomState initial = RoomState(
    status: RoomStatus.loading,
    room: null,
    lights: [],
    aggregates: null,
    summary: ModeSummary.nothingSet,
  );

  bool get anyOn => aggregates?.anyOn ?? false;
  bool get canKelvin => aggregates?.canKelvin ?? false;
  String? get kelvinNote => aggregates?.kelvinNote;
  int get brightness => aggregates?.brightness ?? LiveState.initial.brightness;
  int get kelvin => aggregates?.kelvin ?? LiveState.initial.kelvin;
  bool get isEmpty => lights.isEmpty;

  @override
  List<Object?> get props => [status, room, lights, aggregates, summary];
}
