import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

enum HomesStatus { loading, ready }

/// A home with what the Homes sheet says about it: `<r> rooms · <l> lights`.
class HomeSummary extends Equatable {
  final Home home;
  final int roomCount;
  final int lightCount;
  const HomeSummary({
    required this.home,
    required this.roomCount,
    required this.lightCount,
  });
  @override
  List<Object?> get props => [home, roomCount, lightCount];
}

sealed class HomesNotice extends Equatable {
  const HomesNotice();
}

/// A home was just created and activated; the view toasts and goes to
/// discovery (spec §10.2).
final class HomeCreatedNotice extends HomesNotice {
  final Home home;
  const HomeCreatedNotice(this.home);
  @override
  List<Object?> get props => [home];
}

final class HomesError extends HomesNotice {
  final String message;
  const HomesError(this.message);
  @override
  List<Object?> get props => [message];
}

class HomesState extends Equatable {
  final HomesStatus status;
  final List<HomeSummary> homes;
  final String? activeHomeId;
  final HomesNotice? notice;

  const HomesState({
    required this.status,
    required this.homes,
    required this.activeHomeId,
    this.notice,
  });

  /// What bootstrap knows before anything is subscribed: enough for the
  /// router's redirect (spec §9), with counts still to come.
  factory HomesState.snapshot(List<Home> homes, AppSettings settings) =>
      HomesState(
        status: HomesStatus.loading,
        homes: [
          for (var h in homes)
            HomeSummary(home: h, roomCount: 0, lightCount: 0),
        ],
        activeHomeId: settings.activeHomeId,
      );

  Home? get activeHome {
    for (var h in homes) {
      if (h.home.id == activeHomeId) return h.home;
    }
    return null;
  }

  bool get hasHome => homes.isNotEmpty;

  HomesState copyWith({
    HomesStatus? status,
    List<HomeSummary>? homes,
    String? activeHomeId,
    bool clearActiveHome = false,
    HomesNotice? notice,
    bool clearNotice = false,
  }) => HomesState(
    status: status ?? this.status,
    homes: homes ?? this.homes,
    activeHomeId: clearActiveHome ? null : activeHomeId ?? this.activeHomeId,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, homes, activeHomeId, notice];
}
