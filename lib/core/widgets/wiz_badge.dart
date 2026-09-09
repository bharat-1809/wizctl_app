import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

enum WizBadgeTone { neutral, accent, online, danger }

/// Small engraved status pill: reachability, bulb class, scene state. The
/// dot breathes for live tones only; it is the only looping animation apart
/// from a powered light's emission.
class WizBadge extends StatelessWidget {
  final String label;
  final WizBadgeTone tone;
  final bool dot;

  const WizBadge({
    super.key,
    required this.label,
    this.tone = WizBadgeTone.neutral,
    this.dot = false,
  });

  /// Badge.jsx `height: 22` (spec §11.2, "22 tall pill").
  static const double height = 22;

  /// Badge.jsx `width: 6, height: 6` on the dot, and its `0 0 8px` glow.
  static const double dotSize = 6;
  static const double dotGlowBlur = 8;

  /// The engraved well the pill sits in: Badge.jsx
  /// `background: 'rgba(0,0,0,.35)'` (spec §11.2, "black 35 % well").
  static const double scrimAlpha = 0.35;

  /// The label runs semibold against the caption token's 400
  /// (Badge.jsx `fontWeight: 600`).
  static const FontWeight labelWeight = FontWeight.w600;

  /// How far the live dot dips at the middle of its pulse: Badge.jsx
  /// `@keyframes wz-pulse{0%,100%{opacity:1;transform:scale(1)}
  /// 50%{opacity:.4;transform:scale(.72)}}`.
  static const double pulseOpacityDip = 0.6;
  static const double pulseScaleDip = 0.28;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var (fg, dotColor) = switch (tone) {
      WizBadgeTone.neutral => (c.textTertiary, c.signalOffline),
      WizBadgeTone.accent => (c.amber400, c.amber500),
      WizBadgeTone.online => (c.signalOnline, c.signalOnline),
      WizBadgeTone.danger => (c.signalDanger, c.signalDanger),
    };
    // Badge.jsx: only a toned dot is live, a neutral one is just engraved.
    var live = dot && tone != WizBadgeTone.neutral;
    return WizSurface(
      spec: wiz.elevation.well,
      radius: BorderRadius.circular(wiz.space.pill),
      color: c.shadowBase.withValues(alpha: scrimAlpha),
      height: height,
      // Badge.jsx `padding: '0 9px'`: 8 plus the 1 that half the 2 px `s1`
      // step gives. No `alignment`: like a `WizChip`, a badge must hug its
      // label rather than fill the width it is offered.
      padding: EdgeInsets.symmetric(
        horizontal: wiz.space.s4 + wiz.space.s1 / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            _Dot(color: dotColor, live: live),
            // Badge.jsx `gap: 6`.
            SizedBox(width: wiz.space.s3),
          ],
          Text(
            label.toUpperCase(),
            style: wiz.typography.caption.copyWith(
              fontWeight: labelWeight,
              color: fg,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool live;

  const _Dot({required this.color, required this.live});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _pulse;

  /// What the paint reads: Badge.jsx runs `wz-pulse` on
  /// `var(--ease-tactile)`, so the dip is eased, not linear.
  CurvedAnimation? _eased;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Badge.jsx runs `wz-pulse` for 2.2 s — the `ping` token — over a whole
    // round trip, whose midpoint is the keyframe at 50 %. A controller
    // repeating in reverse plays that midpoint at the end of each run, so
    // it takes half the token to get there.
    var motion = context.wiz.motion;
    var halfCycle = motion.ping ~/ 2;
    var pulse = _pulse;
    if (pulse == null) {
      pulse = _pulse = AnimationController(vsync: this, duration: halfCycle);
      _eased = CurvedAnimation(parent: pulse, curve: motion.tactile);
    } else {
      pulse.duration = halfCycle;
    }
    _sync();
  }

  /// Runs the pulse for a live dot and parks a still one at rest.
  void _sync() {
    var pulse = _pulse!;
    if (widget.live) {
      if (!pulse.isAnimating) pulse.repeat(reverse: true);
    } else if (pulse.isAnimating) {
      pulse.stop();
    }
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    // The curve first: it holds a listener on the controller under it.
    _eased?.dispose();
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _eased!,
      builder: (context, _) {
        var t = (widget.live && !reduced) ? _eased!.value : 0.0;
        return Opacity(
          opacity: 1 - WizBadge.pulseOpacityDip * t,
          child: Transform.scale(
            scale: 1 - WizBadge.pulseScaleDip * t,
            child: Container(
              width: WizBadge.dotSize,
              height: WizBadge.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: widget.live
                    ? [
                        BoxShadow(
                          color: widget.color,
                          blurRadius: WizBadge.dotGlowBlur,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
