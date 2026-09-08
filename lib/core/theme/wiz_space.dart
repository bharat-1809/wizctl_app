import 'package:flutter/foundation.dart';

/// Spacing, radii and hardware sizes from `tokens/spacing.css`, plus the
/// layout numbers from the handoff spec (rail, inspector, tab bar).
@immutable
class WizSpace {
  const WizSpace._();

  static const WizSpace standard = WizSpace._();

  final double s1 = 2,
      s2 = 4,
      s3 = 6,
      s4 = 8,
      s5 = 12,
      s6 = 16,
      s7 = 20,
      s8 = 24,
      s9 = 32,
      s10 = 40,
      s11 = 56,
      s12 = 72;

  final double r1 = 6, r2 = 10, r3 = 14, r4 = 20, r5 = 28, r6 = 36;

  /// Large enough to round any control fully.
  final double pill = 999;

  final double controlSm = 36, controlMd = 48, controlLg = 56;

  /// Touch targets never go below this on any platform.
  final double hitMin = 44;

  final double knobSm = 56, knobMd = 96, knobLg = 168;

  /// Recessed slider well thickness.
  final double track = 14;

  final double panelPad = 16, panelPadLg = 20;

  final double gutter = 20, gutterDesktop = 32;

  /// Desktop rail widths: full, on very wide windows, and icon-only.
  final double rail = 264, railWide = 288, railIcon = 72;

  /// Desktop inspector widths: normal and on very wide windows.
  final double inspector = 352, inspectorWide = 400;

  /// Phone tab bar height and how far it floats above the bottom edge.
  final double tabBar = 72, tabBarFloat = 18;

  final double hairline = 1, keyBorder = 1.5;

  /// Keyboard focus ring thickness (spec §11.2, "Focus: 2 px amber ring").
  final double focusRing = 2;
}
