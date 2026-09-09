import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';
import '../../core/theme/wiz_type.dart';

/// A titled block in the gallery.
class GallerySection extends StatelessWidget {
  final String title;
  final Widget child;

  const GallerySection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Padding(
      padding: EdgeInsets.only(bottom: wiz.space.s9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: wiz.typography.heading.copyWith(
              color: wiz.colors.textPrimary,
            ),
          ),
          SizedBox(height: wiz.space.s5),
          child,
        ],
      ),
    );
  }
}

/// The brand block from the prototype's sidebar: the wordmark in the display
/// face at weight 900 over the sample home's name
/// (`design/reference/_ds_bundle.js:3474`).
class GalleryWordmark extends StatelessWidget {
  const GalleryWordmark({super.key});

  /// `design/reference/_ds_bundle.js:3483`, "WIZCTL".
  static const String wordmark = 'WIZCTL';

  /// The sample home the prototype's sidebar names (`:3488`).
  static const String sampleHome = 'Kaverappa House';

  /// The sub-line is set a size below body, at `fontSize: 12.5` (`:3486`);
  /// `bodySm` is the token nearest it.
  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var title = wiz.typography.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          wordmark,
          style: title.copyWith(
            // `fontWeight: 900, letterSpacing: '.02em', lineHeight: 1` on the
            // 30 the title token already carries.
            fontWeight: FontWeight.w900,
            letterSpacing: title.fontSize! * WizType.wordmarkTracking,
            height: 1,
            color: c.textPrimary,
          ),
        ),
        SizedBox(height: wiz.space.s2),
        Text(
          sampleHome,
          style: wiz.typography.bodySm.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}
