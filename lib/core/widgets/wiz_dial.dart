import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_theme.dart';
import 'wiz_dial_disc.dart';
import 'wiz_dial_painter.dart';

/// Rotary knob. Drag vertically (or use arrow keys) to change the value.
/// Machined bezel, knurled rim, engraved index mark, amber sweep arc. The
/// readout snaps; only the knob and the arc glow ease.
///
/// The face is drawn by [WizDialDisc]; everything here is the gesture, the
/// keyboard, the focus ring, the semantics and the label.
class WizDial extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final String unit;
  final double size;
  final bool enabled;

  const WizDial({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    this.onChangeEnd,
    this.label,
    this.unit = '%',
    required this.size,
    this.enabled = true,
  });

  /// The diameters the design draws a knob at. 168 is Dial.jsx's own
  /// `size = 168` (the kit's `space.knobLg`); 56 is `space.knobSm`, the
  /// smallest knob in the spec's hardware sizes. A caller asking for
  /// anything outside gets the nearest dial the design actually has, so a
  /// layout cannot invent a knob the chassis has no part for.
  static const double minSize = 56;
  static const double maxSize = 168;

  @override
  State<WizDial> createState() => _WizDialState();
}

class _WizDialState extends State<WizDial> {
  /// Owned rather than left to [Focus] so keyboard focus can be driven and
  /// asserted from outside the widget.
  final FocusNode _focusNode = FocusNode(debugLabel: 'WizDial');

  double? _dragStartY;
  double _dragStartValue = 0;

  /// The last value [_commit] settled on. `onChangeEnd` reports this rather
  /// than `widget.value`, which is still the old one until whoever owns the
  /// value has rebuilt this widget.
  double _committed = 0;

  int? _notch;
  bool _down = false;
  bool _focused = false;

  double get _pct =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  /// How far one arrow key, or one assistive-technology increment, moves.
  double get _keyDelta => widget.step * WizDialGeometry.keySteps;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The nearest value on the scale: clamped to the range, snapped to the
  /// nearest whole [WizDial.step] measured from [WizDial.min], then clamped
  /// again — when the range is not a whole number of steps, the last step
  /// rounds up past [WizDial.max] (0..100 by 8 would land on 104).
  double _snap(double raw) {
    var clamped = raw.clamp(widget.min, widget.max);
    var stepped =
        ((clamped - widget.min) / widget.step).round() * widget.step +
        widget.min;
    return stepped.clamp(widget.min, widget.max);
  }

  /// How assistive technology reads a value out, e.g. `50%`.
  String _spoken(double value) => '${value.round()}${widget.unit}';

  double _commit(double raw) {
    var next = _snap(raw);
    var notch =
        ((next - widget.min) /
                (widget.max - widget.min) *
                WizDialGeometry.detents)
            .round();
    if (notch != _notch) {
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    if (next != widget.value) widget.onChanged(next);
    _committed = next;
    return next;
  }

  /// One discrete move — an arrow key or an assistive-technology increment.
  /// Unlike a drag it is over the moment it happens, so it reports the end
  /// of the change itself.
  void _step(double by) => widget.onChangeEnd?.call(_commit(widget.value + by));

  void _start(DragStartDetails d) {
    _dragStartY = d.localPosition.dy;
    _dragStartValue = widget.value;
    _committed = widget.value;
    _notch = (_pct * WizDialGeometry.detents).round();
    setState(() => _down = true);
    context.feedback.play(FeedbackKind.press);
  }

  void _update(DragUpdateDetails d) {
    var startY = _dragStartY;
    if (startY == null) return;
    var range = widget.max - widget.min;
    _commit(
      _dragStartValue +
          (startY - d.localPosition.dy) / WizDialGeometry.dragTravel * range,
    );
  }

  void _end() {
    if (_dragStartY == null) return;
    _dragStartY = null;
    setState(() => _down = false);
    // A touch that never moved the dial — a tap, or a drag that came home
    // again — changed nothing, so there is no change to have ended.
    if (_committed != _dragStartValue) widget.onChangeEnd?.call(_committed);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    var k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
      _step(_keyDelta);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.arrowLeft) {
      _step(-_keyDelta);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var d = widget.size.clamp(WizDial.minSize, WizDial.maxSize);
    var armed = widget.enabled;

    // The ring's box is always here, carrying a border only while focused,
    // the way `WizSlider`'s does: a wrapper that comes and goes changes the
    // child at the slot above it and costs the disc its element, and with it
    // any gesture that was running when focus arrived.
    Widget visual = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(d),
        border: _focused
            ? Border.all(color: c.focusRing, width: wiz.space.focusRing)
            : null,
      ),
      child: WizDialDisc(
        diameter: d,
        pct: _pct,
        value: widget.value,
        unit: widget.unit,
        dragging: _dragStartY != null,
      ),
    );

    return SizedBox(
      // The dial is exactly as wide as it is told, whatever its label reads.
      width: d,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            slider: true,
            label: widget.label,
            value: _spoken(widget.value),
            // A node that offers increase or decrease alongside a value has
            // to say what those actions would read out, or the framework
            // asserts.
            increasedValue: _spoken(_snap(widget.value + _keyDelta)),
            decreasedValue: _spoken(_snap(widget.value - _keyDelta)),
            enabled: armed,
            onIncrease: armed ? () => _step(_keyDelta) : null,
            onDecrease: armed ? () => _step(-_keyDelta) : null,
            child: Focus(
              focusNode: _focusNode,
              // A disabled dial is not a tab stop and draws no ring.
              canRequestFocus: armed,
              onFocusChange: (v) => setState(() => _focused = v),
              onKeyEvent: _key,
              child: MouseRegion(
                cursor: armed
                    ? SystemMouseCursors.resizeUpDown
                    : SystemMouseCursors.forbidden,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // The drag starts where the finger landed, not where the
                  // recogniser won the arena, so the 160 px that cover the
                  // range are 160 px of finger rather than 160 plus however
                  // much slop the gesture cost.
                  dragStartBehavior: DragStartBehavior.down,
                  // Null while disabled, so no recogniser is built and a
                  // scroll view above keeps every vertical drag.
                  onVerticalDragStart: armed ? _start : null,
                  onVerticalDragUpdate: armed ? _update : null,
                  onVerticalDragEnd: armed ? (_) => _end() : null,
                  onVerticalDragCancel: armed ? _end : null,
                  child: Opacity(
                    opacity: armed ? 1 : WizColors.disabledAlpha,
                    child: AnimatedScale(
                      scale: _down ? m.pressScale : 1,
                      duration: m.release,
                      curve: m.settle,
                      child: visual,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.label != null) ...[
            // Dial.jsx column `gap: 10`.
            SizedBox(height: wiz.space.s2 + wiz.space.s3),
            // The knob's node above already carries the label and the value;
            // the caption is the same word drawn, and announcing it too
            // would read the dial twice.
            ExcludeSemantics(
              child: Text(
                widget.label!.toUpperCase(),
                style: wiz.typography.label.copyWith(color: c.textTertiary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
