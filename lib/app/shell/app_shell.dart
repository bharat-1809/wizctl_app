import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/wiz_layout.dart';
import '../../features/home/widgets/homes_notice_listener.dart';
import '../widgets/blink_notice_listener.dart';
import 'compact_shell.dart';
import 'desktop_shell.dart';

/// One shell builder for every width (spec §9): the phone's floating tab bar on
/// a compact window, the desktop's rail from medium up. The branch navigator is
/// the same object whichever chrome wraps it, and each branch holds a global
/// navigator key, so a resize across the boundary keeps the route and every
/// route bloc.
///
/// The two app-scope listeners are mounted here, once, rather than on each
/// screen: a home created from the Homes sheet toasts and goes to discovery
/// from wherever the sheet was opened, and a blink can be started from any
/// card. Both need a context under the router, which the shell builder has and
/// the app root does not.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    var compact = context.layout.widthClass.isCompact;
    return HomesNoticeListener(
      child: BlinkNoticeListener(
        child: compact
            ? CompactShell(shell: shell)
            : DesktopShell(shell: shell),
      ),
    );
  }
}
