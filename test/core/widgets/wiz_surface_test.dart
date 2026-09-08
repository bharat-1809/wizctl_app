import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';
import 'package:wizctl_app/core/widgets/wiz_panel.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('WizSurface paints outer shadows and sizes to its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        Builder(
          builder: (context) {
            var wiz = context.wiz;
            return WizSurface(
              spec: wiz.elevation.raised,
              radius: BorderRadius.circular(wiz.space.r3),
              gradient: LinearGradient(
                colors: [wiz.colors.surfaceKey, wiz.colors.surfaceRaised],
              ),
              child: const SizedBox(width: 120, height: 40),
            );
          },
        ),
      ),
    );
    expect(tester.getSize(find.byType(WizSurface)), const Size(120, 40));
    var box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(WizSurface),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    var decoration = box.decoration as BoxDecoration;
    expect(decoration.boxShadow, hasLength(2));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets(
    'WizPanel inset variant uses the well recipe and default padding',
    (tester) async {
      await tester.pumpWidget(
        wizTestApp(
          const WizPanel(
            variant: WizPanelVariant.inset,
            child: SizedBox(width: 50, height: 20),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(WizPanel)),
        const Size(50 + 32, 20 + 32),
      );
    },
  );

  testWidgets('WizPanel glow fades with the on flag', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const WizPanel(glow: true, child: SizedBox(width: 10, height: 10)),
      ),
    );
    expect(
      tester.widget<WizGlow>(find.byType(WizGlow)).on,
      isTrue,
      reason: 'glow: true should render a WizGlow that is on',
    );

    await tester.pumpWidget(
      wizTestApp(
        const WizPanel(glow: false, child: SizedBox(width: 10, height: 10)),
      ),
    );
    expect(
      tester.widget<WizGlow>(find.byType(WizGlow)).on,
      isFalse,
      reason: 'glow: false should render a WizGlow that is off',
    );
  });
}
