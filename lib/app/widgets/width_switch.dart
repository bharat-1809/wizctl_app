import 'package:flutter/widgets.dart';

import '../../core/layout/wiz_layout.dart';

/// Shows [compact] on a phone-width window and [wide] on everything from
/// medium up (spec §14, `WidthClass.isCompact`).
///
/// The one place that branch is written, so a route with both a phone and a
/// desktop reading — `HomePage`, `RoomPage` — is a single line and the two
/// cannot drift apart. It reads the *window's* class: `WizLayoutScope` is
/// installed once above the router (Task 19) and nothing re-scopes it, so a
/// narrow content frame never demotes a desktop window to a phone.
///
/// Both children are built as widgets either way — cheap, since only the
/// chosen one is mounted — and the route's bloc lives above this, so a resize
/// across the boundary swaps the widget and keeps the data.
class WidthSwitch extends StatelessWidget {
  final Widget compact;
  final Widget wide;

  const WidthSwitch({super.key, required this.compact, required this.wide});

  @override
  Widget build(BuildContext context) =>
      context.layout.widthClass.isCompact ? compact : wide;
}
