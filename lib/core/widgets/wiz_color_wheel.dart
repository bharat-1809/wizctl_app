import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_theme.dart';
import '../util/color_maths.dart';
import 'wiz_color_wheel_disc.dart';

/// Hue in degrees (0 at the top, clockwise) and saturation in [0, 1].
@immutable
class WizHsv {
  final double hue;
  final double saturation;

  const WizHsv(this.hue, this.saturation);

  Color get color => hsvToColor(hue, saturation);

  /// Value equality, so a caller — and the wheel's own "did this gesture
  /// move anything" test — can compare two readings rather than their
  /// halves.
  @override
  bool operator ==(Object other) =>
      other is WizHsv && other.hue == hue && other.saturation == saturation;

  @override
  int get hashCode => Object.hash(hue, saturation);

  @override
  String toString() => 'WizHsv($hue, $saturation)';
}

/// HSV colour wheel with a raised puck. Drag anywhere inside the disc: the
/// angle from 12 o'clock is the hue, the distance from the centre is the
/// saturation, and a detent fires every [detentDegrees] of hue.
///
/// The face is painted by [WizColorWheelDisc]; everything here is the
/// gesture, the keyboard, the focus ring and the semantics.
class WizColorWheel extends StatefulWidget {
  final double hue;
  final double saturation;
  final ValueChanged<WizHsv> onChanged;
  final ValueChanged<WizHsv>? onChangeEnd;
  final double size;
  final bool enabled;

  const WizColorWheel({
    super.key,
    required this.hue,
    required this.saturation,
    required this.onChanged,
    this.onChangeEnd,
    required this.size,
    this.enabled = true,
  });

  // ColorWheel.jsx: ring inset, puck, ring width, usable radius margin, detent.
  static const double ringInset = 8;
  static const double puckSize = 34;
  static const double puckRing = 4;
  static const double radiusMargin = 18;
  static const double detentDegrees = 15;
  static const double whiteStop = 0.62;

  /// How many notches go round the ring: 360° at [detentDegrees] each. The
  /// notch at the top is one notch and not both 0 and 24, so a hue crossing
  /// 12 o'clock sounds once (spec §11.2, "a detent every 15° of hue").
  static const int notches = 360 ~/ detentDegrees;

  /// The disc the design draws, at its widest and at its narrowest. Spec
  /// §14: "the colour wheel is `min(available, 228)`" — 228 is the phone
  /// tab's width (spec §11.2) — and "touch targets never below 44", the
  /// smallest disc a finger can still aim inside. A caller asking for
  /// anything outside gets the wheel the chassis has room for.
  static const double minSize = 44;
  static const double maxSize = 228;

  /// How far one arrow key moves saturation. Spec §14 gives the wheel no
  /// step of its own, so it takes the kit's notch count: a twentieth of the
  /// range, as `WizSlider.detents` divides a rail.
  static const double keySaturationStep = 0.05;

  @override
  State<WizColorWheel> createState() => _WizColorWheelState();
}

class _WizColorWheelState extends State<WizColorWheel> {
  /// Owned rather than left to [Focus] so keyboard focus can be driven and
  /// asserted from outside the widget.
  final FocusNode _focusNode = FocusNode(debugLabel: 'WizColorWheel');

  bool _dragging = false;
  bool _focused = false;

  /// Whether the touch now down has already opened a change. Cleared by the
  /// [Listener] below on pointer down, so a fresh touch is a fresh change
  /// however the arena resolves — the pan recogniser reports one
  /// `onPanDown` per pointer sequence today, and this keeps one touch to
  /// one `press` if a second recogniser is ever added beside it, as
  /// `WizSlider`'s tap is.
  bool _begun = false;

  int? _notch;

  /// The last reading [_commit] settled on. `onChangeEnd` reports this
  /// rather than the widget's own hue and saturation, which are still the
  /// old ones until whoever owns them has rebuilt this widget.
  late WizHsv _committed = _value;

