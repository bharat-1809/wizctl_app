import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizKeySize { sm, md, lg }

enum WizKeyShape { circle, squircle }

/// Round or squircle icon key: the default control for anything without a
/// text label. Active keys are amber.
class WizIconKey extends StatelessWidget {
  final WizIconData icon;
  final WizKeySize size;
  final WizKeyShape shape;
  final bool active;
  final bool enabled;
  final VoidCallback? onPressed;
  final String semanticsLabel;

  const WizIconKey({
    super.key,
    required this.icon,
    this.size = WizKeySize.md,
    this.shape = WizKeyShape.circle,
    this.active = false,
    this.enabled = true,
    this.onPressed,
    required this.semanticsLabel,
  });

  // Design system IconButton.jsx: diameter and glyph size per size.
  static const _diameter = {
    WizKeySize.sm: 36.0,
    WizKeySize.md: 44.0,
    WizKeySize.lg: 56.0,
  };
  static const _glyph = {
    WizKeySize.sm: 16.0,
    WizKeySize.md: 20.0,
    WizKeySize.lg: 24.0,
  };

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var d = _diameter[size]!;
    var radius = BorderRadius.circular(
      shape == WizKeyShape.circle ? d / 2 : wiz.space.r3,
    );
    return WizPressable(
      onTap: onPressed,
      enabled: enabled && onPressed != null,
      scale: wiz.motion.smallKeyScale,
      semanticsLabel: semanticsLabel,
      // The ring traces the cap: circular on a circle, squircle on a
      // squircle, rather than a rounded box around either.
      focusRadius: radius,
      // A key drawn smaller than the touch minimum still has to be as easy
      // to hit; the cap keeps its diameter and the hit area grows around it.
      hitPadding: d >= wiz.space.hitMin
          ? null
          : EdgeInsets.all((wiz.space.hitMin - d) / 2),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: radius,
        gradient: active
            ? wizVertical(c.amber400, c.amber600)
            : wizVertical(c.surfaceKey, c.surfaceRaised),
        width: d,
        height: d,
        // Kept here, unlike the button and chip: the surface is a fixed
        // square, so the Align is what stops the glyph being stretched to
        // the full diameter by the tight constraints.
        alignment: Alignment.center,
        child: WizIcon(
          icon,
          size: _glyph[size]!,
          color: active ? c.textOnAccent : c.textSecondary,
        ),
      ),
    );
  }
}
