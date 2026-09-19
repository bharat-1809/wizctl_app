import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/feedback/audio_player_port.dart';
import '../core/feedback/feedback_service.dart';
import '../core/feedback/haptic_mapper.dart';
import '../core/feedback/soloud_player.dart';
import '../core/feedback/synth_feedback_service.dart';
import '../core/theme/wiz_textures.dart';
import '../core/widgets/toast_controller.dart';
import '../domain/entities/entities.dart';
import 'dependencies.dart';

/// Everything the widget tree needs that is built once at start: the
/// feedback layer and toast queue (Plan 2), the logic graph (Plan 3), and a
/// snapshot of the homes and settings so the first frame can route without
/// a round trip to the database (spec §9, the `/setup` redirect).
class AppServices {
  final FeedbackService feedback;
  final ToastController toasts;
  final AppDependencies deps;
  final List<Home> homes;
  final AppSettings settings;

  const AppServices({
    required this.feedback,
    required this.toasts,
    required this.deps,
    required this.homes,
    required this.settings,
  });
}

/// The open licences the app ships, by the family each covers. All three
/// faces are under the SIL Open Font License, whose terms require the
/// licence to travel with the software, so the text is bundled and handed to
/// the registry rather than merely linked.
///
/// The fourth face, Neumatic Compressed, is a commercial one and carries no
/// licence file here; see the README.
const Map<String, String> _fontLicences = {
  'Big Shoulders Display': 'assets/fonts/OFL-BigShouldersDisplay.txt',
  'Hanken Grotesk': 'assets/fonts/OFL-HankenGrotesk.txt',
  'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
};

/// Adds the bundled font licences to the registry the standard
/// `LicensePage` reads, so they are listed beside the packages'.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (var entry in _fontLicences.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString(entry.value));
    }
  });
}

/// The pixel ratio the grain tile is rendered at. Read from the implicit
/// view, which is the only one that exists before `runApp`; a headless
/// embedder has none, and 1 is then the honest answer.
double _devicePixelRatio() =>
    WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ??
    1;

/// Binding, textures at the real pixel ratio, the logic graph, then the
/// feedback layer with the persisted toggle already applied.
///
/// The graph comes before the feedback layer on purpose: `feedbackEnabled`
/// lives in the settings table, and a click played at the wrong setting on
/// the first screen is exactly the kind of thing the user notices.
///
/// The grain tile is awaited *before* `runApp`: `WizTextures.grainPaint`
/// returns null until it exists and the painters that read it simply paint
/// nothing, without ever asking again — a tile arriving a frame later would
/// leave the chassis flat until something else repainted it.
///
/// [player], [haptics] and [dependencies] default to the real ones; a test
/// injects fakes and an in-memory graph so that no audio engine is started
/// and no database file is written. The feedback defaults are constructed
/// *inside* the guard on purpose: [SynthFeedbackService.init] never throws
/// (it reports a dead engine and stays silent-but-haptic), so the only
/// failure this catch can still see is a synchronous one from construction —
/// a platform with the SoLoud plugin missing, an embedder with no audio
/// device at all. That is exactly the case where the app must run silently
/// rather than not at all.
Future<AppServices> bootstrap({
  AudioPlayerPort? player,
  HapticMapper? haptics,
  AppDependencies? dependencies,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();

  // Guarded on its own: a texture that will not render is a flat chassis,
  // not a dead app, and an unhandled throw here would take `main` down before
  // a single frame was drawn. `WizTextures.grainPaint` returns null until a
  // tile exists and every painter that reads it treats null as "paint no
  // grain", so carrying on is safe.
  //
  // Untested: `WizTextures.load` is a static with no injection point, so
  // there is no way to make it fail from a test without reaching into the
  // kit. The branch is one report-and-continue.
  try {
    await WizTextures.load(devicePixelRatio: _devicePixelRatio());
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'wizctl bootstrap',
        context: ErrorDescription('rendering the grain texture'),
      ),
    );
  }

  // Not guarded: a graph that cannot be built (a database that will not
  // open) is a dead app, and the error must reach the console rather than a
  // silent placeholder screen.
  var deps = dependencies ?? await AppDependencies.build();
  var settings = await deps.settings.get();
  var homes = await deps.homes.getAll();

  FeedbackService feedback;
  try {
    var synth = SynthFeedbackService(
      player: player ?? SoLoudPlayer(),
      haptics: haptics ?? HapticMapper(),
      enabled: settings.feedbackEnabled,
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
    deps: deps,
    homes: homes,
    settings: settings,
  );
}
