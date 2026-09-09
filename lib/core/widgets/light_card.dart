import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'wiz_glow.dart';
import 'wiz_pressable.dart';
import 'wiz_slider.dart';
import 'wiz_surface.dart';
import 'wiz_toggle.dart';

/// Which brightness control a [LightCard] carries under its header: the
/// draggable rail (a phone, and a room's list), a read-only meter (the
/// desktop grid, where the rail belongs to the inspector instead), or
/// neither — a plug switches power only, so there is nothing to dim.
enum WizBrightnessControl { rail, meter, none }

/// A single light: name, mode or address meta, power switch, and brightness
/// as a rail (phone) or a read-only meter (desktop grid). A plug shows
/// neither. Emits the amber ring while lit; drops to 55 % when unreachable.
///
/// The name and meta ellipsise, so a card needs a bounded width: a vertical
/// list, or a grid tile.
class LightCard extends StatelessWidget {
  final String name;
  final String? meta;
  final WizIconData icon;
  final bool on;
  final bool unreachable;
  final double brightness;
  final WizBrightnessControl control;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<double>? onBrightness;
  final ValueChanged<double>? onBrightnessEnd;
  final bool selected;
  final VoidCallback? onTap;

  const LightCard({
    super.key,
    required this.name,
    this.meta,
    this.icon = WizIcons.lightbulb,
    required this.on,
    this.unreachable = false,
    required this.brightness,
    this.control = WizBrightnessControl.rail,
    this.onToggle,
    this.onBrightness,
    this.onBrightnessEnd,
    this.selected = false,
    this.onTap,
  });

  /// What a bulb dims between (spec §5, `brightness /*10–100*/`; LightCard.jsx
  /// `min: 10, max: 100`, `design/reference/_ds_bundle.js:1936`). Stated here
  /// rather than read from the `wizctl` package: the kit knows no protocol.
  static const double brightnessMin = 10;
  static const double brightnessMax = 100;

  /// The icon well and its glyph: LightCard.jsx `width: 46, height: 46`
  /// (`design/reference/_ds_bundle.js:1887`) and `size: 22` (`:1900`).
  /// Spec §11.2, "46 icon well".
  static const double well = 46;
  static const double glyph = 22;

  /// The lit well's fill: LightCard.jsx
  /// `radial-gradient(circle at 50% 30%,var(--amber-400),var(--amber-700))`
  /// (`:1893`). 30 % down the well is -0.4 in [Alignment]'s -1..1 space, and
  /// a CSS radial gradient given no size is `farthest-corner`, which from
  /// there reaches sqrt(0.5² + 0.7²) of a square well's side — Flutter
  /// defaults to 0.5, which would compress amber 700 into the middle.
  static const Alignment wellGradientCentre = Alignment(0, -0.4);
  static const double wellGradientRadius = 0.86;

  /// The lit well's rim and emission: LightCard.jsx
  /// `inset 0 1px 0 rgba(255,255,255,.35),0 0 20px -4px rgba(255,176,32,.7)`
  /// (`:1894`). Unlit it is the plain `--elev-well` of every other well.
  static const double wellRimOffsetY = 1;
  static const double wellRimAlpha = 0.35;
  static const double wellGlowBlur = 20;
  static const double wellGlowSpread = -4;
  static const double wellGlowAlpha = 0.7;

  /// The name: LightCard.jsx `fontSize: 16.5, fontWeight: 600` (`:1910`,
  /// `:1911`) and `lineHeight: 1.2` (`:1913`); spec §11.2, "name 16.5 / 600".
  /// Its `-.005em` tracking is [WizType.rowTitleTracking].
  static const double titleSize = 16.5;
  static const FontWeight titleWeight = FontWeight.w600;
  static const double titleHeight = 1.2;

  /// The mono meta, a half step under the `mono` token: LightCard.jsx
  /// `fontSize: 11` (`:1923`); spec §11.2, "mono meta 11".
  static const double metaSize = 11;

  /// The read-only meter: LightCard.jsx `height: 6` (`:1950`); spec §11.2,
  /// "6 px meter with amber 700 → 300 fill".
  static const double meterThickness = 6;

