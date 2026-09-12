import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';

void main() {
  testWidgets('the scope hands out its service', (tester) async {
    var recording = RecordingFeedbackService();
    late FeedbackService found;
    await tester.pumpWidget(
      FeedbackScope(
        service: recording,
        child: Builder(
          builder: (context) {
            found = context.feedback;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(found, same(recording));
    found.play(FeedbackKind.detent);
    expect(recording.played, [FeedbackKind.detent]);
  });

  testWidgets('without a scope, feedback is a silent no-op', (tester) async {
    late FeedbackService found;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          found = context.feedback;
          return const SizedBox();
        },
      ),
    );
    expect(found, isA<NoopFeedbackService>());
    found.play(FeedbackKind.power);
  });

  test('a disabled recorder records nothing', () async {
    var recording = RecordingFeedbackService();
    await recording.setEnabled(false);
    recording.play(FeedbackKind.press);
    expect(recording.played, isEmpty);
    expect(recording.enabled, isFalse);
  });
}
