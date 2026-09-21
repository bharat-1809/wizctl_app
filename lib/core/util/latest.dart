import 'dart:async';

/// The latest value of each source, re-emitted whenever any of them changes,
/// starting once every source has produced one — the `combineLatest` every
/// stream library has. The app takes no such library for three arities.
///
/// Single-subscription. An error from any source is forwarded; the result
/// closes when every source has closed.
///
/// Cancelling detaches every source's listener synchronously. The future it
/// returns says only that: it does **not** mean the sources have finished
/// their own tear-down, and it deliberately does not wait for them — awaiting
/// a source's cancel future deadlocks under `flutter_test`'s fake async
/// (`_combine`'s `onCancel` says why).
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

/// Each value of [source] replaces the stream [mapper] built from the one
/// before it — the `switchMap` every stream library has.
///
/// `asyncExpand` is not this. It *pauses* [source] until the stream it just
/// built is done, so with an endless inner stream — any repository watch —
/// the second value of [source] is never read at all and the first inner
/// stream keeps emitting under it.
///
/// Single-subscription. A new value of [source] cancels the previous inner
/// subscription before subscribing to the next; errors from [source] and from
/// an inner stream are forwarded; the result closes once [source] is done and
/// the last inner stream is done.
///
/// Cancelling the result detaches both listeners synchronously, and, as with
/// [combineLatest2], the future it returns does not mean either one has
/// finished its own tear-down.
Stream<T> switchLatest<S, T>(Stream<S> source, Stream<T> Function(S) mapper) {
  late StreamController<T> controller;
  StreamSubscription<S>? outer;
  StreamSubscription<T>? inner;
  var sourceDone = false;
  void closeIfDone() {
    if (sourceDone && inner == null) controller.close();
  }

  controller = StreamController<T>(
    onListen: () {
      outer = source.listen(
        (value) {
          // Cancelling stops delivery at once — the `onDone` below included,
          // so a stream being replaced can never close the result. Its future
          // is cleanup only, and awaiting it here would let the next value of
          // [source] interleave with the swap.
          unawaited(inner?.cancel());
          inner = mapper(value).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              inner = null;
              closeIfDone();
            },
          );
        },
        onError: controller.addError,
        onDone: () {
          sourceDone = true;
          closeIfDone();
        },
      );
    },
    // Neither cancel is awaited, for the reason `_combine`'s is not: both
    // detach their listener synchronously, and waiting on the future either
    // hands back deadlocks under `flutter_test`'s fake async.
    onCancel: () async {
      outer?.cancel();
      inner?.cancel();
    },
  );
  return controller.stream;
}

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
    // Every source is cancelled, and none of the cancels is awaited. A
    // subscription detaches its listener synchronously; the future it returns
    // is often the SDK's shared null future, which belongs to the root zone,
    // and awaiting one of those inside `flutter_test`'s fake-async zone never
    // resumes — a widget test that closed a bloc subscribed here hung for
    // ever, silently. Nothing here needs to know when a source has finished
    // its own tear-down.
    onCancel: () async {
      for (var s in subscriptions) {
        s.cancel();
      }
    },
  );
  return controller.stream;
}
