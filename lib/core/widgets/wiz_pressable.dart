import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_theme.dart';

/// What the builder can react to.
@immutable
class WizPressState {
  final bool pressed;
  final bool hovered;
  final bool focused;

  const WizPressState({
    this.pressed = false,
    this.hovered = false,
    this.focused = false,
  });
}

typedef WizPressBuilder = Widget Function(
  BuildContext context,
  WizPressState state,
);

/// The one press recipe for every clickable thing: on pointer down the part
/// sinks [travel] and scales to [scale] in 80 ms and fires [feedback]; on
/// release it springs back on the settle curve in 140 ms. Hover brightens
/// raised parts on desktop; focus draws the amber ring. Selection itself
/// never animates, the press does.
class WizPressable extends StatefulWidget {
  final WizPressBuilder builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The cue played when the part goes down, or null for a control that
  /// plays its own on commit instead — a `WizToggle` fires `toggleOn` or
  /// `toggleOff` when the switch actually closes, not when it is touched.
  final FeedbackKind? feedback;
  final double? scale;
  final double? travel;
  final bool enabled;
  final String? semanticsLabel;
  final bool hover;
  final MouseCursor? cursor;

  /// Reported to assistive technology as the switch state, for a pressable
  /// that is a switch rather than a plain button. Null for everything else.
  final bool? toggled;

  /// Extra transparent hit area around the visual, for controls drawn
  /// smaller than the 44 minimum.
  final EdgeInsets? hitPadding;

  /// Shape of the focus ring. Defaults to `space.r3`, which is right for a
  /// button cap; controls that are another shape pass their own, so the ring
  /// traces the part rather than a rounded box around it — a circular
  /// [WizIconKey] passes `d / 2`, a [WizChip] passes the pill radius.
  final BorderRadius? focusRadius;

  /// Whether the press waits for the gesture arena instead of firing on the
  /// raw pointer down.
  ///
  /// False (the default) is the tactile ideal: a [Listener] sinks the part
  /// and fires [feedback] the instant the finger lands, before any recogniser
  /// has claimed the gesture. True hands both to [GestureDetector]'s tap
  /// callbacks, so a pressable *wrapping* other controls — a device card with
  /// its own toggle and slider — stays still when a child wins the arena.
  ///
  /// The arena only tells this widget apart from its children once one of
  /// them claims the gesture. Until then a resting finger still counts as a
  /// press on this one after `kPressTimeout` (100 ms), because that is when
  /// [GestureDetector] reports the tap down. A child that claims the gesture
  /// later — a slider taking a drag — releases the sink through `onTapCancel`.
  final bool arenaResolved;

  const WizPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.feedback = FeedbackKind.press,
    this.scale,
    this.travel,
    this.enabled = true,
    this.semanticsLabel,
    this.hover = true,
    this.cursor,
    this.toggled,
    this.hitPadding,
    this.focusRadius,
    this.arenaResolved = false,
  });

  @override
  State<WizPressable> createState() => _WizPressableState();
}

class _WizPressableState extends State<WizPressable> {
  /// Owned rather than left to [FocusableActionDetector] so keyboard focus
  /// can be driven and asserted from outside the widget.
  final FocusNode _focusNode = FocusNode(debugLabel: 'WizPressable');

