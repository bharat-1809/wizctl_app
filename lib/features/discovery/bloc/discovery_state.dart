import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

/// What the screen shows (spec §8 "phase (idle/probingKnown/broadcasting/
/// sweeping/found/empty/error)").
enum DiscoveryView {
  idle,
  probingKnown,
  broadcasting,
  sweeping,
  found,
  empty,
  error,
}

sealed class DiscoveryNotice extends Equatable {
  const DiscoveryNotice();
}

/// A device became a light in this home: the view names it `<alias>` and
/// says where it came from, `<ip>`.
final class LightSavedNotice extends DiscoveryNotice {
  final String alias;
  final String ip;
  const LightSavedNotice(this.alias, this.ip);
  @override
  List<Object?> get props => [alias, ip];
}

/// A save the domain refused, carrying the use case's own line.
final class SaveFailedNotice extends DiscoveryNotice {
  final String message;
  const SaveFailedNotice(this.message);
  @override
  List<Object?> get props => [message];
}

class DiscoveryState extends Equatable {
  final DiscoveryView view;
  final DiscoveryProgress? progress;
  final List<FoundDevice> found;

  /// Saves in flight, by address, with the alias each is being given; the
  /// view names its loading toast from this.
  final Map<String, String> saving;
  final String? subnet;
  final DeviceFailure? failure;

  /// Whether a sweep has run in this screen's life: the empty state's copy
  /// and the found banner's body change after one (spec §10.8).
  final bool sweptOnce;
  final List<String> failedRanges;
  final DiscoveryNotice? notice;

  const DiscoveryState({
    required this.view,
    this.progress,
    required this.found,
    required this.saving,
    this.subnet,
    this.failure,
    this.sweptOnce = false,
    this.failedRanges = const [],
    this.notice,
  });

  static const DiscoveryState initial = DiscoveryState(
    view: DiscoveryView.idle,
    found: [],
    saving: {},
  );

  bool get isScanning =>
      view == DiscoveryView.probingKnown ||
      view == DiscoveryView.broadcasting ||
      view == DiscoveryView.sweeping;

  List<FoundDevice> get kept => found.where((f) => f.kept).toList();
  int get keptCount => kept.length;

  DiscoveryState copyWith({
    DiscoveryView? view,
    DiscoveryProgress? progress,
    bool clearProgress = false,
    List<FoundDevice>? found,
    Map<String, String>? saving,
    String? subnet,
    DeviceFailure? failure,
    bool clearFailure = false,
    bool? sweptOnce,
    List<String>? failedRanges,
    DiscoveryNotice? notice,
    bool clearNotice = false,
  }) => DiscoveryState(
    view: view ?? this.view,
    progress: clearProgress ? null : progress ?? this.progress,
    found: found ?? this.found,
    saving: saving ?? this.saving,
    subnet: subnet ?? this.subnet,
    failure: clearFailure ? null : failure ?? this.failure,
    sweptOnce: sweptOnce ?? this.sweptOnce,
    failedRanges: failedRanges ?? this.failedRanges,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    view,
    progress,
    found,
    saving,
    subnet,
    failure,
    sweptOnce,
    failedRanges,
    notice,
  ];
}
