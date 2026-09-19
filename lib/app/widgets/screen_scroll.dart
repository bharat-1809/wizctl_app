import 'package:flutter/material.dart';

import '../../core/layout/wiz_layout.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_pull_to_refresh.dart';

/// The scrolling body every compact screen shares (`WizCtl_Mobile.dc.html`
/// line 171: `padding: 8px 40px 116px 20px; gap: 16px`): the gutter on both
/// sides, the top inset plus a little air, the bottom inset the shell
/// reports (safe area plus the floating tab bar, Task 19) plus a gap, and a
/// fixed gap between children. Pull to refresh when [onRefresh] is given.
class ScreenScroll extends StatelessWidget {
  final List<Widget> children;
  final double? gap;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  const ScreenScroll({
    super.key,
    required this.children,
    this.gap,
    this.onRefresh,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var gutter = context.layout.gutter;
    var inset = MediaQuery.paddingOf(context);
    var list = ListView.separated(
      controller: controller,
      // Always scrollable, or a short screen could not be pulled.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        gutter,
        inset.top + space.s4,
        gutter,
        inset.bottom + space.s8,
      ),
      itemCount: children.length,
      itemBuilder: (context, i) => children[i],
      separatorBuilder: (context, i) => SizedBox(height: gap ?? space.s6),
    );
    // The insets are spent here; nothing below should add them again.
    var body = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: list,
    );
    var refresh = onRefresh;
    return refresh == null
        ? body
        : WizPullToRefresh(onRefresh: refresh, child: body);
  }
}
