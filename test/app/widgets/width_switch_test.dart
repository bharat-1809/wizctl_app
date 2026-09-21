import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/width_switch.dart';

import '../../support/router_harness.dart';

/// The two surfaces either side of the compact boundary
/// (`WizBreakpoints.compactMax`): a phone, and a desktop window.
const Size _phone = Size(390, 844);
const Size _desktop = Size(1200, 800);

void main() {
  const subject = WidthSwitch(compact: Text('phone'), wide: Text('desktop'));

  testWidgets('a compact window takes the compact child', (tester) async {
    await pumpRouted(tester, subject, size: _phone);
    expect(find.text('phone'), findsOneWidget);
    expect(find.text('desktop'), findsNothing);
  });

  testWidgets('anything wider takes the wide child', (tester) async {
    await pumpRouted(tester, subject, size: _desktop);
    expect(find.text('desktop'), findsOneWidget);
    expect(find.text('phone'), findsNothing);
  });
}
