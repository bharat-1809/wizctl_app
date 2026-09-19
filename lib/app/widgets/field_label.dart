import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';

/// The caps label above a field or a group: "ROOM NAME", "GLYPH", "COLOURS"
/// (spec §10, "control labels are uppercase with 0.10 em tracking").
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Text(
      text.toUpperCase(),
      style: wiz.typography.label.copyWith(color: wiz.colors.textTertiary),
    );
  }
}
