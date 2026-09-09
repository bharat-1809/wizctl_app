import 'package:flutter/widgets.dart';

import '../theme/wiz_theme.dart';
import 'wiz_breakpoints.dart';

/// The current width class and gutter, installed by [WizLayoutScope].
class WizLayout extends InheritedWidget {
  final WidthClass widthClass;
  final double width;
  final double gutter;

  const WizLayout({
    super.key,
    required this.widthClass,
    required this.width,
    required this.gutter,
    required super.child,
  });

  static WizLayout of(BuildContext context) {
    var layout = maybeOf(context);
    assert(layout != null, 'No WizLayoutScope above this widget');
    return layout!;
  }

  /// The layout, or null when there is no [WizLayoutScope] above — for a
  /// widget that can be dropped straight into a gallery page or a test and
  /// still has to choose a size. Depends on the scope exactly as [of] does,
  /// so the caller rebuilds when the width class changes.
  static WizLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WizLayout>();

  @override
  bool updateShouldNotify(WizLayout oldWidget) =>
      widthClass != oldWidget.widthClass ||
      width != oldWidget.width ||
      gutter != oldWidget.gutter;
}

/// Measures its constraints and installs a [WizLayout] for descendants.
class WizLayoutScope extends StatelessWidget {
  final Widget child;

  const WizLayoutScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var widthClass = WizBreakpoints.classify(width);
        return WizLayout(
          widthClass: widthClass,
          width: width,
          gutter: widthClass.isCompact ? space.gutter : space.gutterDesktop,
          child: child,
        );
      },
    );
  }
}

extension WizLayoutContext on BuildContext {
  WizLayout get layout => WizLayout.of(this);
}
