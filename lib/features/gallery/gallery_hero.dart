import 'package:flutter/material.dart';

import '../../core/motion/breathe.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/util/color_maths.dart';
import '../../core/widgets/fixture_hero.dart';
import '../../core/widgets/wiz_chip.dart';
import '../../core/widgets/wiz_readout.dart';
import 'gallery_section.dart';

/// Every fixture shape, lit by the same light the switches and dials drive,
/// with the emission readout breathing alongside it.
class GalleryHero extends StatefulWidget {
  final bool power;
  final double brightness;
  final double kelvin;

  const GalleryHero({
    super.key,
    required this.power,
    required this.brightness,
    required this.kelvin,
  });

  @override
  State<GalleryHero> createState() => _GalleryHeroState();
}

class _GalleryHeroState extends State<GalleryHero> {
  WizFixture _fixture = WizFixture.bulb;

  /// Enum names are the protocol's, not the user's: the chip shows the shape
  /// in sentence case.
  static String _label(WizFixture fixture) =>
      fixture.name[0].toUpperCase() + fixture.name.substring(1);

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var emission = widget.power
        ? WizEmission.lit(
            color: kelvinToColor(widget.kelvin.round()),
            brightness: widget.brightness.round(),
          )
        : WizEmission.off;
    return GallerySection(
      title: 'Hero',
      child: Column(
        children: [
          FixtureHero(fixture: _fixture, emission: emission),
          SizedBox(height: space.s5),
          // The desktop inspector's variant: the same fixture at 0.6 scale
          // in a short well (spec §11.2).
          FixtureHero(fixture: _fixture, emission: emission, compact: true),
          SizedBox(height: space.s5),
          Breathe(
            active: widget.power,
            child: WizReadout(
              value: widget.power ? '${widget.brightness.round()}' : '0',
              unit: '%',
              label: 'Emission',
              size: WizReadoutSize.lg,
              tone: WizReadoutTone.accent,
              center: true,
            ),
          ),
          SizedBox(height: space.s5),
          Wrap(
            spacing: space.s3,
            runSpacing: space.s3,
            alignment: WrapAlignment.center,
            children: [
              for (var f in WizFixture.values)
                WizChip(
                  label: _label(f),
                  selected: f == _fixture,
                  onTap: () => setState(() => _fixture = f),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
