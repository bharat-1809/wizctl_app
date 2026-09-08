import 'dart:async';

import 'package:wizctl/wizctl.dart';

import '../../domain/entities/device_failure.dart';
import '../../domain/services/device_gateway.dart';
import 'gateway_tuning.dart';

/// The bulbs, through the wizctl package. One `WizLight` per address and
/// purpose, so reads and writes keep their own timeouts.
class WizDeviceGateway implements DeviceGateway {
  final GatewayTuning tuning;
  final Map<String, WizLight> _readers = {};
  final Map<String, WizLight> _writers = {};

  WizDeviceGateway({this.tuning = const GatewayTuning()});

  WizLight _reader(String ip) => _readers.putIfAbsent(
    ip,
    () => WizLight(
      ip,
      port: tuning.port,
      timeout: tuning.readTimeout,
      retry: tuning.readRetry,
    ),
  );

  WizLight _writer(String ip) => _writers.putIfAbsent(
    ip,
    () => WizLight(
      ip,
      port: tuning.port,
      timeout: tuning.writeTimeout,
      retry: tuning.writeRetry,
    ),
  );

  static DeviceFailure mapError(Object error, String ip) => switch (error) {
    WizTimeoutError e => TimeoutFailure(ip, e.retryCount),
    WizConnectionError e => UnreachableFailure(ip, e.message),
    WizMethodNotFoundError e => UnsupportedFailure(ip, e.method),
    WizArgumentError e => InvalidArgumentFailure(e.message),
    WizResponseError e => UnreachableFailure(ip, e.message),
    WizUnknownBulbError e => UnreachableFailure(ip, e.message),
    _ => UnreachableFailure(ip, '$error'),
  };

  Future<T> _guard<T>(String ip, Future<T> Function() op) async {
    try {
      return await op();
    } catch (e) {
      throw DeviceException(mapError(e, ip));
    }
  }

  @override
  Future<LightState> readState(String ip) =>
      _guard(ip, () => _reader(ip).getState());

  @override
  Future<BulbConfig> readConfig(String ip) =>
      _guard(ip, () => _reader(ip).getSystemConfig());

  @override
  Future<void> send(String ip, ControlSignal signal) =>
      _guard(ip, () => _writer(ip).send(signal));

  @override
  Future<List<DiscoveredLight>> broadcast() => _guard(
    tuning.broadcastAddress,
    () => WizDiscovery.discover(
      broadcastAddress: tuning.broadcastAddress,
      timeout: tuning.broadcastTimeout,
      port: tuning.port,
      localPort: tuning.localPort,
    ),
  );

  Stream<ScanEvent> _mapErrors(Stream<ScanEvent> stream, String ip) =>
      stream.handleError(
        (Object e) => throw DeviceException(mapError(e, ip)),
        test: (e) => e is! DeviceException,
      );

  @override
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}) => _mapErrors(
    WizDiscovery.probeAddressesStream(
      addresses: ips,
      timeout: tuning.readTimeout,
      rounds: rounds,
      port: tuning.port,
      localPort: tuning.localPort,
    ),
    ips.join(','),
  );

  @override
  Stream<ScanEvent> sweep({String? subnet}) => _mapErrors(
    WizDiscovery.scanSubnetStream(
      subnet: subnet,
      timeout: tuning.sweepTimeout,
      port: tuning.port,
      localPort: tuning.localPort,
    ),
    subnet ?? 'subnet',
  );
}
