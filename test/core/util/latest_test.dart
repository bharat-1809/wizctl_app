import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/util/latest.dart';

void main() {
  test('emits once every source has a value, then on every change', () async {
    var a = StreamController<int>();
    var b = StreamController<String>();
    var seen = <(int, String)>[];
    var sub = combineLatest2(a.stream, b.stream).listen(seen.add);

    a.add(1);
    await pumpEventQueue();
    expect(seen, isEmpty, reason: 'b has no value yet');
    b.add('x');
    a.add(2);
    b.add('y');
    await pumpEventQueue();
    expect(seen, [(1, 'x'), (2, 'x'), (2, 'y')]);

    await sub.cancel();
    await a.close();
    await b.close();
  });

  test('three and four sources', () async {
    // Fresh streams for each call: `Stream.value` is single-subscription, so
    // the same instance can't be handed to two independent combinators.
    expect(
      await combineLatest3(
        Stream.value(1),
        Stream.value('b'),
        Stream.value(true),
      ).first,
      (1, 'b', true),
    );
    expect(
      await combineLatest4(
        Stream.value(1),
        Stream.value('b'),
        Stream.value(true),
        Stream.value(2.5),
      ).first,
      (1, 'b', true, 2.5),
    );
  });

  test('cancelling cancels every source and errors pass through', () async {
    var cancelled = 0;
    Stream<int> source() {
      late StreamController<int> controller;
      controller = StreamController<int>(
        onListen: () => controller.add(1),
        onCancel: () => cancelled++,
      );
      return controller.stream;
    }

    var sub = combineLatest2(source(), source()).listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    expect(cancelled, 2);

    var failing = StreamController<int>();
    var errors = <Object>[];
    var sub2 = combineLatest2(
      failing.stream,
      Stream.value(0),
    ).listen((_) {}, onError: errors.add);
    failing.addError(StateError('boom'));
    await pumpEventQueue();
    expect(errors.single, isA<StateError>());
    await sub2.cancel();
    await failing.close();
  });

  test('closes when every source is done', () async {
    var done = false;
    combineLatest2(
      Stream.value(1),
      Stream.value(2),
    ).listen((_) {}, onDone: () => done = true);
    await pumpEventQueue();
    expect(done, isTrue);
  });

  group('switchLatest', () {
    test('a new source value cancels the stream before it', () async {
      var inners = <String, StreamController<String>>{};
      var cancelled = <String>[];
      Stream<String> inner(String tag) {
        var controller = StreamController<String>(
          onCancel: () => cancelled.add(tag),
        );
        inners[tag] = controller;
        return controller.stream;
      }

      var source = StreamController<String>();
      var seen = <String>[];
      var sub = switchLatest(source.stream, inner).listen(seen.add);

      source.add('a');
      await pumpEventQueue();
      inners['a']!.add('a1');
      await pumpEventQueue();

      source.add('b');
      await pumpEventQueue();
      expect(cancelled, ['a'], reason: "a's stream goes when b arrives");
      // The replaced stream is no longer listened to, so what it emits next
      // never reaches the result.
      inners['a']!.add('a2');
      inners['b']!.add('b1');
      await pumpEventQueue();
      expect(seen, ['a1', 'b1']);

      await sub.cancel();
      expect(cancelled, ['a', 'b']);
      await source.close();
    });

    test(
      'the last inner stream keeps going after the source is done',
      () async {
        var inner = StreamController<int>();
        var source = StreamController<int>();
        var seen = <int>[];
        var done = false;
        switchLatest(
          source.stream,
          (_) => inner.stream,
        ).listen(seen.add, onDone: () => done = true);

        source.add(1);
        await source.close();
        inner.add(10);
        await pumpEventQueue();
        expect(seen, [
          10,
        ], reason: 'a closed source must not cut the inner off');
        expect(done, isFalse);

        await inner.close();
        await pumpEventQueue();
        expect(done, isTrue, reason: 'both are done now');
      },
    );

    test(
      'a source that ends with nothing in flight closes the result',
      () async {
        var done = false;
        switchLatest(
          const Stream<int>.empty(),
          (_) => const Stream<int>.empty(),
        ).listen((_) {}, onDone: () => done = true);
        await pumpEventQueue();
        expect(done, isTrue);
      },
    );

    test(
      'errors from the source and from an inner stream pass through',
      () async {
        var source = StreamController<int>();
        var inner = StreamController<int>();
        var errors = <Object>[];
        var sub = switchLatest(
          source.stream,
          (_) => inner.stream,
        ).listen((_) {}, onError: errors.add);

        source.add(1);
        await pumpEventQueue();
        inner.addError(StateError('inner'));
        source.addError(ArgumentError('outer'));
        await pumpEventQueue();
        expect(errors, [isA<StateError>(), isA<ArgumentError>()]);

        await sub.cancel();
        await source.close();
        await inner.close();
      },
    );

    test(
      'cancelling the result cancels the source and the inner stream',
      () async {
        var cancelled = <String>[];
        var source = StreamController<int>(
          onCancel: () => cancelled.add('source'),
        );
        var inner = StreamController<int>(
          onCancel: () => cancelled.add('inner'),
        );
        var sub = switchLatest(
          source.stream,
          (_) => inner.stream,
        ).listen((_) {});

        source.add(1);
        await pumpEventQueue();
        await sub.cancel();
        expect(cancelled, ['source', 'inner']);
      },
    );
  });

  // Both combiners cancel their sources without awaiting the futures those
  // cancels return, and this is the property that needs it: a subscription's
  // `cancel()` hands back the SDK's shared null future, which belongs to the
  // root zone, and awaiting one of those inside the tester's fake-async zone
  // never resumes — `pump` turns the fake loop, and only the real loop can
  // complete it. A bloc closed from a widget test hung here for ever,
  // silently, with no output and no test timeout. The real-zone tests above
  // cannot catch it: they passed while the code still awaited.
  testWidgets('a cancel inside the tester zone completes there', (
    tester,
  ) async {
    var cancelled = <String>[];
    var a = StreamController<int>(onCancel: () => cancelled.add('a'));
    var b = StreamController<int>(onCancel: () => cancelled.add('b'));
    var inner = StreamController<int>(onCancel: () => cancelled.add('inner'));

    var combined = combineLatest2(a.stream, b.stream).listen((_) {});
    var switched = switchLatest(
      Stream<int>.value(1),
      (_) => inner.stream,
    ).listen((_) {});
    a.add(1);
    b.add(2);
    await tester.pump();

    // Reaching the line after each await is the assertion.
    await combined.cancel();
    await switched.cancel();
    expect(cancelled, containsAll(['a', 'b', 'inner']));
  });
}
