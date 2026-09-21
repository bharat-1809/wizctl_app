import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/widgets/wiz_stat_tile.dart';

/// The two instrument tiles over the desktop grid (spec §10.9): how many
/// lights are on out of the total, in amber, and how many are not answering.
///
/// It reports what the grid's own bloc already counted, so the two numbers
/// can never disagree with the cards below them.
class GridStats extends StatelessWidget {
  final int onCount;
  final int total;
  final int unreachable;

  const GridStats({
    super.key,
    required this.onCount,
    required this.total,
    required this.unreachable,
  });

  /// `WizCtl_Desktop.dc.html` line 176: `gap:14px` between the two tiles.
  static const double gap = 14;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WizStatTile(
            icon: WizIcons.zap,
            label: Strings.lightsOnTile,
            value: Strings.onOf(onCount, total),
            accent: true,
          ),
        ),
        const SizedBox(width: gap),
        Expanded(
          child: WizStatTile(
            icon: WizIcons.wifi,
            label: Strings.notAnsweringTile,
            value: '$unreachable',
          ),
        ),
      ],
    );
  }
}
