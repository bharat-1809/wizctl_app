import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../motion/reduced_motion.dart';
import '../theme/wiz_theme.dart';
import 'fixture_geometry.dart';
import 'fixture_hero_painter.dart';

/// How a light is drawn on its detail screen: the shape the user told us to
/// show it as, not the protocol's module name (spec §352).
enum WizFixture { bulb, dome, desk, strip, socket }

/// What a light is emitting, spec §5.6. Off is transparent with a barely
/// visible filament; on scales with brightness.
@immutable
class WizEmission {
  final Color color;
  final double alpha;
  final double bloom;
  final double filament;

  const WizEmission({
    required this.color,
    required this.alpha,
    required this.bloom,
    required this.filament,
  });

  /// Spec §5.6: "alpha = 0.30 + brightness/100 × 0.62".
  static const double alphaBase = 0.30;
  static const double alphaSpan = 0.62;

  /// Spec §5.6: "bloom = 0.22 + brightness/100 × 0.58".
  static const double bloomBase = 0.22;
  static const double bloomSpan = 0.58;

  /// Spec §5.6: "soft alpha = alpha × 0.32" — the emission's outer half,
  /// where the glow has already given most of itself up to the glass.
  static const double softFactor = 0.32;

  /// Spec §5.6: a lit filament is fully opaque; an off or unreachable one
  /// drops to "filament opacity 0.06". It is the opacity of the whole
  /// emission layer, not of the filament alone, so at [off] — whose
  /// [alpha] is 0 — what it actually leaves on screen is the mouth's dark
  /// rim at 0.06 of its weight, and no glow at all.
  static const double litFilament = 1;
  static const double offFilament = 0.06;

  /// Off or unreachable (spec §5.6, and
  /// `design/reference/WizCtl_Mobile.dc.html:809`). The colour is
  /// `colors.amber500` written out, because a `const` cannot read the
  /// theme; at [alpha] 0 none of it is painted, and it exists only so a
  /// lerp away from off starts on the right hue.
  static const WizEmission off = WizEmission(
    color: Color(0xFFFFB020),
    alpha: 0,
    bloom: 0,
    filament: offFilament,
  );

  factory WizEmission.lit({required Color color, required int brightness}) {
    var b = brightness.clamp(0, 100) / 100;
    return WizEmission(
      color: color,
      alpha: alphaBase + b * alphaSpan,
      bloom: bloomBase + b * bloomSpan,
      filament: litFilament,
    );
  }

  /// The emission colour at its own alpha, scaled by a layer's opacity.
  ///
  /// The prototype puts that opacity on the element (`opacity:{{
  /// light.emOpacity }}`); here it is folded into the colour instead,
  /// because a `Paint` that carries a gradient may not also carry a colour —
  /// the shader wins and the colour is dead (see `WizTextures.grainPaint`).
  Color em([double opacity = 1]) => color.withValues(alpha: alpha * opacity);

  /// [em]'s soft outer half: spec §5.6's `alpha × 0.32`.
  Color emSoft([double opacity = 1]) =>
      color.withValues(alpha: alpha * softFactor * opacity);

  /// [lerpDouble] rather than `a + (b - a) * t` so that t = 0 and t = 1
  /// return the ends exactly, and a settled tween paints what it was given.
  static WizEmission lerp(WizEmission a, WizEmission b, double t) =>
      WizEmission(
        color: Color.lerp(a.color, b.color, t)!,
        alpha: lerpDouble(a.alpha, b.alpha, t)!,
        bloom: lerpDouble(a.bloom, b.bloom, t)!,
        filament: lerpDouble(a.filament, b.filament, t)!,
      );

  /// Value equality, which [TweenAnimationBuilder] needs: it restarts the
  /// ramp whenever the new `end` differs from the running one, so without
  /// this a parent that rebuilds with an equal-but-new emission would
  /// re-run the 420 ms warm-up on every frame it rebuilds.
  @override
  bool operator ==(Object other) =>
      other is WizEmission &&
      other.color == color &&
      other.alpha == alpha &&
      other.bloom == bloom &&
      other.filament == filament;

