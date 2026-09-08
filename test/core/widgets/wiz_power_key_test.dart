import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('sizes and feedback', (tester) async {
    var feedback = RecordingFeedbackService();
    var on = false;
    await tester.pumpWidget(
      wizTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WizPowerKey(on: on, onChanged: (v) => setState(() => on = v)),
                WizPowerKey(
                  on: on,
                  onChanged: (v) => setState(() => on = v),
                  size: WizPowerKeySize.md,
                ),
              ],
            );
          },
        ),
        feedback: feedback,
      ),
    );
    var sizes = tester
        .widgetList(find.byType(WizPowerKey))
        .map((w) => tester.getSize(find.byWidget(w)))
        .toList();
    expect(sizes[0], const Size(132, 132));
    expect(sizes[1], const Size(96, 96));
    await tester.tap(find.byType(WizPowerKey).first);
    await tester.pumpAndSettle();
    expect(on, isTrue);
    await tester.tap(find.byType(WizPowerKey).first);
    await tester.pumpAndSettle();
    expect(on, isFalse);
    expect(feedback.played, [FeedbackKind.power, FeedbackKind.toggleOff]);
  });

  testWidgets('a disabled power key ignores taps and plays nothing', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var changed = false;
    await tester.pumpWidget(
      wizTestApp(
        WizPowerKey(
          on: false,
          enabled: false,
          onChanged: (_) => changed = true,
        ),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizPowerKey));
    await tester.pumpAndSettle();
    expect(changed, isFalse);
    expect(feedback.played, isEmpty);
  });

  testWidgets('a power key with no handler ignores taps and plays nothing', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(
      wizTestApp(
        const WizPowerKey(on: false, onChanged: null),
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizPowerKey));
    await tester.pumpAndSettle();
    expect(feedback.played, isEmpty);
  });

  testWidgets('assistive tech sees a labelled switch that reports its state', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var on = true;
    try {
      await tester.pumpWidget(
        wizTestApp(
          StatefulBuilder(
            builder: (context, setState) =>
                WizPowerKey(on: on, onChanged: (v) => setState(() => on = v)),
          ),
        ),
      );
      expect(find.semantics.byLabel('Power'), findsOne);
      expect(
        find.semantics.byLabel('Power'),
        isSemantics(
          label: 'Power',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Power'));
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('Power'), isSemantics(isToggled: false));
    } finally {
      handle.dispose();
    }
  });
}
