import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the domain layer imports nothing from Flutter, drift, dart:io or outer layers', () {
    var files = Directory('lib/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    var forbidden = RegExp(
      r"import '(package:flutter/|package:drift|dart:io|package:wizctl_app/data|package:wizctl_app/features|package:wizctl_app/app|package:wizctl_app/core)",
    );
    for (var f in files) {
      var bad = forbidden
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(0))
          .toList();
      expect(bad, isEmpty, reason: '${f.path} imports $bad');
    }
  });
}
