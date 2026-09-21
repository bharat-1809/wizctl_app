import 'package:flutter/material.dart';

import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_skeleton.dart';

/// Three placeholder rows while a scan runs (spec §10.8, "three skeletons"):
/// a round well and two bars, in the proportions of the `WizListRow` a found
/// device will land in, so the list does not collapse and then jump.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key});

  /// The geometry of the row being stood in for: `WizListRow.well` is 40, and
  /// the two bars are the title (16 / 600) and the meta (bodySm 13) at the
  /// widths a device name and an "ip · class" line occupy.
  static const int rows = 3;
  static const double well = 40;
  static const double titleWidth = 160, titleHeight = 14;
  static const double metaWidth = 90, metaHeight = 10;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Column(
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) SizedBox(height: space.s4),
          WizPanel(
            padding: EdgeInsets.symmetric(
              horizontal: space.s6,
              vertical: space.s5,
            ),
            child: Row(
              children: [
                const WizSkeleton(width: well, height: well, circle: true),
                SizedBox(width: space.s5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WizSkeleton(width: titleWidth, height: titleHeight),
                    SizedBox(height: space.s3),
                    const WizSkeleton(width: metaWidth, height: metaHeight),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
