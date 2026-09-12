import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets(
    'a field is a control-height well that types into its controller',
    (tester) async {
      var controller = TextEditingController();
      addTearDown(controller.dispose);
      String? submitted;
      await tester.pumpWidget(
        wizTestApp(
          WizTextField(
            controller: controller,
            placeholder: 'Home name',
            onSubmitted: (value) => submitted = value,
            textInputAction: TextInputAction.done,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(WizTextField)).height,
        WizSpace.standard.controlMd,
      );
      expect(find.text('Home name'), findsOneWidget);

      await tester.enterText(find.byType(WizTextField), 'Loft');
      await tester.pump();
      expect(controller.text, 'Loft');
      expect(tester.testTextInput.hasAnyClients, isTrue);

      // What pressing Enter on a single-line field sends.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 'Loft');
    },
  );

  testWidgets('onChanged reports every keystroke', (tester) async {
    var controller = TextEditingController();
    addTearDown(controller.dispose);
    var seen = <String>[];
    await tester.pumpWidget(
      wizTestApp(WizTextField(controller: controller, onChanged: seen.add)),
    );
    await tester.enterText(find.byType(WizTextField), 'Den');
    await tester.pump();
    expect(seen, ['Den']);
  });

  testWidgets('a disabled field takes neither focus nor input', (tester) async {
    var controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wizTestApp(WizTextField(controller: controller, enabled: false)),
    );
    await tester.tap(find.byType(WizTextField));
    await tester.pumpAndSettle();
    expect(
      tester.testTextInput.hasAnyClients,
      isFalse,
      reason: 'a disabled field never opens an input connection',
    );
    expect(controller.text, isEmpty);
  });
}
