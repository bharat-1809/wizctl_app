import 'dart:async';

/// Where this device is on the network right now.
abstract interface class NetworkInfo {
  /// The `a.b.c` prefix of the LAN address, or null with no IPv4 address.
  Future<String?> currentSubnet();
}

/// Off network = the home has a subnet and this device is not on it
/// (spec §5.9). No SSID reads, no location permission.
class NetworkMonitor {
  final NetworkInfo _info;
  final Duration interval;
  final StreamController<String?> _subnet = StreamController.broadcast();
  String? _current;
  Timer? _timer;
  bool _known = false;

  NetworkMonitor(this._info, {this.interval = const Duration(seconds: 5)});

  String? get current => _current;

  /// This device's subnet: what the monitor already knows, if it has read the
  /// interfaces at least once, and every change after that. One subscription
  /// per call; it closes when the monitor is disposed.
  ///
  /// Deliberately not an `async*` body. A generator suspended in
  /// `yield* _subnet.stream` is cancelled only once the generator itself has
  /// run to completion, and inside `flutter_test`'s fake-async zone that
  /// never happens: `cancel()` — and so the `close()` of any cubit
  /// subscribed here — waits for ever, with no output and no test timeout,
  /// because the isolate never yields. A controller cancels its source
  /// subscription and is done.
  Stream<String?> watchSubnet() {
    late StreamController<String?> out;
    StreamSubscription<String?>? subscription;
    out = StreamController<String?>(
      onListen: () {
        // Both synchronously, in this order: a change written in the same
        // turn as the `listen` call is then delivered after the replay
        // rather than lost in the window before the source is subscribed.
        if (_known) out.add(_current);
        subscription = _subnet.stream.listen(
          out.add,
          onError: out.addError,
          onDone: out.close,
        );
      },
      // `async`, and the source's own cancel deliberately not awaited: a
      // broadcast subscription drops its listener synchronously and hands
      // back the SDK's shared null future, which belongs to the root zone.
      // Waiting on that — or returning it from here — makes
      // `await subscription.cancel()` wait for a root-zone microtask, which
      // never runs while `flutter_test`'s fake-async zone holds the thread.
      // This closure's own future is created in the canceller's zone, so the
      // await resumes there.
      onCancel: () async {
        subscription?.cancel();
        subscription = null;
      },
    );
    return out.stream;
  }

  bool isOffNetwork(String? homeSubnet) {
    if (homeSubnet == null) return false;
    if (!_known) return false;
    return _current != homeSubnet;
  }

  Stream<bool> watchOffNetwork(String? homeSubnet) =>
      watchSubnet().map((_) => isOffNetwork(homeSubnet)).distinct();

  Future<void> refresh() async {
    String? next;
    try {
      next = await _info.currentSubnet();
    } catch (e) {
      next = null;
    }
    var changed = !_known || next != _current;
    _known = true;
    _current = next;
    if (changed && !_subnet.isClosed) _subnet.add(next);
  }

  void start() {
    _timer?.cancel();
    unawaited(refresh());
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _subnet.close();
  }
}
