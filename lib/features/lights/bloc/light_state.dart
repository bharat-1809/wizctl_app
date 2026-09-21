import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/capability_rules.dart';
import '../../../domain/services/mode_summarizer.dart';

enum LightStatus { loading, ready, gone }

sealed class LightNotice extends Equatable {
  const LightNotice();
}

/// "`<name>` forgotten" / "Removed from this home's config file"; the view
/// leaves the screen. It arrives with [LightStatus.gone] in the same state,
/// so a forget gives the view exactly one reason to go.
final class LightForgottenNotice extends LightNotice {
  final String name;
  const LightForgottenNotice(this.name);
  @override
  List<Object?> get props => [name];
}

final class LightError extends LightNotice {
  final String message;
  const LightError(this.message);
  @override
  List<Object?> get props => [message];
}

class LightState extends Equatable {
  final LightStatus status;
  final Light? light;
  final Room? room;
  final LiveState live;
  final ModeSummary summary;
  final LightNotice? notice;

  const LightState({
    required this.status,
    required this.light,
    required this.room,
    required this.live,
    required this.summary,
    this.notice,
  });

  static const LightState initial = LightState(
    status: LightStatus.loading,
    light: null,
    room: null,
    live: LiveState.initial,
    summary: ModeSummary.nothingSet,
  );

  BulbClass? get _cls => light?.bulbClass;
  bool get canBrightness => CapabilityRules.brightness(_cls);
  bool get canKelvin => CapabilityRules.kelvin(_cls);
  bool get canColour => CapabilityRules.colour(_cls);
  bool get canScenes => CapabilityRules.scenes(_cls);
  bool get isSocket => _cls == BulbClass.socket;

  /// The speed rail: only while on a dynamic scene (spec §5.1).
  bool get speedVisible => CapabilityRules.speed(live);

  bool get isStaticScene =>
      live.active == ActiveChannel.scene &&
      !CapabilityRules.isDynamicScene(live.sceneId);

  String? get sceneName => live.active == ActiveChannel.scene
      ? ModeSummarizer.sceneName(live.sceneId)
      : null;

  /// [light] and [room] cannot be cleared: a light that has gone keeps the
  /// last one seen, so the forgotten notice can still name it.
  LightState copyWith({
    LightStatus? status,
    Light? light,
    Room? room,
    LiveState? live,
    ModeSummary? summary,
    LightNotice? notice,
    bool clearNotice = false,
  }) => LightState(
    status: status ?? this.status,
    light: light ?? this.light,
    room: room ?? this.room,
    live: live ?? this.live,
    summary: summary ?? this.summary,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, light, room, live, summary, notice];
}
