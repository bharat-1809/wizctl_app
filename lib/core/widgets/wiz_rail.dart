import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../layout/wiz_breakpoints.dart';
import '../layout/wiz_layout.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_cap_tracker.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

class WizRailItem<T> {
  final T value;
  final String label;
  final WizIconData icon;
  final String? meta;

  const WizRailItem({
    required this.value,
    required this.label,
    required this.icon,
    this.meta,
  });
}

class WizRailSection<T> {
  final String title;
  final List<WizRailItem<T>> items;

  const WizRailSection({required this.title, required this.items});
}

/// Desktop rail: brand block, room and house navigation with a sliding
/// raised cap, footer slot. Collapses to icons with tooltips on medium
/// windows.
class WizRail<T> extends StatefulWidget {
  final Widget? brand;
  final Widget? collapsedBrand;
  final List<WizRailSection<T>> sections;
  final T? value;
  final ValueChanged<T> onChanged;
  final Widget? footer;
  final bool collapsed;
  final double? width;

  const WizRail({
    super.key,
    this.brand,
    this.collapsedBrand,
    required this.sections,
    required this.value,
    required this.onChanged,
    this.footer,
    this.collapsed = false,
    this.width,
  });

  /// Item box and glyph (spec §11.2 `WizRail`, "42-tall items";
  /// Sidebar.jsx `height: 42, padding: '0 12px'`). The glyph is the 18 the
  /// rail's rows use, a size down from a list row's 20–24.
  static const double itemHeight = 42;
  static const double glyph = 18;
  static const double itemPadX = 12;

  /// Gap between an item's icon and its label (Sidebar.jsx `gap: 11`).
  static const double iconGap = 11;

  /// The item sinks a hair under the finger (Sidebar.jsx `onPointerDown`,
  /// `transform: scale(.98)`).
  static const double pressedScale = 0.98;

  /// Label tracking: Sidebar.jsx `fontSize: 15, letterSpacing: '-.005em'`,
  /// multiplied out the way the type tokens are.
  static const double labelTracking = 15 * -0.005;

  /// The mono count on the right of a row (Sidebar.jsx `fontSize: 11`).
  static const double metaSize = 11;

  @override
  State<WizRail<T>> createState() => _WizRailState<T>();
}

class _WizRailState<T> extends State<WizRail<T>>
    with WizCapTracker<WizRail<T>> {
  /// The rail is as wide as the window can afford, unless the caller has
  /// pinned it (spec §11.2: 264, 288 on a wide window, 72 icon-only).
  double _width(BuildContext context) {
    var space = context.wiz.space;
    if (widget.width != null) return widget.width!;
    if (widget.collapsed) return space.railIcon;
    var widthClass = WizLayout.maybeOf(context)?.widthClass;
    return widthClass == WidthClass.wide ? space.railWide : space.rail;
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var s = wiz.space;
    var radius = BorderRadius.circular(s.r2);

    Widget itemFor(WizRailItem<T> it) {
      var on = it.value == widget.value;
      // The key goes on the outermost box of the item — not on the tooltip
      // wrapped around it — so the cap measures the same rect either way.
      Widget body = Semantics(
        key: keyFor(it.value as Object),
        selected: on,
        child: WizPressable(
          scale: WizRail.pressedScale,
          travel: 0,
          // Silent on press: the cue belongs to the change, below.
          feedback: null,
          semanticsLabel: it.label,
          focusRadius: radius,
          // The rail's list scrolls, so the press waits for the arena.
          arenaResolved: true,
          onTap: () {
            if (on) return;
            context.feedback.play(FeedbackKind.tick);
            widget.onChanged(it.value);
          },
          builder: (context, state) => SizedBox(
            height: WizRail.itemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: WizRail.itemPadX),
              child: Row(
                mainAxisAlignment: widget.collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: m.ui,
                    curve: m.tactile,
                    style: TextStyle(color: on ? c.amber400 : c.textTertiary),
                    child: WizIcon(it.icon, size: WizRail.glyph),
                  ),
                  if (!widget.collapsed) ...[
                    const SizedBox(width: WizRail.iconGap),
                    // Tight, so the meta stays pinned to the right edge
                    // (Sidebar.jsx `flex: 1`) and a long room name
                    // ellipsises rather than overflowing.
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text(
                        it.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: wiz.typography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: WizRail.labelTracking,
                          color: on ? c.textPrimary : c.textSecondary,
                          height: 1,
                        ),
                      ),
                    ),
                    if (it.meta != null)
                      Text(
                        it.meta!,
                        style: wiz.typography.mono.copyWith(
                          fontSize: WizRail.metaSize,
                          color: c.textTertiary,
                          height: 1,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      if (widget.collapsed) body = Tooltip(message: it.label, child: body);
      return body;
    }

    return Container(
      width: _width(context),
      decoration: BoxDecoration(
        gradient: wizVertical(c.char900, c.char950),
        border: Border(
          right: BorderSide(color: c.edgeHairline, width: s.hairline),
        ),
      ),
      // Sidebar.jsx pads the rail by `--space-7`; the icon-only variant
      // pads by s4 instead, so a 42-tall item still centres its glyph
      // inside the 72 the spec gives it.
      padding: EdgeInsets.all(widget.collapsed ? s.s4 : s.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.collapsed
              ? widget.collapsedBrand != null
              : widget.brand != null) ...[
            widget.collapsed ? widget.collapsedBrand! : widget.brand!,
            SizedBox(height: s.s8),
          ],
          Expanded(
            child: SingleChildScrollView(
              // Measured from inside the layout: collapsing the rail is a
              // width change, which relays out without a rebuild here.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  measureCap(widget.value);
                  return Stack(
                    key: containerKey,
                    children: [
                      if (capRect != null)
                        AnimatedPositioned.fromRect(
                          key: const Key('wiz-cap'),
                          rect: capRect!,
                          duration: m.panel,
                          curve: m.settle,
                          child: IgnorePointer(
                            child: WizSurface(
                              spec: wiz.elevation.raised,
                              radius: radius,
                              gradient: wizVertical(
                                c.surfaceKey,
                                c.surfaceRaised,
                              ),
                            ),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < widget.sections.length; i++) ...[
                            if (i > 0) SizedBox(height: s.s8),
                            if (!widget.collapsed)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: s.s3,
                                  bottom: s.s3,
                                ),
                                child: Text(
                                  widget.sections[i].title.toUpperCase(),
                                  style: wiz.typography.caption.copyWith(
                                    color: c.textTertiary,
                                  ),
                                ),
                              ),
                            for (
                              var j = 0;
                              j < widget.sections[i].items.length;
                              j++
                            ) ...[
                              if (j > 0) SizedBox(height: s.s3),
                              itemFor(widget.sections[i].items[j]),
                            ],
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (widget.footer != null && !widget.collapsed) ...[
            SizedBox(height: s.s8),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}
