import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/wiz_layout.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_tab_bar.dart';
import 'shell_branch.dart';

/// The phone chrome (spec §9): the branch navigator under a floating tab bar
/// that hides on discovery.
///
/// The bar's height and float are added to the bottom inset the screens read,
/// so their content scrolls clear of it instead of ending underneath it.
class CompactShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const CompactShell({super.key, required this.shell});

  /// Discovery is a branch without a tab, and a scan is a full-screen job
  /// with its own way back (spec §10.8).
  static bool showsTabBar(int branchIndex) =>
      ShellBranch.of(branchIndex) != ShellBranch.discover;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var media = MediaQuery.of(context);
    var shows = showsTabBar(shell.currentIndex);
    var lift = shows ? space.tabBar + space.tabBarFloat : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(
              bottom: media.padding.bottom + lift,
            ),
          ),
          child: shell,
        ),
        if (shows)
          Positioned(
            left: context.layout.gutter,
            right: context.layout.gutter,
            bottom: media.padding.bottom + space.tabBarFloat,
            child: WizTabBar<ShellBranch>(
              tabs: ShellBranch.tabs,
              value: ShellBranch.of(shell.currentIndex),
              onChanged: (branch) => shell.goBranch(
                branch.index,
                // A tap on the tab already showing goes back to that branch's
                // first route, the way a phone's tab bar does — so a room
                // detail leaves when Rooms is tapped again.
                initialLocation: branch.index == shell.currentIndex,
              ),
            ),
          ),
      ],
    );
  }
}