  /// Its readout: LightCard.jsx `fontSize: 18, fontWeight: 800` (`:1969`,
  /// `:1970`) — the size `readoutSm` already carries, stated so the tracking
  /// beside it reads as the em value it is — and the unit's `fontSize: 10.5`
  /// (`:1977`). Spec §11.2, "an 18 display readout".
  static const double meterReadoutSize = 18;
  static const FontWeight meterReadoutWeight = FontWeight.w800;
  static const double meterUnitSize = 10.5;

  /// The wifi glyph on the unreachable line: LightCard.jsx `size: 15`
  /// (`:1990`).
  static const double unreachableGlyph = 15;

  /// How far a card that is not answering fades back: LightCard.jsx
  /// `opacity: unreachable ? 0.55 : 1` (`:1875`); spec §11.2, "opacity 0.55
  /// when unreachable".
  static const double unreachableOpacity = 0.55;

  /// The whole percentage the meter and the rail's readout show:
  /// LightCard.jsx `Math.min(100, Math.max(0, Math.round(brightness)))`
  /// (`:1862`). The card is drawn from whatever a bulb reported, which is
  /// not promised to sit inside the rail's own bounds.
  int get _pct => brightness.round().clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var lit = on && !unreachable;
    var showRail = lit && control == WizBrightnessControl.rail;
    var showMeter = lit && control == WizBrightnessControl.meter;
    var radius = BorderRadius.circular(wiz.space.r4);

