import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// The iOS audio session for the clicks (spec §13): ambient, so they mix
/// with whatever is playing and go quiet with the mute switch. SoLoud does
/// not own the session, so the app configures it before the engine starts.
const AudioSessionConfiguration wizAudioSession = AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.ambient,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
  avAudioSessionMode: AVAudioSessionMode.defaultMode,
  avAudioSessionRouteSharingPolicy:
      AVAudioSessionRouteSharingPolicy.defaultPolicy,
  avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
);

/// Configures the session on iOS and does nothing elsewhere.
///
/// Never throws: a session that will not configure leaves the engine's
/// default in place, which is what shipped before this. [isIos] is the
/// platform test, injectable so a test can take either branch without a
/// platform channel to answer it.
Future<void> configureAudioSession({bool Function()? isIos}) async {
  var ios = isIos ?? () => !kIsWeb && Platform.isIOS;
  if (!ios()) return;
  try {
    var session = await AudioSession.instance;
    await session.configure(wizAudioSession);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'wizctl feedback',
        context: ErrorDescription('configuring the audio session'),
      ),
    );
  }
}
