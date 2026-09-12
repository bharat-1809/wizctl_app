import 'package:equatable/equatable.dart';

enum DiscoveryPhase { probingKnown, broadcasting, sweeping }

/// Progress of a discovery run; [fraction] is null-safe for the filament
/// bar (broadcast has no count, so probed and total are 0 and fraction 0).
class DiscoveryProgress extends Equatable {
  final DiscoveryPhase phase;
  final int probed;
  final int total;
  final double fraction;
  final String? subnet;

  const DiscoveryProgress({
    required this.phase,
    this.probed = 0,
    this.total = 0,
    this.fraction = 0,
    this.subnet,
  });

  bool get isDeterminate => total > 0;

  @override
  List<Object?> get props => [phase, probed, total, fraction, subnet];
}
