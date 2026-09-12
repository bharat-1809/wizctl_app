import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/bootstrap.dart';

void main() {
  const files = [
    'BigShouldersDisplay-SemiBold.ttf',
    'BigShouldersDisplay-Bold.ttf',
    'BigShouldersDisplay-ExtraBold.ttf',
    'BigShouldersDisplay-Black.ttf',
    'NeumaticCompressed-ExtraBold.otf',
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
      'BigShouldersDisplay',
      'NeumaticCompressed',
      'HankenGrotesk',
      'JetBrainsMono',
    ]) {
      expect(pubspec, contains('family: $family'));
    }
  });

  /// The three open licences, by the family each covers.
  const licences = {
    'Big Shoulders Display': 'assets/fonts/OFL-BigShouldersDisplay.txt',
    'Hanken Grotesk': 'assets/fonts/OFL-HankenGrotesk.txt',
    'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
  };

  testWidgets('the OFL licences are bundled and reach the licence page', (
    tester,
  ) async {
    var pubspec = File('pubspec.yaml').readAsStringSync();
    for (var path in licences.values) {
      expect(File(path).existsSync(), isTrue, reason: '$path missing');
      expect(pubspec, contains(path), reason: '$path not declared');
      // Loaded through the bundle, not off disk: a file that is on disk but
      // not in the asset manifest would never reach a running app.
      var text = await rootBundle.loadString(path);
      expect(
        text,
        contains('SIL OPEN FONT LICENSE'),
        reason: '$path is not the licence it is named for',
      );
    }

    // The standard licence page reads the registry, so being bundled is only
    // half of shipping a licence.
    registerFontLicences();
    var listed = <String>{};
    await for (var entry in LicenseRegistry.licenses) {
      listed.addAll(entry.packages);
    }
    expect(listed, containsAll(licences.keys));
  });
}
