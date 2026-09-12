import 'package:flutter/material.dart';

import '../theme/wiz_elevation.dart';
import 'wiz_grain.dart';

/// How far outside [RRect.outerRect] the "everything outside the shape"
/// rect used by [paintInsets] extends: comfortably past the largest blur any
/// [WizInset] in the kit uses, so the un-blurred rect edge never shows
/// through before the blur has faded it away.
const double _insetShadowBleed = 64;

/// Paints CSS-style inset shadows inside [rrect]: the shadow cast by the
/// area outside the shape, shifted by the inset's offset, blurred, clipped
/// to the shape. A blur of zero with a 1 px offset is the hard highlight or
/// groove line every raised or recessed part carries.
///
/// The list is painted in order, so the **last** entry lands on top. CSS is
/// the other way round — the first `box-shadow` is drawn over the ones
/// after it — so a spec transcribed straight from `elevation.css`, as every
/// [WizShadowSpec] in the kit is, stacks its insets in the opposite order.
/// That does not show, because the two halves of a pair sit on opposite
/// edges: a positive offset shifts the hole down and uncovers a line along
/// the top, a negative one uncovers a line along the bottom. They meet only
/// where a blur is wide enough to cross the part. A caller that needs one
/// of them over the other lists that one last.
void paintInsets(Canvas canvas, RRect rrect, List<WizInset> insets) {
  if (insets.isEmpty) return;
  var outer = rrect.outerRect.inflate(_insetShadowBleed);
  canvas.save();
  canvas.clipRRect(rrect);
  for (var inset in insets) {
    var hole = Path()..addRRect(rrect.shift(Offset(0, inset.offsetY)));
    var shadow = Path.combine(
      PathOperation.difference,
      Path()..addRect(outer),
      hole,
    );
    var paint = Paint()..color = inset.color;
    if (inset.blur > 0) {
      // Flutter's blur sigma is roughly half the CSS blur radius it mimics.
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, inset.blur / 2);
    }
    canvas.drawPath(shadow, paint);
  }
  canvas.restore();
}

/// A chassis surface: fill, outer cast shadows, inner highlight and groove,
/// optional grain and optional emission glow. Every panel, key, well and
/// knob in the kit is a [WizSurface] with a different [spec].
class WizSurface extends StatelessWidget {
  final WizShadowSpec spec;
  final BorderRadius radius;
  final Gradient? gradient;
  final Color? color;
  final bool grain;
  final double grainOpacity;
  final List<BoxShadow> glow;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// Whether [child] is clipped to [radius]. Default true. Turn off only
  /// when content must intentionally bleed past the shape's corners (e.g. a
  /// pip escaping a knob rim) — the grain layer and the inner
  /// highlight/groove painted by [spec] are always clipped regardless.
  final bool clipChild;

  const WizSurface({
    super.key,
    required this.spec,
    required this.radius,
    this.gradient,
    this.color,
    this.grain = false,
    this.grainOpacity = 1,
    this.glow = const [],
    this.child,
    this.padding,
    this.width,
    this.height,
    this.alignment,
    this.clipChild = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (alignment != null) {
      content = Align(alignment: alignment!, child: content);
    }

    Widget painted = CustomPaint(
      foregroundPainter: _InsetPainter(spec.insets, radius),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Clipped here unconditionally: [clipChild] governs the child's
          // own content, not this texture, which must never show square
          // corners on a rounded surface.
          if (grain)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: WizGrain(opacity: grainOpacity),
              ),
            ),
          content,
        ],
      ),
    );
    if (clipChild) {
      painted = ClipRRect(borderRadius: radius, child: painted);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color : null,
        borderRadius: radius,
        boxShadow: [...spec.outer, ...glow],
      ),
      child: SizedBox(width: width, height: height, child: painted),
    );
  }
}

class _InsetPainter extends CustomPainter {
  final List<WizInset> insets;
  final BorderRadius radius;

  _InsetPainter(this.insets, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    paintInsets(canvas, radius.toRRect(Offset.zero & size), insets);
  }

  @override
  bool shouldRepaint(_InsetPainter old) =>
      old.insets != insets || old.radius != radius;
}
