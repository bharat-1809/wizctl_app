import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

void main() {
  test('unknown lights read as initial; puts and updates notify', () async {
    var store = LiveStateStore();
    expect(store.of('x'), LiveState.initial);
    var seen = <LiveState>[];
    var sub = store.watch('a').listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    store.put('a', LiveState.initial.copyWith(isOn: true));
    store.update('a', (s) => s.copyWith(brightness: 42));
    store.put('b', LiveState.initial);
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((s) => s.brightness), [60, 60, 42]);
    expect(seen.last.isOn, isTrue);
    expect(store.snapshot.keys, containsAll(['a', 'b']));
    await sub.cancel();
    store.dispose();
  });

  test('seed replaces everything and watchAll replays', () async {
    var store = LiveStateStore();
    store.seed({'a': LiveState.initial.copyWith(kelvin: 4000)});
    var first = await store.watchAll().first;
    expect(first['a']!.kelvin, 4000);
    store.remove('a');
    expect(store.snapshot, isEmpty);
    store.dispose();
  });

  test('snapshot is unmodifiable', () {
    var store = LiveStateStore();
    store.put('x', LiveState.initial);
    expect(
      () => store.snapshot['x'] = LiveState.initial,
      throwsUnsupportedError,
    );
    store.dispose();
  });

  test('watchAll keeps emitting', () async {
    var store = LiveStateStore();
    var seen = <Map<String, LiveState>>[];
    var sub = store.watchAll().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    store.put('a', LiveState.initial.copyWith(brightness: 100));
    store.put('b', LiveState.initial.copyWith(brightness: 200));
    await Future<void>.delayed(Duration.zero);
    expect(seen.length, 3);
    expect(seen.last['b']!.brightness, 200);
    await sub.cancel();
    store.dispose();
  });

  test('remove of unknown id does not emit', () async {
    var store = LiveStateStore();
    var seen = <Map<String, LiveState>>[];
    var sub = store.watchAll().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    store.remove('nope');
    await Future<void>.delayed(Duration.zero);
    expect(seen.length, 1);
    await sub.cancel();
    store.dispose();
  });

  test('dispose completes subscriptions', () async {
    var store = LiveStateStore();
    var done = Completer<void>();
    store.watch('a').listen((_) {}, onDone: done.complete);
    store.dispose();
    await done.future.timeout(const Duration(seconds: 1));
    store.put('x', LiveState.initial);
  });
}
