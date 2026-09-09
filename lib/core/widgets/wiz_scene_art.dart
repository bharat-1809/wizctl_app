import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'scene_gradients.dart';
import 'wiz_grain.dart';

/// One radial bloom: its centre and radii as fractions of the box, and the
/// stop where its colour has faded all the way out.
typedef _Bloom = ({double cx, double cy, double rx, double ry, double fade});

/// Procedural scene art from two colours: a top-left highlight, a
/// bottom-right bloom, a diagonal blend and the grain. Every tile is a slot
/// keyed `scene-<id>` so real artwork can replace it later.
class WizSceneArt extends StatelessWidget {
  /// The two colours the art blends, or null for the flat face — the
  /// theme's `char800 → char900`, which only a build can read. A scene id
  /// [sceneGradients] has no entry for wears it: a bulb reports 0 when no
  /// scene is set (`WizLightState.isSceneMode` is `sceneId > 0`) and can
  /// report a rhythm id past the 1000 the library enumerates.
  final Color? from;
  final Color? to;
  final BorderRadius radius;
  final bool sheen;
  final double grainOpacity;
  final Widget? child;

  /// Spec §331: "grain at 85 %".
  static const double grainOpacityDefault = 0.85;

  /// Spec §331: "radial 72 %×58 % at (26 %, 14 %) `from` → transparent 68 %".
  static const _Bloom _fromBloom = (
    cx: 0.26,
    cy: 0.14,
    rx: 0.72,
    ry: 0.58,
    fade: 0.68,
  );

  /// Spec §331: "radial 84 %×70 % at (82 %, 96 %) `to` → transparent 72 %".
  static const _Bloom _toBloom = (
    cx: 0.82,
    cy: 0.96,
    rx: 0.84,
    ry: 0.70,
    fade: 0.72,
  );

  /// The "top-left sheen" of spec §331, whose geometry the spec leaves open.
  /// The reference draws it as
  /// `radial-gradient(58% 44% at 28% 18%, …, transparent 68%)`
  /// (`design/reference/WizCtl_Mobile.dc.html:393`).
  static const _Bloom _sheenBloom = (
    cx: 0.28,
    cy: 0.18,
    rx: 0.58,
    ry: 0.44,
    fade: 0.68,
  );

  /// How opaque the sheen's centre is: `rgba(255,255,255,.30)` in
  /// `design/reference/WizCtl_Mobile.dc.html:393`, taken here from the
  /// theme's `colors.highlightBase` rather than a literal white.
  static const double _sheenAlpha = .30;

  /// Spec §331: "linear 158° `from → to`". A CSS angle is a direction
  /// measured clockwise from straight up, so the gradient axis is
  /// (sin 158°, −cos 158°) = (0.375, 0.927) in screen coordinates, pointing
  /// down and to the right; begin is its negation in Alignment's -1..1 box.
  ///
  /// The *direction* is exact; the *length* is not. CSS sizes its gradient
  /// line so the end stops sit at the corners' projections — 1.302·w on a
  /// square at this angle — whereas these alignments span a chord of 1.0·w,
  /// so the blend runs slightly steeper than CSS between the same two
  /// colours. Both endpoints are the full `from` and `to`, and the blooms
  /// dominate the corners, so the difference is not visible on a tile.
  static const Alignment _blendBegin = Alignment(-0.375, -0.927);
  static const Alignment _blendEnd = Alignment(0.375, 0.927);

  const WizSceneArt({
    super.key,
    required Color this.from,
    required Color this.to,
    required this.radius,
    this.sheen = false,
    this.grainOpacity = grainOpacityDefault,
    this.child,
  });

  /// The art for a built-in WiZ scene, by `WizScene.id`.
  ///
  /// Carries the spec's `scene-<id>` key unless the caller gives its own, so
  /// the slot can be found and swapped for real artwork later (spec §331).
  ///
  /// An id with no art of its own degrades to the flat face rather than
  /// throwing: the id is whatever a bulb reported, which is 0 when nothing
  /// is set and may be a rhythm id past the 1000 the library knows.
  WizSceneArt.scene(
    int id, {
    Key? key,
    required this.radius,
    this.sheen = false,
    this.grainOpacity = grainOpacityDefault,
    this.child,
  }) : from = sceneGradients[id]?.from,
       to = sceneGradients[id]?.to,
       super(key: key ?? ValueKey('scene-$id'));

  @override
  Widget build(BuildContext context) {
    var c = context.wiz.colors;
    // The flat face `ModeRow`'s `FlatModeArt` wears (`:873`
    // `const flat = 'linear-gradient(180deg,#24242A,#16161A)'`, which is
    // `char800 → char900`), read from the theme rather than stated twice.
    var blendFrom = from ?? c.char800;
    var blendTo = to ?? c.char900;
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WizSceneArtPainter(
                blendFrom,
                blendTo,
                sheen ? c.highlightBase : null,
              ),
            ),
          ),
          Positioned.fill(child: WizGrain(opacity: grainOpacity)),
          ?child,
        ],
      ),
    );
  }
}

/// Public only so widget tests can tell the art's own layer apart from the
/// [WizGrain] stacked over it; nothing outside this library may paint with it.
@visibleForTesting
class WizSceneArtPainter extends CustomPainter {
  final Color from;
  final Color to;

  /// The sheen's colour, or null when this art has no sheen.
  final Color? highlight;

  WizSceneArtPainter(this.from, this.to, this.highlight);

  void _bloom(Canvas canvas, Size size, _Bloom at, Color color) {
    canvas.save();
    canvas.translate(size.width * at.cx, size.height * at.cy);
    canvas.scale(size.width * at.rx, size.height * at.ry);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: [0, at.fade],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: WizSceneArt._blendBegin,
          end: WizSceneArt._blendEnd,
          colors: [from, to],
        ).createShader(rect),
    );
    _bloom(canvas, size, WizSceneArt._toBloom, to);
    _bloom(canvas, size, WizSceneArt._fromBloom, from);
    var sheen = highlight;
    if (sheen != null) {
      _bloom(
        canvas,
        size,
        WizSceneArt._sheenBloom,
        sheen.withValues(alpha: WizSceneArt._sheenAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(WizSceneArtPainter old) =>
      old.from != from || old.to != to || old.highlight != highlight;
}