    var header = Row(
      // LightCard.jsx `gap: 13` (`:1883`), between every child alike.
      spacing: wiz.space.s5 + wiz.space.s1 / 2,
      children: [
        AnimatedSwitcher(
          // The gradient and the shadows both change with the state and
          // neither interpolates, so the two wells cross-fade — the recipe
          // `WizToggle` uses for its track.
          duration: m.light,
          switchInCurve: m.tactile,
          switchOutCurve: m.tactile,
          child: _well(wiz, lit),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: wiz.typography.body.copyWith(
                  fontSize: titleSize,
                  fontWeight: titleWeight,
                  letterSpacing: titleSize * WizType.rowTitleTracking,
                  height: titleHeight,
                  color: c.textPrimary,
                ),
              ),
              if (meta != null)
                Padding(
                  // LightCard.jsx `marginTop: 2` (`:1921`).
                  padding: EdgeInsets.only(top: wiz.space.s1),
                  child: Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wiz.typography.mono.copyWith(
                      fontSize: metaSize,
                      color: c.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // A node of its own, always. A disabled `WizPressable` annotates
        // with no actions at all, and a config like that dissolves into
        // whichever node it lands in — so an unreachable card's switch would
        // otherwise pour its label into the card's, which would then read
        // the light's name twice and leave the card button unnamed.
        Semantics(
          container: true,
          child: WizToggle(
            value: lit,
            onChanged: onToggle,
            enabled: !unreachable && onToggle != null,
            semanticsLabel: name,
          ),
        ),
      ],
    );

    Widget? second;
    if (showRail) {
      second = WizSlider(
        value: brightness,
        min: brightnessMin,
        max: brightnessMax,
        // The rail is shown live, so it always drags; a card given no
        // handler simply reports nowhere.
        onChanged: onBrightness ?? (_) {},
        onChangeEnd: onBrightnessEnd,
        label: 'Brightness',
        readout: '$_pct%',
      );
    } else if (showMeter) {
      second = _meter(wiz);
    } else if (unreachable) {
      second = Row(
        // LightCard.jsx `gap: 7` (`:1984`).
        spacing: wiz.space.s3 + wiz.space.s1 / 2,
        children: [
          WizIcon(WizIcons.wifi, size: unreachableGlyph, color: c.signalDanger),
          Expanded(
            // Task 27 swaps this for the shared string.
            child: Text(
              'No response on the local network',
              style: wiz.typography.bodySm.copyWith(color: c.signalDanger),
            ),
          ),
        ],
      );
    }

    Widget card(bool pressed) => AnimatedOpacity(
      opacity: unreachable ? unreachableOpacity : 1,
      duration: m.ui,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Behind the card, in its shape: the ring a lit bulb throws on the
          // chassis, faded in and out by `WizGlow` rather than by a
          // controller of this card's own.
          Positioned.fill(
            child: WizGlow(
              on: lit,
              shadows: wiz.elevation.glowAmber,
              radius: radius,
            ),
          ),
          WizSurface(
            spec: pressed ? wiz.elevation.pressed : wiz.elevation.panel,
            radius: radius,
            gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
            // The desktop grid's selection ring, drawn the way
            // `WizElevation.glowAmber`'s outer ring is (plan §11.2: the
            // inspector marks which card it is showing). The JSX card has no
            // selected state.
            glow: selected
                ? [
                    BoxShadow(
                      color: c.amber500,
                      spreadRadius: wiz.space.keyBorder,
                    ),
                  ]
                : const [],
            padding: EdgeInsets.all(wiz.space.panelPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                // LightCard.jsx `gap: hasSecondRow ? 14 : 0` (`:1870`).
                if (second != null) ...[
                  SizedBox(height: wiz.space.s5 + wiz.space.s1),
                  second,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card(false);
    return WizPressable(
      onTap: onTap,
      scale: m.cardScale,
      // No `semanticsLabel`: the pressable already marks the node a button,
      // and the name and meta inside it name it. Naming it again would have
      // assistive tech read the light's name twice.
      //
      // The card wraps a toggle and a rail, so the sink waits for the arena
      // rather than firing under a finger that is on its way to one of them.
      arenaResolved: true,
      builder: (context, state) => card(state.pressed),
    );
  }

  /// The icon well. Lit it is a hot amber lens; dark it is the recessed
  /// charcoal well every other glyph in the kit sits in.
  Widget _well(WizTheme wiz, bool lit) {
    var c = wiz.colors;
    return WizSurface(
      // Identity, so the switcher above cross-fades on the state rather than
      // rebuilding one surface whose paint would jump.
      key: ValueKey(lit),
      spec: lit
          ? WizShadowSpec(
              insets: [
                WizInset(
                  offsetY: wellRimOffsetY,
                  blur: 0,
                  color: c.highlightBase.withValues(alpha: wellRimAlpha),
                ),
              ],
              outer: [
                BoxShadow(
                  color: c.amber500.withValues(alpha: wellGlowAlpha),
                  blurRadius: wellGlowBlur,
                  spreadRadius: wellGlowSpread,
                ),
              ],
            )
          : wiz.elevation.well,
      radius: BorderRadius.circular(wiz.space.r2),
      gradient: lit
          ? RadialGradient(
              center: wellGradientCentre,
              radius: wellGradientRadius,
              colors: [c.amber400, c.amber700],
            )
          : null,
      color: lit ? null : c.char1000,
      width: well,
      height: well,
      alignment: Alignment.center,
      child: WizIcon(
        icon,
        size: glyph,
        color: lit ? c.textOnAccent : c.textTertiary,
      ),
    );
  }

  /// The read-only brightness meter: a recessed rail with an amber fill and
  /// the percentage beside it. Shown where the drag belongs to something
  /// else — the desktop grid, whose inspector owns the rail.
  Widget _meter(WizTheme wiz) {
    var c = wiz.colors;
    var m = wiz.motion;
    var pill = BorderRadius.circular(wiz.space.pill);
    return Row(
      // LightCard.jsx `gap: 12` (`:1945`).
      spacing: wiz.space.s5,
      children: [
        Expanded(
          child: WizSurface(
            spec: wiz.elevation.well,
            radius: pill,
            gradient: wizVertical(c.char1000, c.char900),
            height: meterThickness,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: m.light,
                curve: m.tactile,
                widthFactor: _pct / 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: pill,
                    // LightCard.jsx
                    // `linear-gradient(90deg,var(--amber-700),var(--amber-300))`
                    // (`:1962`), which is what a `LinearGradient` left to its
                    // own `centerLeft` → `centerRight` already draws.
                    gradient: LinearGradient(colors: [c.amber700, c.amber300]),
                  ),
                  child: const SizedBox(height: meterThickness),
                ),
              ),
            ),
          ),
        ),
        Text.rich(
          TextSpan(
            text: '$_pct',
            children: [
              TextSpan(
                text: '%',
                style: TextStyle(
                  fontSize: meterUnitSize,
                  color: c.textTertiary,
                ),
              ),
            ],
          ),
          style: wiz.typography.readoutSm.copyWith(
            fontSize: meterReadoutSize,
            fontWeight: meterReadoutWeight,
            letterSpacing: meterReadoutSize * WizType.meterReadoutTracking,
            color: c.amber400,
          ),
        ),
      ],
    );
  }
}
