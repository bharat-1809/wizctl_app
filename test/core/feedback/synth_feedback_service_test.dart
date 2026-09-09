import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/audio_player_port.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/haptic_mapper.dart';
import 'package:wizctl_app/core/feedback/synth_feedback_service.dart';

class FakePlayer implements AudioPlayerPort {
  final loaded = <String>[];
  final played = <(String, double)>[];
  bool inited = false;
  bool disposed = false;
  bool failInit = false;

  @override
  Future<void> init() async {
    if (failInit) throw StateError('no audio device');
    inited = true;
  }

  @override
  Future<void> load(String name, Uint8List wav) async => loaded.add(name);

  @override
  void play(String name, {double volume = 1}) => played.add((name, volume));

  @override
  Future<void> dispose() async => disposed = true;
}

/// A mapper whose four platform calls only write their name down.
HapticMapper recordingMapper(List<String> log) => HapticMapper(
  supported: true,
  selection: () async => log.add('selection'),
  light: () async => log.add('light'),
  medium: () async => log.add('medium'),
  heavy: () async => log.add('heavy'),
);

/// Long enough for both haptic gaps (30 ms and 40 ms) to have elapsed.
Future<void> pumpHaptics() =>
    Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  group('SynthFeedbackService', () {
    test('init loads every kind; play routes sound and haptics', () async {
      var player = FakePlayer();
      var haptics = <String>[];
      var service = SynthFeedbackService(
        player: player,
        haptics: recordingMapper(haptics),
      );
      await service.init();
      expect(player.inited, isTrue);
      expect(player.loaded, FeedbackKind.values.map((k) => k.name));
      service.play(FeedbackKind.detent);
      service.play(FeedbackKind.power);
      await pumpHaptics();
      expect(player.played.map((p) => p.$1), ['detent', 'power']);
      // The master gain is already baked into the samples (WizSynth.render),
      // so the service never asks the player for a second one.
      expect(player.played.first.$2, 1.0);
      expect(haptics, ['selection', 'heavy']);
    });

    test('disabled plays nothing; enabling ticks once', () async {
      var player = FakePlayer();
      var enabledLog = <bool>[];
      var service = SynthFeedbackService(
        player: player,
        haptics: HapticMapper(supported: false),
        enabled: false,
        onEnabledChanged: enabledLog.add,
      );
      await service.init();
      expect(service.enabled, isFalse);
      service.play(FeedbackKind.press);
      expect(player.played, isEmpty);
      await service.setEnabled(true);
      expect(service.enabled, isTrue);
      expect(enabledLog, [true]);
      expect(player.played.map((p) => p.$1), ['tick']);
    });

    test('a failing engine is reported once and never throws', () async {
      var player = FakePlayer()..failInit = true;
      var haptics = <String>[];
      var service = SynthFeedbackService(
        player: player,
        haptics: recordingMapper(haptics),
      );
      var reported = <FlutterErrorDetails>[];
      var previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      try {
        await service.init();
      } finally {
        FlutterError.onError = previous;
      }
      expect(reported, hasLength(1));
      expect(reported.single.library, 'wizctl feedback');
      expect(reported.single.exception, isStateError);
      // Silent, but the hand still feels the key.
      service.play(FeedbackKind.press);
      await pumpHaptics();
      expect(player.played, isEmpty);
      expect(haptics, ['light']);
    });

    test('dispose reaches the player', () async {
      var player = FakePlayer();
      var service = SynthFeedbackService(
        player: player,
        haptics: HapticMapper(supported: false),
      );
      await service.init();
      await service.dispose();
      expect(player.disposed, isTrue);
    });
  });

  group('HapticMapper', () {
    test('every kind maps to a haptic, release excepted', () async {
      for (var kind in FeedbackKind.values) {
        var haptics = <String>[];
        await recordingMapper(haptics).play(kind);
        if (kind == FeedbackKind.release) {
          expect(
            haptics,
            isEmpty,
            reason: '$kind should be silent to the hand',
          );
        } else {
          expect(haptics, isNotEmpty, reason: '$kind has no haptic');
        }
      }
    });

    test('confirm and reject are two spaced impacts', () async {
      var haptics = <String>[];
      var mapper = recordingMapper(haptics);
      await mapper.play(FeedbackKind.confirm);
      await mapper.play(FeedbackKind.reject);
      expect(haptics, ['light', 'medium', 'heavy', 'heavy']);
    });

    test('an unsupported platform feels nothing', () async {
      var haptics = <String>[];
      var mapper = HapticMapper(
        supported: false,
        selection: () async => haptics.add('selection'),
        heavy: () async => haptics.add('heavy'),
      );
      for (var kind in FeedbackKind.values) {
        await mapper.play(kind);
      }
      expect(haptics, isEmpty);
    });

    test('haptics are supported on phones only', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (var platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          HapticMapper().supported,
          platform == TargetPlatform.iOS || platform == TargetPlatform.android,
          reason: '$platform',
        );
      }
    });
  });
}
