import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/repositories/live_state_persister.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

import '../../support/fakes.dart';

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

/// A [LiveStateStore] whose `watchAll` subscription's `cancel()` resolves
/// inside the current zone. The base store's broadcast controller declares
/// no `onCancel`, so `cancel()` returns the process-wide `Future._nullFuture`
/// sentinel, which is pinned to whichever zone first realized it; inside a
/// different `fakeAsync` zone that future never completes, so
/// `flushMicrotasks`/`elapse` can't observe it. Relaying events through a
/// controller that declares its own `onCancel` — returning a freshly
/// created, zone-local future rather than awaiting the upstream
/// subscription's own (equally pinned) cancel future — lets a test actually
/// observe `LiveStatePersister.dispose()` finish cancelling its
/// subscription.
class _InZoneCancelStore extends LiveStateStore {
  @override
  Stream<Map<String, LiveState>> watchAll() {
    late StreamSubscription<Map<String, LiveState>> upstream;
    var controller = StreamController<Map<String, LiveState>>(
      onCancel: () {
        unawaited(upstream.cancel());
        return Future.value();
      },
    );
    upstream = super.watchAll().listen(controller.add);
    return controller.stream;
  }
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
}
