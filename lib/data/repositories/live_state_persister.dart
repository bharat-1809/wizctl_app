import 'dart:async';

import '../../domain/entities/live_state.dart';
import '../../domain/repositories/live_state_persistence.dart';
import '../../domain/services/live_state_store.dart';

/// Writes the store to the database, debounced so a dial drag costs one
/// write rather than a hundred.
class LiveStatePersister {
  final LiveStateStore _store;
  final LiveStatePersistence _persistence;
  final Duration debounce;
  StreamSubscription<Map<String, LiveState>>? _sub;
  Timer? _timer;
  Map<String, LiveState>? _latest;

  LiveStatePersister({
    required LiveStateStore store,
    required LiveStatePersistence persistence,
    this.debounce = const Duration(milliseconds: 500),
  }) : _store = store, // ignore: prefer_initializing_formals
       _persistence = persistence; // ignore: prefer_initializing_formals

  void start() {
    _sub ??= _store.watchAll().skip(1).listen((states) {
      _latest = states;
      _timer?.cancel();
      _timer = Timer(debounce, _flush);
    });
  }

  void _flush() {
    var latest = _latest;
    if (latest == null) return;
    _latest = null;
    unawaited(_persistence.save(latest));
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _flush();
    await _sub?.cancel();
    _sub = null;
  }
}
