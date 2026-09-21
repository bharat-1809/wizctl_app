import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../../../domain/entities/entities.dart';
import 'glyph_picker.dart';

/// ROOM NAME and, when a glyph is given, GLYPH: the body of the add, new
/// and rename room sheets (spec §10.1, §10.6).
class RoomForm extends StatelessWidget {
  final TextEditingController controller;
  final RoomGlyph? glyph;
  final ValueChanged<RoomGlyph>? onGlyph;
  final String placeholder;

  const RoomForm({
    super.key,
    required this.controller,
    this.glyph,
    this.onGlyph,
    this.placeholder = Strings.roomNamePlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var glyph = this.glyph;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel(Strings.roomName),
        SizedBox(height: space.s3),
        WizTextField(
          controller: controller,
          placeholder: placeholder,
          autofocus: true,
        ),
        if (glyph != null) ...[
          SizedBox(height: space.s6),
          const FieldLabel(Strings.glyph),
          SizedBox(height: space.s3),
          GlyphPicker(value: glyph, onChanged: onGlyph ?? (_) {}),
        ],
      ],
    );
  }
}
