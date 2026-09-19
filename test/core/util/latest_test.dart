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
}
