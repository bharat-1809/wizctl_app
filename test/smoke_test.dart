import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';

void main() {
  testWidgets('the app builds and the debug gallery is home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var toasts = ToastController();
    addTearDown(toasts.dispose);

    // Never `bootstrap()`: that starts the real audio engine and renders the
    // grain tile. The services it would build are handed in silent instead.
    await tester.pumpWidget(
      WizCtlApp(
        services: AppServices(feedback: NoopFeedbackService(), toasts: toasts),
      ),
    );

    // The gallery loops for ever (badge dot pulse, skeleton sheen, spinner,
    // the lit hero's breathe, the indeterminate filament), so the tree never
    // settles and `pumpAndSettle` would time out. Bounded pumps only, long
    // enough to drain every `RiseIn` stagger timer.
    await tester.pump(const Duration(milliseconds: 1500));

    // `kDebugMode` is true under `flutter test`, so the gallery is home.
    expect(find.text('Gallery'), findsOneWidget);
  });
}
