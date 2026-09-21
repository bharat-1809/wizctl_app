import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One `lib` file and every path it imports, each already resolved to a
/// repository path so that a relative import and a `package:wizctl_app` one
/// read the same.
class _Source {
  final String path;
  final List<String> imports;
  const _Source(this.path, this.imports);
}

final RegExp _import = RegExp("^import '([^']+)'");

List<String> _importsOf(File file) {
  var out = <String>[];
  for (var line in file.readAsLinesSync()) {
    var match = _import.firstMatch(line);
    if (match == null) continue;
    var target = match.group(1)!;
    if (target.startsWith('package:wizctl_app/')) {
      out.add(target.replaceFirst('package:wizctl_app/', 'lib/'));
    } else if (target.startsWith('package:') || target.startsWith('dart:')) {
      out.add(target);
    } else {
      // A relative import resolved against the file that wrote it, so that
      // `../../app/router.dart` is recognisable from whatever depth it is
      // written at.
      out.add(Uri.parse(file.path).resolve(target).path);
    }
  }
  return out;
}

/// Every `.dart` file under `lib`, read once for all three rules below.
List<_Source> _sources() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => _Source(f.path, _importsOf(f)))
        .toList();

/// The three layering rules of the plan's Global Constraints, as one source
/// scan: blocs are pure, the kit knows nothing of the app, and a feature knows
/// nothing of how it is routed.
void main() {
  late List<_Source> sources;

  setUpAll(() {
    sources = _sources();
    expect(sources, isNotEmpty, reason: 'the scan found no files under lib');
  });

  /// Every `<file>: <import>` pair among the files [where] matches whose import
  /// contains one of [forbidden].
  List<String> offenders({
    required bool Function(String path) where,
    required List<String> forbidden,
  }) {
    var out = <String>[];
    var scanned = 0;
    for (var source in sources.where((s) => where(s.path))) {
      scanned++;
      for (var import in source.imports) {
        for (var bad in forbidden) {
          if (import.contains(bad)) out.add('${source.path}: $import');
        }
      }
    }
    expect(scanned, greaterThan(0), reason: 'the scan matched no files');
    return out;
  }

  test('bloc files import no widgets, router, data or kit', () {
    // Blocs are pure: their only Flutter import is `foundation.dart`, for
    // `ValueListenable`.
    expect(
      offenders(
        where: (p) => p.contains('/bloc/') || p.contains('lib/app/blocs/'),
        forbidden: [
          'package:flutter/material.dart',
          'package:flutter/widgets.dart',
          'package:flutter/cupertino.dart',
          'package:flutter_bloc/',
          'package:go_router/',
          '/data/',
          '/core/widgets/',
        ],
      ),
      isEmpty,
    );
  });

  test('the kit knows nothing of the features or the app', () {
    // `lib/core` is the design kit and its tokens, reusable because nothing in
    // it reaches up. A kit widget that read a bloc or a route would tie the kit
    // to this app's shape, and could no longer be moved or tested on its own.
    expect(
      offenders(
        where: (p) => p.startsWith('lib/core/'),
        forbidden: ['lib/features/', 'lib/app/'],
      ),
      isEmpty,
    );
  });

  test('a feature knows nothing of how it is routed', () {
    // A screen navigates through `AppRoutes` and `lib/app/navigation.dart`,
    // never through the router itself or the shells. The other direction is the
    // whole point of the shells: they compose the features.
    expect(
      offenders(
        where: (p) => p.startsWith('lib/features/'),
        forbidden: ['lib/app/router', 'lib/app/shell/'],
      ),
      isEmpty,
    );
  });
}
