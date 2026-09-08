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
    var layout = context.dependOnInheritedWidgetOfExactType<WizLayout>();
    assert(layout != null, 'No WizLayoutScope above this widget');
    return layout!;
  }

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
