import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// The two persisted toggles (spec §10.7) and the prototype switches
/// (spec §18), which only debug builds ever change.
class SettingsState extends Equatable {
  final bool feedbackEnabled;
  final bool rescanOnLaunch;
  final DebugFlags debugFlags;

  const SettingsState({
    required this.feedbackEnabled,
    required this.rescanOnLaunch,
    required this.debugFlags,
  });

  factory SettingsState.from(AppSettings settings, DebugFlags flags) =>
      SettingsState(
        feedbackEnabled: settings.feedbackEnabled,
        rescanOnLaunch: settings.rescanOnLaunch,
        debugFlags: flags,
      );

  SettingsState copyWith({
    bool? feedbackEnabled,
    bool? rescanOnLaunch,
    DebugFlags? debugFlags,
  }) => SettingsState(
    feedbackEnabled: feedbackEnabled ?? this.feedbackEnabled,
    rescanOnLaunch: rescanOnLaunch ?? this.rescanOnLaunch,
    debugFlags: debugFlags ?? this.debugFlags,
  );

  @override
  List<Object?> get props => [feedbackEnabled, rescanOnLaunch, debugFlags];
}
