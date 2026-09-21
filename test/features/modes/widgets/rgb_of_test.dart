import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/modes/widgets/rgb_of.dart';

void main() {
  test("a colour becomes the domain's 0-255 triple", () {
    expect(rgbOf(const Color(0xFFFF4A3D)), const Rgb(255, 74, 61));
    expect(rgbOf(const Color(0xFF000000)), const Rgb(0, 0, 0));
  });
}
