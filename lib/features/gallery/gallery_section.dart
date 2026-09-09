import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';

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
