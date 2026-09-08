import 'dart:async';

import '../entities/live_state.dart';

/// The in-memory truth about what every light is doing. Repositories hold
/// what the user configured; this holds what the bulbs reported or what
/// the app just wrote optimistically. Screens project it; use cases mutate
/// it; a data-layer listener persists it.
class LiveStateStore {
  final Map<String, LiveState> _states = {};
  final StreamController<Map<String, LiveState>> _all =
      StreamController.broadcast();

  LiveState of(String lightId) => _states[lightId] ?? LiveState.initial;

  Map<String, LiveState> get snapshot => Map.unmodifiable(_states);

  Stream<Map<String, LiveState>> watchAll() async* {
    yield snapshot;
    yield* _all.stream;
  }

  Stream<LiveState> watch(String lightId) async* {
    var last = of(lightId);
    yield last;
    yield* _all.stream.map((all) => all[lightId] ?? LiveState.initial)
    // The last mutation is safe because this generator stream has exactly one listener.
    .where((next) {
      if (next == last) return false;
      last = next;
      return true;
    });
  }

  void put(String lightId, LiveState state) {
    _states[lightId] = state;
    _emit();
  }

  void update(String lightId, LiveState Function(LiveState current) change) =>
      put(lightId, change(of(lightId)));

  void seed(Map<String, LiveState> states) {
    _states
      ..clear()
      ..addAll(states);
    _emit();
  }

  void remove(String lightId) {
    if (_states.remove(lightId) != null) _emit();
  }

  void _emit() {
    if (!_all.isClosed) _all.add(snapshot);
  }

  void dispose() => _all.close();
}
