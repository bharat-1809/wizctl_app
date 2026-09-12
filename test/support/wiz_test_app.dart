import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';

/// Wraps a widget in the WizCtl theme, a fixed phone-sized MediaQuery and a
/// recording feedback service, so widget tests can assert on sounds fired.
///
/// A [MediaQuery] alone does not change the tester's layout constraints —
/// call [setSurface] first when a test needs the surface itself to be a
/// particular size (width classes, layout breakpoints).
Widget wizTestApp(
  Widget child, {
  Size size = const Size(390, 844),
  FeedbackService? feedback,
}) {
  return FeedbackScope(
    service: feedback ?? RecordingFeedbackService(),
    child: MaterialApp(
      theme: buildWizThemeData(),
      home: Builder(
        // Copied from what the view already reports rather than built
        // outright, so a nested override — the platform's "reduce motion"
        // switch, say — keeps the size this harness pinned instead of
        // dropping it back to zero.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}

/// Wraps [child] in a `MediaQuery` that keeps everything the harness above
/// it set and turns the platform's "reduce motion" switch to [reduced].
///
/// The wrapper is there either way, so a test that flips the switch on a
/// live tree does not change its shape and cost the subject its `State`.
Widget reducedMotion(Widget child, {bool reduced = true}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child,
  ),
);

/// Sets the test surface's physical size so layout — not just `MediaQuery`
/// data — reflects [size]. Restores the tester's view on teardown.
Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
