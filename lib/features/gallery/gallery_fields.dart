import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_text_field.dart';
import 'gallery_section.dart';

/// The one input in the kit, at both heights.
class GalleryFields extends StatelessWidget {
  const GalleryFields({super.key});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return GallerySection(
      title: 'Fields',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tall field names a home; the short one names a light.
          WizTextField(placeholder: 'Kaverappa House', height: space.controlLg),
          SizedBox(height: space.s5),
          WizTextField(placeholder: 'Bedside bulb', height: space.controlMd),
          SizedBox(height: space.s5),
          WizTextField(
            placeholder: 'Read only',
            height: space.controlMd,
            enabled: false,
          ),
        ],
      ),
    );
  }
}
