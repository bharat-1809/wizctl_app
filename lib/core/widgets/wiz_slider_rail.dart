import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_slider_fill.dart';
import 'wiz_surface.dart';

/// The slider's painted rail: the recessed well, the lit fill and the ivory
/// handle. Internal to `WizSlider` — it takes parameters and paints them,
/// and owns no gesture, focus or semantics of its own.
class WizSliderRail extends StatelessWidget {
  /// How far along the range the value sits, 0..1.
  final double pct;

  final WizSliderFill fill;

  /// The width the rail was given: the handle rides it, so it cannot be
  /// read off a constraint here without a second layout pass.
  final double width;

  /// A rail under the finger tracks it exactly; a released one eases.
  final bool dragging;

  const WizSliderRail({
    super.key,
    required this.pct,
    required this.fill,
    required this.width,
    this.dragging = false,
  });

  // Slider.jsx: handle `width/height: 26`, fill `inset: 2`, fill
  // `minWidth: 6`.
  static const double handleSize = 26;
  static const double fillInset = 2;
  static const double fillMin = 6;

  // Slider.jsx handle: `0 3px 6px rgba(0,0,0,.6)` is the shadow it sits in,
  // `inset 0 1px 0 rgba(255,255,255,.95)` the rim the light catches.
  static const double _handleShadowAlpha = .60;
  static const double _handleRimAlpha = .95;

  // Slider.jsx fill on brightness and kelvin: the light it is emitting
  // spills past the rail — `0 0 14px -2px rgba(255,176,32,.45)` (amber-500).
  static const double _glowAlpha = .45;
  static const double _glowBlur = 14;
  static const double _glowSpread = -2;

  /// How tall the rail's box is. The rail itself is thinner than a
  /// fingertip, so the box around it is the full 44 px touch target (spec
  /// §11.2) with the rail and handle centred inside.
  static double heightFor(WizTheme wiz) =>
      math.max(handleSize, math.max(wiz.space.track, wiz.space.hitMin));

  /// The recessed rail itself: Slider.jsx
  /// `linear-gradient(180deg,--char-1000,--char-900)` under `--elev-well`.
  Widget _well(WizTheme wiz, BorderRadius pill, double top) {
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: wiz.space.track,
      child: WizSurface(
        spec: wiz.elevation.well,
        radius: pill,
        gradient: wizVertical(wiz.colors.char1000, wiz.colors.char900),
      ),
    );
  }

  /// The lit part of the rail, inset from it on every side and never
  /// narrower than [fillMin] so a value of zero still reads as a rail with
  /// a beginning.
  Widget _lit(WizTheme wiz, BorderRadius pill, double top) {
    var c = wiz.colors;
    return AnimatedPositioned(
      duration: dragging ? Duration.zero : wiz.motion.release,
      curve: wiz.motion.tactile,
      left: fillInset,
      top: top + fillInset,
      height: wiz.space.track - fillInset * 2,
      width: math.max(fillMin, (width - fillInset * 2) * pct),
      child: DecoratedBox(
        key: const Key('wiz-slider-fill'),
        decoration: BoxDecoration(
          borderRadius: pill,
          gradient: LinearGradient(colors: fill.colors(c)),
          boxShadow: fill.glows
              ? [
                  BoxShadow(
                    color: c.amber500.withValues(alpha: _glowAlpha),
                    blurRadius: _glowBlur,
                    spreadRadius: _glowSpread,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  /// The ivory grip, riding the rail with its centre on the value and
  /// overhanging both ends of it, as Slider.jsx's `marginLeft: -13` does.
  Widget _handle(WizTheme wiz, double top) {
    var c = wiz.colors;
    return AnimatedPositioned(
      duration: dragging ? Duration.zero : wiz.motion.release,
      curve: wiz.motion.tactile,
      left: pct * width - handleSize / 2,
      top: top,
      child: WizSurface(
        spec: WizShadowSpec(
          outer: [
            BoxShadow(
              color: c.shadowBase.withValues(alpha: _handleShadowAlpha),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
          insets: [
            WizInset(
              offsetY: 1,
              blur: 0,
              color: c.highlightBase.withValues(alpha: _handleRimAlpha),
            ),
          ],
        ),
        radius: BorderRadius.circular(handleSize / 2),
        gradient: wizVertical(c.ivoryHi, c.ivoryLo),
        width: handleSize,
        height: handleSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var pill = BorderRadius.circular(wiz.space.pill);
    var boxH = heightFor(wiz);
    var railTop = (boxH - wiz.space.track) / 2;

    return SizedBox(
      height: boxH,
      child: Stack(
        // The handle overhangs both ends of the rail.
        clipBehavior: Clip.none,
        children: [
          _well(wiz, pill, railTop),
          _lit(wiz, pill, railTop),
          _handle(wiz, (boxH - handleSize) / 2),
        ],
      ),
    );
  }
}
