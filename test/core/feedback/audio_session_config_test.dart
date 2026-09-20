import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/audio_session_config.dart';

void main() {
  test('the session is ambient, mixing, and off iOS nothing is configured', () {
    expect(
      wizAudioSession.avAudioSessionCategory,
      AVAudioSessionCategory.ambient,
    );
    expect(
      wizAudioSession.avAudioSessionCategoryOptions,
      AVAudioSessionCategoryOptions.mixWithOthers,
    );
    expect(wizAudioSession.avAudioSessionMode, AVAudioSessionMode.defaultMode);
  });

  test('off iOS the call returns without touching a platform channel', () {
    // A platform-channel call under test throws MissingPluginException, so
    // completing proves the iOS branch was not taken.
    return expectLater(configureAudioSession(isIos: () => false), completes);
  });
}
