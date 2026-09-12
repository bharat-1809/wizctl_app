import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_skeleton.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('determinate filament fills proportionally and prints the '
      'percentage', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 300,
          child: WizFilamentBar(value: 0.5, label: 'Sweeping subnet'),
        ),
      ),
    );
    // A determinate bar runs no loop, so the frame scheduler drains: this
    // call returning at all is the assertion.
    await tester.pumpAndSettle();
    expect(find.text('SWEEPING SUBNET'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    var track = tester.getRect(find.byKey(const Key('wiz-filament-track')));
    var fill = tester.getRect(find.byKey(const Key('wiz-filament-fill')));
    expect(fill.width, closeTo(track.width * 0.5, 1));
    expect(fill.left, track.left);
    expect(find.byKey(const Key('wiz-filament-hot')), findsNothing);
  });

  testWidgets('a determinate filament clamps a value past the ends', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(const SizedBox(width: 300, child: WizFilamentBar(value: 2.5))),
    );
    await tester.pumpAndSettle();
    var track = tester.getRect(find.byKey(const Key('wiz-filament-track')));
    var fill = tester.getRect(find.byKey(const Key('wiz-filament-fill')));
    expect(fill.width, track.width);
  });

  testWidgets('indeterminate filament keeps moving', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(width: 300, child: WizFilamentBar(label: 'Discovering')),
      ),
    );
    // Bounded pumps only: the loop never settles.
    await tester.pump();
    var a = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    await tester.pump(const Duration(milliseconds: 400));
    var b = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    expect(a.left, isNot(closeTo(b.left, 0.5)));
    expect(find.byKey(const Key('wiz-filament-fill')), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('a filament stops its loop once it becomes determinate', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(const SizedBox(width: 300, child: WizFilamentBar())),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(width: 300, child: WizFilamentBar(value: 0.25)),
      ),
    );
    await tester.pumpAndSettle();
    var track = tester.getRect(find.byKey(const Key('wiz-filament-track')));
    var fill = tester.getRect(find.byKey(const Key('wiz-filament-fill')));
    expect(fill.width, closeTo(track.width * 0.25, 1));
  });

  testWidgets('a determinate filament tells assistive tech both numbers', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 300,
          child: WizFilamentBar(value: 0.5, label: 'Sweeping subnet'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Sweeping subnet'), findsOne);
    expect(
      find.semantics.byLabel('Sweeping subnet'),
      isSemantics(value: '50%'),
      reason:
          'Flutter has no progressbar role, so label plus value is the '
          'closest a bar can get',
    );
    handle.dispose();
  });

  testWidgets('an unlabelled indeterminate filament reads out no percentage', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(const SizedBox(width: 300, child: WizFilamentBar())),
    );
    await tester.pump();
    expect(find.semantics.byValue(RegExp('%')), findsNothing);
    handle.dispose();
  });

  testWidgets('skeleton and spinner sizes', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WizSkeleton(height: 40, circle: true),
            WizSkeleton(width: 120, height: 14),
            WizSpinner(),
          ],
        ),
      ),
    );
    // Bounded pumps only: the sheen and the sweep never settle.
    await tester.pump();
    var sizes = tester
        .widgetList(find.byType(WizSkeleton))
        .map((w) => tester.getSize(find.byWidget(w)))
        .toList();
    expect(sizes[0], const Size(40, 40));
    expect(sizes[1], const Size(120, 14));
    expect(tester.getSize(find.byType(WizSpinner)), const Size(22, 22));
  });

  testWidgets('a skeleton with no width fills the one it is offered', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(const SizedBox(width: 300, child: WizSkeleton(height: 14))),
    );
    await tester.pump();
    expect(tester.getSize(find.byType(WizSkeleton)), const Size(300, 14));
  });

  testWidgets('a skeleton offered a loose width takes all of it', (
    tester,
  ) async {
    await tester.pumpWidget(wizTestApp(const WizSkeleton(height: 14)));
    await tester.pump();
    var body = tester.getSize(find.byType(Scaffold));
    expect(tester.getSize(find.byType(WizSkeleton)).width, body.width);
  });

  testWidgets('the sheen crosses the skeleton', (tester) async {
    await tester.pumpWidget(
      wizTestApp(const SizedBox(width: 300, child: WizSkeleton(height: 14))),
    );
    // Bounded pumps only: the sheen never settles.
    await tester.pump();
    var a = tester.getRect(find.byKey(const Key('wiz-skeleton-sheen')));
    await tester.pump(const Duration(milliseconds: 400));
    var b = tester.getRect(find.byKey(const Key('wiz-skeleton-sheen')));
    expect(a.left, isNot(closeTo(b.left, 0.5)));
    // The band is the width of the well it crosses, not a sliver of it.
    expect(a.width, closeTo(300, 1));
  });

  testWidgets('reduced motion parks every loader', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        reducedMotion(
          const SizedBox(
            width: 300,
            child: Column(
              children: [
                WizFilamentBar(),
                WizSkeleton(width: 120),
                WizSpinner(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    var hotA = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    var sheenA = tester.getRect(find.byKey(const Key('wiz-skeleton-sheen')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.getRect(find.byKey(const Key('wiz-filament-hot'))).left,
      hotA.left,
    );
    expect(
      tester.getRect(find.byKey(const Key('wiz-skeleton-sheen'))).left,
      sheenA.left,
    );
    // No ticker is left running, so the scheduler drains: this returning at
    // all is the assertion that the loops were skipped, not merely hidden.
    await tester.pumpAndSettle();
  });
}
