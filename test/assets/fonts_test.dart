import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const files = [
    'NeumaticCompressed-Light.otf',
    'NeumaticCompressed-Regular.otf',
    'NeumaticCompressed-Medium.otf',
    'NeumaticCompressed-SemiBold.otf',
    'NeumaticCompressed-Bold.otf',
    'NeumaticCompressed-ExtraBold.otf',
    'NeumaticCompressed-Black.otf',
    'HankenGrotesk-Regular.ttf',
    'HankenGrotesk-SemiBold.ttf',
    'HankenGrotesk-Bold.ttf',
    'JetBrainsMono-Regular.ttf',
    'JetBrainsMono-Medium.ttf',
    'JetBrainsMono-Bold.ttf',
  ];

  test('every font file is bundled and declared', () {
    var pubspec = File('pubspec.yaml').readAsStringSync();
    for (var file in files) {
      var f = File('assets/fonts/$file');
      expect(f.existsSync(), isTrue, reason: '$file missing');
      expect(f.lengthSync(), greaterThan(10 * 1024), reason: '$file too small');
      expect(
        pubspec,
        contains('assets/fonts/$file'),
        reason: '$file not declared',
      );
    }
    for (var family in [
      'NeumaticCompressed',
      'HankenGrotesk',
      'JetBrainsMono',
    ]) {
      expect(pubspec, contains('family: $family'));
    }
  });
}
