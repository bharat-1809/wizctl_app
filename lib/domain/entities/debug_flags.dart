import 'package:equatable/equatable.dart';

/// The prototype switches. Only debug builds ever set these.
///
/// [forceTimeout] applies to reads and writes alike, so the unreachable
/// banner can be reviewed from any screen and not just after a command.
class DebugFlags extends Equatable {
  final bool offNetwork;
  final bool forceTimeout;
  final bool findNothing;

  const DebugFlags({
    this.offNetwork = false,
    this.forceTimeout = false,
    this.findNothing = false,
  });

  static const DebugFlags none = DebugFlags();

  DebugFlags copyWith({
    bool? offNetwork,
    bool? forceTimeout,
    bool? findNothing,
  }) => DebugFlags(
    offNetwork: offNetwork ?? this.offNetwork,
    forceTimeout: forceTimeout ?? this.forceTimeout,
    findNothing: findNothing ?? this.findNothing,
  );

  @override
  List<Object?> get props => [offNetwork, forceTimeout, findNothing];
}
