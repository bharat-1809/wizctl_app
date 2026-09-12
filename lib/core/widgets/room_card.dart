import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import '../util/plural.dart';
import 'wiz_glow.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';
import 'wiz_toggle.dart';

/// Room summary tile: room glyph, light count, how many are on, master
/// switch. One tile of the home grid; tapping it opens the room.
class RoomCard extends StatelessWidget {
  final String name;
  final WizIconData icon;
  final int lightCount;
  final int onCount;
  final bool on;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.name,
    required this.icon,
    required this.lightCount,
    required this.onCount,
    required this.on,
    this.onToggle,
    this.onTap,
  });

  /// The glyph well and its glyph: RoomCard.jsx `width: 42, height: 42`
  /// (`design/reference/_ds_bundle.js:2042`) and `size: 21` (`:2053`).
  /// Spec §11.2, "42 glyph well".
  static const double well = 42;
  static const double glyph = 21;

  /// The name: RoomCard.jsx `fontSize: 19, fontWeight: 600` (`:2063`,
  /// `:2064`) and `lineHeight: 1.15` (`:2066`); spec §11.2, "name 19 / 600".
  /// Its `-.01em` tracking is [WizType.roomTitleTracking].
  static const double titleSize = 19;
  static const FontWeight titleWeight = FontWeight.w600;
  static const double titleHeight = 1.15;

  /// A room name is longer than a light's and the tile is narrower, so it
  /// takes a second line before it ellipsises.
  static const int titleMaxLines = 2;

  /// "3 lights · 2 on", or "· all off" when none are: RoomCard.jsx `:2075`.
  String get _meta =>
      '${plural(lightCount, 'light')} · ${onCount > 0 ? '$onCount on' : 'all off'}';

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var radius = BorderRadius.circular(wiz.space.r4);

    Widget card(bool pressed) => Stack(
      fit: StackFit.passthrough,
      children: [
        // RoomCard.jsx `boxShadow: on ? 'var(--elev-panel),var(--glow-amber)'`
        // (`:2027`), faded in and out by `WizGlow` rather than by a
        // controller of this card's own.
        Positioned.fill(
          child: WizGlow(
            on: on,
            shadows: wiz.elevation.glowAmber,
            radius: radius,
          ),
        ),
        WizSurface(
          spec: pressed ? wiz.elevation.pressed : wiz.elevation.panel,
          radius: radius,
          gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
          padding: EdgeInsets.all(wiz.space.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizSurface(
                    spec: wiz.elevation.well,
                    radius: BorderRadius.circular(wiz.space.r2),
                    color: c.char1000,
                    width: well,
                    height: well,
                    alignment: Alignment.center,
                    // The glyph warms with the room over the same duration
                    // the glow behind the tile takes.
                    child: AnimatedDefaultTextStyle(
                      duration: m.light,
                      curve: m.tactile,
                      style: TextStyle(color: on ? c.amber400 : c.textTertiary),
                      child: WizIcon(icon, size: glyph),
                    ),
                  ),
                  const Spacer(),
                  // A node of its own, always: a switch given no handler is
                  // disabled, and a disabled `WizPressable` annotates with no
                  // actions at all — a config like that dissolves into
                  // whichever node it lands in, which would have the tile
                  // read the room's name twice. Same guard as `LightCard`'s.
                  Semantics(
                    container: true,
                    child: WizToggle(
                      value: on,
                      onChanged: onToggle,
                      size: WizToggleSize.sm,
                      enabled: onToggle != null,
                      semanticsLabel: name,
                    ),
                  ),
                ],
              ),
              // RoomCard.jsx `gap: 18` (`:2023`).
              SizedBox(height: wiz.space.s6 + wiz.space.s1),
              Text(
                name,
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: wiz.typography.body.copyWith(
                  fontSize: titleSize,
                  fontWeight: titleWeight,
                  letterSpacing: titleSize * WizType.roomTitleTracking,
                  height: titleHeight,
                  color: c.textPrimary,
                ),
              ),
              // RoomCard.jsx `marginTop: 3` (`:2071`).
              SizedBox(height: wiz.space.s1 + wiz.space.s1 / 2),
              Text(
                _meta,
                style: wiz.typography.bodySm.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return card(false);
    return WizPressable(
      onTap: onTap,
      // RoomCard.jsx `scale(.975)` (`:2028`).
      scale: m.cardScale,
      // No `semanticsLabel`: the pressable already marks the node a button,
      // and the name and count inside it name it. Naming it again would have
      // assistive tech read the room's name twice.
      //
      // The tile wraps its master switch, so the sink waits for the arena
      // rather than firing under a finger that is on its way to the switch.
      arenaResolved: true,
      builder: (context, state) => card(state.pressed),
    );
  }
}
