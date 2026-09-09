import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../layout/wiz_breakpoints.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// The contents of a [showWizSheet] route: the sheet itself, the scrim behind
/// it, its entrance, and — on a phone — the drag that throws it away. Built by
/// `showWizSheet`; there is no reason to construct one directly.
///
/// Every `:nnnn` below is a line of `design/reference/_ds_bundle.js`, whose
/// `components/layout/Sheet.jsx` begins at `:2630`.
class WizSheetRoute extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? footer;
  final double? maxWidth;

  /// Whether [body] goes inside the sheet's own scroll view — see
  /// `showWizSheet`, which documents both sides.
  final bool scrollable;

  /// The route's own transition. The rise, the fade and the scrim all come
  /// off this one value.
  final Animation<double> animation;

  const WizSheetRoute({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
    required this.maxWidth,
    required this.scrollable,
    required this.animation,
  });

  /// Grab handle `width: 44, height: 4, … borderRadius: 2` (`:2683`); spec
  /// §11.2, "grab handle 44×4".
  static const double handleWidth = 44;
  static const double handleHeight = 4;
  static const double handleRadius = 2;

  /// How far the sheet climbs as it fades in: `@keyframes wz-sheet-in{from{
  /// transform:translateY(14px);opacity:.6}}` (`:70`); spec §11.2, "rise 14 +
  /// fade". The JSX starts the fade at .6 because its scrim appears at once;
  /// here the scrim fades on the same animation, so the sheet fades from 0
  /// rather than flashing in over an empty backdrop.
  static const double rise = 14;

  /// `maxHeight: '86%'` (`:2672`); spec §11.2, "max height 86 %" — of the
  /// whole sheet, padding included, and of what the keyboard leaves of the
  /// window.
  static const double maxHeightFraction = 0.86;

  /// `width: centred ? 'min(520px,100%)' : '100%'` (`:2671`); spec §11.2,
  /// "width capped 520 or 680" — the 680 is a caller's [maxWidth], not a
  /// second default.
  static const double dialogWidth = 520;

  /// `backdropFilter: 'blur(6px)'` (`:2662`); spec §11.2, "scrim 72 % with
  /// 6 px blur". The 72 % is `WizColors.surfaceScrim` itself.
  static const double scrimBlur = 6;

  /// Drag past this much of the sheet's own height, or flick faster than
  /// this, and it goes rather than springing back (spec §11.2, "drag to
  /// dismiss with proportional scrim").
  static const double dismissFraction = 0.3;
  static const double dismissVelocity = 700;

  @override
  State<WizSheetRoute> createState() => _WizSheetRouteState();
}

class _WizSheetRouteState extends State<WizSheetRoute> {
  /// Built in didChangeDependencies, never as a field initialiser: its curve
  /// comes from `context.wiz.motion`, and an InheritedWidget lookup like that
  /// isn't safe before the element has established dependencies.
  CurvedAnimation? _entrance;

  /// The entrance and the drag together — everything the scrim, the fade and
  /// the sheet's offset are repainted from.
  Listenable? _repaint;

  /// The platform's "reduce motion" switch, read where the dependency is
  /// registered. Under it the sheet is simply there, at rest, on frame one.
  bool _reduced = false;

  /// How far a finger has pulled the sheet down, in logical pixels. A
  /// notifier rather than state, so a drag repaints the scrim and the offset
  /// without rebuilding the sheet's own subtree every frame.
  final ValueNotifier<double> _drag = ValueNotifier<double>(0);

  /// Sits on the sheet's outermost box, so a drag can be measured against the
  /// height the sheet actually took.
  final GlobalKey _sheetKey = GlobalKey();

  /// The sheet's laid-out height — what a drag is judged against, rather than
  /// the 86 % cap, which a short sheet never comes near.
  double get _sheetHeight {
    var box = _sheetKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var settle = context.wiz.motion.settle;
    _reduced = MediaQuery.disableAnimationsOf(context);
    var entrance = _entrance;
    if (entrance == null) {
      entrance = CurvedAnimation(parent: widget.animation, curve: settle);
      _entrance = entrance;
      _repaint = Listenable.merge(<Listenable>[entrance, _drag]);
    } else {
      entrance.curve = settle;
    }
  }

