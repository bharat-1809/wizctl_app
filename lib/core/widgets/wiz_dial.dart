import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_dial_painter.dart';
import 'wiz_surface.dart';

/// Rotary knob. Drag vertically (or use arrow keys) to change the value.
/// Machined bezel, knurled rim, engraved index mark, amber sweep arc. The
/// readout snaps; only the knob and the arc glow ease.
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

  /// Dial.jsx disc: `filter: drop-shadow(0 0 12px rgba(255,176,32,.28))` —
  /// amber-500 at .28, blurred 12.
  static const double _arcGlowAlpha = .28;
  static const double _arcGlowBlur = 12;

  /// Dial.jsx index mark: `border-radius: 2` and
  /// `box-shadow: 0 0 10px rgba(255,194,77,.9)` — amber-400 at .9, blur 10.
  static const double _markRadius = 2;
  static const double _markGlowAlpha = .9;
  static const double _markGlowBlur = 10;

  /// Dial.jsx readout: `letterSpacing: '.01em'`, i.e. this fraction of
  /// whichever font size the span it sits in is set at.
  static const double _readoutTracking = 0.01;

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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The nearest value on the scale: clamped to the range, then snapped to
  /// the nearest whole [WizDial.step] measured from [WizDial.min].
  double _snap(double raw) {
    var clamped = raw.clamp(widget.min, widget.max);
    return ((clamped - widget.min) / widget.step).round() * widget.step +
        widget.min;
  }

  /// How far one arrow key, or one assistive-technology increment, moves.
  double get _keyDelta => widget.step * WizDialGeometry.keySteps;

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

  void _start(DragStartDetails d) {
    if (!widget.enabled) return;
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
    widget.onChangeEnd?.call(_committed);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    var k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
      widget.onChangeEnd?.call(_commit(widget.value + _keyDelta));
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.arrowLeft) {
      widget.onChangeEnd?.call(_commit(widget.value - _keyDelta));
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
    var pct = _pct;
    var angle = WizDialGeometry.angleFor(pct);
    var knobInset = d * WizDialGeometry.knobInset;
    var wellInset = d * WizDialGeometry.wellInset;
    var knobSize = d - knobInset * 2;
    var circle = BorderRadius.circular(d);

    var disc = SizedBox(
      width: d,
      height: d,
      child: Stack(
        children: [
          // Sweep arc and its glow
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: pct > 0 ? 1 : 0,
              duration: m.ui,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.amber500.withValues(
                        alpha: WizDial._arcGlowAlpha,
                      ),
                      blurRadius: WizDial._arcGlowBlur,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WizDialArcPainter(
                pct: pct,
                amber600: c.amber600,
                amber400: c.amber400,
                amber500: c.amber500,
                dead: c.char1000,
                insets: wiz.elevation.well.insets,
              ),
            ),
          ),
          // Knob
          Positioned(
            left: knobInset,
            top: knobInset,
            width: knobSize,
            height: knobSize,
            child: AnimatedRotation(
              turns: angle / 360,
              duration: _dragStartY == null ? m.release : Duration.zero,
              curve: m.settle,
              child: WizSurface(
                spec: wiz.elevation.knob,
                radius: circle,
                color: c.char850,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: WizKnobFacePainter(
                        elevation: wiz.elevation,
                        top: c.surfaceKey,
                        bottom: c.char950,
                        highlight: c.highlightBase,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: d * WizDialGeometry.markTop,
                        ),
                        child: Container(
                          width: WizDialGeometry.markWidth,
                          height: d * WizDialGeometry.markHeight,
                          decoration: BoxDecoration(
                            color: c.amber300,
                            borderRadius: BorderRadius.circular(
                              WizDial._markRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: c.amber400.withValues(
                                  alpha: WizDial._markGlowAlpha,
                                ),
                                blurRadius: WizDial._markGlowBlur,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Readout well
          Positioned(
            left: wellInset,
            top: wellInset,
            right: wellInset,
            bottom: wellInset,
            child: IgnorePointer(
              child: WizSurface(
                spec: wiz.elevation.wellDeep,
                radius: circle,
                gradient: wizVertical(c.char850, c.char1000),
                alignment: Alignment.center,
                // The engraved number is decoration: left in, it would
                // merge into the slider's label and be read out twice,
                // once as the label and again as the value.
                child: ExcludeSemantics(child: _readout(wiz, d)),
              ),
            ),
          ),
        ],
      ),
    );

    Widget visual = disc;
    if (_focused) {
      visual = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: circle,
          border: Border.all(color: c.focusRing, width: wiz.space.focusRing),
        ),
        child: visual,
      );
    }

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
            enabled: widget.enabled,
            onIncrease: widget.enabled
                ? () => _commit(widget.value + _keyDelta)
                : null,
            onDecrease: widget.enabled
                ? () => _commit(widget.value - _keyDelta)
                : null,
            child: Focus(
              focusNode: _focusNode,
              onFocusChange: (v) => setState(() => _focused = v),
              onKeyEvent: _key,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.resizeUpDown
                    : SystemMouseCursors.forbidden,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // The drag starts where the finger landed, not where the
                  // recogniser won the arena, so the 160 px that cover the
                  // range are 160 px of finger rather than 160 plus however
                  // much slop the gesture cost.
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragStart: _start,
                  onVerticalDragUpdate: _update,
                  onVerticalDragEnd: (_) => _end(),
                  onVerticalDragCancel: _end,
                  child: Opacity(
                    opacity: widget.enabled ? 1 : WizColors.disabledAlpha,
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
            Text(
              widget.label!.toUpperCase(),
              style: wiz.typography.label.copyWith(color: c.textTertiary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// The engraved number and its unit. Two spans rather than one so the
  /// value alone is addressable, laid out unbounded inside a [FittedBox]:
  /// the compressed display face always fits the well, and a fallback face
  /// that does not shrinks rather than spilling over the knob.
  Widget _readout(WizTheme wiz, double d) {
    var value = wiz.typography.readout.copyWith(
      fontSize: d * WizDialGeometry.valueFont,
      fontWeight: FontWeight.w800,
      letterSpacing: d * WizDialGeometry.valueFont * WizDial._readoutTracking,
      color: wiz.colors.textPrimary,
    );
    // Dial.jsx's unit span overrides only size and colour; the tracking it
    // inherits is relative to its own smaller size.
    var unit = value.copyWith(
      fontSize: d * WizDialGeometry.unitFont,
      letterSpacing: d * WizDialGeometry.unitFont * WizDial._readoutTracking,
      color: wiz.colors.textTertiary,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('${widget.value.round()}', style: value, maxLines: 1),
          Text(widget.unit, style: unit, maxLines: 1),
        ],
      ),
    );
  }
}
