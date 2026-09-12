import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/layout/wiz_breakpoints.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('classify maps widths to classes', () {
    expect(WizBreakpoints.classify(320), WidthClass.compact);
    expect(WizBreakpoints.classify(719), WidthClass.compact);
    expect(WizBreakpoints.classify(720), WidthClass.medium);
    expect(WizBreakpoints.classify(1099), WidthClass.medium);
    expect(WizBreakpoints.classify(1100), WidthClass.expanded);
    expect(WizBreakpoints.classify(1600), WidthClass.wide);
    expect(WidthClass.medium.isDesktopLike, isTrue);
    expect(WidthClass.compact.isDesktopLike, isFalse);
    expect(WidthClass.compact.isCompact, isTrue);
    expect(WidthClass.medium.isCompact, isFalse);
    expect(WidthClass.expanded.hasInspectorColumn, isTrue);
    expect(WidthClass.wide.hasInspectorColumn, isTrue);
    expect(WidthClass.medium.hasInspectorColumn, isFalse);
    expect(WidthClass.compact.hasInspectorColumn, isFalse);
  });

  // `wizTestApp(size:)` only sets `MediaQuery`; the tester's actual layout
  // constraints come from the physical surface, so every width-class
  // assertion below sets that surface with `setSurface` first (per the
  // harness doc comment on `setSurface`).
  testWidgets('a compact surface classifies as compact', (tester) async {
    await setSurface(tester, const Size(390, 844));
    late WizLayout layout;
    await tester.pumpWidget(
      wizTestApp(
        WizLayoutScope(
          child: Builder(
            builder: (context) {
              layout = context.layout;
              return const SizedBox();
            },
          ),
        ),
        size: const Size(390, 844),
      ),
    );
    expect(layout.widthClass, WidthClass.compact);
    expect(layout.gutter, 20);
  });

  testWidgets('a medium surface classifies as medium', (tester) async {
    await setSurface(tester, const Size(800, 600));
    late WizLayout layout;
    await tester.pumpWidget(
      wizTestApp(
        WizLayoutScope(
          child: Builder(
            builder: (context) {
              layout = context.layout;
              return const SizedBox();
            },
          ),
        ),
        size: const Size(800, 600),
      ),
    );
    expect(layout.widthClass, WidthClass.medium);
    expect(layout.gutter, 32);
  });

  testWidgets(
    'WizLayoutScope exposes the class and gutter on an expanded surface',
    (tester) async {
      await setSurface(tester, const Size(1280, 800));
      late WizLayout layout;
      await tester.pumpWidget(
        wizTestApp(
          WizLayoutScope(
            child: Builder(
              builder: (context) {
                layout = context.layout;
                return const SizedBox();
              },
            ),
          ),
          size: const Size(1280, 800),
        ),
      );
      expect(layout.widthClass, WidthClass.expanded);
      expect(layout.gutter, 32);
    },
  );

  testWidgets('a wide surface classifies as wide', (tester) async {
    await setSurface(tester, const Size(1700, 1000));
    late WizLayout layout;
    await tester.pumpWidget(
      wizTestApp(
        WizLayoutScope(
          child: Builder(
            builder: (context) {
              layout = context.layout;
              return const SizedBox();
            },
          ),
        ),
        size: const Size(1700, 1000),
      ),
    );
    expect(layout.widthClass, WidthClass.wide);
    expect(layout.gutter, 32);
  });
}
