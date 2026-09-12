import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_motion.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizToggleSize { sm, md }

/// Physical rocker switch: recessed well, glossy ivory cap, amber filament
/// glow when live. The cap slides on the settle curve; it can also be
/// dragged or flicked.
///
/// The switch closing is the event, not the touch: the cue fires on the
/// commit, so a drag that comes home again is silent.
class WizToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final WizToggleSize size;
  final bool enabled;
  final String semanticsLabel;

  const WizToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = WizToggleSize.md,
    this.enabled = true,
    required this.semanticsLabel,
  });

  // Design system Toggle.jsx TOGGLE_S: track width, height, cap diameter.
  static const _geometry = {
    WizToggleSize.sm: (w: 46.0, h: 27.0, k: 21.0),
    WizToggleSize.md: (w: 60.0, h: 33.0, k: 27.0),
  };

  /// Flick faster than this commits regardless of where the cap is.
  static const double flickVelocity = 200;

  // Toggle.jsx lit track:
  // `inset 0 2px 5px rgba(120,60,0,.55), inset 0 -1px 0 rgba(255,255,255,.35),
  //  0 0 16px -3px rgba(255,176,32,.65)`.
  static const double _litGrooveAlpha = .55;
  static const double _litRimAlpha = .35;
  static const double _litGlowAlpha = .65;

  // Toggle.jsx dark track:
  // `inset 0 2px 5px rgba(0,0,0,.7), inset 0 -1px 0 rgba(255,255,255,.07)`.
  static const double _darkGrooveAlpha = .70;
  static const double _darkRimAlpha = .07;

  // Toggle.jsx cap: `0 3px 6px rgba(0,0,0,.55), 0 1px 0 rgba(255,255,255,.4)
  // inset, inset 0 -2px 3px rgba(0,0,0,.18)` — the drop shadow it sits in,
  // the rim the light catches, and the shading under its own belly.
  static const double _capShadowAlpha = .55;
  static const double _capRimAlpha = .40;
  static const double _capUnderAlpha = .18;

  // Toggle.jsx cap: `radial-gradient(circle at 38% 26%,#FFFFFF,#F1EEE8 42%,
  // #C8C4BB 78%,#A8A49B)`. The centre is those percentages in Alignment's
  // -1..1 space (38% → -0.24, 26% → -0.48); the colours are `colors.ivoryCap`.
  static const Alignment _capGradientCentre = Alignment(-0.24, -0.48);
  static const List<double> _capGradientStops = [0, .42, .78, 1];

  /// A CSS radial gradient with no size given is `farthest-corner`, which
  /// from (38%, 26%) of the cap reaches about 0.965 of its width. Flutter
  /// defaults to 0.5, which would compress every stop into the middle.
  static const double _capGradientRadius = 0.965;

  /// Toggle.jsx cap: `transform: down ? 'scale(.93)' : 'scale(1)'`.
  static const double _capPressScale = 0.93;

  /// Toggle.jsx track: `transform: down ? 'scale(.96)' : 'scale(1)'`.
  static const double _bodyPressScale = 0.96;

  @override
  State<WizToggle> createState() => _WizToggleState();
}

class _WizToggleState extends State<WizToggle> {
  /// Where a finger is currently holding the cap, or null when the cap is
  /// parked at whichever end [WizToggle.value] says.
  double? _dragLeft;

  ({double w, double h, double k}) get _g => WizToggle._geometry[widget.size]!;

  /// The gap Toggle.jsx leaves around the cap, on every side.
  double get _pad => (_g.h - _g.k) / 2;
  double get _leftOn => _g.w - _g.k - _pad;
  double get _restLeft => widget.value ? _leftOn : _pad;
  bool get _armed => widget.enabled && widget.onChanged != null;

  void _commit(bool next) {
    if (!_armed || next == widget.value) return;
    context.feedback.play(
      next ? FeedbackKind.toggleOn : FeedbackKind.toggleOff,
    );
    widget.onChanged!(next);
  }

  void _dragStart(DragStartDetails details) =>
      setState(() => _dragLeft = _restLeft);

  void _dragUpdate(DragUpdateDetails details) => setState(() {
    _dragLeft = ((_dragLeft ?? _restLeft) + details.delta.dx).clamp(
      _pad,
      _leftOn,
    );
  });

  void _dragEnd(DragEndDetails details) {
    var velocity = details.primaryVelocity ?? 0;
    var capCentre = (_dragLeft ?? _restLeft) + _g.k / 2;
    // A flick commits the way it was thrown, however far the cap got;
    // anything slower is decided by the half of the track it came to rest in.
    var next = velocity.abs() > WizToggle.flickVelocity
        ? velocity > 0
        : capCentre > _g.w / 2;
    setState(() => _dragLeft = null);
    _commit(next);
  }

