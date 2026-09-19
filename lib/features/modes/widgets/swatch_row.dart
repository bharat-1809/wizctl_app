import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../domain/entities/entities.dart';
import 'modes_layout.dart';
import 'rgb_of.dart';

/// The twelve hue circles (spec §10.5, "COLOURS twelve hue swatches").
class SwatchRow extends StatelessWidget {
  final ModesLayout layout;
  final bool Function(Rgb rgb) isSelected;
  final ValueChanged<Rgb> onPick;

  const SwatchRow({
    super.key,
    required this.layout,
    required this.isSelected,
    required this.onPick,
  });

  /// The design system's names, in `WizColors.hues` order.
  static const List<String> hueNames = [
    'Red',
    'Orange',
    'Yellow',
    'Lime',
    'Green',
    'Teal',
    'Cyan',
    'Blue',
    'Indigo',
    'Violet',
    'Magenta',
    'Pink',
  ];

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(Strings.colours),
        SizedBox(height: wiz.space.s3),
        Wrap(
          spacing: wiz.space.s3,
          runSpacing: wiz.space.s3,
          children: [
            for (var (i, color) in wiz.colors.hues.indexed)
              Swatch(
                color: color,
                size: layout.swatch,
                label: hueNames[i],
                selected: isSelected(rgbOf(color)),
                onTap: () => onPick(rgbOf(color)),
              ),
          ],
        ),
      ],
    );
  }
}

/// One hue circle: a raised key filled with the colour, ringed when
/// selected.
class Swatch extends StatelessWidget {
  final Color color;
  final double size;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const Swatch({
    super.key,
    required this.color,
    required this.size,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: label,
      toggled: selected,
      scale: wiz.motion.smallKeyScale,
      // A swatch smaller than the 44 minimum pads itself out to it
      // (spec §14); one already that big pads by nothing.
      hitPadding: EdgeInsets.all(
        (wiz.space.hitMin - size).clamp(0, wiz.space.hitMin) / 2,
      ),
      focusRadius: BorderRadius.circular(size / 2),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(size / 2),
        color: color,
        width: size,
        height: size,
        child: selected
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: wiz.colors.amber500,
                    width: wiz.space.keyBorder,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// One white tile: the kelvin colour with its mono label (spec §10.5,
/// "WHITES six kelvin tiles with mono labels").
class WhiteTile extends StatelessWidget {
  final int kelvin;
  final Color color;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  const WhiteTile({
    super.key,
    required this.kelvin,
    required this.color,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: Strings.kelvinLabel(kelvin),
      toggled: selected,
      scale: wiz.motion.smallKeyScale,
      focusRadius: BorderRadius.circular(wiz.space.r2),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(wiz.space.r2),
        color: color,
        width: width,
        height: height,
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: wiz.space.s2),
        child: DecoratedBox(
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(wiz.space.r2),
                  border: Border.all(
                    color: wiz.colors.amber500,
                    width: wiz.space.keyBorder,
                  ),
                )
              : const BoxDecoration(),
          child: Text(
            Strings.kelvinLabel(kelvin),
            style: wiz.typography.mono.copyWith(color: wiz.colors.textOnAccent),
          ),
        ),
      ),
    );
  }
}
