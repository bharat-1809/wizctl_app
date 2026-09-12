import 'dart:async';

import '../../domain/entities/live_state.dart';
import '../../domain/repositories/live_state_persistence.dart';
import '../../domain/services/live_state_store.dart';

/// Writes the store to the database, debounced so a dial drag costs one
/// write rather than a hundred.
class LiveStatePersister {
  final LiveStateStore _store;
  final LiveStatePersistence _persistence;

  /// Where a failed write goes. The write runs on a timer, off any caller's
  /// stack, so an unhandled failure would take the zone down with it; the
  /// default swallows it — a cache write is never worth a crash.
  final void Function(Object error, StackTrace stack)? _onError;
  final Duration debounce;
  StreamSubscription<Map<String, LiveState>>? _sub;
  Timer? _timer;
  Map<String, LiveState>? _latest;

  /// The write in flight, if any: a flush the debounce already fired has no
  /// pending state left for [dispose] to see, so [dispose] awaits this
  /// instead of returning while the database is still being written.
  Future<void>? _inFlight;

  LiveStatePersister({
    required LiveStateStore store,
    required LiveStatePersistence persistence,
    void Function(Object error, StackTrace stack)? onError,
    this.debounce = const Duration(milliseconds: 500),
  }) : _store = store, // ignore: prefer_initializing_formals
       _persistence = persistence, // ignore: prefer_initializing_formals
       _onError = onError; // ignore: prefer_initializing_formals

  void start() {
    _sub ??= _store.watchAll().skip(1).listen((states) {
      _latest = states;
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(_flush()));
    });
  }

  Future<void> _flush() {
    var latest = _latest;
    if (latest == null) return Future.value();
    _latest = null;
    return _inFlight = _write(latest);
  }

  Future<void> _write(Map<String, LiveState> states) async {
    try {
      await _persistence.save(states);
    } catch (error, stack) {
      _onError?.call(error, stack);
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _flush();
    await _inFlight;
    await _sub?.cancel();
    _sub = null;
  }
}
