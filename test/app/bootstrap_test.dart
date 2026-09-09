import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/core/feedback/audio_player_port.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/haptic_mapper.dart';
import 'package:wizctl_app/core/feedback/synth_feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_textures.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';

/// An engine that either works or refuses to start, and writes down what it
/// was asked to do either way.
class _FakePlayer implements AudioPlayerPort {
  final bool failInit;
  final List<String> loaded = [];
  final List<String> played = [];

  _FakePlayer({this.failInit = false});

  @override
  Future<void> init() {
    // Thrown, not returned as a failed future: this is the synchronous
    // failure a missing plugin produces on the very first call.
    if (failInit) throw StateError('no audio device');
    return Future<void>.value();
  }

  @override
  Future<void> load(String name, Uint8List wav) async => loaded.add(name);

  @override
  void play(String name, {double volume = 1}) => played.add(name);

  @override
  Future<void> dispose() async {}
}

/// A mapper whose four platform calls only write their name down, so the
/// haptic half of the layer can be watched without a device.
HapticMapper _recordingHaptics(List<String> log) => HapticMapper(
  supported: true,
  selection: () async => log.add('selection'),
  light: () async => log.add('light'),
  medium: () async => log.add('medium'),
  heavy: () async => log.add('heavy'),
);

void main() {
  // `WizTextures.load` renders its tile through `Picture.toImage`, which
  // needs a real event loop rather than a widget test's fake async zone —
  // so every `bootstrap()` here runs inside `runAsync`.
  testWidgets('bootstrap renders the grain and wires the feedback layer', (
    tester,
  ) async {
    var player = _FakePlayer();
    var haptics = <String>[];

    // `runAsync` returns null only if the test is already torn down.
    var services = (await tester.runAsync(
      () => bootstrap(player: player, haptics: _recordingHaptics(haptics)),
    ))!;
    addTearDown(services.toasts.dispose);

    expect(WizTextures.hasGrain, isTrue);
    expect(services.feedback, isA<SynthFeedbackService>());
    // Every one of the nine cues is rendered into the engine at start.
    expect(player.loaded, FeedbackKind.values.map((k) => k.name));

    // The queue was handed the same service, so a resolved toast is audible
    // without the caller doing anything.
    services.toasts.push(tone: WizToastTone.success, title: 'Cozy applied');
    // Confirm is "light then medium 30 ms apart" (spec §13): the gap is a
    // real timer, and leaving it armed would outlive the test.
    await tester.pump(HapticMapper.confirmGap * 2);
    expect(player.played, [FeedbackKind.confirm.name]);
    expect(haptics, ['light', 'medium']);

    // The toast's own 3.2 s dismiss clock, likewise.
    await tester.pump(ToastController.defaultDuration);
  });

  testWidgets('an audio engine that will not start leaves the app silent', (
    tester,
  ) async {
    var player = _FakePlayer(failInit: true);
    var haptics = <String>[];

    // `runAsync` returns null only if the test is already torn down.
    var services = (await tester.runAsync(
      () => bootstrap(player: player, haptics: _recordingHaptics(haptics)),
    ))!;
    addTearDown(services.toasts.dispose);

    // `SynthFeedbackService.init` never throws (Task 26): it reports the dead
    // engine and stays. So the layer that survives a failed start is the
    // synth one, silent but still haptic — `bootstrap`'s own `NoopFeedback
    // Service` fallback is reserved for a *construction* failure of the real
    // ports (a platform with no SoLoud plugin at all), which cannot be
    // injected because an injected port is already built.
    expect(services.feedback, isA<SynthFeedbackService>());
    expect(tester.takeException(), isA<StateError>());

    services.feedback.play(FeedbackKind.power);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );

    expect(player.played, isEmpty, reason: 'a dead engine must stay silent');
    expect(haptics, ['heavy'], reason: 'haptics survive a dead engine');
  });
}
