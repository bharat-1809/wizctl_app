import 'package:flutter/material.dart';

import '../../core/feedback/feedback_kind.dart';
import '../../core/feedback/feedback_scope.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_button.dart';
import 'gallery_section.dart';

/// One key per [FeedbackKind], built from the enum rather than a list, so a
/// tenth cue could never be added without a key here to hear it with.
class GalleryFeedback extends StatelessWidget {
  const GalleryFeedback({super.key});

  /// Enum names are code, not copy: `toggleOn` reads as "Toggle on".
  static String labelFor(FeedbackKind kind) {
    var spaced = kind.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]!.toLowerCase()}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return GallerySection(
      title: 'Feedback',
      child: Wrap(
        spacing: space.s4,
        runSpacing: space.s4,
        children: [
          for (var kind in FeedbackKind.values)
            WizButton(
              label: labelFor(kind),
              size: WizButtonSize.sm,
              onPressed: () => context.feedback.play(kind),
            ),
        ],
      ),
    );
  }
}
