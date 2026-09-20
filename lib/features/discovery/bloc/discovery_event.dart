import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';

sealed class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();
  @override
  List<Object?> get props => const [];
}

/// Probe the known addresses (when there is a home), then broadcast.
final class DiscoveryStarted extends DiscoveryEvent {
  const DiscoveryStarted();
}

/// The unicast sweep, only ever on the user's key (spec §5.7).
final class DiscoverySweepRequested extends DiscoveryEvent {
  const DiscoverySweepRequested();
}

final class DiscoveryCancelled extends DiscoveryEvent {
  const DiscoveryCancelled();
}

/// Onboarding's keep/drop check on a found row.
final class DiscoveryKeepToggled extends DiscoveryEvent {
  final String ip;
  const DiscoveryKeepToggled(this.ip);
  @override
  List<Object?> get props => [ip];
}

final class DiscoverySaveRequested extends DiscoveryEvent {
  final String ip;
  final String alias;
  final String roomId;
  final Fixture fixture;
  const DiscoverySaveRequested({
    required this.ip,
    required this.alias,
    required this.roomId,
    required this.fixture,
  });
  @override
  List<Object?> get props => [ip, alias, roomId, fixture];
}

final class DiscoveryNoticeCleared extends DiscoveryEvent {
  const DiscoveryNoticeCleared();
}

/// Fed by the bloc itself from the running stream; not for views.
final class DiscoveryUpdateReceived extends DiscoveryEvent {
  final DiscoveryUpdate update;
  const DiscoveryUpdateReceived(this.update);
  @override
  List<Object?> get props => [update];
}

/// Fed by the bloc itself when the stream closes; not for views.
final class DiscoveryRunEnded extends DiscoveryEvent {
  const DiscoveryRunEnded();
}
