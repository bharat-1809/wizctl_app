import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'toast_controller.dart';
import 'wiz_toast.dart';

/// Where the stack sits: above the floating tab bar on a phone, in the
/// bottom-right corner on desktop (spec §11.2, "placed above the tab bar on
/// compact, bottom-right 340 wide on desktop").
enum WizToastPlacement { aboveTabBar, bottomRight }

/// Stacks the controller's toasts at the bottom of the screen. Toasts rise
/// in on the settle curve, newest above the ones already up.
///
/// Must be a direct child of a [Stack]: it builds a [Positioned].
class WizToastLayer extends StatelessWidget {
  final ToastController controller;
  final WizToastPlacement placement;

  /// The window's bottom safe-area inset, so the stack clears the home
  /// indicator — not the tab bar height; the placement adds that. Added to
  /// whatever the placement already reserves.
  final double bottomInset;

  const WizToastLayer({
    super.key,
    required this.controller,
    required this.placement,
    this.bottomInset = 0,
  });

  /// Desktop toasts do not stretch: spec §10.9, "Toasts stack bottom-right,
  /// 340 wide" (desktop.jsx `width: 340`,
  /// `design/reference/_ds_bundle.js:3760`).
  static const double desktopWidth = 340;

  /// Rise 10 px and scale from .97 as a toast fades in: ToastStack.jsx
  /// `@keyframes wz-toast-in{from{transform:translateY(10px) scale(.97);
  /// opacity:0}}` (`design/reference/_ds_bundle.js:2536`).
  static const double riseFrom = 10;
  static const double scaleFrom = 0.97;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var desktop = placement == WizToastPlacement.bottomRight;
    // ToastStack.jsx pins the stack `left`/`right` to `--space-6`
    // (`design/reference/_ds_bundle.js:2544`); desktop.jsx overrides it to a
    // fixed width against `--space-8` (`:3759`).
    var margin = desktop ? wiz.space.s8 : wiz.space.s6;
    return Positioned(
      left: desktop ? null : margin,
      right: margin,
      // The phone's tab bar floats, so the stack clears its height and its
      // float (spec §11.2, "tab bar height 72, float 18") before the safe
      // area. app.jsx reserves `calc(var(--tabbar-height) + 28px)`
      // (`design/reference/_ds_bundle.js:4152`); the tokens are what the
      // Flutter tab bar is actually built from.
      bottom:
          (desktop ? margin : wiz.space.tabBar + wiz.space.tabBarFloat) +
          bottomInset,
      width: desktop ? desktopWidth : null,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // ToastStack.jsx `flexDirection: 'column-reverse'` when the stack
          // is anchored to the bottom (`:2549`): the newest toast rises
          // above the ones already up, rather than pushing them off.
          verticalDirection: VerticalDirection.up,
          // ToastStack.jsx `gap: 'var(--space-4)'` (`:2550`).
          spacing: wiz.space.s4,
          children: [
            for (var toast in controller.toasts)
              _Enter(
                // Keyed by id so a toast already up keeps its element, and
                // so its entrance does not replay when the queue changes.
                key: ValueKey(toast.id),
                child: WizToast(
                  data: toast,
                  onDismiss: () => controller.dismiss(toast.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rises, scales and fades a toast in once, on mount. Implicit rather than
/// driven by a controller, so there is no lifecycle to get wrong and no
/// duration written anywhere but the motion tokens.
class _Enter extends StatelessWidget {
  final Widget child;

  const _Enter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var motion = context.wiz.motion;
    // Reduced motion starts the toast where it ends: present, not moving.
    var reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? 1 : 0, end: 1),
      // Toast.jsx `animation: 'wz-toast-in var(--dur-panel) var(--ease-settle)'`
      // (`design/reference/_ds_bundle.js:2462`); spec §11.2, "260 ms rise-in".
      duration: motion.panel,
      curve: motion.settle,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, WizToastLayer.riseFrom * (1 - t)),
          child: Transform.scale(
            scale: WizToastLayer.scaleFrom + (1 - WizToastLayer.scaleFrom) * t,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}
