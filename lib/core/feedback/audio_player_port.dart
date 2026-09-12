import 'dart:typed_data';

/// What the feedback service needs from an audio engine: load a WAV from
/// memory once, then play it by name with low latency, polyphonically —
/// spec §13, "sources loaded from memory, polyphonic so rapid detents
/// overlap".
abstract interface class AudioPlayerPort {
  /// Starts the engine, if it is not running already.
  Future<void> init();

  /// Keeps [wav] in memory under [name], ready to play.
  Future<void> load(String name, Uint8List wav);

  /// Plays a loaded source. Synchronous: this sits on the pointer-down path
  /// and must not wait for anything. Unknown names are ignored.
  ///
  /// [volume] multiplies the source's own samples. WizCtl's sounds already
  /// carry their master gain, so the service leaves it at 1.
  void play(String name, {double volume = 1});

  /// Releases the sources and, if it started one, the engine.
  Future<void> dispose();
}
