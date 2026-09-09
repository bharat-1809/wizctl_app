import 'package:flutter/widgets.dart';

import '../core/feedback/audio_player_port.dart';
import '../core/feedback/feedback_service.dart';
import '../core/feedback/haptic_mapper.dart';
import '../core/feedback/soloud_player.dart';
import '../core/feedback/synth_feedback_service.dart';
import '../core/theme/wiz_textures.dart';
import '../core/widgets/toast_controller.dart';

/// Everything the widget tree needs that is built once at start.
class AppServices {
  final FeedbackService feedback;
  final ToastController toasts;

  const AppServices({required this.feedback, required this.toasts});
}

/// The pixel ratio the grain tile is rendered at. Read from the implicit
/// view, which is the only one that exists before `runApp`; a headless
/// embedder has none, and 1 is then the honest answer.
double _devicePixelRatio() =>
    WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ??
    1;

/// Binding, textures at the real pixel ratio, and the feedback layer.
///
/// The grain tile is awaited *before* `runApp`: `WizTextures.grainPaint`
/// returns null until it exists and the painters that read it simply paint
/// nothing, without ever asking again — a tile arriving a frame later would
/// leave the chassis flat until something else repainted it.
///
/// [player] and [haptics] default to the real ports; a test injects fakes so
/// that no audio engine is started. Both defaults are constructed *inside*
/// the guard on purpose: [SynthFeedbackService.init] never throws (it reports
/// a dead engine and stays silent-but-haptic), so the only failure this catch
/// can still see is a synchronous one from construction — a platform with the
/// SoLoud plugin missing, an embedder with no audio device at all. That is
/// exactly the case where the app must run silently rather than not at all.
Future<AppServices> bootstrap({
  AudioPlayerPort? player,
  HapticMapper? haptics,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await WizTextures.load(devicePixelRatio: _devicePixelRatio());

  FeedbackService feedback;
  try {
    var synth = SynthFeedbackService(
      player: player ?? SoLoudPlayer(),
      haptics: haptics ?? HapticMapper(),
    );
    await synth.init();
    feedback = synth;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'wizctl bootstrap',
        context: ErrorDescription('starting the feedback layer'),
      ),
    );
    feedback = NoopFeedbackService();
  }
  return AppServices(
    feedback: feedback,
    toasts: ToastController(feedback: feedback),
  );
}
