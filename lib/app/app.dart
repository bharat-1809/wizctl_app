import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/feedback/feedback_scope.dart';
import '../core/layout/wiz_layout.dart';
import '../core/theme/wiz_theme.dart';
import '../core/widgets/toast_controller.dart';
import '../core/widgets/wiz_app_background.dart';
import '../core/widgets/wiz_toast_layer.dart';
import '../features/gallery/gallery_screen.dart';
import 'bootstrap.dart';

/// The root: the kit's theme, the width class, the feedback layer, the
/// chassis background and the toast stack, wrapped around whatever screen is
/// on show.
class WizCtlApp extends StatelessWidget {
  final AppServices services;

  const WizCtlApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return FeedbackScope(
      service: services.feedback,
      child: MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildWizThemeData(),
        builder: (context, child) => WizLayoutScope(
          child: WizAppBackground(
            child: _ToastOverlay(
              toasts: services.toasts,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
        // Plan 4 replaces this with the router; until then the debug gallery
        // is the only screen there is, and a release build has none.
        home: kDebugMode
            ? GalleryScreen(toasts: services.toasts)
            : const _ReleasePlaceholder(),
      ),
    );
  }
}

/// The window title. Not user-facing copy in the [Strings] sense — it is the
/// application's own name, which does not translate.
const String appTitle = 'WizCtl';

/// Puts the toast stack over the current screen: above the floating tab bar
/// on a phone, bottom-right on anything wider (spec §11.2).
///
/// It lives here rather than on each screen so that a toast pushed by a
/// command outlives the screen that started it.
class _ToastOverlay extends StatelessWidget {
  final ToastController toasts;
  final Widget child;

  const _ToastOverlay({required this.toasts, required this.child});

  @override
  Widget build(BuildContext context) {
    var compact = context.layout.widthClass.isCompact;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        WizToastLayer(
          controller: toasts,
          placement: compact
              ? WizToastPlacement.aboveTabBar
              : WizToastPlacement.bottomRight,
          // The safe-area inset only: the placement adds the tab bar's own
          // height and float on top of it.
          bottomInset: MediaQuery.paddingOf(context).bottom,
        ),
      ],
    );
  }
}

/// What a release build shows until Plan 4 lands the real shell.
class _ReleasePlaceholder extends StatelessWidget {
  const _ReleasePlaceholder();

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Scaffold(
      // The chassis, its vignette and its grain are painted by
      // `WizAppBackground` above this; the scaffold only holds the layout,
      // as it does on the gallery. `Colors.transparent` is the same
      // non-chromatic use `buildWizThemeData` already makes of it.
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          appTitle,
          style: wiz.typography.title.copyWith(color: wiz.colors.textPrimary),
        ),
      ),
    );
  }
}
