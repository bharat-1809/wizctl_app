import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_skeleton.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';

import '../../support/wiz_test_app.dart';

/// Wraps [child] in a `MediaQuery` that keeps `wizTestApp`'s data but turns
/// the platform's "reduce motion" switch on.
Widget reducedMotion(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

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
    expect(find.text('%'), findsNothing);
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
    var a = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    await tester.pump(const Duration(milliseconds: 400));
    var b = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    expect(a.left, b.left);
    // No ticker is left running, so the scheduler drains: this returning at
    // all is the assertion that the loops were skipped, not merely hidden.
    await tester.pumpAndSettle();
  });
}