  /// What the colour was when the current touch landed, so a tap that moves
  /// nothing ends no change.
  late WizHsv _gestureStart = _value;

  /// ColorWheel.jsx reports `Math.round(h)` and `+dist.toFixed(3)`: whole
  /// degrees and saturation to three decimals.
  static const double _saturationSteps = 1000;

  /// The diameter the wheel draws at, and the disc geometry that follows.
  double get _diameter =>
      widget.size.clamp(WizColorWheel.minSize, WizColorWheel.maxSize);
  double get _r => _diameter / 2;
  double get _usable => _r - WizColorWheel.radiusMargin;

  /// What the caller is showing, rounded the way a change from this wheel
  /// is, so the two can be compared.
  WizHsv get _value => _round(widget.hue, widget.saturation);

  @override
  void initState() {
    super.initState();
    // Seeded, not left null: a keyboard step is a notch crossing like any
    // other, so the first one sounds like the second. Only the pointer path
    // starts silent, where the touch landing is not itself a crossing.
    _notch = _notchOf(_value.hue);
  }

  @override
  void didUpdateWidget(WizColorWheel old) {
    super.didUpdateWidget(old);
    if (widget.hue != old.hue) _notch = _notchOf(_value.hue);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// A reading on the wheel's own scale: whole degrees wrapped into
  /// [0, 360) — Dart's `%` is euclidean, so a hue stepped below zero comes
  /// back round the top — and saturation clamped inside the disc.
  WizHsv _round(double hue, double saturation) => WizHsv(
    hue.roundToDouble() % 360,
    (saturation.clamp(0.0, 1.0) * _saturationSteps).roundToDouble() /
        _saturationSteps,
  );

  /// Which 15° notch — one [WizColorWheel.detentDegrees] wide — [hue] is in,
  /// counted round the ring so the notch spanning 12 o'clock is one notch:
  /// 355° and 3° are both notch 0, and passing between them sounds once.
  int _notchOf(double hue) =>
      (hue / WizColorWheel.detentDegrees).round() % WizColorWheel.notches;

  /// The colour one arrow key away: [byHue] degrees round the ring, or
  /// [bySaturation] out from the centre.
  WizHsv _shift({double byHue = 0, double bySaturation = 0}) =>
      _round(widget.hue + byHue, widget.saturation + bySaturation);

  /// How assistive technology reads a colour out, e.g.
  /// `Hue 30°, saturation 50%`.
  String _spoken(WizHsv v) =>
      'Hue ${v.hue.round()}°, saturation ${(v.saturation * 100).round()}%';

  /// Rounds a raw reading onto the wheel's scale, fires the detent if that
  /// crossed a notch, reports the change, and returns what it settled on.
  WizHsv _commit(double hue, double saturation) {
    var next = _round(hue, saturation);
    var notch = _notchOf(next.hue);
    if (notch != _notch) {
      // Null on the first sample of a touch: landing somewhere is not
      // crossing a notch.
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    // Against both, since two samples in one frame can settle on the same
    // reading before the owner has rebuilt this widget with the first.
    if (next != _value && next != _committed) widget.onChanged(next);
    _committed = next;
    return next;
  }

  /// The colour under a touch at [local]: `atan2` measures from 3 o'clock,
  /// so the wheel's 12 o'clock start is 90° along.
  WizHsv _from(Offset local) {
    var offset = Offset(local.dx - _r, local.dy - _r);
    return _commit(
      math.atan2(offset.dy, offset.dx) * 180 / math.pi + 90,
      // A disc smaller than its own margin has no usable radius to divide
      // by, and every touch on it sits at the centre.
      _usable > 0 ? math.min(1.0, offset.distance / _usable) : 0,
    );
  }

  /// Opens a change under the finger. Runs once per pointer sequence.
  void _begin(Offset local) {
    if (!_begun) {
      _begun = true;
      _notch = null;
      // Both re-seeded from what the wheel is showing, so the dedupe below
      // is scoped to this touch: a caller that ignored the last gesture
      // must still hear this one land on the same colour.
      _gestureStart = _value;
      _committed = _value;
      context.feedback.play(FeedbackKind.press);
    }
    _from(local);
  }

  /// A touch that never moved the colour — a tap on the puck, or a drag
  /// that came home again — changed nothing, so there is no change to end.
  void _end() {
    if (_dragging) setState(() => _dragging = false);
    if (_committed != _gestureStart) widget.onChangeEnd?.call(_committed);
  }

  /// One discrete move — an arrow key or an assistive-technology increment.
  /// Unlike a drag it is over the moment it happens, so it reports the end
  /// of the change itself — unless it had nowhere left to go. Measured
  /// against what the last commit settled on rather than against the
  /// widget's own hue and saturation, which a caller that does not feed the
  /// change back would leave standing, turning every repeat of one key into
  /// another ended change that moved nothing.
  void _step(WizHsv to) {
    var from = _committed;
    var next = _commit(to.hue, to.saturation);
    if (next != from) widget.onChangeEnd?.call(next);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    const turn = WizColorWheel.detentDegrees;
    const reach = WizColorWheel.keySaturationStep;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _step(_shift(byHue: turn));
      case LogicalKeyboardKey.arrowLeft:
        _step(_shift(byHue: -turn));
      case LogicalKeyboardKey.arrowUp:
        _step(_shift(bySaturation: reach));
      case LogicalKeyboardKey.arrowDown:
        _step(_shift(bySaturation: -reach));
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var armed = widget.enabled;
    var increased = _shift(byHue: WizColorWheel.detentDegrees);
    var decreased = _shift(byHue: -WizColorWheel.detentDegrees);

    Widget visual = WizColorWheelDisc(
      diameter: _diameter,
      hue: widget.hue,
      saturation: widget.saturation,
      dragging: _dragging,
    );
    if (_focused) {
      visual = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: wiz.colors.focusRing,
            width: wiz.space.focusRing,
          ),
        ),
        child: visual,
      );
    }

