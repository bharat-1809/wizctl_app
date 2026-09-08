import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

enum WizPanelVariant {
  /// A card sitting on the app surface.
  raised,

  /// A well that holds controls.
  inset,

  /// Hairline only; for device fact panels.
  flat,
}

/// The chassis panel. Raised for cards, inset for wells, flat for facts.
/// Radius 20, padding 16, grain on. Gains the amber emission ring when the
/// light it represents is on.
class WizPanel extends StatelessWidget {
  final WizPanelVariant variant;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final bool grain;
  final bool glow;
  final Widget child;

  const WizPanel({
    super.key,
    this.variant = WizPanelVariant.raised,
    this.radius,
    this.padding,
    this.grain = true,
    this.glow = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var border = BorderRadius.circular(radius ?? wiz.space.r4);
    var (spec, gradient) = switch (variant) {
      WizPanelVariant.raised => (
        wiz.elevation.panel,
        wizVertical(c.surfaceRaised, c.surfacePanel),
      ),
      WizPanelVariant.inset => (
        wiz.elevation.well,
        wizVertical(c.char900, c.char950),
      ),
      WizPanelVariant.flat => (
        wiz.elevation.flat,
        wizVertical(c.surfaceRaised, c.surfacePanel),
      ),
    };
    var surface = WizSurface(
      spec: spec,
      radius: border,
      gradient: gradient,
      grain: grain,
      padding: padding ?? EdgeInsets.all(wiz.space.panelPad),
      child: child,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: WizGlow(
            on: glow,
            shadows: wiz.elevation.glowAmber,
            radius: border,
          ),
        ),
        surface,
      ],
    );
  }
}
