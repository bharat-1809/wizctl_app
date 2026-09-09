import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import 'audio_player_port.dart';
import 'feedback_kind.dart';
import 'feedback_service.dart';
import 'haptic_mapper.dart';
import 'wiz_synth.dart';

/// The real feedback layer: a synthesized click through the audio port plus
/// the platform's haptic (spec §13). On by default; the user's switch is
/// persisted by the caller through [onEnabledChanged].
class SynthFeedbackService implements FeedbackService {
  final AudioPlayerPort player;
  final HapticMapper haptics;

  /// Told whenever [setEnabled] changes the switch, so that Settings can
  /// persist it without this class knowing about storage.
  final ValueChanged<bool>? onEnabledChanged;

  bool _isEnabled;

  /// Whether [init] got as far as loading every source. False after a
  /// failed start: the app is then silent, but still haptic.
  bool _ready = false;

  SynthFeedbackService({
    required this.player,
    required this.haptics,
    bool enabled = true,
    this.onEnabledChanged,
  }) : _isEnabled = enabled;

  /// Starts the engine and renders every kind into it.
  ///
  /// Never throws: a device with no working audio must not take the app
  /// down with it, so a failure is reported and the layer stays silent.
  Future<void> init() async {
    try {
      await player.init();
      for (var kind in FeedbackKind.values) {
        await player.load(kind.name, WizSynth.renderWav(kind));
      }
      _ready = true;
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'wizctl feedback',
          context: ErrorDescription('initialising synthesized feedback'),
        ),
      );
    }
  }

  @override
  bool get enabled => _isEnabled;

  @override
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    onEnabledChanged?.call(value);
    // Turning it on demonstrates itself.
    if (value) play(FeedbackKind.tick);
  }

  @override
  void play(FeedbackKind kind) {
    if (!_isEnabled) return;
    unawaited(haptics.play(kind));
    // No volume argument: WizSynth.render already applied the master gain,
    // so the source plays at the engine's own unity.
    if (_ready) player.play(kind.name);
  }

  Future<void> dispose() => player.dispose();
}
