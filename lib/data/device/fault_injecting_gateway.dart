import 'package:wizctl/wizctl.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/clock.dart';
import '../../domain/services/device_gateway.dart';

/// The prototype switches, for debug builds only (spec §18). Wraps the real
/// gateway so every failure state can be reviewed without touching the
/// network.
class FaultInjectingGateway implements DeviceGateway {
  final DeviceGateway _inner;
  final DebugFlags Function() _flags;
  final Clock _clock;

  /// Force-timeout delay before failing a read or write (spec §18).
  static const Duration forcedTimeout = Duration(milliseconds: 1100);

  /// Attempts reported on a forced timeout, matching the design's "No
  /// response after 3 tries" (spec §3.3).
  static const int forcedAttempts = 3;

  /// Addresses in the fake sweep, matching a real /24 (spec §18).
  static const int fakeAddressCount = 254;

  /// Progress steps the fake sweep reports before its empty done (spec §18).
  static const int fakeSweepSteps = 4;

  /// Delay between each fake sweep progress step (spec §18).
  static const Duration fakeSweepStep = Duration(milliseconds: 400);

  FaultInjectingGateway(
    this._inner, {
    required DebugFlags Function() flags,
    required Clock clock,
  })
    // ignore: prefer_initializing_formals
    : _flags = flags,
       // ignore: prefer_initializing_formals
       _clock = clock;

  Future<T> _maybeTimeout<T>(String ip, Future<T> Function() op) async {
    if (!_flags().forceTimeout) return op();
    await _clock.delay(forcedTimeout);
    throw DeviceException(TimeoutFailure(ip, forcedAttempts));
  }

  @override
  Future<LightState> readState(String ip) =>
      _maybeTimeout(ip, () => _inner.readState(ip));

  @override
  Future<BulbConfig> readConfig(String ip) =>
      _maybeTimeout(ip, () => _inner.readConfig(ip));

  @override
  Future<void> send(String ip, ControlSignal signal) =>
      _maybeTimeout(ip, () => _inner.send(ip, signal));

  @override
  Future<List<DiscoveredLight>> broadcast() async =>
      _flags().findNothing ? const [] : _inner.broadcast();

  @override
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}) =>
      _flags().findNothing
      ? Stream.value(const ScanDone([]))
      : _inner.probe(ips, rounds: rounds);

  @override
  Stream<ScanEvent> sweep({String? subnet}) {
    if (!_flags().findNothing) return _inner.sweep(subnet: subnet);
    return _emptySweep(subnet ?? '192.168.1');
  }

  Stream<ScanEvent> _emptySweep(String subnet) async* {
    for (var step = 1; step <= fakeSweepSteps; step++) {
      await _clock.delay(fakeSweepStep);
      var probed = (fakeAddressCount * step / fakeSweepSteps).round();
      yield ScanProgress(
        addressesProbed: probed,
        addressCount: fakeAddressCount,
        fraction: step / fakeSweepSteps,
        subnet: subnet,
      );
    }
    yield const ScanDone([]);
  }
}
