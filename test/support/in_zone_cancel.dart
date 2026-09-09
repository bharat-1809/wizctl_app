import 'dart:async';

/// Relays [source] through a controller that declares its own `onCancel`,
/// so `cancel()` returns a freshly created, zone-local future a `fakeAsync`
/// test can observe. Streams that declare no `onCancel` — the SDK's `async*`
/// streams and plain broadcast controllers — instead return the process-wide
/// `Future._nullFuture` sentinel, pinned to whichever zone first realized it;
/// inside a different `fakeAsync` zone that future never completes, so
/// `flushMicrotasks`/`elapse` can't observe it. Returning a fresh, zone-local
/// future here — rather than awaiting the upstream subscription's own
/// (equally pinned) cancel future — lets a test actually observe a `dispose()`
/// finish cancelling its subscriptions.
Stream<T> inZoneCancel<T>(Stream<T> source) {
  late StreamSubscription<T> upstream;
  var controller = StreamController<T>(
    onCancel: () {
      unawaited(upstream.cancel());
      return Future.value();
    },
  );
  upstream = source.listen(
    controller.add,
    onError: controller.addError,
    onDone: controller.close,
  );
  return controller.stream;
}
