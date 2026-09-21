import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/settings_cubit.dart';
import 'package:wizctl_app/app/blocs/settings_state.dart';
import 'package:wizctl_app/app/debug_flags_holder.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fakes.dart';

/// Counts the listeners the cubit registers on the flags holder, so a second
/// `subscribe()` cannot quietly add another.
class _CountingFlags extends DebugFlagsHolder {
  int added = 0;
  int removed = 0;

  @override
  void addListener(VoidCallback listener) {
    added++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removed++;
    super.removeListener(listener);
  }
}

void main() {
  late FakeSettingsRepository settings;
  late RecordingFeedbackService feedback;
  late DebugFlagsHolder flags;

  SettingsCubit build() =>
      SettingsCubit(settings: settings, feedback: feedback, debugFlags: flags);

  setUp(() {
    settings = FakeSettingsRepository();
    feedback = RecordingFeedbackService();
    flags = DebugFlagsHolder();
  });

  test(
    'subscribing twice registers one flags listener, removed on close',
    () async {
      var counting = _CountingFlags();
      var cubit = SettingsCubit(
        settings: settings,
        feedback: feedback,
        debugFlags: counting,
      );
      cubit.subscribe();
      cubit.subscribe();
      expect(counting.added, 1);
      await cubit.close();
      expect(
        counting.removed,
        1,
        reason:
            'a second listener would outlive the cubit, emitting on a '
            'closed one',
      );
    },
  );

  test('the initial state comes from the snapshot when given', () {
    var cubit = SettingsCubit(
      settings: settings,
      feedback: feedback,
      debugFlags: flags,
      initial: const AppSettings(feedbackEnabled: false, rescanOnLaunch: false),
    );
    addTearDown(cubit.close);
    expect(cubit.state.feedbackEnabled, isFalse);
    expect(cubit.state.rescanOnLaunch, isFalse);
    expect(cubit.state.debugFlags, DebugFlags.none);
  });

  blocTest<SettingsCubit, SettingsState>(
    'toggling feedback reaches the service and the repository',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await cubit.setFeedback(false);
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) async {
      expect(cubit.state.feedbackEnabled, isFalse);
      expect(feedback.enabled, isFalse);
      expect((await settings.get()).feedbackEnabled, isFalse);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'rescan on launch persists',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await cubit.setRescanOnLaunch(false);
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) async {
      expect(cubit.state.rescanOnLaunch, isFalse);
      expect((await settings.get()).rescanOnLaunch, isFalse);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'the prototype switches write the holder and the state follows',
    build: build,
    act: (cubit) {
      cubit.subscribe();
      cubit.setOffNetwork(true);
      cubit.setForceTimeout(true);
      cubit.setFindNothing(true);
      cubit.setOffNetwork(false);
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(
        flags.value,
        const DebugFlags(forceTimeout: true, findNothing: true),
      );
      expect(cubit.state.debugFlags, flags.value);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'a change written elsewhere shows up',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await settings.save(
        const AppSettings(activeHomeId: 'h1', feedbackEnabled: false),
      );
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) => expect(cubit.state.feedbackEnabled, isFalse),
  );
}
