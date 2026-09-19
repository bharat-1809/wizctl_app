import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/dual_dials.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('two dials split the width minus the gap, clamped to the kit range', () {
    expect(
      DualDials.sizeFor(width: 350, count: 2, gap: 12, preferred: 132),
      132,
    );
    expect(
      DualDials.sizeFor(width: 200, count: 2, gap: 12, preferred: 132),
      94,
    );
    expect(
      DualDials.sizeFor(width: 100, count: 2, gap: 12, preferred: 132),
      WizDial.minSize,
    );
    expect(
      DualDials.sizeFor(width: 800, count: 1, gap: 12, preferred: 400),
      WizDial.maxSize,
    );
  });

  testWidgets('one dial without kelvin, two with, and the note below', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: DualDials(
            brightness: 58,
            onBrightness: (_) {},
            preferredSize: 132,
            note: 'This bulb dims but has no white channel to tune.',
          ),
        ),
      ),
    );
    expect(find.byType(WizDial), findsOneWidget);
    expect(
      find.text('This bulb dims but has no white channel to tune.'),
      findsOneWidget,
    );
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: DualDials(
            brightness: 58,
            kelvin: 3050,
            onBrightness: (_) {},
            onKelvin: (_) {},
            preferredSize: 132,
          ),
        ),
      ),
    );
    expect(find.byType(WizDial), findsNWidgets(2));
    expect(tester.getSize(find.byType(WizDial).first).width, 132);
    // `WizDial` uppercases whatever label it is given.
    expect(find.text('BRIGHTNESS'), findsOneWidget);
    expect(find.text('COLOUR TEMP.'), findsOneWidget);
  });

  testWidgets('each dial reports every move and the release', (tester) async {
    var brightness = <int>[];
    var kelvin = <int>[];
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: DualDials(
            brightness: 58,
            kelvin: 3050,
            onBrightness: brightness.add,
            onKelvin: kelvin.add,
            preferredSize: 132,
          ),
        ),
      ),
    );
    await tester.drag(find.byType(WizDial).first, const Offset(0, -40));
    await tester.pump();
    expect(brightness, isNotEmpty);
    expect(brightness.last, greaterThan(58), reason: 'the drag raised it');
    expect(
      brightness.where((v) => v == brightness.last).length,
      greaterThanOrEqualTo(2),
      reason:
          'the release repeats the value the drag settled on, so the '
          'last value always reaches the use case',
    );
    expect(kelvin, isEmpty, reason: 'one dial does not write the other');
  });
}
