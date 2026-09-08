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

  Stream<String?> watchSubnet() async* {
    if (_known) yield _current;
    yield* _subnet.stream;
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
