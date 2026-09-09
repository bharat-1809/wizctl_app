import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_numeral.dart';

enum WizReadoutSize { sm, md, lg }

enum WizReadoutTone { normal, accent, muted }

/// Instrument readout: large display numeral with a small unit, optional
/// caps label above. Numeric readouts never animate; values snap.
class WizReadout extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final WizReadoutSize size;
  final WizReadoutTone tone;
  final bool mono;
  final bool center;

  const WizReadout({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.size = WizReadoutSize.md,
    this.tone = WizReadoutTone.normal,
    this.mono = false,
    this.center = false,
  });

  /// The large size is the only one with no type token behind it:
  /// Readout.jsx `size === 'lg' ? 48`, against `--type-readout-sm-size` and
  /// `--type-readout-size` for the other two (spec §11.2, "sm 18, md 34,
  /// lg 48").
  static const double lgSize = 48;

  /// The unit is set relative to the numeral it follows: Readout.jsx
  /// `fontSize: '0.44em'`. The gap between them is [WizNumeral.unitGap].
  static const double unitRatio = 0.44;

  /// Readout.jsx `fontWeight: mono ? 500 : 800` for the numeral, and 600
  /// for the unit.
  static const FontWeight numeralWeight = FontWeight.w800;
  static const FontWeight monoWeight = FontWeight.w500;
  static const FontWeight unitWeight = FontWeight.w600;

  /// Readout.jsx `fontVariantNumeric: 'tabular-nums'`, declared the way
  /// `WizType` declares it on the `readout` token.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var fs = switch (size) {
      WizReadoutSize.sm => wiz.typography.readoutSm.fontSize!,
      WizReadoutSize.md => wiz.typography.readout.fontSize!,
      WizReadoutSize.lg => lgSize,
    };
    var color = switch (tone) {
      WizReadoutTone.accent => c.amber400,
      WizReadoutTone.muted => c.textTertiary,
      WizReadoutTone.normal => c.textPrimary,
    };
    // Readout.jsx `fontFamily: mono ? 'var(--font-mono)' :
    // 'var(--font-display)'` with `lineHeight: 1`; the unit inherits the
    // face and overrides only size, weight and colour. `tabular-nums` is
    // set on the flex parent either way, so the mono face — whose `code`
    // token does not carry the feature the `readout` token does — asks for
    // it here, and a readout never reflows as its digits change. A null
    // leaves the display branch on the feature its token already declares.
    var style = (mono ? wiz.typography.code : wiz.typography.readout).copyWith(
      fontSize: fs,
      fontWeight: mono ? monoWeight : numeralWeight,
      fontFeatures: mono ? tabular : null,
      height: 1,
      color: color,
    );
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: wiz.typography.caption.copyWith(color: c.textTertiary),
          ),
          // Readout.jsx `gap: 4` under the label.
          SizedBox(height: wiz.space.s2),
        ],
        WizNumeral(
          value: value,
          unit: unit,
          valueStyle: style,
          unitStyle: style.copyWith(
            fontSize: fs * unitRatio,
            fontWeight: unitWeight,
            color: c.textTertiary,
          ),
          gap: WizNumeral.unitGap,
        ),
      ],
    );
  }
}
