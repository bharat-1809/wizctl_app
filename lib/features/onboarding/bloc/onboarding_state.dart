import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';

enum OnboardingStep { nameHome, discovering, nameLights }

/// What one kept light will be saved as.
class Assignment extends Equatable {
  final String alias;
  final String roomTempId;
  final Fixture fixture;
  const Assignment({
    required this.alias,
    required this.roomTempId,
    required this.fixture,
  });

  Assignment copyWith({String? alias, String? roomTempId, Fixture? fixture}) =>
      Assignment(
        alias: alias ?? this.alias,
        roomTempId: roomTempId ?? this.roomTempId,
        fixture: fixture ?? this.fixture,
      );

  @override
  List<Object?> get props => [alias, roomTempId, fixture];
}

sealed class OnboardingNotice extends Equatable {
  const OnboardingNotice();
}

/// "`<Home>` is set up" / "`<n>` lights in `<m>` rooms", then `/home`.
final class OnboardingDone extends OnboardingNotice {
  final Home home;
  final int lightCount;
  final int roomCount;
  const OnboardingDone(this.home, this.lightCount, this.roomCount);
  @override
  List<Object?> get props => [home, lightCount, roomCount];
}

final class OnboardingError extends OnboardingNotice {
  final String message;
  const OnboardingError(this.message);
  @override
  List<Object?> get props => [message];
}

class OnboardingState extends Equatable {
  final OnboardingStep step;
  final String draftName;
  final List<OnboardingRoom> setupRooms;
  final List<FoundDevice> kept;
  final String? subnet;
  final Map<String, Assignment> assignments;

  /// A finish is in flight or has completed. It gates Finish both while the
  /// write is running and after it succeeded, so the first run writes one home
  /// however many times the button is pressed; a refused finish clears it
  /// again so the user can try once more.
  final bool finishing;
  final OnboardingNotice? notice;

  const OnboardingState({
    required this.step,
    required this.draftName,
    required this.setupRooms,
    required this.kept,
    required this.subnet,
    required this.assignments,
    required this.finishing,
    this.notice,
  });

  /// The rooms the first run offers (`WizCtl_Mobile.dc.html` `setupRooms`).
  static const List<OnboardingRoom> defaultRooms = [
    OnboardingRoom(
      tempId: 'sr-living',
      name: 'Living Room',
      glyph: RoomGlyph.sofa,
      custom: false,
    ),
    OnboardingRoom(
      tempId: 'sr-bedroom',
      name: 'Bedroom',
      glyph: RoomGlyph.bed,
      custom: false,
    ),
    OnboardingRoom(
      tempId: 'sr-kitchen',
      name: 'Kitchen',
      glyph: RoomGlyph.utensils,
      custom: false,
    ),
  ];

  static const OnboardingState initial = OnboardingState(
    step: OnboardingStep.nameHome,
    draftName: '',
    setupRooms: defaultRooms,
    kept: [],
    subnet: null,
    assignments: {},
    finishing: false,
  );

  bool get nameEmpty => draftName.trim().isEmpty;

  /// "Finish setup" waits until every kept light has a name (spec §10.1).
  bool get namesComplete =>
      kept.isNotEmpty &&
      kept.every(
        (f) => (assignments[f.device.ip]?.alias ?? '').trim().isNotEmpty,
      );

  /// Rooms that will be written: those that received a light plus the
  /// custom ones (spec §10.1 step 3).
  int get roomsToWrite {
    var used = {for (var a in assignments.values) a.roomTempId};
    return setupRooms.where((r) => r.custom || used.contains(r.tempId)).length;
  }

  OnboardingState copyWith({
    OnboardingStep? step,
    String? draftName,
    List<OnboardingRoom>? setupRooms,
    List<FoundDevice>? kept,
    String? subnet,
    Map<String, Assignment>? assignments,
    bool? finishing,
    OnboardingNotice? notice,
    bool clearNotice = false,
  }) => OnboardingState(
    step: step ?? this.step,
    draftName: draftName ?? this.draftName,
    setupRooms: setupRooms ?? this.setupRooms,
    kept: kept ?? this.kept,
    subnet: subnet ?? this.subnet,
    assignments: assignments ?? this.assignments,
    finishing: finishing ?? this.finishing,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    step,
    draftName,
    setupRooms,
    kept,
    subnet,
    assignments,
    finishing,
    notice,
  ];
}
