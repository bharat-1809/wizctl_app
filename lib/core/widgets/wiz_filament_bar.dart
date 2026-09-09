import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_filament_painter.dart';
import 'wiz_surface.dart';

/// The house loader: a tungsten filament heating along a recessed wire.
///
/// Indeterminate by default — a hot spot travels the wire; pass [value] for
/// a determinate fill. Current flowing, not a web spinner.
class WizFilamentBar extends StatefulWidget {
  /// How far along, 0..1, or null for the travelling hot spot.
  final double? value;

  /// Optional caption above the wire, uppercased by the bar.
  final String? label;

  final double thickness;

  const WizFilamentBar({
    super.key,
    this.value,
    this.label,
    this.thickness = defaultThickness,
  });

  /// FilamentBar.jsx `thickness = 6` (spec §11.2, "6 tall well").
  static const double defaultThickness = 6;

  /// What the lit length spills: FilamentBar.jsx
  /// `0 0 14px -1px rgba(255,176,32,.7)` — amber-500 at .7.
  static const double fillGlowAlpha = .7;
  static const double fillGlowBlur = 14;
  static const double fillGlowSpread = -1;

  /// The travelling hot spot: FilamentBar.jsx `width: '38%'` and
  /// `@keyframes wz-filament{0%{transform:translateX(-105%)}
  /// 100%{transform:translateX(205%)}}` (spec §11.2, "38 % hot spot
  /// travelling −105 % → 205 %").
  static const double hotWidth = .38;
  static const double travelFrom = -1.05;
  static const double travelTo = 2.05;

  /// What it spills: FilamentBar.jsx `0 0 16px 0 rgba(255,176,32,.55)`.
  static const double hotGlowAlpha = .55;
  static const double hotGlowBlur = 16;

  /// The heat pulse: FilamentBar.jsx `@keyframes wz-filament-heat
  /// {0%,100%{opacity:.62}50%{opacity:1}}` (spec §11.2, "with a heat
  /// pulse").
  static const double heatBase = .62;
  static const double heatSwing = .38;

  /// Where reduced motion parks the hot spot, as a fraction of that travel:
  /// halfway, so it lies across the middle of the wire.
  static const double parkedT = .5;

  @override
  State<WizFilamentBar> createState() => _WizFilamentBarState();
}

