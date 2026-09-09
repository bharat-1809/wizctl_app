import 'package:flutter/material.dart';

import '../copy/strings.dart';
import '../theme/wiz_theme.dart';
import 'wiz_sheet_route.dart';

/// The one modal surface in the kit: a bottom sheet on a phone, a centred
/// dialog everywhere else (spec §11.2, "`WizSheet`: compact = bottom sheet
/// … medium/expanded = centred dialog").
///
/// Rises and fades in over `WizMotion.panel` on the settle curve behind its
/// own blurred scrim. Escape, a tap on the scrim and — on the phone — a drag
/// downwards all close it, completing the future with `null`.
///
/// [footer] is laid out as one row with the last entry taking the rest of it;
/// [maxWidth] widens the dialog past its 520 default.
///
/// [scrollable], the default, puts [builder]'s result inside the sheet's own
/// scroll view, so an ordinary body — a column of fields, a paragraph — starts
/// scrolling once the sheet reaches its 86 % cap and needs nothing from the
/// caller. Pass `false` when the body is itself a viewport (a `ListView`, a
/// `GridView`, a `CustomScrollView`): it is then handed the sheet's bounded
/// height directly and owns the scrolling, where wrapping it would give it an
/// unbounded height and throw.
Future<T?> showWizSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  List<Widget>? footer,
  double? maxWidth,
  bool scrollable = true,
}) {
  var wiz = context.wiz;
  return showGeneralDialog<T>(
    context: context,
    // Also what arms Escape: `_DismissModalAction` fires only on a route
    // whose barrier is dismissible.
    barrierDismissible: true,
    barrierLabel: Strings.close,
    // The sheet paints its own scrim and blur across the whole route, so the
    // route's own barrier stays invisible underneath it.
    barrierColor: wiz.colors.surfaceScrim.withValues(alpha: 0),
    // Sheet.jsx `animation: 'wz-sheet-in var(--dur-panel) …'`
    // (`design/reference/_ds_bundle.js:2678`); spec §11.2, "260 ms rise 14".
    transitionDuration: wiz.motion.panel,
    pageBuilder: (context, animation, secondary) => WizSheetRoute(
      title: title,
      body: builder(context),
      footer: footer,
      maxWidth: maxWidth,
      scrollable: scrollable,
      animation: animation,
    ),
    // The sheet reads the route's animation itself, so that the scrim, the
    // rise and the drag all come off one value.
    transitionBuilder: (context, animation, secondary, child) => child,
  );
}
