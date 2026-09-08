import '../../domain/entities/debug_flags.dart';
import '../../domain/services/network_monitor.dart';

/// "Wrong network" prototype switch: report a subnet no home uses.
class FaultInjectingNetworkInfo implements NetworkInfo {
  final NetworkInfo _inner;
  final DebugFlags Function() _flags;

  /// The subnet reported while "off network" is on, chosen not to match a
  /// home's own (spec §18).
  static const String elsewhere = '10.0.0';

  FaultInjectingNetworkInfo(this._inner, {required DebugFlags Function() flags})
    // ignore: prefer_initializing_formals
    : _flags = flags;

  @override
  Future<String?> currentSubnet() async =>
      _flags().offNetwork ? elsewhere : _inner.currentSubnet();
}
