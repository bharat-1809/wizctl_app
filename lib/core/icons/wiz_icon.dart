import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme/wiz_theme.dart';
import 'wiz_icon_data.dart';

/// Paints a Phosphor Bold glyph. Filled, so scale is the only control:
/// 20–24 in rows, 26–30 in empty-state wells, 0.34 × diameter in a power key.
/// Colour defaults to the ambient text colour, like SVG `currentColor`.
class WizIcon extends StatelessWidget {
  final WizIconData icon;
  final double size;
  final Color? color;

  const WizIcon(this.icon, {super.key, required this.size, this.color});

  /// The design grid every glyph is drawn on.
  static const double grid = 256;

  static final Map<String, Path> _cache = {};

  static Path pathFor(WizIconData icon) =>
      _cache.putIfAbsent(icon.name, () => parseSvgPathData(icon.path));

  @override
  Widget build(BuildContext context) {
    var paintColor =
        color ??
        DefaultTextStyle.of(context).style.color ??
        context.wiz.colors.textPrimary;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _IconPainter(pathFor(icon), paintColor)),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final Path path;
  final Color color;

  _IconPainter(this.path, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var scale = size.width / WizIcon.grid;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.path != path || old.color != color;
}
