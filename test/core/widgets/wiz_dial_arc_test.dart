import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/widgets/wiz_dial_painter.dart';

/// The arc painter's output, sampled where the sweep lands on the disc.
///
/// The sweep's geometry is transcribed from Dial.jsx and reads correctly on
/// paper; what these tests pin is the pixels, because a sweep that starts
/// below 3 o'clock is where Flutter's gradient and CSS's conic disagree.
const double _size = 200;
const double _radius = 90;

Future<ui.Image> _paint(WidgetTester tester, double pct) async {
  var c = WizColors.standard;
  var recorder = ui.PictureRecorder();
  WizDialArcPainter(
    pct: pct,
    amber600: c.amber600,
    amber400: c.amber400,
    amber500: c.amber500,
    dead: c.char1000,
    insets: const [],
  ).paint(Canvas(recorder), const Size(_size, _size));
  var picture = recorder.endRecording();
  // `Picture.toImage` needs a real event loop, as `WizTextures.load` does.
  var image = await tester.runAsync(
    () => picture.toImage(_size.toInt(), _size.toInt()),
  );
  return image!;
}

/// The colour [degreesFrom12] clockwise from the top, on the ring.
Future<Color> _at(WidgetTester tester, ui.Image image, double degreesFrom12) {
  return tester
      .runAsync(() async {
        var rgba = (await image.toByteData())!;
        var rad = degreesFrom12 * math.pi / 180;
        var x = (_size / 2 + _radius * math.sin(rad)).round();
        var y = (_size / 2 - _radius * math.cos(rad)).round();
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

/// Somewhere on the amber sweep: opaque, red-led, little blue.
final Matcher _amber = predicate<Color>(
  (c) => c.a == 1 && c.r > 0.7 && c.b < 0.4,
  'an opaque amber',
);

/// The unfilled travel: the opaque near-black the arc is cut from.
final Matcher _dead = predicate<Color>(
  (c) => c.a == 1 && c.r < 0.15 && c.g < 0.15 && c.b < 0.15,
  'the opaque dead colour',
);

/// The wedge beyond the travel: Dial.jsx ends its conic on `transparent`,
/// leaving the disc beneath to show.
final Matcher _clear = predicate<Color>((c) => c.a == 0, 'transparent');

void main() {
  testWidgets('at 100% the amber runs the whole 280° of travel', (
    tester,
  ) async {
    var image = await _paint(tester, 1);
    // Just past the start at the bottom-left, up through 12, round to just
    // before the end at the bottom-right.
    for (var deg in [-135.0, -90.0, 0.0, 90.0, 135.0]) {
      expect(await _at(tester, image, deg), _amber, reason: '$deg° from 12');
    }
  });

  testWidgets('the 80° wedge centred on 6 o\'clock is never painted', (
    tester,
  ) async {
    for (var pct in [0.0, 0.5, 1.0]) {
      var image = await _paint(tester, pct);
      for (var deg in [145.0, 180.0, 215.0]) {
        expect(
          await _at(tester, image, deg),
          _clear,
          reason: '$deg° from 12 at $pct',
        );
      }
    }
  });

  testWidgets('at 0% the travel is unfilled but still drawn', (tester) async {
    var image = await _paint(tester, 0);
    for (var deg in [-135.0, 0.0, 90.0]) {
      expect(await _at(tester, image, deg), _dead, reason: '$deg° from 12');
    }
  });

  testWidgets('at 50% the fill ends at 12 o\'clock', (tester) async {
    var image = await _paint(tester, 0.5);
    expect(await _at(tester, image, -10), _amber);
    expect(await _at(tester, image, 10), _dead);
  });
}
