import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// Zero state: recessed glyph well, one line of plain explanation, one action.
class WizEmptyState extends StatelessWidget {
  final WizIconData icon;
  final String title;
  final String? body;
  final Widget? action;

  const WizEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  /// The recessed well (EmptyState.jsx `width: 76, height: 76`, radius
  /// `'50%'`) and the glyph in it, which the screens pass as
  /// `<Icon name="radio" size={30} />` (spec §11.2, "76 deep well with a
  /// 30 icon").
  static const double well = 76;
  static const double glyph = 30;

  /// EmptyState.jsx `maxWidth: 320` on the body copy.
  static const double bodyMaxWidth = 320;

  /// The title runs bolder than the `heading` token's 600
  /// (EmptyState.jsx `fontWeight: 700`).
  static const FontWeight titleWeight = FontWeight.w700;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    return Padding(
      // EmptyState.jsx `padding: 'var(--space-10) var(--space-7)'`.
      padding: EdgeInsets.symmetric(
        vertical: wiz.space.s10,
        horizontal: wiz.space.s7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WizSurface(
            spec: wiz.elevation.wellDeep,
            radius: BorderRadius.circular(well / 2),
            gradient: wizVertical(c.char1000, c.char900),
            width: well,
            height: well,
            alignment: Alignment.center,
            child: WizIcon(icon, size: glyph, color: c.textTertiary),
          ),
          // EmptyState.jsx `gap: 16`, between the well, the copy and the
          // action alike.
          SizedBox(height: wiz.space.s6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: wiz.typography.heading.copyWith(
              fontWeight: titleWeight,
              color: c.textPrimary,
            ),
          ),
          if (body != null) ...[
            // EmptyState.jsx `marginTop: 6` under the title.
            SizedBox(height: wiz.space.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: bodyMaxWidth),
              child: Text(
                body!,
                textAlign: TextAlign.center,
                style: wiz.typography.body.copyWith(color: c.textTertiary),
              ),
            ),
          ],
          if (action != null) ...[SizedBox(height: wiz.space.s6), action!],
        ],
      ),
    );
  }
}
