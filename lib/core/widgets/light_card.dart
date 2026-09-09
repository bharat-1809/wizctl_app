import 'package:flutter/material.dart';

import '../copy/strings.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'light_card_brightness.dart';
import 'light_card_well.dart';
import 'wiz_glow.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';
import 'wiz_toggle.dart';

export 'light_card_brightness.dart' show WizBrightnessControl;

/// A single light: name, mode or address meta, power switch, and brightness
/// as a rail (phone) or a read-only meter (desktop grid). A plug shows
/// neither. Emits the amber ring while lit; drops to 55 % when unreachable.
///
/// The name and meta ellipsise, so a card needs a bounded width: a vertical
/// list, or a grid tile.
///
/// The well and the brightness row are [LightCardWell] and
/// [LightCardBrightness]; this file is the card's chassis, copy and switch.
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

  /// What a bulb dims between: the rail's own bounds, named here too because
  /// the card is what callers hold. See [LightCardBrightness] for the
  /// citation.
  static const double brightnessMin = LightCardBrightness.brightnessMin;
  static const double brightnessMax = LightCardBrightness.brightnessMax;

  /// The name: LightCard.jsx `fontSize: 16.5, fontWeight: 600` (`:1910`,
  /// `:1911`) and `lineHeight: 1.2` (`:1913`); spec §11.2, "name 16.5 / 600".
  /// Its `-.005em` tracking is [WizType.rowTitleTracking].
  static const double titleSize = 16.5;
  static const FontWeight titleWeight = FontWeight.w600;
  static const double titleHeight = 1.2;

  /// The mono meta, a half step under the `mono` token: LightCard.jsx
  /// `fontSize: 11` (`:1923`); spec §11.2, "mono meta 11".
  static const double metaSize = 11;

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
    var dims = lit && control != WizBrightnessControl.none;
    var radius = BorderRadius.circular(wiz.space.r4);

    var header = Row(
      // LightCard.jsx `gap: 13` (`:1883`), between every child alike.
      spacing: wiz.space.s5 + wiz.space.s1 / 2,
      children: [
        LightCardWell(icon: icon, lit: lit),
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
    if (dims) {
      // A node of its own, for the switch's reason. An inert rail annotates
      // with no actions either, so without this it would swallow the card's
      // copy and leave the card button unnamed.
      second = Semantics(
        container: true,
        child: LightCardBrightness(
          control: control,
          brightness: brightness,
          pct: _pct,
          onBrightness: onBrightness,
          onBrightnessEnd: onBrightnessEnd,
        ),
      );
    } else if (unreachable) {
      second = Row(
        // LightCard.jsx `gap: 7` (`:1984`).
        spacing: wiz.space.s3 + wiz.space.s1 / 2,
        children: [
          WizIcon(WizIcons.wifi, size: unreachableGlyph, color: c.signalDanger),
          Expanded(
            child: Text(
              Strings.noResponse,
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
}
