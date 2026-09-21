import 'package:flutter/material.dart';

import '../layout/wiz_layout.dart';
import '../theme/wiz_theme.dart';
import 'wiz_filament_bar.dart';

/// Pull to refresh drawn as a filament bar (spec §12, "pull-to-refresh
/// drawn as a filament bar"): Material's gesture and thresholds, the house
/// loader instead of its spinner. The bar sits under the top inset for as
/// long as the pull is armed or the refresh runs; no opacity layer, so it
/// simply is or is not there.
class WizPullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const WizPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<WizPullToRefresh> createState() => _WizPullToRefreshState();
}

class _WizPullToRefreshState extends State<WizPullToRefresh> {
  RefreshIndicatorStatus? _status;

  bool get _showing => switch (_status) {
    RefreshIndicatorStatus.armed ||
    RefreshIndicatorStatus.snap ||
    RefreshIndicatorStatus.refresh => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    // `maybeOf`, like `WizRail`: a kit widget has to be able to stand on a
    // gallery page or in a test with no `WizLayoutScope` above it, and the
    // compact gutter is the one this bar is drawn against.
    var gutter = WizLayout.maybeOf(context)?.gutter ?? space.gutter;
    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) => setState(() => _status = status),
          child: widget.child,
        ),
        if (_showing)
          Positioned(
            top: MediaQuery.paddingOf(context).top + space.s4,
            left: gutter,
            right: gutter,
            child: const IgnorePointer(child: WizFilamentBar()),
          ),
      ],
    );
  }
}
