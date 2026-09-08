import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

/// Pill chip for room and option picking. Amber when selected.
class WizChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final WizIconData? icon;
  final double? height;
  final bool enabled;

  /// Amber text on a charcoal cap, for "New room" style actions.
  final bool accentText;

  const WizChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.height,
    this.enabled = true,
    this.accentText = false,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var h = height ?? wiz.space.controlSm;
    var ink = selected
        ? c.textOnAccent
        : (accentText ? c.amber400 : c.textSecondary);
    return WizPressable(
      onTap: onTap,
      enabled: enabled && onTap != null,
      feedback: FeedbackKind.tick,
      scale: wiz.motion.keyScale,
      semanticsLabel: label,
      // The cap stays 36 tall; the hit area is padded out to the minimum.
      hitPadding: EdgeInsets.symmetric(
        vertical: (wiz.space.hitMin - h).clamp(0, wiz.space.hitMin) / 2,
      ),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: BorderRadius.circular(wiz.space.pill),
        gradient: selected
            ? wizVertical(c.amber400, c.amber600)
            : wizVertical(c.surfaceKey, c.surfaceRaised),
        height: h,
        padding: EdgeInsets.symmetric(horizontal: wiz.space.s3 + wiz.space.s4),
        // No `alignment`: WizSurface's Align expands to any bounded width it
        // is offered, and a chip must always hug its label.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              WizIcon(icon!, size: wiz.typography.body.fontSize!, color: ink),
              SizedBox(width: wiz.space.s3),
            ],
            Text(
              label,
              style: wiz.typography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: ink,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
