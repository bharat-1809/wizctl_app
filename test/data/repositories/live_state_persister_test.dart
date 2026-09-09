import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/repositories/live_state_persister.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

import '../../support/fakes.dart';
import '../../support/in_zone_cancel.dart';

/// A [FakeLiveStatePersistence] whose `save` suspends for 10 ms before
/// delegating, so a test can distinguish a caller that awaits the write from
/// one that only fires it.
class _DelayedFakeLiveStatePersistence extends FakeLiveStatePersistence {
  @override
  Future<void> save(Map<String, LiveState> states) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return super.save(states);
  }
}

/// A [FakeLiveStatePersistence] whose `save` always fails, so a test can
/// watch a failed write reach `onError` instead of the zone.
class _FailingFakeLiveStatePersistence extends FakeLiveStatePersistence {
  @override
  Future<void> save(Map<String, LiveState> states) async {
    throw StateError('disk full');
  }
}

/// A [LiveStateStore] whose `watchAll` subscription's `cancel()` resolves
/// inside the current zone, so a `fakeAsync` test can observe
/// `LiveStatePersister.dispose()` finish cancelling it — see [inZoneCancel].
class _InZoneCancelStore extends LiveStateStore {
  @override
  Stream<Map<String, LiveState>> watchAll() => inZoneCancel(super.watchAll());
}

void main() {
  test('coalesces bursts of changes into one save after the debounce', () {
    fakeAsync((async) {
      var store = LiveStateStore();
      var persistence = FakeLiveStatePersistence();
      var persister = LiveStatePersister(
        store: store,
        persistence: persistence,
        debounce: const Duration(milliseconds: 500),
      );
      persister.start();
      async.flushMicrotasks();
      store.put('a', LiveState.initial.copyWith(isOn: true));
      store.put('a', LiveState.initial.copyWith(brightness: 30));
      store.put('b', LiveState.initial);
      async.elapse(const Duration(milliseconds: 499));
      expect(persistence.saves, 0);
      async.elapse(const Duration(milliseconds: 2));
      expect(persistence.saves, 1);
      expect(persistence.stored['a']!.brightness, 30);
      persister.dispose();
      store.dispose();
    });
  });

  test('dispose awaits the pending debounced write', () {
    fakeAsync((async) {
      var store = _InZoneCancelStore();
      var persistence = _DelayedFakeLiveStatePersistence();
      var persister = LiveStatePersister(
        store: store,
        persistence: persistence,
        debounce: const Duration(milliseconds: 500),
      );
      persister.start();
      async.flushMicrotasks();
      store.put('a', LiveState.initial.copyWith(isOn: true));
      async.elapse(const Duration(milliseconds: 100));
      var disposed = false;
      unawaited(persister.dispose().then((_) => disposed = true));
      async.flushMicrotasks();
      expect(disposed, isFalse);
      expect(persistence.saves, 0);
      async.elapse(const Duration(milliseconds: 10));
      expect(disposed, isTrue);
      expect(persistence.saves, 1);
      expect(persistence.stored['a']!.isOn, isTrue);
      async.elapse(const Duration(milliseconds: 500));
      expect(persistence.saves, 1);
      store.dispose();
    });
  });

  test('dispose awaits a write the debounce already fired', () {
    fakeAsync((async) {
      var store = _InZoneCancelStore();
      var persistence = _DelayedFakeLiveStatePersistence();
      var persister = LiveStatePersister(
        store: store,
        persistence: persistence,
        debounce: const Duration(milliseconds: 500),
      );
      persister.start();
      async.flushMicrotasks();
      store.put('a', LiveState.initial.copyWith(isOn: true));
      async.elapse(const Duration(milliseconds: 500));
      expect(persistence.saves, 0, reason: 'fired, still writing');
      var disposed = false;
      unawaited(persister.dispose().then((_) => disposed = true));
      async.flushMicrotasks();
      expect(disposed, isFalse, reason: 'the in-flight write is awaited');
      async.elapse(const Duration(milliseconds: 10));
      expect(disposed, isTrue);
      expect(persistence.saves, 1);
      store.dispose();
    });
  });

  test('a failed write reaches onError and dispose still completes', () {
    fakeAsync((async) {
      var store = _InZoneCancelStore();
      var persistence = _FailingFakeLiveStatePersistence();
      Object? error;
      StackTrace? stack;
      var persister = LiveStatePersister(
        store: store,
        persistence: persistence,
        debounce: const Duration(milliseconds: 500),
        onError: (e, s) {
          error = e;
          stack = s;
        },
      );
      persister.start();
      async.flushMicrotasks();
      store.put('a', LiveState.initial.copyWith(isOn: true));
      async.elapse(const Duration(milliseconds: 600));
      expect(error, isA<StateError>());
      expect(stack, isNotNull);
      var disposed = false;
      unawaited(persister.dispose().then((_) => disposed = true));
      async.flushMicrotasks();
      expect(disposed, isTrue);
      store.dispose();
    });
  });
}
