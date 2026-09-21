import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../domain/entities/entities.dart';

/// The six room glyphs as squircle keys, the chosen one amber (spec
/// §10.1, "GLYPH ×6"). The prototype's 48 squares are the kit's md key.
class GlyphPicker extends StatelessWidget {
  final RoomGlyph value;
  final ValueChanged<RoomGlyph> onChanged;

  const GlyphPicker({super.key, required this.value, required this.onChanged});

  /// What the screen reader calls each glyph.
  static String labelFor(RoomGlyph glyph) => switch (glyph) {
    RoomGlyph.sofa => Strings.glyphSofa,
    RoomGlyph.bed => Strings.glyphBed,
    RoomGlyph.utensils => Strings.glyphKitchen,
    RoomGlyph.bath => Strings.glyphBath,
    RoomGlyph.lampDesk => Strings.glyphLamp,
    RoomGlyph.trees => Strings.glyphTrees,
  };

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Wrap(
      spacing: space.s4,
      runSpacing: space.s4,
      children: [
        for (var glyph in RoomGlyph.values)
          WizIconKey(
            icon: WizIcons.byName(glyph.iconName)!,
            shape: WizKeyShape.squircle,
            active: glyph == value,
            semanticsLabel: labelFor(glyph),
            onPressed: () => onChanged(glyph),
          ),
      ],
    );
  }
}
