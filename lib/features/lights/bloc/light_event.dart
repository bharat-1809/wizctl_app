import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

sealed class LightEvent extends Equatable {
  const LightEvent();
  @override
  List<Object?> get props => const [];
}

final class LightSubscribed extends LightEvent {
  const LightSubscribed();
}

final class LightPowerChanged extends LightEvent {
  final bool on;
  const LightPowerChanged(this.on);
  @override
  List<Object?> get props => [on];
}

final class LightBrightnessChanged extends LightEvent {
  final int value;
  const LightBrightnessChanged(this.value);
  @override
  List<Object?> get props => [value];
}

final class LightKelvinChanged extends LightEvent {
  final int kelvin;
  const LightKelvinChanged(this.kelvin);
  @override
  List<Object?> get props => [kelvin];
}

final class LightSpeedChanged extends LightEvent {
  final int speed;
  const LightSpeedChanged(this.speed);
  @override
  List<Object?> get props => [speed];
}

/// "Show it as" (spec §10.4).
final class LightFixtureChanged extends LightEvent {
  final Fixture fixture;
  const LightFixtureChanged(this.fixture);
  @override
  List<Object?> get props => [fixture];
}

final class LightRenamed extends LightEvent {
  final String name;
  const LightRenamed(this.name);
  @override
  List<Object?> get props => [name];
}

final class LightForgotten extends LightEvent {
  const LightForgotten();
}

/// The unreachable banner's Retry: read the bulb once more.
final class LightRetryRequested extends LightEvent {
  const LightRetryRequested();
}

final class LightNoticeCleared extends LightEvent {
  const LightNoticeCleared();
}
