import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_cap_tracker.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

class WizTab<T> {
  final T value;
  final WizIconData icon;
  final String label;

  const WizTab({required this.value, required this.icon, required this.label});
}

/// Floating bottom nav on the phone: the amber cap slides to the tab you pick.
class WizTabBar<T> extends StatefulWidget {
  final List<WizTab<T>> tabs;
  final T value;
  final ValueChanged<T> onChanged;

  const WizTabBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
  });

  /// Item square, bar padding and glyph (spec §11.2 `WizTabBar`, "items 52
  /// squares"; TabBar.jsx `width: 52, height: 52`, `padding: '0 10px'`).
  static const double itemSize = 52;
  static const double padX = 10;

  /// Phosphor glyphs read at 20–24 in a row; the tab bar takes the middle
  /// (`WizIcon`, spec §11.1).
  static const double glyph = 22;

  /// The selected icon grows a little inside its cap (spec §11.2,
  /// "selected icon onAccent and scale 1.06"; TabBar.jsx `transform: on ?
  /// 'scale(1.06)' : 'scale(1)'`).
  static const double selectedScale = 1.06;

  @override
  State<WizTabBar<T>> createState() => _WizTabBarState<T>();
}

class _WizTabBarState<T> extends State<WizTabBar<T>>
    with WizCapTracker<WizTabBar<T>> {
  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;

    Widget tabFor(WizTab<T> tab) {
      var on = tab.value == widget.value;
      return Semantics(
        key: keyFor(tab.value as Object),
        selected: on,
        child: WizPressable(
          // The cap moves, the tab stays put.
          scale: 1,
          travel: 0,
          feedback: null,
          semanticsLabel: tab.label,
          focusRadius: BorderRadius.circular(wiz.space.r3),
          onTap: () {
            if (on) return;
            context.feedback.play(FeedbackKind.tick);
            widget.onChanged(tab.value);
          },
          builder: (context, state) => SizedBox(
            width: WizTabBar.itemSize,
            height: WizTabBar.itemSize,
            child: Center(
              child: AnimatedScale(
                scale: on ? WizTabBar.selectedScale : 1,
                duration: m.panel,
                curve: m.settle,
                child: AnimatedDefaultTextStyle(
                  duration: m.ui,
                  curve: m.tactile,
                  style: TextStyle(color: on ? c.textOnAccent : c.textTertiary),
                  child: WizIcon(tab.icon, size: WizTabBar.glyph),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return WizSurface(
      spec: wiz.elevation.key,
      radius: BorderRadius.circular(wiz.space.r5),
      gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
      height: wiz.space.tabBar,
      padding: const EdgeInsets.symmetric(horizontal: WizTabBar.padX),
      // Measured from inside the layout, so a rotation or a resize moves the
      // cap without waiting for a rebuild from above.
      child: LayoutBuilder(
        builder: (context, constraints) {
          measureCap(widget.value);
          return Stack(
            key: containerKey,
            // The row of 52 squares rides in the middle of the 72 bar
            // (TabBar.jsx `alignItems: 'center'`).
            alignment: Alignment.center,
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
                      radius: BorderRadius.circular(wiz.space.r3),
                      gradient: wizVertical(c.amber400, c.amber600),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [for (var tab in widget.tabs) tabFor(tab)],
              ),
            ],
          );
        },
      ),
    );
  }
}
