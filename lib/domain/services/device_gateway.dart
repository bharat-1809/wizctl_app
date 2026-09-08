import 'package:wizctl/wizctl.dart';

/// The boundary to the bulbs. Every method throws [DeviceException] on
/// failure; streams error with it. Timeouts and retries are the
/// implementation's concern (spec §5.8, §5.11).
abstract interface class DeviceGateway {
  Future<LightState> readState(String ip);
  Future<BulbConfig> readConfig(String ip);
  Future<void> send(String ip, ControlSignal signal);
  Future<List<DiscoveredLight>> broadcast();
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1});
  Stream<ScanEvent> sweep({String? subnet});
}
