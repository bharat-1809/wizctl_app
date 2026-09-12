import 'package:flutter/widgets.dart';

import '../theme/wiz_textures.dart';

/// Paints the machined grain over whatever it is stacked on. Ignores
/// pointers, and paints nothing until [WizTextures.load] has produced a
/// tile.
class WizGrain extends StatelessWidget {
  final double opacity;

  const WizGrain({super.key, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GrainPainter(opacity)));
  }
}

class _GrainPainter extends CustomPainter {
  final double opacity;

  _GrainPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = WizTextures.grainPaint(opacity: opacity);
    if (paint == null) return;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.opacity != opacity;
}
