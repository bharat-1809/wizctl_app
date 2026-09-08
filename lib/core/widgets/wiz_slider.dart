import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// The fill gradient differs per purpose (Slider.jsx SLIDER_FILLS), plus a
/// live-colour fill for brightness in colour mode (handoff proposal).
class WizSliderFill {
  final List<Color> Function(WizColors c) colors;

  /// Brightness and kelvin fills carry the amber glow.
  final bool glows;

  const WizSliderFill._(this.colors, this.glows);

  static final WizSliderFill brightness = WizSliderFill._(
    (c) => [c.railDark, c.amber300],
    true,
  );
  static final WizSliderFill kelvin = WizSliderFill._(
    (c) => [
      c.kelvinStops[2200]!,
      c.kelvinStops[3500]!,
      c.kelvinStops[4500]!,
      c.kelvinStops[6500]!,
    ],
    true,
  );
  static final WizSliderFill speed = WizSliderFill._(
    (c) => [c.railDark, c.hueCyan],
    false,
  );
  static final WizSliderFill neutral = WizSliderFill._(
    (c) => [c.railDark, c.railMid],
    false,
  );

  /// A fill in the light's own colour, for brightness while a hue is set.
  factory WizSliderFill.colour(Color color) =>
      WizSliderFill._((_) => [color, color], false);
}

/// Recessed rail with a raised ivory handle. Drag or tap anywhere on the
/// track; a detent fires every twentieth of the range.
class WizSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final WizSliderFill? fill;
  final String? label;
  final String? readout;
  final bool enabled;

  const WizSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    this.onChangeEnd,
    this.fill,
    this.label,
    this.readout,
    this.enabled = true,
  });

  // Slider.jsx: handle `width/height: 26`, fill `inset: 2`, fill
  // `minWidth: 6`, and the twenty notches of `Math.round(p * 20)`.
  static const double handleSize = 26;
  static const double fillInset = 2;
  static const double fillMin = 6;
  static const int detents = 20;

  // Slider.jsx handle: `0 3px 6px rgba(0,0,0,.6)` is the shadow it sits in,
  // `inset 0 1px 0 rgba(255,255,255,.95)` the rim the light catches.
  static const double _handleShadowAlpha = .60;
  static const double _handleRimAlpha = .95;

  // Slider.jsx fill on brightness and kelvin: the light it is emitting
  // spills past the rail — `0 0 14px -2px rgba(255,176,32,.45)` (amber-500).
  static const double _glowAlpha = .45;
  static const double _glowBlur = 14;
  static const double _glowSpread = -2;

  /// Slider.jsx readout: the display face at `fontSize: 20`, between the
  /// kit's two readout sizes.
  static const double _readoutSize = 20;

  @override
  State<WizSlider> createState() => _WizSliderState();
}

class _WizSliderState extends State<WizSlider> {
  /// Owned rather than left to [Focus] so keyboard focus can be driven and
  /// asserted from outside the widget.
  final FocusNode _focusNode = FocusNode(debugLabel: 'WizSlider');

  bool _dragging = false;
  bool _focused = false;
  int? _notch;

  /// The last value [_commit] settled on. `onChangeEnd` reports this rather
  /// than `widget.value`, which is still the old one until whoever owns the
  /// value has rebuilt this widget.
  late double _committed = widget.value;

  /// What the value was when the current touch landed, so a tap that moves
  /// nothing ends no change.
  late double _gestureStart = widget.value;

  double get _pct =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The nearest value on the scale: clamped to the range, snapped to the
  /// nearest whole [WizSlider.step] measured from [WizSlider.min], then
  /// clamped again — a range that is not a whole number of steps would
  /// otherwise round its last step past [WizSlider.max].
  double _snap(double raw) {
    var clamped = raw.clamp(widget.min, widget.max);
    var stepped =
        widget.min +
        ((clamped - widget.min) / widget.step).round() * widget.step;
    return stepped.clamp(widget.min, widget.max);
  }

