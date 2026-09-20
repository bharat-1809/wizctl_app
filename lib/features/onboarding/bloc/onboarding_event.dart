import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => const [];
}

final class OnboardingNameChanged extends OnboardingEvent {
  final String name;
  const OnboardingNameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

/// "Create home": the name is kept as a draft and the flow moves on; the
/// home itself is written at the end (spec §10.1).
final class OnboardingHomeCreated extends OnboardingEvent {
  const OnboardingHomeCreated();
}

final class OnboardingBack extends OnboardingEvent {
  const OnboardingBack();
}

/// "Save `<n>` lights": the discovery step hands over what it kept and the
/// subnet it saw.
final class OnboardingToNaming extends OnboardingEvent {
  final List<FoundDevice> kept;
  final String? subnet;
  const OnboardingToNaming(this.kept, this.subnet);
  @override
  List<Object?> get props => [kept, subnet];
}

final class OnboardingAliasChanged extends OnboardingEvent {
  final String ip;
  final String alias;
  const OnboardingAliasChanged(this.ip, this.alias);
  @override
  List<Object?> get props => [ip, alias];
}

final class OnboardingRoomPicked extends OnboardingEvent {
  final String ip;
  final String roomTempId;
  const OnboardingRoomPicked(this.ip, this.roomTempId);
  @override
  List<Object?> get props => [ip, roomTempId];
}

final class OnboardingFixturePicked extends OnboardingEvent {
  final String ip;
  final Fixture fixture;
  const OnboardingFixturePicked(this.ip, this.fixture);
  @override
  List<Object?> get props => [ip, fixture];
}

/// The New room sheet: a custom room, optionally given the light whose
/// card opened the sheet.
final class OnboardingRoomAdded extends OnboardingEvent {
  final String name;
  final RoomGlyph glyph;
  final String? forIp;
  const OnboardingRoomAdded(this.name, this.glyph, {this.forIp});
  @override
  List<Object?> get props => [name, glyph, forIp];
}

final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}

final class OnboardingNoticeCleared extends OnboardingEvent {
  const OnboardingNoticeCleared();
}
