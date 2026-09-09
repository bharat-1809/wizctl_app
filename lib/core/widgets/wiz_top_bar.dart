import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';

/// Screen header: optional leading key, display-face title with sub-line,
/// trailing slot.
///
/// The titles ellipsise, so the bar needs a bounded width: the top of a
/// screen's column, or an `Expanded`/`Flexible` in a row.
class WizTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const WizTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  /// TopBar.jsx `minHeight: 56` (spec §11.2, "min height 56"). Written out
  /// rather than taken from `space.controlLg`, which is the 56 button
  /// height: the two are the same number for different reasons.
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    // TopBar.jsx `gap: 14`, between the leading slot, the titles and the
    // trailing slot alike.
    var gap = wiz.space.s5 + wiz.space.s1;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: gap)],
          Expanded(
            child: Column(
              // Without this the titles take every pixel of a bounded
              // height offered from above — a `Center`, a sized box — and
              // the bar measures that instead of its own [minHeight].
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: wiz.typography.title.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Padding(
                    // TopBar.jsx `marginTop: 2` under the title.
                    padding: EdgeInsets.only(top: wiz.space.s1),
                    child: Text(
                      subtitle!,
                      style: wiz.typography.bodySm.copyWith(
                        color: c.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: gap), trailing!],
        ],
      ),
    );
  }
}
