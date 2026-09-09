import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_player_port.dart';

/// The `flutter_soloud` backend (spec §13, "Playback: `flutter_soloud`,
/// sources loaded from memory, polyphonic"). No files, no decoding at play
/// time.
///
/// Not unit-tested: every call reaches native code through FFI. It is kept
/// thin for that reason — the rest of the feedback layer talks to
/// [AudioPlayerPort] and is tested against a fake. The iOS ambient audio
/// session of spec §13 is not set here: `flutter_soloud` does not own the
/// platform audio session, so that belongs to the app shell.
class SoLoudPlayer implements AudioPlayerPort {
  final Map<String, AudioSource> _sources = {};

  /// Whether this player started the engine, and so should stop it.
  bool _ownsEngine = false;

  /// The start currently in flight, and only that. `isInitialized` is a
  /// synchronous snapshot the package itself warns about (soloud.dart:310-313),
  /// so two overlapping callers would both read false and both start the
  /// engine; they share this future instead. A start that has finished —
  /// whether it succeeded or threw — is forgotten, so the next call re-checks
  /// the engine and can retry a failed start or restart one that an external
  /// owner has since stopped.
  Future<void>? _starting;

  @override
  Future<void> init() =>
      // `_start()` is async, so this assignment lands before whenComplete's
      // callback can null the field again.
      _starting ??= _start().whenComplete(() => _starting = null);

  Future<void> _start() async {
    if (SoLoud.instance.isInitialized) return;
    await SoLoud.instance.init();
    _ownsEngine = true;
  }

  @override
  Future<void> load(String name, Uint8List wav) async {
    // The path is an identity for the engine's loader, not a file on disk.
    _sources[name] = await SoLoud.instance.loadMem('wizctl-$name.wav', wav);
  }

  @override
  void play(String name, {double volume = 1}) {
    var source = _sources[name];
    if (source == null) return;
    SoLoud.instance.play(source, volume: volume);
  }

  @override
  Future<void> dispose() async {
    // Safe to call twice, and safe if something else already stopped the
    // engine: disposing a source needs a live one.
    if (SoLoud.instance.isInitialized) {
      for (var source in _sources.values) {
        await SoLoud.instance.disposeSource(source);
      }
      if (_ownsEngine) SoLoud.instance.deinit();
    }
    _sources.clear();
    _ownsEngine = false;
    _starting = null;
  }
}
