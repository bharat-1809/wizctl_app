import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';

/// "\<n\> lights not answering" in the danger colour under the All lights
/// panel (spec §10.2).
class UnreachableLine extends StatelessWidget {
  final int count;
  const UnreachableLine({super.key, required this.count});

  /// The prototype's `icSm` glyph.
  static const double glyph = 15;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Row(
      children: [
        WizIcon(WizIcons.wifi, size: glyph, color: wiz.colors.signalDanger),
        SizedBox(width: wiz.space.s3),
        Text(
          Strings.notAnswering(count),
          style: wiz.typography.bodySm.copyWith(color: wiz.colors.signalDanger),
        ),
      ],
    );
  }
}