  /// Identity for whatever the builder returns, so that the wrappers hover
  /// and focus add and remove around it cannot cost it its element.
  ///
  /// Hover wraps the visual in a [ColorFiltered] and focus in a
  /// [DecoratedBox]; without a key the child at the animation's slot changes
  /// type when either appears, and the framework then inflates a fresh
  /// element tree — a hosted [StatefulWidget] loses its [State] mid-gesture,
  /// so hovering a light card while its rail is held would drop the drag. A
  /// [GlobalKey] is re-taken across the move rather than rebuilt. The cheap
  /// alternative — an always-present [ColorFiltered] — would cost a
  /// `saveLayer` per card for every frame it is on screen.
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'WizPressable content');

  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  /// Where the finger landed, so a drag past the touch slop can release the
  /// sink before any recogniser has claimed the gesture.
  Offset? _downAt;

  /// CSS `filter: brightness(1.08)` as a colour matrix.
  static List<double> _brightness(double b) => [
    b, 0, 0, 0, 0, //
    0, b, 0, 0, 0, //
    0, 0, b, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// [silent] re-takes a sink the part already had, without a second cue.
  void _down({bool silent = false}) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    var kind = widget.feedback;
    if (!silent && kind != null) context.feedback.play(kind);
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  void _activate() {
    if (!widget.enabled) return;
    var kind = widget.feedback;
    if (kind != null) context.feedback.play(kind);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    var motion = context.wiz.motion;
    var colors = context.wiz.colors;
    var scale = widget.scale ?? motion.pressScale;
    var travel = widget.travel ?? motion.pressTravel;
    var state = WizPressState(
      pressed: _pressed,
      hovered: _hovered,
      focused: _focused,
    );

    Widget visual = KeyedSubtree(
      key: _contentKey,
      child: widget.builder(context, state),
    );
    if (widget.semanticsLabel != null) {
      // A given label is the whole node. Left in, the copy the builder draws
      // merges into the node beside it and a `WizButton('Retry')` — whose
      // cap prints `RETRY` — reads "Retry\nRETRY".
      //
      // Excluded here rather than through `Semantics.excludeSemantics` on
      // the node below: that flag drops the *whole* descendant subtree,
      // which includes the `Focus` inside `FocusableActionDetector`, and a
      // key that no longer reports `isFocusable` cannot be reached by
      // keyboard or by switch control. Nothing else under the node
      // annotates — the gesture detector is already excluded — so this
      // covers exactly the drawn copy.
      //
      // A pressable that gives no label of its own is named by the copy
      // inside it and keeps that subtree, and so does every nested control
      // a card holds.
      visual = ExcludeSemantics(child: visual);
    }
    if (widget.hover && _hovered && !_pressed && widget.enabled) {
      visual = ColorFiltered(
        colorFilter: ColorFilter.matrix(_brightness(motion.hoverBrightness)),
        child: visual,
      );
    }
    if (_focused) {
      visual = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius:
              widget.focusRadius ?? BorderRadius.circular(context.wiz.space.r3),
          border: Border.all(
            color: colors.focusRing,
            width: context.wiz.space.focusRing,
          ),
        ),
        child: visual,
      );
    }
    visual = TweenAnimationBuilder<double>(
      tween: Tween(end: _pressed ? 1 : 0),
      duration: _pressed ? motion.press : motion.release,
      curve: _pressed ? motion.pressCurve : motion.settle,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, travel * t),
        child: Transform.scale(scale: 1 - (1 - scale) * t, child: child),
      ),
      child: visual,
    );
    if (!widget.enabled) {
      visual = Opacity(opacity: WizColors.disabledAlpha, child: visual);
    }
    if (widget.hitPadding != null) {
      visual = Padding(padding: widget.hitPadding!, child: visual);
    }

    var armed = widget.enabled;
    var byArena = armed && widget.arenaResolved;
    // A long press winning the arena rejects the tap recogniser under it, so
    // the sink has to be handed over or the part would pop back up with the
    // finger still down. Both setState calls land in one event dispatch and
    // so coalesce into a single rebuild, and the hand-over is silent. This
    // applies in both modes: the tap recogniser is in the arena either way,
    // and `onTapCancel` releases the sink either way.
    var handsOverToLongPress = armed && widget.onLongPress != null;
    Widget gestures = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // The outer Semantics is the tappable node; a second one here would
      // give every control two.
      excludeFromSemantics: true,
      onTapDown: byArena ? (_) => _down() : null,
      onTapUp: byArena ? (_) => _up() : null,
      // Not gated on the mode: whenever the tap is lost — a scroll view
      // taking the drag, a finger sliding off — the part has to come back up,
      // and in Listener mode nothing else reports that.
      onTapCancel: _up,
      onLongPressStart: handsOverToLongPress
          ? (_) => _down(silent: true)
          : null,
      onLongPressEnd: handsOverToLongPress ? (_) => _up() : null,
      // A pointer cancelled after the long press was accepted reports here,
      // never through onLongPressEnd.
      onLongPressCancel: handsOverToLongPress ? _up : null,
      onTap: armed ? widget.onTap : null,
      onLongPress: armed ? widget.onLongPress : null,
      child: visual,
    );
    if (!widget.arenaResolved) {
      // The distance `TapGestureRecognizer` itself resolves to, so the visual
      // and the tap always agree about when the gesture got away. It is the
      // same for a mouse as for a finger: the recogniser's slop comes from
      // the device's gesture settings, not from the pointer kind.
      var slop =
          MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;
      gestures = Listener(
        onPointerDown: (event) {
          _downAt = event.position;
          _down();
        },
        // A flick can drag the pointer past the slop before any recogniser
        // has claimed it, so `onTapCancel` never comes. Releasing here is
        // what stops a control staying depressed for a whole scroll.
        onPointerMove: (event) {
          var from = _downAt;
          if (from != null && (event.position - from).distance > slop) {
            _downAt = null;
            _up();
          }
        },
        onPointerUp: (_) {
          _downAt = null;
          _up();
        },
        onPointerCancel: (_) {
          _downAt = null;
          _up();
        },
        child: gestures,
      );
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      toggled: widget.toggled,
      label: widget.semanticsLabel,
      onTap: armed ? _activate : null,
      onLongPress: armed ? widget.onLongPress : null,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        enabled: widget.enabled,
        mouseCursor:
            widget.cursor ??
            (widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: <Type, Action<Intent>>{
          // Enter and Space both reach here through the app's default
          // shortcuts; web maps Enter to ButtonActivateIntent instead.
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: gestures,
      ),
    );
  }
}