  @override
  void dispose() {
    _entrance?.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _dragUpdate(DragUpdateDetails details) =>
      _drag.value = (_drag.value + details.delta.dy).clamp(0, _sheetHeight);

  void _dragEnd(DragEndDetails details) {
    var height = _sheetHeight;
    var far =
        height > 0 && _drag.value / height > WizSheetRoute.dismissFraction;
    var flick = (details.primaryVelocity ?? 0) > WizSheetRoute.dismissVelocity;
    if (far || flick) {
      Navigator.of(context).maybePop();
    } else {
      _drag.value = 0;
    }
  }

  /// Grab handle, title, body and footer row — the same inside whichever
  /// shape the sheet took.
  Widget _content(WizTheme wiz, {required bool handle, required double gap}) {
    var c = wiz.colors;
    var actions = widget.footer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (handle)
          // Decorative: the sheet is named already, and the drag the handle
          // hints at is not the only way out.
          ExcludeSemantics(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: gap),
                // Handle `boxShadow: 'var(--elev-well)'`, `background:
                // 'var(--char-700)'` (`:2687`, `:2688`).
                child: WizSurface(
                  key: const Key('wiz-sheet-handle'),
                  spec: wiz.elevation.well,
                  radius: BorderRadius.circular(WizSheetRoute.handleRadius),
                  color: c.char700,
                  width: WizSheetRoute.handleWidth,
                  height: WizSheetRoute.handleHeight,
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: gap),
          // Title `fontSize: 'var(--type-heading-size)', fontWeight: 600`
          // (`:2693`) — `WizType.heading` is both.
          child: Text(
            widget.title,
            style: wiz.typography.heading.copyWith(color: c.textPrimary),
          ),
        ),
        // `overflow: 'auto'` (`:2673`): a plain body scrolls inside the sheet
        // once the sheet reaches its 86 %. A body that is its own viewport
        // takes the bounded height directly instead — wrapping one would hand
        // it an unbounded height and throw.
        Flexible(
          child: widget.scrollable
              ? SingleChildScrollView(child: widget.body)
              : widget.body,
        ),
        if (actions != null && actions.isNotEmpty)
          Padding(
            // Footer `marginTop: 'var(--space-7)', gap: 'var(--space-4)'`
            // (`:2698`, `:2700`).
            padding: EdgeInsets.only(top: wiz.space.s7),
            child: Row(
              spacing: wiz.space.s4,
              children: [
                // The last action is the primary one and takes the rest of the
                // row, so a lone button fills the footer.
                for (var i = 0; i < actions.length; i++)
                  if (i == actions.length - 1)
                    Expanded(child: actions[i])
                  else
                    actions[i],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var space = wiz.space;
    var motion = wiz.motion;
    var size = MediaQuery.sizeOf(context);
    var compact = WizBreakpoints.classify(size.width).isCompact;
    // The software keyboard lifts a bottom sheet clear of itself, and the
    // 86 % is of whatever it leaves of the window.
    var keyboard = compact ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    var travel = (size.height - keyboard) * WizSheetRoute.maxHeightFraction;
    var pad = space.panelPadLg;
    // A bottom sheet runs to the bottom edge of the window, so it clears the
    // home indicator with its own padding rather than with a SafeArea that
    // would leave the blurred scrim showing beneath it. `padding`, not
    // `viewPadding`: it already has the keyboard's inset taken out of it, so
    // a raised keyboard and the indicator never pad the sheet twice over.
    var bottom = compact ? pad + MediaQuery.paddingOf(context).bottom : pad;
    // The same 14 sits under the handle and under the title: `margin:
    // '0 auto 14px'` and `'0 0 14px'` (`:2685`, `:2692`).
    var gap = space.s5 + space.s1;

    Widget sheet = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: travel),
      // `borderRadius: centred ? 'var(--radius-5)' : 'var(--radius-5)
      // var(--radius-5) 0 0'`, `padding: 'var(--panel-pad-lg)'`, `background:
      // 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))'`
      // and `boxShadow: 'var(--elev-overlay)'` (`:2674`–`:2677`).
      child: WizSurface(
        key: const Key('wiz-sheet'),
        spec: wiz.elevation.overlay,
        radius: compact
            ? BorderRadius.vertical(top: Radius.circular(space.r5))
            : BorderRadius.circular(space.r5),
        gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
        padding: EdgeInsets.fromLTRB(pad, pad, pad, bottom),
        child: _content(wiz, handle: compact, gap: gap),
      ),
    );

    sheet = GestureDetector(
      key: _sheetKey,
      // Opaque, so the sheet's whole box stops a pointer — `onClick: e =>
      // e.stopPropagation()` (`:2669`). Without it a tap on a rounded corner,
      // where the surface's own decoration does not answer the hit test,
      // falls through the stack to the scrim and closes the sheet.
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: compact ? _dragUpdate : null,
      onVerticalDragEnd: compact ? _dragEnd : null,
      child: sheet,
    );

    sheet = compact
        ? SizedBox(width: double.infinity, child: sheet)
        : Padding(
            // The scrim pads a centred dialog by 24 (`:2663`), so it never
            // runs into the window edge.
            padding: EdgeInsets.all(space.s8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth ?? WizSheetRoute.dialogWidth,
              ),
              child: sheet,
            ),
          );

    var entrance = _entrance!;
    return AnimatedBuilder(
      animation: _repaint!,
      // Built once per build rather than once per frame: neither the entrance
      // nor a drag changes anything inside the sheet.
      child: sheet,
      builder: (context, child) {
        // The settle curve overshoots 1 on its way home. The rise wants that
        // overshoot; every alpha has to be clamped out of it.
        var raw = _reduced ? 1.0 : entrance.value;
        var progress = raw.clamp(0.0, 1.0);
        var drag = _drag.value;
        var height = _sheetHeight;
        // "Proportional scrim": it thins as the sheet is dragged away.
        var scrim = progress * (1 - (height > 0 ? drag / height : 0.0));
        var blur = WizSheetRoute.scrimBlur * scrim;
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              // The route's own `barrierLabel` is the dismiss affordance; a
              // second, unlabelled full-screen tap target would only clutter
              // the semantics tree.
              excludeFromSemantics: true,
              onTap: () => Navigator.of(context).maybePop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                // `background: 'var(--surface-scrim)'` (`:2661`), which is
                // already the spec's 72 %.
                child: ColoredBox(
                  color: c.surfaceScrim.withValues(
                    alpha: c.surfaceScrim.a * scrim,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: !compact,
              child: AnimatedPadding(
                padding: EdgeInsets.only(bottom: keyboard),
                duration: _reduced ? Duration.zero : motion.panel,
                curve: motion.settle,
                child: Align(
                  alignment: compact
                      ? Alignment.bottomCenter
                      : Alignment.center,
                  child: Semantics(
                    // `role="dialog" aria-modal="true" aria-label={title}`
                    // (`:2666`–`:2668`).
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: widget.title,
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(0, WizSheetRoute.rise * (1 - raw)),
                        // The body may hold Material widgets, and the route
                        // sits above the app's own Material.
                        child: Material(
                          type: MaterialType.transparency,
                          child: compact
                              ? AnimatedContainer(
                                  // Instant while the finger is down, so the
                                  // sheet tracks it exactly; the release is
                                  // the part that animates, home on the
                                  // settle curve.
                                  duration: !_reduced && drag == 0
                                      ? motion.release
                                      : Duration.zero,
                                  curve: motion.settle,
                                  transform: Matrix4.translationValues(
                                    0,
                                    drag,
                                    0,
                                  ),
                                  child: child,
                                )
                              : child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
