import 'package:equatable/equatable.dart';

sealed class HomesEvent extends Equatable {
  const HomesEvent();
  @override
  List<Object?> get props => const [];
}

final class HomesSubscribed extends HomesEvent {
  const HomesSubscribed();
}

final class HomeCreated extends HomesEvent {
  final String name;
  const HomeCreated(this.name);
  @override
  List<Object?> get props => [name];
}

final class HomeSwitched extends HomesEvent {
  final String homeId;
  const HomeSwitched(this.homeId);
  @override
  List<Object?> get props => [homeId];
}

final class HomeRenamed extends HomesEvent {
  final String homeId;
  final String name;
  const HomeRenamed(this.homeId, this.name);
  @override
  List<Object?> get props => [homeId, name];
}

final class HomeDeleted extends HomesEvent {
  final String homeId;
  const HomeDeleted(this.homeId);
  @override
  List<Object?> get props => [homeId];
}

final class HomesNoticeCleared extends HomesEvent {
  const HomesNoticeCleared();
}
