import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Directives allowed anywhere in `lib/domain`: `dart:async`/`dart:math`,
/// `package:equatable`, `package:wizctl`, or a relative import/export/part
/// that resolves to a file inside `lib/domain` itself. Everything else
/// (Flutter, drift, dart:io, other packages, or a relative path that
/// escapes the domain directory) fails the test.
const _allowedDartLibraries = {'dart:async', 'dart:math'};
const _allowedPackagePrefixes = ['package:equatable/', 'package:wizctl/'];

bool _isAllowedTarget(String target, String importingDir, String domainRoot) {
  if (target.startsWith('dart:')) {
    return _allowedDartLibraries.contains(target);
  }
  if (target.startsWith('package:')) {
    return _allowedPackagePrefixes.any(target.startsWith);
  }
  // A relative import/export/part: it must resolve to a path inside
  // lib/domain once resolved against the importing file's own directory.
  var resolved = p.normalize(p.join(importingDir, target));
  return p.isWithin(domainRoot, resolved);
}

void main() {
  test('the domain layer only imports equatable, wizctl, dart:async/dart:math, '
      'or files within lib/domain itself', () {
    var files = Directory('lib/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);

    var directiveRegExp = RegExp(
      r'''^\s*(?:import|export|part)\s+(['"])([^'"]+)\1''',
      multiLine: true,
    );
    var domainRoot = p.normalize('lib/domain');

    for (var f in files) {
      var importingDir = p.dirname(f.path);
      for (var match in directiveRegExp.allMatches(f.readAsStringSync())) {
        var target = match.group(2)!;
        expect(
          _isAllowedTarget(target, importingDir, domainRoot),
          isTrue,
          reason: "${f.path} has a disallowed directive: '$target'",
        );
      }
    }
  });
}
