import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../motion/reduced_motion.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_scene_art.dart';
import 'wiz_surface.dart';

/// What the Light mode row shows in its art square.
sealed class WizModeArt {
  const WizModeArt();
}

final class SceneModeArt extends WizModeArt {
  final int sceneId;
  const SceneModeArt(this.sceneId);
}

final class SolidModeArt extends WizModeArt {
  final Color color;
  const SolidModeArt(this.color);
}

final class FlatModeArt extends WizModeArt {
  const FlatModeArt();
}

/// The Light mode row: art square, "LIGHT MODE", the current state as a
/// heading (a scene name, "Colour", "2700K white", "Mixed" or "Nothing
/// set") and a chevron well. Opens the three-tab sheet scoped to its target.
///
/// The prototype has no `ModeRow.jsx`: the row is written out where it is
/// used — `design/reference/WizCtl_Mobile.dc.html:220` (the room panel) and
/// `:312` (light detail), `WizCtl_Desktop.dc.html:195` and `:385` — all the
/// same markup. Line citations below are into the mobile file, from `:220`.
class ModeRow extends StatelessWidget {
  final WizModeArt art;
  final String name;
  final VoidCallback? onTap;
  final String label;

  const ModeRow({
    super.key,
    required this.art,
    required this.name,
    required this.onTap,
    this.label = 'Light mode',
  });

  /// The art square (`:221` `width:48px;height:48px`; spec §11.2, "48 art
  /// square").
  static const double artSize = 48;

  /// The chevron's well (`:226` `width:32px;height:32px`).
  static const double chevronWell = 32;

  /// Its glyph, the design system's small icon size (`:227`
  /// `size="{{ icSm }}"`, drawn `15px`; spec §11.3, "14–15 in captions").
  static const double chevronGlyph = 15;

  /// The hairline around the art (`:221`
  /// `box-shadow:inset 0 0 0 1px rgba(0,0,0,.5)`), on `colors.shadowBase`
  /// rather than a literal black.
  static const double artShadowAlpha = .5;

  /// Identity of the flat face — worn by a mode with neither a scene nor a
  /// colour of its own — so the switcher can cross-fade on it.
  static const Key flatArtKey = ValueKey('flat');

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    // `:221` and `:226`, both `border-radius:var(--radius-2)`.
    var artRadius = BorderRadius.circular(wiz.space.r2);
    // The switcher stacks its faces loosely, so each one states that it
    // fills the frame rather than collapsing to nothing around its paint.
    // The art's own key is the identity the cross-fade runs on.
    Widget artWidget = switch (art) {
      // `WizSceneArt.scene` already carries `ValueKey('scene-<id>')`
      // (spec §331), and fills the frame through its own stack.
      SceneModeArt(:var sceneId) => WizSceneArt.scene(
        sceneId,
        radius: artRadius,
      ),
      SolidModeArt(:var color) => DecoratedBox(
        key: ValueKey(color),
        decoration: BoxDecoration(color: color, borderRadius: artRadius),
        child: const SizedBox.expand(),
      ),
      // Nothing set, a mixed selection, a socket: `:873`
      // `const flat = 'linear-gradient(180deg,#24242A,#16161A)'`, which is
      // `char800 → char900`.
      FlatModeArt() => DecoratedBox(
        key: flatArtKey,
        decoration: BoxDecoration(
          gradient: wizVertical(c.char800, c.char900),
          borderRadius: artRadius,
        ),
        child: const SizedBox.expand(),
      ),
    };
    return WizPressable(
      onTap: onTap,
      enabled: onTap != null,
      scale: m.keyScale,
      // The ring traces the key's own shape. This is also the pressable's
      // default; the row states it beside the radius it has to match.
      focusRadius: BorderRadius.circular(wiz.space.r3),
      // Nothing inside the row is a control of its own, so the sink can
      // fire on the raw pointer down instead of waiting for the arena.
      arenaResolved: false,
      // No `semanticsLabel`: the pressable already marks the node a button,
      // and the caps label and name inside it name it. Naming it again
      // would have assistive tech read "Light mode" twice.
      builder: (context, state) => WizSurface(
        // `:220` `box-shadow:var(--elev-raised)`, sinking on
        // `style-active`.
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        // `:220` `border-radius:var(--radius-3)`; spec §11.2, "raised key
        // (radius 14)".
        radius: BorderRadius.circular(wiz.space.r3),
        // `:220`
        // `linear-gradient(180deg,var(--surface-key),var(--surface-raised))`.
        gradient: wizVertical(c.surfaceKey, c.surfaceRaised),
        // `:220` `padding:10px 12px`.
        padding: EdgeInsets.symmetric(
          vertical: wiz.space.s4 + wiz.space.s1,
          horizontal: wiz.space.s5,
        ),
        child: Row(
          children: [
            SizedBox(
              width: artSize,
              height: artSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: artRadius,
                  // The prototype's `1px` hairline is an *inset* shadow,
                  // which a `WizInset` cannot express: with no offset and
                  // no blur, `paintInsets` differences the shape against
                  // itself and paints nothing. So it is spread just outside
                  // the shape instead, the way `WizListRow`'s active ring
                  // is — the art clips to the same radius over it.
                  boxShadow: [
                    BoxShadow(
                      color: c.shadowBase.withValues(alpha: artShadowAlpha),
                      spreadRadius: wiz.space.hairline,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: artRadius,
                  child: AnimatedSwitcher(
                    // Spec §11.2, "art cross-fades 260 ms on change", and
                    // §12, "the mode row art cross-fading 260": the panel
                    // duration on the settle curve. Neither a gradient nor
                    // a scene's paint interpolates, so the two faces
                    // cross-fade the way a `LightCardWell` does.
                    duration: wizReducedMotion(context)
                        ? Duration.zero
                        : m.panel,
                    switchInCurve: m.settle,
                    switchOutCurve: m.settle,
                    child: artWidget,
                  ),
                ),
              ),
            ),
            // `:220` `gap:13px`, which the spacing scale does not reach:
            // the row takes its 14 step beside the art and its 12 step
            // beside the chevron.
            SizedBox(width: wiz.space.s5 + wiz.space.s1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // `:223` `font-size:11px;letter-spacing:.1em;
                  // text-transform:uppercase;color:var(--text-tertiary)`.
                  Text(
                    label.toUpperCase(),
                    style: wiz.typography.label.copyWith(color: c.textTertiary),
                  ),
                  // `:222` `gap:2px`.
                  SizedBox(height: wiz.space.s1),
                  // `:224` the display face at 23 / 600 / .025 em, which is
                  // the `heading` token exactly, ellipsised on overflow.
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wiz.typography.heading.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: wiz.space.s5),
            // `:226` `width:32px;height:32px;border-radius:var(--radius-2);
            // background:var(--char-1000);box-shadow:var(--elev-well);
            // color:var(--text-secondary)`.
            WizSurface(
              spec: wiz.elevation.well,
              radius: artRadius,
              color: c.char1000,
              width: chevronWell,
              height: chevronWell,
              alignment: Alignment.center,
              child: WizIcon(
                WizIcons.chevronRight,
                size: chevronGlyph,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
