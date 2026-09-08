import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_grain.dart';

/// The screen background: app surface, a soft top vignette as if room light
/// falls from above, and the grain. Equivalent to the design system's
/// `.wz-app`.
class WizAppBackground extends StatelessWidget {
  final Widget child;

  const WizAppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return ColoredBox(
      color: wiz.colors.surfaceApp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _VignettePainter(
              alpha: wiz.elevation.vignetteAlpha,
              highlight: wiz.colors.highlightBase,
            ),
          ),
          const WizGrain(),
          child,
        ],
      ),
    );
  }
}

/// `radial-gradient(115% 85% at 50% -8%, white .055, transparent 58%)`: an
/// ellipse wider than the screen, centred just above its top edge, so the
/// highlight only grazes the top of the chassis.
class _VignettePainter extends CustomPainter {
  final double alpha;
  final Color highlight;

  _VignettePainter({required this.alpha, required this.highlight});

  // Ellipse radii as a fraction of the canvas size: 115% wide, 85% tall.
  static const double _radiusX = 1.15, _radiusY = 0.85;

  // Ellipse centre: horizontally centred, 8% of the height above the top edge.
  static const double _centerY = -0.08;

  // Gradient stop where the highlight has fully faded to transparent.
  static const double _fadeStop = 0.58;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * _centerY);
    canvas.scale(size.width * _radiusX, size.height * _radiusY);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            highlight.withValues(alpha: alpha),
            highlight.withValues(alpha: 0),
          ],
          stops: const [0, _fadeStop],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VignettePainter old) =>
      old.alpha != alpha || old.highlight != highlight;
}
