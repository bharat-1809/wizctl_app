import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// Small instrument tile: caps label with glyph, then a display-face value.
class WizStatTile extends StatelessWidget {
  final WizIconData icon;
  final String label;
  final String value;
  final String? unit;
  final bool accent;

  const WizStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.accent = false,
  });

  /// The value: StatTile.jsx `fontSize: 28, fontWeight: 800` (spec §11.2,
  /// "value 28 display 800 tabular"). The weight is a step above the
  /// `readout` token's 700.
  static const double valueSize = 28;
  static const FontWeight valueWeight = FontWeight.w800;

  /// The unit rides the value's baseline: StatTile.jsx `fontSize: 13,
  /// fontWeight: 600` and the `gap: 2` between the two.
  static const double unitSize = 13;
  static const FontWeight unitWeight = FontWeight.w600;
  static const double unitGap = 2;

  /// The label's glyph (spec §11.2, "caption with 14 icon";
  /// `WizCtl_Mobile.dc.html` builds the tile icons as `this.ic(…, 14)`) and
  /// StatTile.jsx's `gap: 7` beside it.
  static const double glyph = 14;
  static const double iconGap = 7;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    // The unit keeps the value's face and tabular figures: in StatTile.jsx
    // it is a span inside the display-face one, overriding only size,
    // weight and colour.
    var numeral = wiz.typography.readout;
    return WizSurface(
      spec: wiz.elevation.panel,
      radius: BorderRadius.circular(wiz.space.r3),
      gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
      // StatTile.jsx `padding: '14px 16px'`.
      padding: EdgeInsets.symmetric(
        vertical: wiz.space.s5 + wiz.space.s1,
        horizontal: wiz.space.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              WizIcon(icon, size: glyph, color: c.textTertiary),
              const SizedBox(width: iconGap),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: wiz.typography.caption.copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // StatTile.jsx `gap: 12` between the label and the value.
          SizedBox(height: wiz.space.s5),
          Row(
            mainAxisSize: MainAxisSize.min,
            // StatTile.jsx `alignItems: 'baseline'`: the unit sits on the
            // numeral's baseline, not centred against its cap height.
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: numeral.copyWith(
                    fontSize: valueSize,
                    fontWeight: valueWeight,
                    color: accent ? c.amber400 : c.textPrimary,
                  ),
                ),
              ),
              if (unit != null)
                Padding(
                  // The gap hangs off the unit rather than sitting between
                  // the two as a box of its own: every child of a baseline
                  // row has to have a baseline to align to.
                  padding: const EdgeInsets.only(left: unitGap),
                  child: Text(
                    unit!,
                    style: numeral.copyWith(
                      fontSize: unitSize,
                      fontWeight: unitWeight,
                      color: c.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
