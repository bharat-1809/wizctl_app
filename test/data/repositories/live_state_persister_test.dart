import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/repositories/live_state_persister.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

import '../../support/fakes.dart';

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
}
