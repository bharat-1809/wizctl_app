import 'dart:async';

/// The latest value of each source, re-emitted whenever any of them changes,
/// starting once every source has produced one — the `combineLatest` every
/// stream library has. The app takes no such library for three arities.
///
/// Single-subscription. Cancelling cancels every source; an error from any
/// source is forwarded; the result closes when every source has closed.
Stream<(A, B)> combineLatest2<A, B>(Stream<A> a, Stream<B> b) =>
    _combine([a, b]).map((v) => (v[0] as A, v[1] as B));

Stream<(A, B, C)> combineLatest3<A, B, C>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
) => _combine([a, b, c]).map((v) => (v[0] as A, v[1] as B, v[2] as C));

Stream<(A, B, C, D)> combineLatest4<A, B, C, D>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
) =>
    _combine([a, b, c, d])
        .map((v) => (v[0] as A, v[1] as B, v[2] as C, v[3] as D));

Stream<List<Object?>> _combine(List<Stream<Object?>> sources) {
  late StreamController<List<Object?>> controller;
  var subscriptions = <StreamSubscription<Object?>>[];
  var latest = List<Object?>.filled(sources.length, null);
  var seen = List<bool>.filled(sources.length, false);
  var done = 0;
  controller = StreamController<List<Object?>>(
    onListen: () {
      for (var i = 0; i < sources.length; i++) {
        subscriptions.add(
          sources[i].listen(
            (value) {
              latest[i] = value;
              seen[i] = true;
              if (seen.every((s) => s)) controller.add(List.of(latest));
            },
            onError: controller.addError,
            onDone: () {
              if (++done == sources.length) controller.close();
            },
          ),
        );
      }
    },
    onPause: () {
      for (var s in subscriptions) {
        s.pause();
      }
    },
    onResume: () {
      for (var s in subscriptions) {
        s.resume();
      }
    },
    onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
  );
  return controller.stream;
}
