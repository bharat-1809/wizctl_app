import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizButtonVariant { primary, secondary, ghost, danger }

enum WizButtonSize { sm, md, lg }

/// Tactile key. Label is uppercase with wide tracking; the press sinks it
/// into the chassis. Every variant carries a raised cap, including ghost, so
/// siblings read as the same size.
class WizButton extends StatelessWidget {
  final String label;
  final WizButtonVariant variant;
  final WizButtonSize size;
  final WizIconData? icon;
  final WizIconData? iconAfter;
  final bool fullWidth;
  final bool enabled;
  final VoidCallback? onPressed;

  const WizButton({
    super.key,
    required this.label,
    this.variant = WizButtonVariant.secondary,
    this.size = WizButtonSize.md,
    this.icon,
    this.iconAfter,
    this.fullWidth = false,
    this.enabled = true,
    this.onPressed,
  });

  // Design system Button.jsx BUTTON_SIZES: horizontal padding / font size /
  // gap / icon. Height and radius come from the space tokens below.
  static const _sizes = {
    WizButtonSize.sm: (px: 14.0, fs: 12.0, gap: 6.0, icon: 14.0),
    WizButtonSize.md: (px: 20.0, fs: 13.5, gap: 8.0, icon: 16.0),
    WizButtonSize.lg: (px: 26.0, fs: 15.0, gap: 10.0, icon: 18.0),
  };

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var s = _sizes[size]!;
    var height = switch (size) {
      WizButtonSize.sm => wiz.space.controlSm,
      WizButtonSize.md => wiz.space.controlMd,
      WizButtonSize.lg => wiz.space.controlLg,
    };
    var radius = BorderRadius.circular(switch (size) {
      WizButtonSize.sm => wiz.space.r2,
      WizButtonSize.md => wiz.space.r3,
      WizButtonSize.lg => wiz.space.r4,
    });
    var (gradient, ink, spec, feedback) = switch (variant) {
      WizButtonVariant.primary => (
        wizVertical(c.amber400, c.amber600),
        c.textOnAccent,
        wiz.elevation.key,
        FeedbackKind.confirm,
      ),
      WizButtonVariant.secondary => (
        wizVertical(c.surfaceKey, c.surfaceRaised),
        c.textPrimary,
        wiz.elevation.raised,
        FeedbackKind.press,
      ),
      WizButtonVariant.ghost => (
        wizVertical(c.char800, c.char850),
        c.textSecondary,
        wiz.elevation.raised,
        FeedbackKind.press,
      ),
      WizButtonVariant.danger => (
        wizVertical(c.dangerKeyTop, c.dangerKeyBottom),
        c.dangerKeyInk,
        wiz.elevation.raised,
        FeedbackKind.reject,
      ),
    };
    var textStyle = wiz.typography.body.copyWith(
      fontSize: s.fs,
      fontWeight: FontWeight.w700,
      letterSpacing: s.fs * WizType.labelTracking,
      color: ink,
      height: 1,
    );

    return WizPressable(
      onTap: onPressed,
      enabled: enabled && onPressed != null,
      feedback: feedback,
      scale: wiz.motion.keyScale,
      semanticsLabel: label,
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : spec,
        radius: radius,
        gradient: gradient,
        height: height,
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: s.px),
        // No `alignment`: WizSurface's Align expands to any bounded width it
        // is offered, which would make every button in a Column full width.
        // The row below centres the cap's contents instead.
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              WizIcon(icon!, size: s.icon, color: ink),
              SizedBox(width: s.gap),
            ],
            Text(
              label.toUpperCase(),
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (iconAfter != null) ...[
              SizedBox(width: s.gap),
              WizIcon(iconAfter!, size: s.icon, color: ink),
            ],
          ],
        ),
      ),
    );
  }
}
