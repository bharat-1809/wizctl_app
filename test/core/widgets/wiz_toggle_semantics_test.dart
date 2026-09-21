import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a toggle reads as a switch: a toggled state, its value, a tap', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    try {
      // The engine has no switch role — `SemanticsRole` has no member for one
      // (`bin/cache/pkg/sky_engine/lib/ui/semantics.dart`) — so a switch is a
      // button that reports a toggled state, and its position is that state's
      // value. Both platforms' screen readers announce it from these flags.
      await tester.pumpWidget(
        wizTestApp(
          WizToggle(value: true, onChanged: (_) {}, semanticsLabel: 'Lamp'),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lamp')),
        matchesSemantics(
          label: 'Lamp',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.pumpWidget(
        wizTestApp(
          WizToggle(value: false, onChanged: (_) {}, semanticsLabel: 'Lamp'),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lamp')),
        matchesSemantics(
          label: 'Lamp',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    } finally {
      handle.dispose();
    }
  });
}
