import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_space.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'wiz_cap_tracker.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

class WizSegment<T> {
  final T value;
  final String label;
  final WizIconData? icon;

  const WizSegment({required this.value, required this.label, this.icon});
}

enum WizSegmentSize { sm, md }

/// Recessed track holding one raised selector that slides between items.
class WizSegmentedControl<T> extends StatefulWidget {
  final List<WizSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool fullWidth;
  final WizSegmentSize size;

  const WizSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.fullWidth = true,
    this.size = WizSegmentSize.md,
  });

  /// Track padding and the gap between items (spec §11.2
  /// `WizSegmentedControl`, "4 padding and gap"; SegmentedControl.jsx
  /// `gap: 4, padding: 4`).
  static const double trackPad = 4;
  static const double gap = 4;

  /// Item label sizes (spec §11.2, "items uppercase 13 / 12";
  /// SegmentedControl.jsx `fontSize: size === 'sm' ? 12 : 13`).
  static const double labelSizeMd = 13;
  static const double labelSizeSm = 12;

  /// Item height (spec §11.2, "Heights 44 / 36"; SegmentedControl.jsx
  /// `const h = size === 'sm' ? 36 : 44`). The md height is written out
  /// rather than taken from `space.controlMd`, which is the 48 button
  /// height; only the sm height has a matching token.
  static const double heightMd = 44;

  /// An unselected item rests a hair small, so the selected one reads as
  /// the raised part (SegmentedControl.jsx `transform: on ? 'scale(1)' :
  /// 'scale(.98)'`).
  static const double restingScale = 0.98;

  /// Gap between an item's icon and its label (SegmentedControl.jsx
  /// `gap: 7`).
  static const double iconGap = 7;

  /// A segment's glyph reads one step above its label, the way a chip's
  /// does (`WizChip`: a body-sized 15 glyph beside a bodySm 13 label).
  static const double iconBump = 2;

  @override
  State<WizSegmentedControl<T>> createState() => _WizSegmentedControlState<T>();
}

class _WizSegmentedControlState<T> extends State<WizSegmentedControl<T>>
    with WizCapTracker<WizSegmentedControl<T>> {
  double _height(WizSpace space) => widget.size == WizSegmentSize.sm
      ? space.controlSm
      : WizSegmentedControl.heightMd;

  double get _labelSize => widget.size == WizSegmentSize.sm
      ? WizSegmentedControl.labelSizeSm
      : WizSegmentedControl.labelSizeMd;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var h = _height(wiz.space);
    var fs = _labelSize;
    var pill = BorderRadius.circular(wiz.space.pill);

    Widget itemFor(WizSegment<T> seg) {
      var on = seg.value == widget.value;
      var ink = on ? c.textPrimary : c.textTertiary;
      // The key goes on the outermost widget of the item, so the tracker
      // measures the whole item rather than the label inside it.
      return Semantics(
        key: keyFor(seg.value as Object),
        selected: on,
        child: WizPressable(
          // The cap is the moving part; the item itself neither sinks nor
          // shrinks under the finger.
          scale: 1,
          travel: 0,
          // Silent on press: the cue belongs to the change, below.
          feedback: null,
          semanticsLabel: seg.label,
          focusRadius: pill,
          // The cap keeps the height the spec draws it at and the finger
          // gets the 44 minimum (spec §399), the way a `WizChip`'s 36 cap
          // does. The padding is the track's own, spent on the item
          // instead, so the control is exactly as tall as it was and a
          // small control's 36 cap sits in a 44 target.
          hitPadding: const EdgeInsets.symmetric(
            vertical: WizSegmentedControl.trackPad,
          ),
          // Segmented controls ride inside scrolling sheets and panels.
          arenaResolved: true,
          onTap: () {
            if (on) return;
            context.feedback.play(FeedbackKind.tick);
            widget.onChanged(seg.value);
          },
          builder: (context, state) => AnimatedScale(
            scale: on ? 1 : WizSegmentedControl.restingScale,
            duration: m.release,
            curve: m.settle,
            child: SizedBox(
              height: h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wiz.space.s6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (seg.icon != null) ...[
                      WizIcon(
                        seg.icon!,
                        size: fs + WizSegmentedControl.iconBump,
                        color: ink,
                      ),
                      const SizedBox(width: WizSegmentedControl.iconGap),
                    ],
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: m.ui,
                        curve: m.tactile,
                        style: wiz.typography.body.copyWith(
                          fontSize: fs,
                          fontWeight: FontWeight.w700,
                          letterSpacing: fs * WizType.segmentTracking,
                          color: ink,
                          height: 1,
                        ),
                        child: Text(
                          seg.label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    var items = widget.segments
        .map((seg) {
          var item = itemFor(seg);
          return widget.fullWidth ? Expanded(child: item) : item;
        })
        .toList(growable: false);

    return WizSurface(
      spec: wiz.elevation.well,
      radius: pill,
      gradient: wizVertical(c.char1000, c.char900),
      // Horizontal only: the vertical 4 is carried by each item's hit
      // padding instead, which puts it inside the touch target rather than
      // outside it. The track measures the same either way.
      padding: const EdgeInsets.symmetric(
        horizontal: WizSegmentedControl.trackPad,
      ),
      // Layout alone does not rebuild, so the measurement is scheduled from
      // here: a resized track re-measures without a rebuild from above.
      child: LayoutBuilder(
        builder: (context, constraints) {
          measureCap(
            widget.value,
            inset: const EdgeInsets.symmetric(
              vertical: WizSegmentedControl.trackPad,
            ),
          );
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
                      radius: pill,
                      gradient: wizVertical(c.surfaceKey, c.surfaceRaised),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: widget.fullWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: WizSegmentedControl.gap),
                    items[i],
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
