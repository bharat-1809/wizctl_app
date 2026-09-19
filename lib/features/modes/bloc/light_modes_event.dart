import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import 'light_modes_state.dart';

sealed class LightModesEvent extends Equatable {
  const LightModesEvent();
  @override
  List<Object?> get props => const [];
}

final class ModesSubscribed extends LightModesEvent {
  const ModesSubscribed();
}

final class ModesTargetChanged extends LightModesEvent {
  final ModeTarget target;
  const ModesTargetChanged(this.target);
  @override
  List<Object?> get props => [target];
}

final class ModesTabChanged extends LightModesEvent {
  final ModesTab tab;
  const ModesTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

/// A swatch, or a wheel position the view has already turned into a colour.
final class ColourPicked extends LightModesEvent {
  final Rgb rgb;
  const ColourPicked(this.rgb);
  @override
  List<Object?> get props => [rgb];
}

final class WhitePicked extends LightModesEvent {
  final int kelvin;
  const WhitePicked(this.kelvin);
  @override
  List<Object?> get props => [kelvin];
}

final class ScenePicked extends LightModesEvent {
  final int sceneId;
  const ScenePicked(this.sceneId);
  @override
  List<Object?> get props => [sceneId];
}

final class SpeedChanged extends LightModesEvent {
  final int speed;
  const SpeedChanged(this.speed);
  @override
  List<Object?> get props => [speed];
}

final class ModesNoticeCleared extends LightModesEvent {
  const ModesNoticeCleared();
}
