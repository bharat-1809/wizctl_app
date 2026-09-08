import 'feedback_kind.dart';

/// Sound plus haptics for every control. Safe to call on every pointer down.
abstract interface class FeedbackService {
  bool get enabled;
  Future<void> setEnabled(bool value);
  void play(FeedbackKind kind);
}

/// Does nothing. Used before the audio engine is ready and in widget tests
/// that do not care about feedback.
class NoopFeedbackService implements FeedbackService {
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async => _enabled = value;

  @override
  void play(FeedbackKind kind) {}
}

/// Records what was played, for tests.
class RecordingFeedbackService implements FeedbackService {
  final List<FeedbackKind> played = [];
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async => _enabled = value;

  @override
  void play(FeedbackKind kind) {
    if (_enabled) played.add(kind);
  }
}
