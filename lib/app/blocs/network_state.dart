import 'package:equatable/equatable.dart';

sealed class NetworkNotice extends Equatable {
  const NetworkNotice();
}

/// A retry found the device still elsewhere; the view toasts "Still on …".
final class StillOffNotice extends NetworkNotice {
  final String? currentSubnet;
  const StillOffNotice(this.currentSubnet);
  @override
  List<Object?> get props => [currentSubnet];
}

/// Off network = the active home has a subnet and this device is not on it,
/// or has no IPv4 address at all (spec §5.9).
class NetworkState extends Equatable {
  final bool offNetwork;
  final String? currentSubnet;
  final String? homeSubnet;
  final NetworkNotice? notice;

  const NetworkState({
    required this.offNetwork,
    required this.currentSubnet,
    required this.homeSubnet,
    this.notice,
  });

  static const NetworkState initial = NetworkState(
    offNetwork: false,
    currentSubnet: null,
    homeSubnet: null,
  );

  NetworkState copyWith({
    bool? offNetwork,
    String? currentSubnet,
    bool clearCurrent = false,
    String? homeSubnet,
    bool clearHome = false,
    NetworkNotice? notice,
    bool clearNotice = false,
  }) => NetworkState(
    offNetwork: offNetwork ?? this.offNetwork,
    currentSubnet: clearCurrent ? null : currentSubnet ?? this.currentSubnet,
    homeSubnet: clearHome ? null : homeSubnet ?? this.homeSubnet,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [offNetwork, currentSubnet, homeSubnet, notice];
}
