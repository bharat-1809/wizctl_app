import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_gateway.dart';

/// Scripted bulbs. Each ip has a state; sends are recorded and applied to
/// the state so a later read sees them. `failing` ips throw on every call
/// (including `broadcast`, keyed under `'broadcast'`).
class FakeGateway implements DeviceGateway {
  final Map<String, LightState> states = {};
  final Map<String, BulbConfig> configs = {};
  final Map<String, DeviceFailure> failing = {};
  final List<(String ip, ControlSignal signal)> sends = [];
  final List<String> reads = [];
  List<DiscoveredLight> broadcastResult = [];
  List<ScanEvent> probeEvents = [];
  List<ScanEvent> sweepEvents = [];
  final List<List<String>> probeCalls = [];
  final List<String?> sweepCalls = [];
  Duration sendLatency = Duration.zero;

  void _check(String ip) {
    var f = failing[ip];
    if (f != null) throw DeviceException(f);
  }

  @override
  Future<LightState> readState(String ip) async {
    reads.add(ip);
    _check(ip);
    return states[ip] ?? const LightState(isOn: false);
  }

  @override
  Future<BulbConfig> readConfig(String ip) async {
    _check(ip);
    return configs[ip] ?? const BulbConfig();
  }

  @override
  Future<void> send(String ip, ControlSignal signal) async {
    if (sendLatency > Duration.zero) await Future<void>.delayed(sendLatency);
    sends.add((ip, signal));
    _check(ip);
    var s = states[ip] ?? const LightState(isOn: false);
    states[ip] = LightState(
      isOn: signal.state ?? s.isOn,
      dimming: signal.dimming ?? s.dimming,
      r:
          signal.r ??
          (signal.temperature != null || signal.sceneId != null ? null : s.r),
      g:
          signal.g ??
          (signal.temperature != null || signal.sceneId != null ? null : s.g),
      b:
          signal.b ??
          (signal.temperature != null || signal.sceneId != null ? null : s.b),
      temperature:
          signal.temperature ??
          (signal.r != null || signal.sceneId != null ? null : s.temperature),
      sceneId:
          signal.sceneId ??
          (signal.r != null || signal.temperature != null ? 0 : s.sceneId),
      speed: signal.speed ?? s.speed,
      mac: s.mac,
    );
  }

  @override
  Future<List<DiscoveredLight>> broadcast() async {
    _check('broadcast');
    return broadcastResult;
  }

  @override
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}) {
    probeCalls.add(ips.toList());
    return Stream.fromIterable(probeEvents);
  }

  @override
  Stream<ScanEvent> sweep({String? subnet}) {
    sweepCalls.add(subnet);
    return Stream.fromIterable(sweepEvents);
  }
}
