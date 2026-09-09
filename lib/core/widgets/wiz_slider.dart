import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_theme.dart';
import 'wiz_slider_fill.dart';
import 'wiz_slider_rail.dart';

export 'wiz_slider_fill.dart' show WizSliderFill;

/// Recessed rail with a raised ivory handle. Drag or tap anywhere on the
/// track; a detent fires every twentieth of the range.
///
/// The rail is painted by [WizSliderRail]; everything here is the gesture,
/// the keyboard, the focus ring, the semantics and the header.
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

  /// Notches across the range; each crossing fires a detent: Slider.jsx
  /// `Math.round(p * 20)`.
  static const int detents = 20;

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

  /// Whether the touch now down has already opened a change. The tap
  /// recogniser fires `onTapDown` at its deadline even when it goes on to
  /// lose the arena to the drag, so without this a slow drag would open the
  /// gesture twice — playing `press` twice, and re-baselining what the
  /// change is measured against onto a value the tap-down had already
  /// committed. Cleared by the [Listener] on pointer down rather than by
  /// `onTapCancel`, which the arena fires *before* it accepts the winner.
  bool _begun = false;

  int? _notch;

  /// The last value [_commit] settled on. `onChangeEnd` reports this rather
  /// than `widget.value`, which is still the old one until whoever owns the
  /// value has rebuilt this widget.
  late double _committed = widget.value;

  /// What the value was when the current touch landed, so a tap that moves
  /// nothing ends no change.
  late double _gestureStart = widget.value;

  /// Zero when the range is empty, rather than the NaN that dividing by it
  /// would put into every offset this drives.
  double get _pct => widget.max > widget.min
      ? ((widget.value - widget.min) / (widget.max - widget.min)).clamp(
          0.0,
          1.0,
        )
      : 0;

  @override
  void initState() {
    super.initState();
    // Seeded, not left null: a keyboard step is a notch crossing like any
    // other, so the first one sounds like the second. Only the pointer path
    // starts silent, where the touch landing is not itself a crossing.
    _notch = _notchOf(widget.value);
  }

  @override
  void didUpdateWidget(WizSlider old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _notch = _notchOf(widget.value);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Which of the [WizSlider.detents] notches [value] sits in, or null when
  /// the range is empty and there are no notches to sit in.
  int? _notchOf(double value) {
    if (widget.max <= widget.min) return null;
    return ((value - widget.min) /
            (widget.max - widget.min) *
            WizSlider.detents)
        .round();
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

  /// The bare number, which is what assistive technology reads when it asks
  /// what a step would do.
  String _number(double value) => '${value.round()}';

  /// Snaps [raw] onto the scale, fires the detent if that crossed a notch,
  /// reports the change, and returns what it settled on.
  double _commit(double raw) {
    var next = _snap(raw);
    var notch = _notchOf(next);
    if (notch != null && notch != _notch) {
      // Null on the first sample of a touch: landing somewhere is not
      // crossing a notch.
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    // Against both, since two samples in one frame can settle on the same
    // value before the owner has rebuilt this widget with the first.
    if (next != widget.value && next != _committed) widget.onChanged(next);
    _committed = next;
    return next;
  }

  /// The value under a touch [dx] logical pixels along a [width]-wide box.
  double _from(double dx, double width) => _commit(
    widget.min + (dx / width).clamp(0.0, 1.0) * (widget.max - widget.min),
  );

  /// Opens a change under the finger. Runs once per pointer sequence: a
  /// second call, from the drag recogniser after the tap recogniser's, is
  /// just another sample of the same touch.
  void _begin(double dx, double width) {
    if (_begun) {
      _from(dx, width);
      return;
    }
    _begun = true;
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
  /// of the change itself — unless it had nowhere left to go.
  void _step(double by) {
    var next = _commit(widget.value + by);
    if (next != widget.value) widget.onChangeEnd?.call(next);
  }

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

  /// The rail and everything that takes a touch on it, [w] wide.
  Widget _control(WizTheme wiz, double w) {
    var armed = widget.enabled;
    return MouseRegion(
      cursor: armed ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: Listener(
        // Every recogniser below sees this pointer first, so a fresh touch
        // is a fresh change however the arena resolves afterwards.
        onPointerDown: (_) => _begun = false,
        child: GestureDetector(
          key: const Key('wiz-slider-track'),
          behavior: HitTestBehavior.opaque,
          // The [Semantics] above already offers increase and decrease.
          // Left to itself the recogniser would add `tap` and a scroll
          // action per direction, and a synthetic scroll hands the drag a
          // *global* position, which this widget reads as a local one and
          // jumps the value to the end of the rail.
          excludeFromSemantics: true,
          // The value follows the finger from where it landed, not from
          // where the recogniser won the arena.
          dragStartBehavior: DragStartBehavior.down,
          // Null while disabled, so no recogniser is built and a scroll
          // view above keeps every horizontal drag.
          onTapDown: armed ? (d) => _begin(d.localPosition.dx, w) : null,
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
                borderRadius: BorderRadius.circular(wiz.space.pill),
                border: _focused
                    ? Border.all(
                        color: wiz.colors.focusRing,
                        width: wiz.space.focusRing,
                      )
                    : null,
              ),
              child: WizSliderRail(
                pct: _pct,
                fill: widget.fill ?? WizSliderFill.brightness,
                width: w,
                dragging: _dragging,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
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
          value: widget.readout ?? _number(widget.value),
          // A node that offers increase or decrease alongside a value has
          // to say what those actions would read out, or the framework
          // asserts. Always the bare number: a caller's readout is one
          // fixed string, so all three would otherwise read alike.
          increasedValue: _number(_snap(widget.value + widget.step)),
          decreasedValue: _number(_snap(widget.value - widget.step)),
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
              builder: (context, constraints) =>
                  _control(wiz, constraints.maxWidth),
            ),
          ),
        ),
      ],
    );
  }
}