    return Semantics(
      slider: true,
      label: 'Colour wheel',
      value: _spoken(_value),
      // A node that offers increase or decrease alongside a value has to
      // say what those actions would read out, or the framework asserts.
      // Both step the hue, the axis the ring is named for.
      increasedValue: _spoken(increased),
      decreasedValue: _spoken(decreased),
      enabled: armed,
      onIncrease: armed ? () => _step(increased) : null,
      onDecrease: armed ? () => _step(decreased) : null,
      child: Focus(
        focusNode: _focusNode,
        // A disabled wheel is not a tab stop and draws no ring.
        canRequestFocus: armed,
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: _key,
        child: MouseRegion(
          cursor: armed
              ? SystemMouseCursors.precise
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The [Semantics] above already offers increase and decrease.
            // Left to itself the recogniser would add a scroll action per
            // direction, and a synthetic scroll hands the drag a *global*
            // position, which this widget reads as a local one and throws
            // the colour to the rim.
            excludeFromSemantics: true,
            // The colour follows the finger from where it landed, not
            // from where the recogniser won the arena.
            dragStartBehavior: DragStartBehavior.down,
            // Null while disabled, so no recogniser is built and a scroll
            // view above keeps every drag.
            onPanDown: armed
                ? (details) {
                    setState(() => _dragging = true);
                    _begin(details.localPosition);
                  }
                : null,
            onPanUpdate: armed ? (d) => _from(d.localPosition) : null,
            onPanEnd: armed ? (_) => _end() : null,
            onPanCancel: armed ? _end : null,
            child: Listener(
              // Inside the detector rather than around it: the hit-test
              // path runs deepest first, and `RawGestureDetector` hosts
              // its own listener above this one, so a listener wrapped
              // *round* the detector would clear the flag after
              // `onPanDown` had already opened the change. Opaque, so it
              // is on that path whatever the disc below it hit-tests as.
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _begun = false,
              child: Opacity(
                opacity: armed ? 1 : WizColors.disabledAlpha,
                child: visual,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
