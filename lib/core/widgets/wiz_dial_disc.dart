import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_dial_painter.dart';
import 'wiz_surface.dart';

/// The dial's face, internal to `WizDial`: the recessed disc with its amber
/// sweep arc and glow, the knurled knob and its index mark, and the deep
/// well holding the readout.
///
/// Everything it draws it is told — it holds no gesture, focus or semantics
/// logic, and never changes a value. Those all stay in `WizDial`.
class WizDialDisc extends StatelessWidget {
  /// The disc's diameter, already clamped to the design's range.
  final double diameter;

  /// How far round the sweep the value sits, 0..1.
  final double pct;

  /// The number engraved in the well, and the unit after it.
  final double value;
  final String unit;

  /// Whether a finger is on the knob. A dragged knob tracks it exactly; a
  /// released one eases round on the settle curve.
  final bool dragging;

  const WizDialDisc({
    super.key,
    required this.diameter,
    required this.pct,
    required this.value,
    required this.unit,
    required this.dragging,
  });

  /// Dial.jsx disc: `filter: drop-shadow(0 0 12px rgba(255,176,32,.28))` —
  /// amber-500 at .28, blurred 12.
  static const double _arcGlowAlpha = .28;
  static const double _arcGlowBlur = 12;

  /// Dial.jsx index mark: `border-radius: 2` and
  /// `box-shadow: 0 0 10px rgba(255,194,77,.9)` — amber-400 at .9, blur 10.
  static const double _markRadius = 2;
  static const double _markGlowAlpha = .9;
  static const double _markGlowBlur = 10;

  /// Dial.jsx readout: `letterSpacing: '.01em'`.
  static const double _readoutTracking = 0.01;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var d = diameter;
    var knobInset = d * WizDialGeometry.knobInset;
    var wellInset = d * WizDialGeometry.wellInset;
    var knobSize = d - knobInset * 2;
    var circle = BorderRadius.circular(d);

    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        children: [
          // Sweep arc and its glow
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: pct > 0 ? 1 : 0,
              duration: m.ui,
              curve: m.tactile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.amber500.withValues(alpha: _arcGlowAlpha),
                      blurRadius: _arcGlowBlur,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WizDialArcPainter(
                pct: pct,
                amber600: c.amber600,
                amber400: c.amber400,
                amber500: c.amber500,
                dead: c.char1000,
                insets: wiz.elevation.well.insets,
              ),
            ),
          ),
          // Knob
          Positioned(
            left: knobInset,
            top: knobInset,
            width: knobSize,
            height: knobSize,
            child: AnimatedRotation(
              turns: WizDialGeometry.angleFor(pct) / 360,
              duration: dragging ? Duration.zero : m.release,
              curve: m.settle,
              child: WizSurface(
                spec: wiz.elevation.knob,
                radius: circle,
                color: c.char850,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: WizKnobFacePainter(
                        elevation: wiz.elevation,
                        top: c.surfaceKey,
                        bottom: c.char950,
                        highlight: c.highlightBase,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: d * WizDialGeometry.markTop,
                        ),
                        child: Container(
                          width: WizDialGeometry.markWidth,
                          height: d * WizDialGeometry.markHeight,
                          decoration: BoxDecoration(
                            color: c.amber300,
                            borderRadius: BorderRadius.circular(_markRadius),
                            boxShadow: [
                              BoxShadow(
                                color: c.amber400.withValues(
                                  alpha: _markGlowAlpha,
                                ),
                                blurRadius: _markGlowBlur,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Readout well
          Positioned(
            left: wellInset,
            top: wellInset,
            right: wellInset,
            bottom: wellInset,
            child: IgnorePointer(
              child: WizSurface(
                spec: wiz.elevation.wellDeep,
                radius: circle,
                gradient: wizVertical(c.char850, c.char1000),
                alignment: Alignment.center,
                // The engraved number is decoration: left in, it would
                // merge into the slider's label and be read out twice,
                // once as the label and again as the value.
                child: ExcludeSemantics(child: _readout(wiz, d)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The engraved number and its unit. Two spans rather than one so the
  /// value alone is addressable, laid out unbounded inside a [FittedBox]:
  /// the compressed display face always fits the well, and a fallback face
  /// that does not shrinks rather than spilling over the knob.
  Widget _readout(WizTheme wiz, double d) {
    var valueStyle = wiz.typography.readout.copyWith(
      fontSize: d * WizDialGeometry.valueFont,
      fontWeight: FontWeight.w800,
      letterSpacing: d * WizDialGeometry.valueFont * _readoutTracking,
      color: wiz.colors.textPrimary,
    );
    // Dial.jsx's unit span overrides only size and colour. CSS
    // `letter-spacing` inherits as a computed length, so in the reference
    // the unit keeps the value's `0.24 * size * .01`; scaling it to the
    // unit's own smaller size instead keeps the tracking in proportion to
    // the glyphs it is set on, which is what the em value was chosen for.
    var unitStyle = valueStyle.copyWith(
      fontSize: d * WizDialGeometry.unitFont,
      letterSpacing: d * WizDialGeometry.unitFont * _readoutTracking,
      color: wiz.colors.textTertiary,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('${value.round()}', style: valueStyle, maxLines: 1),
          Text(unit, style: unitStyle, maxLines: 1),
        ],
      ),
    );
  }
}
