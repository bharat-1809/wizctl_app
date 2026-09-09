import 'package:flutter/material.dart';

/// A numeral with its unit on the same baseline: the shape every instrument
/// in the kit shows a number in. Readout.jsx, StatTile.jsx and Dial.jsx all
/// lay it out the same way — `display: flex; alignItems: 'baseline'`, the
/// unit a span nested in the numeral's own type, overriding only size,
/// weight and colour.
///
/// Two text nodes rather than one rich span, so the number alone is
/// addressable: `find.text('2700')` matches a `Text.rich` on its whole
/// plain text, `"2700K"`, and so would never see the value.
class WizNumeral extends StatelessWidget {
  final String value;
  final String? unit;
  final TextStyle valueStyle;

  /// The unit's type, defaulting to [valueStyle] the way the JSX's unit
  /// span inherits everything it does not override.
  final TextStyle? unitStyle;

  /// Space between the numeral and its unit. Zero by default, which is what
  /// Dial.jsx's engraved readout sets; [unitGap] is what the other two use.
  final double gap;

  /// Whether the numeral may take less than its intrinsic width, and
  /// ellipsise rather than overflow the row. Only legal where the width is
  /// bounded: inside a `FittedBox` — the dial's readout — a flexible child
  /// has nothing to flex against and the flex layout asserts.
  final bool flexible;

  const WizNumeral({
    super.key,
    required this.value,
    this.unit,
    required this.valueStyle,
    this.unitStyle,
    this.gap = 0,
    this.flexible = false,
  });

  /// Readout.jsx and StatTile.jsx both `gap: 2` between numeral and unit.
  static const double unitGap = 2;

  @override
  Widget build(BuildContext context) {
    Widget numeral = Text(
      value,
      style: valueStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        flexible ? Flexible(child: numeral) : numeral,
        if (unit != null)
          Padding(
            // The gap hangs off the unit rather than sitting between the two
            // as a box of its own: every child of a baseline row has to have
            // a baseline to align to, and a `SizedBox` has none.
            padding: EdgeInsets.only(left: gap),
            child: Text(unit!, style: unitStyle ?? valueStyle, maxLines: 1),
          ),
      ],
    );
  }
}
