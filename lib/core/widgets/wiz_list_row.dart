import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

/// One line in a list of rooms, lights or settings: leading icon well,
/// title, meta, trailing slot. Rows have no dividers; lists use gaps.
///
/// The title and meta ellipsise, so a row needs a bounded width: a vertical
/// list, or an `Expanded`/`Flexible` in a row.
class WizListRow extends StatelessWidget {
  final WizIconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? meta;
  final Widget? trailing;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WizListRow({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.meta,
    this.trailing,
    this.active = false,
    this.onTap,
    this.onLongPress,
  });

  /// The leading icon well (ListRow.jsx `width: 40, height: 40`; spec §11.2,
  /// "40 icon well").
  static const double well = 40;

  /// Its glyph: rows hand `ListRow` a bare `<Icon>`, so it renders at
  /// Icon.jsx's default `size = 20` (spec §11.2 draws rows at 20–24).
  static const double glyph = 20;

  /// Title size and weight (ListRow.jsx `fontSize: 16, fontWeight: 600`;
  /// spec §11.2, "title 16 / 600"). Tracking is [WizType.rowTitleTracking].
  static const double titleSize = 16;
  static const FontWeight titleWeight = FontWeight.w600;

  /// ListRow.jsx sets the title no line-height, so it renders at the
  /// browser's `normal` leading — about 1.25 for the UI face, and far
  /// tighter than the 1.5 the `body` token carries. Flutter has no
  /// "normal", so it is stated.
  static const double titleHeight = 1.25;

  /// The active row's amber hairline (ListRow.jsx
  /// `inset 0 0 0 1px rgba(255,176,32,.28)`).
  static const double activeRingAlpha = 0.28;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    // ListRow.jsx `gap: 14`, and the same 14 of side padding
    // (`padding: '12px 14px'`).
    var gap = wiz.space.s5 + wiz.space.s1;
    var interactive = onTap != null || onLongPress != null;

    Widget body(bool pressed) => ConstrainedBox(
      // A row is a touch target, and a title-only one is exactly as tall as
      // its copy and padding. The floor is read from the token every other
      // key in the kit reads it from, rather than left to arithmetic that
      // happens to land on it.
      constraints: BoxConstraints(minHeight: wiz.space.hitMin),
      child: WizSurface(
        spec: pressed
            ? wiz.elevation.pressed
            : (active ? wiz.elevation.raised : wiz.elevation.panel),
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: active
            ? wizVertical(c.surfaceKey, c.surfaceRaised)
            : wizVertical(c.surfaceRaised, c.surfacePanel),
        // The JSX ring is an *inset* one, which a `WizInset` cannot express:
        // with no offset and no blur, `paintInsets` differences the shape
        // against itself and paints nothing. So the hairline is drawn just
        // outside the shape instead, the way `WizElevation.glowAmber`'s
        // `spreadRadius: 1` ring is. A pressed row drops it: ListRow.jsx
        // gives a row that is down `elev-pressed` and nothing else.
        glow: active && !pressed
            ? [
                BoxShadow(
                  color: c.amber500.withValues(alpha: activeRingAlpha),
                  spreadRadius: 1,
                ),
              ]
            : const [],
        padding: EdgeInsets.symmetric(vertical: wiz.space.s5, horizontal: gap),
        child: Row(
          children: [
            if (icon != null || iconWidget != null) ...[
              WizSurface(
                spec: wiz.elevation.well,
                radius: BorderRadius.circular(wiz.space.r2),
                color: c.char1000,
                width: well,
                height: well,
                alignment: Alignment.center,
                child:
                    iconWidget ??
                    WizIcon(
                      icon!,
                      size: glyph,
                      color: active ? c.amber400 : c.textTertiary,
                    ),
              ),
              SizedBox(width: gap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wiz.typography.body.copyWith(
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                      letterSpacing: titleSize * WizType.rowTitleTracking,
                      color: c.textPrimary,
                      height: titleHeight,
                    ),
                  ),
                  if (meta != null)
                    Padding(
                      // ListRow.jsx `marginTop: 1`: half the 2 px `s1` step,
                      // the smallest gap the scale reaches.
                      padding: EdgeInsets.only(top: wiz.space.s1 / 2),
                      child: Text(
                        meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: wiz.typography.bodySm.copyWith(
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: gap), trailing!],
          ],
        ),
      ),
    );

    if (!interactive) return body(false);
    return WizPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: wiz.motion.pressScale,
      // No `semanticsLabel`: the pressable already marks the node a button,
      // and the title and meta inside it name it. Naming it again would
      // have assistive tech read the row's title twice.
      //
      // Rows carry toggles and sliders in their trailing slot and ride in
      // scrolling lists, so the sink waits for the arena.
      arenaResolved: true,
      builder: (context, state) => body(state.pressed),
    );
  }
}