  /// How assistive technology reads the value out: the caller's own readout
  /// when it has one, else the bare number.
  String _spoken(double value) => widget.readout ?? '${value.round()}';

  /// Snaps [raw] onto the scale, fires the detent if that crossed a notch,
  /// reports the change, and returns what it settled on.
  double _commit(double raw) {
    var next = _snap(raw);
    var notch =
        ((next - widget.min) / (widget.max - widget.min) * WizSlider.detents)
            .round();
    if (notch != _notch) {
      // Null on the first sample of a gesture: landing somewhere is not
      // crossing a notch.
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    if (next != widget.value) widget.onChanged(next);
    _committed = next;
    return next;
  }

  /// The value under a touch [dx] logical pixels along a [width]-wide box.
  double _from(double dx, double width) => _commit(
    widget.min + (dx / width).clamp(0.0, 1.0) * (widget.max - widget.min),
  );

  void _begin(double dx, double width) {
    _notch = null;
    _gestureStart = widget.value;
    context.feedback.play(FeedbackKind.press);
    _from(dx, width);
  }

  /// A touch that never moved the value — a tap on the handle, or a drag
  /// that came home again — changed nothing, so there is no change to end.
  void _end() {
    if (_dragging) setState(() => _dragging = false);
    if (_committed != _gestureStart) widget.onChangeEnd?.call(_committed);
  }

  /// One discrete move — an arrow key or an assistive-technology increment.
  /// Unlike a drag it is over the moment it happens, so it reports the end
  /// of the change itself.
  void _step(double by) => widget.onChangeEnd?.call(_commit(widget.value + by));

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    var k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowRight) {
      _step(widget.step);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowLeft) {
      _step(-widget.step);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The recessed rail itself, centred in the touch box: Slider.jsx
  /// `linear-gradient(180deg,--char-1000,--char-900)` under `--elev-well`.
  Widget _rail(WizTheme wiz, BorderRadius pill, double top) {
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
  /// narrower than [WizSlider.fillMin] so a value of zero still reads as a
  /// rail with a beginning.
  Widget _fill(
    WizTheme wiz,
    BorderRadius pill,
    WizSliderFill fill,
    double top,
    double width,
  ) {
    var c = wiz.colors;
    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : wiz.motion.release,
      curve: wiz.motion.tactile,
      left: WizSlider.fillInset,
      top: top + WizSlider.fillInset,
      height: wiz.space.track - WizSlider.fillInset * 2,
      width: math.max(
        WizSlider.fillMin,
        (width - WizSlider.fillInset * 2) * _pct,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: pill,
          gradient: LinearGradient(colors: fill.colors(c)),
          boxShadow: fill.glows
              ? [
                  BoxShadow(
                    color: c.amber500.withValues(alpha: WizSlider._glowAlpha),
                    blurRadius: WizSlider._glowBlur,
                    spreadRadius: WizSlider._glowSpread,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  /// The ivory grip, riding the rail with its centre on the value and
  /// overhanging both ends of it, as Slider.jsx's `marginLeft: -13` does.
  Widget _handle(WizTheme wiz, double top, double width) {
    var c = wiz.colors;
    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : wiz.motion.release,
      curve: wiz.motion.tactile,
      left: _pct * width - WizSlider.handleSize / 2,
      top: top,
      child: WizSurface(
        spec: WizShadowSpec(
          outer: [
            BoxShadow(
              color: c.shadowBase.withValues(
                alpha: WizSlider._handleShadowAlpha,
              ),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
          insets: [
            WizInset(
              offsetY: 1,
              blur: 0,
              color: c.highlightBase.withValues(
                alpha: WizSlider._handleRimAlpha,
              ),
            ),
          ],
        ),
        radius: BorderRadius.circular(WizSlider.handleSize / 2),
        gradient: wizVertical(c.ivoryHi, c.ivoryLo),
        width: WizSlider.handleSize,
        height: WizSlider.handleSize,
      ),
    );
  }

  /// Label on the left, readout on the right, sharing a baseline.
  Widget _header(WizTheme wiz) {
    var c = wiz.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.label != null)
          Text(
            widget.label!.toUpperCase(),
            style: wiz.typography.label.copyWith(color: c.textTertiary),
          ),
        if (widget.readout != null)
          Text(
            widget.readout!,
            style: wiz.typography.readoutSm.copyWith(
              fontSize: WizSlider._readoutSize,
              color: c.textPrimary,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var fill = widget.fill ?? WizSliderFill.brightness;
    var pill = BorderRadius.circular(wiz.space.pill);
    // The rail is thinner than a fingertip, so what takes the touch is the
    // full 44 px target (spec §11.2) with the rail centred inside it.
    var boxH = math.max(
      WizSlider.handleSize,
      math.max(wiz.space.track, wiz.space.hitMin),
    );
    var railTop = (boxH - wiz.space.track) / 2;
    var armed = widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.readout != null)
          Padding(
            // Slider.jsx column `gap: 10`.
            padding: EdgeInsets.only(bottom: wiz.space.s2 + wiz.space.s3),
            child: _header(wiz),
          ),
        Semantics(
          slider: true,
          label: widget.label,
          value: _spoken(widget.value),
          // A node that offers increase or decrease alongside a value has
          // to say what those actions would read out, or the framework
          // asserts.
          increasedValue: _spoken(_snap(widget.value + widget.step)),
          decreasedValue: _spoken(_snap(widget.value - widget.step)),
          enabled: armed,
          onIncrease: armed ? () => _step(widget.step) : null,
          onDecrease: armed ? () => _step(-widget.step) : null,
          child: Focus(
            focusNode: _focusNode,
            // A disabled slider is not a tab stop and draws no ring.
            canRequestFocus: armed,
            onFocusChange: (v) => setState(() => _focused = v),
            onKeyEvent: _key,
            child: LayoutBuilder(
              builder: (context, constraints) {
                var w = constraints.maxWidth;
                return MouseRegion(
                  cursor: armed
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.forbidden,
                  child: GestureDetector(
                    key: const Key('wiz-slider-track'),
                    behavior: HitTestBehavior.opaque,
                    // The [Semantics] above already offers increase and
                    // decrease. Left to itself the recogniser would add
                    // `tap` and a scroll action per direction, and a
                    // synthetic scroll hands the drag a *global* position,
                    // which this widget reads as a local one and jumps the
                    // value to the end of the rail.
                    excludeFromSemantics: true,
                    // The value follows the finger from where it landed,
                    // not from where the recogniser won the arena.
                    dragStartBehavior: DragStartBehavior.down,
                    // Null while disabled, so no recogniser is built and a
                    // scroll view above keeps every horizontal drag.
                    onTapDown: armed
                        ? (d) => _begin(d.localPosition.dx, w)
                        : null,
                    onTapUp: armed ? (_) => _end() : null,
                    onHorizontalDragStart: armed
                        ? (d) {
                            setState(() => _dragging = true);
                            _begin(d.localPosition.dx, w);
                          }
                        : null,
                    onHorizontalDragUpdate: armed
                        ? (d) => _from(d.localPosition.dx, w)
                        : null,
                    onHorizontalDragEnd: armed ? (_) => _end() : null,
                    onHorizontalDragCancel: armed ? _end : null,
                    child: Opacity(
                      opacity: armed ? 1 : WizColors.disabledAlpha,
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: pill,
                          border: _focused
                              ? Border.all(
                                  color: wiz.colors.focusRing,
                                  width: wiz.space.focusRing,
                                )
                              : null,
                        ),
                        child: SizedBox(
                          height: boxH,
                          child: Stack(
                            // The handle overhangs both ends of the rail.
                            clipBehavior: Clip.none,
                            children: [
                              _rail(wiz, pill, railTop),
                              _fill(wiz, pill, fill, railTop, w),
                              _handle(
                                wiz,
                                (boxH - WizSlider.handleSize) / 2,
                                w,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
