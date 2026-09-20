import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/widgets/homes_notice_listener.dart';
import '../widgets/blink_notice_listener.dart';
import 'compact_shell.dart';

/// One shell builder for every width (spec §9): the branch navigator is the
/// same object whichever chrome wraps it, so the route and its blocs survive a
/// resize. Task 20 adds the desktop chrome for the wider classes by switching
/// on `context.layout.widthClass` here; until then every width gets the phone
/// chrome.
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
    return HomesNoticeListener(
      child: BlinkNoticeListener(child: CompactShell(shell: shell)),
    );
  }
}
