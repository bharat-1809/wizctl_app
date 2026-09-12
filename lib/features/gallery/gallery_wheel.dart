import 'package:flutter/material.dart';

import '../../core/widgets/wiz_color_wheel.dart';
import 'gallery_section.dart';

/// The hue/saturation wheel on its own, sized to the column it is given.
class GalleryWheel extends StatefulWidget {
  const GalleryWheel({super.key});

  /// The wheel the phone layout draws (spec §11.2, "radius margin 18");
  /// narrower columns simply get the whole width.
  static const double preferredSize = 228;

  /// A warm amber start, so the puck sits where the lights usually are.
  static const WizHsv initial = WizHsv(28, 0.9);

  @override
  State<GalleryWheel> createState() => _GalleryWheelState();
}

class _GalleryWheelState extends State<GalleryWheel> {
  WizHsv _hsv = GalleryWheel.initial;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Colour wheel',
      child: Center(
        child: LayoutBuilder(
          builder: (context, box) {
            var size = box.maxWidth < GalleryWheel.preferredSize
                ? box.maxWidth
                : GalleryWheel.preferredSize;
            return WizColorWheel(
              hue: _hsv.hue,
              saturation: _hsv.saturation,
              size: size,
              onChanged: (v) => setState(() => _hsv = v),
            );
          },
        ),
      ),
    );
  }
}