  /// Guarded: a recogniser disposed part-way through a rebuild can report a
  /// cancel while the tree is still building, and there is nothing to undo.
  void _dragCancel() {
    if (_dragLeft != null) setState(() => _dragLeft = null);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var g = _g;
    var radius = BorderRadius.circular(wiz.space.pill);

    // The drag wraps the pressable rather than sitting inside its builder,
    // so that it is on the hit-test path for the whole 44-tall hit area
    // while the pressable keeps the focus ring around the track alone. The
    // pressable's own detector is opaque, so `deferToChild` still reaches
    // every pixel of the padded box; the tap and the drag then compete in
    // the arena as they always did, and when the drag wins, the pressable's
    // `onTapCancel` lets its press go.
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      // The pressable owns the semantics node; this only moves the cap.
      excludeFromSemantics: true,
      onHorizontalDragStart: _armed ? _dragStart : null,
      onHorizontalDragUpdate: _armed ? _dragUpdate : null,
      onHorizontalDragEnd: _armed ? _dragEnd : null,
      onHorizontalDragCancel: _armed ? _dragCancel : null,
      child: WizPressable(
        onTap: () => _commit(!widget.value),
        enabled: _armed,
        semanticsLabel: widget.semanticsLabel,
        toggled: widget.value,
        // The press recipe supplies focus, keyboard activation, hover and the
        // disabled cursor; the rocker's own body scale replaces its sink, and
        // the cue waits for the commit rather than firing on the touch.
        scale: 1,
        travel: 0,
        feedback: null,
        // A drag on the cap must be able to take the gesture off the tap.
        arenaResolved: true,
        // The ring traces the pill, not a rounded box around it.
        focusRadius: radius,
        // The track stays 27 or 33 tall; the hit area is padded out to the 44
        // minimum (spec §14), with the ring inside it, around the track.
        hitPadding: EdgeInsets.symmetric(
          vertical: (wiz.space.hitMin - g.h).clamp(0, wiz.space.hitMin) / 2,
        ),
        builder: (context, state) {
          // A drag holds the rocker down after the tap it grew out of was
          // rejected in the arena and the pressable let its own press go.
          var down = state.pressed || _dragLeft != null;
          return AnimatedScale(
            scale: down ? WizToggle._bodyPressScale : 1,
            duration: wiz.motion.release,
            curve: wiz.motion.settle,
            child: SizedBox(
              width: g.w,
              height: g.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      // The gradient and the shadows both change with the
                      // state, and neither interpolates: cross-fade instead.
                      duration: wiz.motion.ui,
                      switchInCurve: wiz.motion.tactile,
                      switchOutCurve: wiz.motion.tactile,
                      child: _track(wiz.colors, radius),
                    ),
                  ),
                  AnimatedPositioned(
                    // A dragged cap tracks the finger; a released one slides.
                    duration: _dragLeft == null
                        ? wiz.motion.panel
                        : Duration.zero,
                    curve: wiz.motion.settle,
                    left: _dragLeft ?? _restLeft,
                    top: _pad,
                    child: _cap(wiz.colors, wiz.motion, down),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The well the cap rides in: charcoal and recessed when dark, hot metal
  /// with a filament glow when live.
  ///
  /// The shadow numbers are Toggle.jsx's `box-shadow` transcribed: the inset
  /// offsets and blurs are its `inset 0 2px 5px` and `inset 0 -1px 0`, and
  /// the glow is its `0 0 16px -3px` (blur 16, spread -3) in amber.
  Widget _track(WizColors c, BorderRadius radius) {
    var on = widget.value;
    return WizSurface(
      // Identity, so the switcher cross-fades on the state rather than
      // rebuilding one surface whose paint would jump.
      key: ValueKey(on),
      spec: on
          ? WizShadowSpec(
              insets: [
                WizInset(
                  offsetY: 2,
                  blur: 5,
                  color: c.shadowAmber.withValues(
                    alpha: WizToggle._litGrooveAlpha,
                  ),
                ),
                WizInset(
                  offsetY: -1,
                  blur: 0,
                  color: c.highlightBase.withValues(
                    alpha: WizToggle._litRimAlpha,
                  ),
                ),
              ],
              outer: [
                BoxShadow(
                  color: c.amber500.withValues(alpha: WizToggle._litGlowAlpha),
                  blurRadius: 16,
                  spreadRadius: -3,
                ),
              ],
            )
          : WizShadowSpec(
              insets: [
                WizInset(
                  offsetY: 2,
                  blur: 5,
                  color: c.shadowBase.withValues(
                    alpha: WizToggle._darkGrooveAlpha,
                  ),
                ),
                WizInset(
                  offsetY: -1,
                  blur: 0,
                  color: c.highlightBase.withValues(
                    alpha: WizToggle._darkRimAlpha,
                  ),
                ),
              ],
            ),
      radius: radius,
      // Toggle.jsx track gradient.
      gradient: on
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.amber600, c.amber400, c.amber500],
              stops: const [0, .62, 1],
            )
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.char1000, c.char800],
            ),
      // The switcher lays its children out loosely, so the track has to
      // carry its own size rather than stretch to the stack.
      width: _g.w,
      height: _g.h,
    );
  }

  /// The glossy ivory cap, lit from the top left like everything else.
  ///
  /// A [WizSurface] rather than a [DecoratedBox]: two of Toggle.jsx's three
  /// cap shadows are inset, which [BoxDecoration.boxShadow] cannot paint.
  Widget _cap(WizColors c, WizMotion m, bool down) {
    return AnimatedScale(
      scale: down ? WizToggle._capPressScale : 1,
      duration: m.release,
      curve: m.settle,
      child: WizSurface(
        // Toggle.jsx cap `box-shadow`, transcribed: `0 3px 6px` outside,
        // then `0 1px 0` inset and `inset 0 -2px 3px`.
        spec: WizShadowSpec(
          outer: [
            BoxShadow(
              color: c.shadowBase.withValues(alpha: WizToggle._capShadowAlpha),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
          insets: [
            WizInset(
              offsetY: 1,
              blur: 0,
              color: c.highlightBase.withValues(alpha: WizToggle._capRimAlpha),
            ),
            WizInset(
              offsetY: -2,
              blur: 3,
              color: c.shadowBase.withValues(alpha: WizToggle._capUnderAlpha),
            ),
          ],
        ),
        radius: BorderRadius.circular(_g.k / 2),
        gradient: RadialGradient(
          center: WizToggle._capGradientCentre,
          radius: WizToggle._capGradientRadius,
          colors: c.ivoryCap,
          stops: WizToggle._capGradientStops,
        ),
        width: _g.k,
        height: _g.k,
      ),
    );
  }
}