  @override
  int get hashCode => Object.hash(color, alpha, bloom, filament);
}

class _EmissionTween extends Tween<WizEmission> {
  _EmissionTween({
    required WizEmission super.begin,
    required WizEmission super.end,
  });

  @override
  WizEmission lerp(double t) => WizEmission.lerp(begin!, end!, t);
}

/// The emission hero: a fixture drawn from the light's "show it as" kind,
/// its glow tracking colour and brightness. Colour changes ramp over 420 ms
/// (the bulb physically warming) and the emission breathes while on.
///
/// Decorative: the screen names the light around it, so the paint carries no
/// semantics of its own.
class FixtureHero extends StatefulWidget {
  final WizFixture fixture;
  final WizEmission emission;

  /// The desktop inspector variant: a 132-tall well with the fixture at 0.6.
  final bool compact;

  const FixtureHero({
    super.key,
    required this.fixture,
    required this.emission,
    this.compact = false,
  });

  @override
  State<FixtureHero> createState() => _FixtureHeroState();
}

class _FixtureHeroState extends State<FixtureHero>
    with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _breathe;

  /// The reference runs the breathe on `var(--ease-tactile)`, so the swell
  /// is eased, not linear.
  CurvedAnimation? _eased;

  /// The platform's "reduce motion" switch, read where the dependency is
  /// registered so that turning it on stops the loop rather than merely
  /// freezing what it paints.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `@keyframes wz-breathe{0%,100%{opacity:.88}50%{opacity:1}}` over 5.5 s
    // (`design/reference/WizCtl_Mobile.dc.html:259`): a controller repeating
    // in reverse plays that midpoint peak at the end of each run, so it
    // takes half the token to get there.
    var motion = context.wiz.motion;
    var halfCycle = motion.breathe ~/ 2;
    _reduced = wizReducedMotion(context);
    var c = _breathe;
    if (c == null) {
      c = _breathe = AnimationController(vsync: this, duration: halfCycle);
      _eased = CurvedAnimation(parent: c, curve: motion.tactile);
    } else {
      c.duration = halfCycle;
    }
    _sync();
  }

  /// Breathes a live light and parks any other at full emission — where a
  /// breath tops out, so switching on picks the swell up rather than
  /// stepping down into it.
  void _sync() {
    var c = _breathe!;
    if (widget.emission.alpha > 0 && !_reduced) {
      if (!c.isAnimating) c.repeat(reverse: true);
    } else if (!c.isCompleted) {
      c.stop();
      c.value = c.upperBound;
    }
  }

  @override
  void didUpdateWidget(FixtureHero old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    // The curve first: it holds a listener on the controller under it.
    _eased?.dispose();
    _breathe?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var motion = wiz.motion;
    var box = widget.compact ? FixtureGeometry.compactBox : FixtureGeometry.box;
    return ExcludeSemantics(
      // The design box scaled uniformly to whatever width the hero is given
      // (spec §352); the painter works in the box's own coordinates.
      child: AspectRatio(
        aspectRatio: box.width / box.height,
        child: TweenAnimationBuilder<WizEmission>(
          tween: _EmissionTween(begin: widget.emission, end: widget.emission),
          duration: motion.light,
          curve: motion.tactile,
          builder: (context, emission, _) => AnimatedBuilder(
            animation: _eased!,
            builder: (context, _) => CustomPaint(
              painter: FixtureHeroPainter(
                fixture: widget.fixture,
                emission: emission,
                breath:
                    motion.breatheMin + (1 - motion.breatheMin) * _eased!.value,
                compact: widget.compact,
                colors: wiz.colors,
                elevation: wiz.elevation,
                space: wiz.space,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