class _WizFilamentBarState extends State<WizFilamentBar>
    with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _run;

  /// The platform's "reduce motion" switch, read where the dependency is
  /// registered so that turning it on stops the loop rather than merely
  /// freezing what it paints.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var motion = context.wiz.motion;
    _reduced = MediaQuery.disableAnimationsOf(context);
    var run = _run;
    if (run == null) {
      run = _run = AnimationController(vsync: this, duration: motion.filament);
    } else {
      run.duration = motion.filament;
    }
    _sync();
  }

  /// Only an indeterminate wire loops: a determinate one eases its width to
  /// each new value and then stands still, so it settles.
  void _sync() {
    var run = _run!;
    if (widget.value == null && !_reduced) {
      if (!run.isAnimating) run.repeat();
    } else if (run.isAnimating) {
      run.stop();
    }
  }

  @override
  void didUpdateWidget(WizFilamentBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _run?.dispose();
    super.dispose();
  }

  String _percent(double pct) => '${(pct * 100).round()}%';

  /// FilamentBar.jsx's caption row: the label uppercased in the caption
  /// token, the percentage in mono beside it (`gap: 12`), the pair sitting
  /// `gap: 8` above the wire.
  Widget _caption(WizTheme wiz, double? pct) {
    var c = wiz.colors;
    var t = wiz.typography;
    return Padding(
      padding: EdgeInsets.only(bottom: wiz.space.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label!.toUpperCase(),
              style: t.caption.copyWith(color: c.textTertiary),
            ),
          ),
          if (pct != null) ...[
            SizedBox(width: wiz.space.s5),
            // The mono face at the caption's size, not `code`: the JSX span
            // is `var(--font-mono)` inheriting `--type-caption-size` with
            // `letterSpacing: 0`, which is what `mono` is.
            Text(_percent(pct), style: t.mono.copyWith(color: c.textTertiary)),
          ],
        ],
      ),
    );
  }

  /// The recessed wire: FilamentBar.jsx
  /// `linear-gradient(180deg,--char-1000,--char-900)` under `--elev-well`,
  /// rounded to a pill, clipping whatever runs along it.
  Widget _track(WizTheme wiz, double width, double? pct) {
    var c = wiz.colors;
    return SizedBox(
      key: const Key('wiz-filament-track'),
      height: widget.thickness,
      child: WizSurface(
        spec: wiz.elevation.well,
        radius: BorderRadius.circular(wiz.space.pill),
        gradient: wizVertical(c.char1000, c.char900),
        child: CustomPaint(
          painter: WizFilamentTicks(
            c.highlightBase.withValues(alpha: WizFilamentTicks.alpha),
          ),
          child: Stack(
            children: [pct == null ? _hot(wiz, width) : _fill(wiz, width, pct)],
          ),
        ),
      ),
    );
  }

  /// The lit length of wire, easing to each new width over `--dur-light`.
  Widget _fill(WizTheme wiz, double width, double pct) {
    var c = wiz.colors;
    return AnimatedPositioned(
      key: const Key('wiz-filament-fill'),
      duration: wiz.motion.light,
      curve: wiz.motion.tactile,
      left: 0,
      top: 0,
      bottom: 0,
      width: pct * width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(wiz.space.pill),
          gradient: LinearGradient(colors: [c.amber700, c.amber300]),
          boxShadow: [
            BoxShadow(
              color: c.amber500.withValues(alpha: WizFilamentBar.fillGlowAlpha),
              blurRadius: WizFilamentBar.fillGlowBlur,
              spreadRadius: WizFilamentBar.fillGlowSpread,
            ),
          ],
        ),
      ),
    );
  }

  /// The hot spot travelling the wire. It fades out at both ends, so the
  /// span reads as heat moving through metal rather than a block sliding.
  Widget _hot(WizTheme wiz, double width) {
    var c = wiz.colors;
    var hot = width * WizFilamentBar.hotWidth;
    return AnimatedBuilder(
      animation: _run!,
      // Hoisted out of the builder: only the position and the heat change.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(wiz.space.pill),
          gradient: LinearGradient(
            colors: [
              c.amber500.withValues(alpha: 0),
              c.amber300,
              c.amber500.withValues(alpha: 0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: c.amber500.withValues(alpha: WizFilamentBar.hotGlowAlpha),
              blurRadius: WizFilamentBar.hotGlowBlur,
            ),
          ],
        ),
      ),
      builder: (context, child) {
        // Reduced motion parks the run halfway along its travel, at the top
        // of the heat pulse: a still filament that still reads as hot.
        var travel = WizFilamentBar.parkedT;
        var heat = WizFilamentBar.heatBase + WizFilamentBar.heatSwing;
        if (!_reduced) {
          var t = _run!.value;
          // FilamentBar.jsx runs `wz-filament` on `var(--ease-tactile)`:
          // the hot spot leaves fast and coasts in.
          travel = wiz.motion.tactile.transform(t);
          // The raised cosine is the JSX's ease-in-out 0 / 50 / 100 heat
          // ramp written as maths: 0 at both ends of the run, 1 in the
          // middle. No `WizMotion` curve describes a round trip like it.
          var pulse = (1 - math.cos(2 * math.pi * t)) / 2;
          heat = WizFilamentBar.heatBase + WizFilamentBar.heatSwing * pulse;
        }
        var span = WizFilamentBar.travelTo - WizFilamentBar.travelFrom;
        return Positioned(
          key: const Key('wiz-filament-hot'),
          left: hot * (WizFilamentBar.travelFrom + span * travel),
          top: 0,
          bottom: 0,
          width: hot,
          child: Opacity(opacity: heat, child: child!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    // `num.clamp` widens to `num`, and nothing downstream takes one.
    var pct = widget.value?.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) _caption(wiz, pct),
        Semantics(
          label: widget.label,
          value: pct == null ? null : _percent(pct),
          // The hot spot is measured in fractions of the wire, so the wire
          // has to have been measured first.
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _track(wiz, constraints.maxWidth, pct),
          ),
        ),
      ],
    );
  }
}
