import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/features/onboarding/widgets/ping_ring.dart';
import 'package:wizctl_app/features/onboarding/widgets/radar.dart';

import '../../../support/wiz_test_app.dart';

/// Far enough into the 2.2 s ping for a ring to have grown measurably, and
/// short of the cycle's end so a comparison cannot land back where it began.
const Duration _intoTheCycle = Duration(milliseconds: 700);

/// The rings are compared by the scale they are drawn at, so the tolerance
/// only has to absorb the last bit of `0.7 / 2.2` against the clock's own
/// 700 ms / 2200 ms.
const double _tolerance = 0.001;

/// The scale ring [index] is drawn at. `Transform.scale` writes it into the
/// matrix's first cell.
double _scaleOf(WidgetTester tester, int index) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(PingRing).at(index),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .storage[0];

void main() {
  testWidgets('the radar is 150 across with a 64 key and two rings that ping', (
    tester,
  ) async {
    await tester.pumpWidget(wizTestApp(const Radar()));
    expect(
      tester.getSize(find.byType(Radar)),
      const Size(Radar.well, Radar.well),
    );
    expect(find.byKey(Radar.keyKey), findsOneWidget);
    expect(tester.getSize(find.byKey(Radar.keyKey)).width, Radar.keySize);
    expect(find.byType(PingRing), findsNWidgets(2));
    // A ticker fixes its own zero on the first frame it is called on, which
    // is the one after the clock starts — so this, not the mount, is the
    // first frame the rings can be compared from.
    await tester.pump();
    var before = _scaleOf(tester, 0);
    await tester.pump(_intoTheCycle);
    expect(
      _scaleOf(tester, 0),
      isNot(closeTo(before, _tolerance)),
      reason: 'the ring grows',
    );
  });

  testWidgets('the second ring trails the first by 0.7 of the 2.2 s clock', (
    tester,
  ) async {
    await tester.pumpWidget(wizTestApp(const Radar()));
    await tester.pump();
    var trailing = _scaleOf(tester, 1);
    expect(
      _scaleOf(tester, 0),
      isNot(closeTo(trailing, _tolerance)),
      reason: 'the two rings are not in step',
    );
    await tester.pump(WizMotion.standard.ping * Radar.ringDelayFraction);
    expect(
      _scaleOf(tester, 0),
      closeTo(trailing, _tolerance),
      reason: 'the leading ring has reached where the trailing one started',
    );
  });

  testWidgets('under reduced motion the rings stand still', (tester) async {
    await tester.pumpWidget(wizTestApp(reducedMotion(const Radar())));
    await tester.pump();
    var before = _scaleOf(tester, 0);
    await tester.pump(_intoTheCycle);
    expect(_scaleOf(tester, 0), closeTo(before, _tolerance));
  });
}
