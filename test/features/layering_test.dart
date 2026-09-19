import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blocs are pure: they may not import widgets, flutter_bloc, the router,
/// the data layer or the kit (plan Global Constraints). Their only Flutter
/// import is `foundation.dart`, for `ValueListenable`.
void main() {
  test('bloc files import no widgets, router, data or kit', () {
    var offenders = <String>[];
    var forbidden = [
      "package:flutter/material.dart",
      "package:flutter/widgets.dart",
      "package:flutter/cupertino.dart",
      "package:flutter_bloc/",
      "package:go_router/",
      "/data/",
      "/core/widgets/",
    ];
    var files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => f.path.contains('/bloc/') || f.path.contains('lib/app/blocs/'),
        );
    expect(files, isNotEmpty, reason: 'the scan found no bloc files');
    for (var file in files) {
      for (var line in file.readAsLinesSync()) {
        if (!line.startsWith('import ')) continue;
        for (var bad in forbidden) {
          if (line.contains(bad)) offenders.add('${file.path}: $line');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
