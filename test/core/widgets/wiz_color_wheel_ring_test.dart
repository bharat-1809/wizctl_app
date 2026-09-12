import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel_disc.dart';

import '../../support/wiz_test_app.dart';

/// The hue ring as painted, sampled just inside the chassis rim, where the
/// white wash has faded out and only the ring's own colour is left.
const double _diameter = 240;
const double _sampleRadius = _diameter / 2 - WizColorWheel.ringInset - 4;

Future<ui.Image> _render(WidgetTester tester) async {
  var key = GlobalKey();
  await tester.pumpWidget(
    wizTestApp(
      RepaintBoundary(
        key: key,
        // Saturation 0 parks the puck in the centre, clear of the ring.
        child: const WizColorWheelDisc(
          diameter: _diameter,
          hue: 0,
          saturation: 0,
          dragging: false,
        ),
      ),
    ),
  );
  await tester.pump();
  var boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  var image = await tester.runAsync(() => boundary.toImage());
  return image!;
}

/// The colour [degreesFrom12] clockwise from the top, on the ring.
Future<Color> _at(WidgetTester tester, ui.Image image, double degreesFrom12) {
  return tester
      .runAsync(() async {
        var rgba = (await image.toByteData())!;
        var rad = degreesFrom12 * math.pi / 180;
        var x = (_diameter / 2 + _sampleRadius * math.sin(rad)).round();
        var y = (_diameter / 2 - _sampleRadius * math.cos(rad)).round();
        var i = (y * image.width + x) * 4;
        return Color.fromARGB(
          rgba.getUint8(i + 3),
          rgba.getUint8(i),
          rgba.getUint8(i + 1),
          rgba.getUint8(i + 2),
        );
      })
      .then((c) => c!);
}

Matcher _led(String name, bool Function(Color c) test) =>
    predicate<Color>(test, name);

void main() {
  testWidgets('the ring runs red, yellow, green, cyan, violet, magenta', (
    tester,
  ) async {
    var image = await _render(tester);
    var expected = <double, Matcher>{
      0: _led('red', (c) => c.r > c.g && c.r > c.b && c.r > 0.6),
      45: _led('yellow', (c) => c.r > 0.6 && c.g > 0.6 && c.b < 0.4),
      90: _led('green', (c) => c.g > c.r && c.g > c.b),
      180: _led('cyan', (c) => c.b > c.r && c.g > c.r),
      270: _led('violet', (c) => c.b > c.r && c.r > c.g),
      315: _led('magenta', (c) => c.r > 0.6 && c.b > 0.6 && c.g < 0.4),
    };
    for (var entry in expected.entries) {
      expect(
        await _at(tester, image, entry.key),
        entry.value,
        reason: '${entry.key}° from 12',
      );
    }
  });
}
