import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String? activeHomeId;
  final bool feedbackEnabled;
  final bool rescanOnLaunch;

  const AppSettings({
    this.activeHomeId,
    this.feedbackEnabled = true,
    this.rescanOnLaunch = true,
  });

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    String? activeHomeId,
    bool clearActiveHome = false,
    bool? feedbackEnabled,
    bool? rescanOnLaunch,
  }) => AppSettings(
    activeHomeId: clearActiveHome ? null : (activeHomeId ?? this.activeHomeId),
    feedbackEnabled: feedbackEnabled ?? this.feedbackEnabled,
    rescanOnLaunch: rescanOnLaunch ?? this.rescanOnLaunch,
  );

  @override
  List<Object?> get props => [activeHomeId, feedbackEnabled, rescanOnLaunch];
}
