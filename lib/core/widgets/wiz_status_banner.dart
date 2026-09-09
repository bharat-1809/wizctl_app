import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'wiz_spinner.dart';
import 'wiz_surface.dart';

/// StatusBanner.jsx `STATUS_TONES` (`design/reference/_ds_bundle.js:2322`).
enum WizStatus { loading, success, error, warn, info }

/// Inline state band: what is happening, and what to do about it. A banner
/// is a condition; if the user can fix it, it is a banner, not a toast
/// (spec §15, "A banner is a condition, a toast is an event").
class WizStatusBanner extends StatelessWidget {
  final WizStatus status;
  final String title;
  final String? body;

  /// The trailing slot, normally a `WizButton`. The banner does not build it,
  /// so a screen can put a key, a badge or nothing there.
  final Widget? action;

  const WizStatusBanner({
    super.key,
    required this.status,
    required this.title,
    this.body,
    this.action,
  });

  /// The icon well and what sits in it: StatusBanner.jsx `width: 30,
  /// height: 30` (`design/reference/_ds_bundle.js:2374`), the resolved
  /// glyph's `size: 16` (`:2388`) and the loading `Spinner size={18}`
  /// (`:2385`). Spec §11.2: "30 icon well".
  static const double well = 30;
  static const double glyph = 16;
  static const double spinner = 18;

  /// The title: StatusBanner.jsx `fontSize: 14, fontWeight: 600`
  /// (`design/reference/_ds_bundle.js:2398`); spec §11.2, "title 14 / 600".
  static const double titleSize = 14;
  static const FontWeight titleWeight = FontWeight.w600;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    // StatusBanner.jsx `gap: 13` (`design/reference/_ds_bundle.js:2365`):
    // 12 plus the 1 that half the 2 px `s1` step gives, the way a badge's
    // 9 px padding is written.
    var gap = wiz.space.s5 + wiz.space.s1 / 2;
    var (icon, color) = switch (status) {
      // Loading has no glyph, so the tone's `--text-secondary` never paints;
      // the amber the spec asks for is the spinner's own accent default.
      WizStatus.loading => (null, c.textSecondary),
      WizStatus.success => (WizIcons.check, c.signalOnline),
      WizStatus.error => (WizIcons.x, c.signalDanger),
      WizStatus.warn => (WizIcons.wifi, c.signalWarn),
      WizStatus.info => (WizIcons.terminal, c.textSecondary),
    };
    return Semantics(
      // The band is a container whose children are explicit, so an [action]
      // key stays its own node: `WizPressable` annotates with
      // `container: false`, so without this the whole banner collapses into
      // a single unlabelled button. The live region is *not* here — a node
      // with explicit children absorbs no words, so it would announce
      // nothing; it goes around the copy below instead.
      container: true,
      explicitChildNodes: true,
      child: WizSurface(
        spec: wiz.elevation.well,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(c.char900, c.char950),
        // StatusBanner.jsx `padding: '12px 14px'` (`:2366`).
        padding: EdgeInsets.symmetric(
          vertical: wiz.space.s5,
          horizontal: wiz.space.s5 + wiz.space.s1,
        ),
        child: Row(
          spacing: gap,
          children: [
            WizSurface(
              // The JSX draws this well with a lighter bespoke
              // `inset 0 1px 3px rgba(0,0,0,.6)` (`:2381`); the kit's `well`
              // token is used instead, as `WizListRow`'s icon well does.
              spec: wiz.elevation.well,
              radius: BorderRadius.circular(wiz.space.r2),
              color: c.char1000,
              width: well,
              height: well,
              alignment: Alignment.center,
              child: icon == null
                  ? const WizSpinner(size: spinner)
                  : WizIcon(icon, size: glyph, color: color),
            ),
            Expanded(
              // StatusBanner.jsx `role: status === 'error' ? 'alert' :
              // 'status'` (`design/reference/_ds_bundle.js:2361`): only a
              // failure interrupts.
              //
              // It sits on the copy rather than on the band: with no
              // explicit children of its own this node absorbs both Texts,
              // so the region announces "title, body" — while an action key
              // outside it stays separately reachable.
              child: Semantics(
                container: true,
                liveRegion: status == WizStatus.error,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: wiz.typography.body.copyWith(
                        fontSize: titleSize,
                        fontWeight: titleWeight,
                        // StatusBanner.jsx `letterSpacing: '-.005em'`
                        // (`:2400`), the em value the kit states once on the
                        // row title.
                        letterSpacing: titleSize * WizType.rowTitleTracking,
                        color: c.textPrimary,
                      ),
                    ),
                    if (body != null)
                      Padding(
                        // StatusBanner.jsx `marginTop: 1` (`:2406`): half the
                        // 2 px `s1` step, the smallest gap the scale reaches.
                        padding: EdgeInsets.only(top: wiz.space.s1 / 2),
                        child: Text(
                          body!,
                          style: wiz.typography.bodySm.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
