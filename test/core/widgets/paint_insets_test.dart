import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_elevation.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';

void main() {
  test('paintInsets does not throw for every elevation spec', () {
    var e = WizElevation.standard;
    var specs = <WizShadowSpec>[
      e.panel,
      e.raised,
      e.key,
      e.knob,
      e.pressed,
      e.well,
      e.wellDeep,
      e.overlay,
      e.flat,
    ];
    var rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 60),
      const Radius.circular(12),
    );

    for (var spec in specs) {
      var recorder = PictureRecorder();
      var canvas = Canvas(recorder);
      expect(() => paintInsets(canvas, rrect, spec.insets), returnsNormally);
      recorder.endRecording();
    }
  });
}
