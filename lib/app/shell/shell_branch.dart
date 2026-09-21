import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/widgets/wiz_tab_bar.dart';
import '../routes.dart';

/// The shell's branches, in the order the `StatefulShellRoute` lists them
/// (spec §9): the four tabs, then discovery, which has no tab.
///
/// The order is the contract between the enum and the router — a branch's
/// `index` is the index `StatefulNavigationShell` reports and takes — so a
/// branch may only ever be added at the end, beside its route.
enum ShellBranch {
  home(AppRoutes.home),
  rooms(AppRoutes.rooms),
  modes(AppRoutes.modes),
  settings(AppRoutes.settings),
  discover(AppRoutes.discover);

  /// Where `goBranch` lands: the branch's first route.
  final String path;

  const ShellBranch(this.path);

  static ShellBranch of(int index) => values[index];

  /// The phone's tab bar (`WizCtl_Mobile.dc.html` `tabs`). Discovery is not
  /// here: it is reached from Home and from the unreachable banner, and its
  /// branch hides the bar (see `CompactShell.showsTabBar`).
  static const List<WizTab<ShellBranch>> tabs = [
    WizTab(value: home, icon: WizIcons.house, label: Strings.tabHome),
    WizTab(value: rooms, icon: WizIcons.layoutGrid, label: Strings.rooms),
    WizTab(value: modes, icon: WizIcons.sparkles, label: Strings.tabScenes),
    WizTab(
      value: settings,
      icon: WizIcons.slidersHorizontal,
      label: Strings.settings,
    ),
  ];
}
