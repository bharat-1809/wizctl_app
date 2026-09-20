import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/feedback/feedback_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/settings_repository.dart';
import '../debug_flags_holder.dart';
import 'settings_state.dart';

/// The Settings screen's toggles. The feedback toggle reaches the service at
/// once and the repository right after, so a click is silent from the very
/// next press rather than from the next launch.
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settings;
  final FeedbackService _feedback;
  final DebugFlagsHolder _flags;
  StreamSubscription<AppSettings>? _subscription;

  SettingsCubit({
    required SettingsRepository settings,
    required FeedbackService feedback,
    required DebugFlagsHolder debugFlags,
    AppSettings? initial,
  }) : _settings = settings, // ignore: prefer_initializing_formals
       _feedback = feedback, // ignore: prefer_initializing_formals
       _flags = debugFlags, // ignore: prefer_initializing_formals
       super(
         SettingsState.from(initial ?? AppSettings.defaults, debugFlags.value),
       );

  /// Idempotent in both halves. The flags listener used to sit outside the
  /// `??=`, so a second call registered another one: `close()` removes one, and
  /// the survivor emits on a closed cubit.
  void subscribe() {
    if (_subscription != null) return;
    _subscription = _settings.watch().listen(
      (s) => emit(
        state.copyWith(
          feedbackEnabled: s.feedbackEnabled,
          rescanOnLaunch: s.rescanOnLaunch,
        ),
      ),
    );
    _flags.addListener(_onFlags);
  }

  void _onFlags() => emit(state.copyWith(debugFlags: _flags.value));

  Future<void> setFeedback(bool value) async {
    await _feedback.setEnabled(value);
    await _settings.save(
      (await _settings.get()).copyWith(feedbackEnabled: value),
    );
  }

  Future<void> setRescanOnLaunch(bool value) async {
    await _settings.save(
      (await _settings.get()).copyWith(rescanOnLaunch: value),
    );
  }

  void setOffNetwork(bool value) =>
      _flags.value = _flags.value.copyWith(offNetwork: value);

  void setForceTimeout(bool value) =>
      _flags.value = _flags.value.copyWith(forceTimeout: value);

  void setFindNothing(bool value) =>
      _flags.value = _flags.value.copyWith(findNothing: value);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _flags.removeListener(_onFlags);
    return super.close();
  }
}
