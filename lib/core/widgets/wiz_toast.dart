import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'toast_controller.dart';
import 'wiz_button.dart';
import 'wiz_pressable.dart';
import 'wiz_spinner.dart';
import 'wiz_surface.dart';

/// One toast: an event, never a condition. Rendered by `WizToastLayer`;
/// mounted directly only in tests and gallery pages.
class WizToast extends StatelessWidget {
  final WizToastData data;

  /// Null hides the dismiss key. The layer always passes one.
  final VoidCallback? onDismiss;

  const WizToast({super.key, required this.data, this.onDismiss});

  /// The icon well and what sits in it: Toast.jsx `width: 26, height: 26`
  /// (`design/reference/_ds_bundle.js:2467`), the resolved glyph's
  /// `size: 14` (`:2481`) and the loading `Spinner size={16}` (`:2478`).
  /// Spec §11.2: "26 icon well".
  static const double well = 26;
  static const double glyph = 14;
  static const double spinner = 16;

  /// The dismiss key's cap: Toast.jsx `width: 26, height: 26` (`:2507`) and
  /// `borderRadius: '50%'` (`:2513`) on a transparent ground (`:2514`).
  static const double dismissCap = 26;

  /// The title: Toast.jsx `fontSize: 13.5, fontWeight: 600` (`:2491`).
  static const double titleSize = 13.5;
  static const FontWeight titleWeight = FontWeight.w600;

  /// The body runs a half step under `bodySm`: Toast.jsx `fontSize: 12`
  /// (`:2499`).
  static const double bodySize = 12;

  /// The drop the card casts beyond `elev-key`, so a toast reads as floating
  /// over the screen rather than sitting on it: Toast.jsx
  /// `0 18px 40px -18px rgba(0,0,0,.8)` (`:2461`).
  static const double dropOffsetY = 18;
  static const double dropBlur = 40;
  static const double dropSpread = -18;
  static const double dropAlpha = 0.8;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var key = wiz.elevation.key;
    var (icon, color) = switch (data.tone) {
      WizToastTone.success => (WizIcons.check, c.signalOnline),
      WizToastTone.error => (WizIcons.x, c.signalDanger),
      // No glyph, so the tone's amber is the spinner's accent default.
      WizToastTone.loading => (null, c.amber400),
      WizToastTone.info => (WizIcons.zap, c.textSecondary),
    };
    return Semantics(
      // Ruling: every toast is a live region, so a screen reader announces
      // it once when it arrives. The JSX narrows this to errors
      // (`design/reference/_ds_bundle.js:2453`); a toast is the only report
      // a write gets, so none of them may pass silently.
      container: true,
      liveRegion: true,
      // Without this the action and dismiss keys merge into the live region
      // and the toast becomes one unlabelled button: `WizPressable` marks
      // itself with `container: false`, so only the region above it can
      // force its keys to stay separate nodes.
      explicitChildNodes: true,
      child: WizSurface(
        spec: WizShadowSpec(
          insets: key.insets,
          outer: [
            ...key.outer,
            BoxShadow(
              color: c.shadowBase.withValues(alpha: dropAlpha),
              offset: const Offset(0, dropOffsetY),
              blurRadius: dropBlur,
              spreadRadius: dropSpread,
            ),
          ],
        ),
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
        // Toast.jsx `padding: '11px 13px'` (`:2458`): the 12 px `s5` step
        // one either side of half the 2 px `s1` step.
        padding: EdgeInsets.symmetric(
          vertical: wiz.space.s5 - wiz.space.s1 / 2,
          horizontal: wiz.space.s5 + wiz.space.s1 / 2,
        ),
        child: Row(
          // Toast.jsx `gap: 12` (`:2457`), between every child alike.
          spacing: wiz.space.s5,
          children: [
            WizSurface(
              spec: wiz.elevation.well,
              radius: BorderRadius.circular(wiz.space.r1),
              color: c.char1000,
              width: well,
              height: well,
              alignment: Alignment.center,
              child: icon == null
                  ? const WizSpinner(size: spinner)
                  : WizIcon(icon, size: glyph, color: color),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: wiz.typography.body.copyWith(
                      fontSize: titleSize,
                      fontWeight: titleWeight,
                      // Toast.jsx `letterSpacing: '-.005em'` (`:2493`), the
                      // em value the kit states once on the row title.
                      letterSpacing: titleSize * WizType.rowTitleTracking,
                      color: c.textPrimary,
                    ),
                  ),
                  if (data.body != null)
                    Padding(
                      // Toast.jsx `marginTop: 1` (`:2498`).
                      padding: EdgeInsets.only(top: wiz.space.s1 / 2),
                      child: Text(
                        data.body!,
                        style: wiz.typography.bodySm.copyWith(
                          fontSize: bodySize,
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (data.actionLabel != null)
              WizButton(
                label: data.actionLabel!,
                variant: WizButtonVariant.ghost,
                size: WizButtonSize.sm,
                onPressed: data.onAction,
              ),
            if (onDismiss != null) _DismissKey(onDismiss: onDismiss!),
          ],
        ),
      ),
    );
  }
}

/// The bare X. Not a `WizIconKey`: the JSX draws it on a transparent ground
/// (`design/reference/_ds_bundle.js:2514`), and a raised cap must never nest
/// directly inside the raised card it sits on. `WizPressable` is what still
/// gives it the keyboard activation, the focus ring and the press cue every
/// control in the kit carries.
class _DismissKey extends StatelessWidget {
  final VoidCallback onDismiss;

  const _DismissKey({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var radius = BorderRadius.circular(WizToast.dismissCap / 2);
    return WizPressable(
      onTap: onDismiss,
      scale: wiz.motion.smallKeyScale,
      // Task 27 swaps this for the shared string.
      semanticsLabel: 'Dismiss',
      focusRadius: radius,
      // The cap is drawn smaller than the touch minimum, so the hit area
      // grows around it, the way a `WizIconKey`'s does.
      hitPadding: EdgeInsets.all((wiz.space.hitMin - WizToast.dismissCap) / 2),
      // Nothing in the glyph reacts to the press: the sink and the scale
      // `WizPressable` applies around it are the whole response.
      builder: (context, _) => SizedBox(
        width: WizToast.dismissCap,
        height: WizToast.dismissCap,
        child: Center(
          child: WizIcon(
            WizIcons.x,
            size: WizToast.glyph,
            color: wiz.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}
