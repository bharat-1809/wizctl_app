import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/features/home/widgets/homes_notice_listener.dart';
import 'package:wizctl_app/features/home/widgets/homes_sheet.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

/// The sheet is a bottom sheet on a phone and a centred dialog above it
/// (spec §11.2), so every case runs on a phone surface rather than the
/// tester's 800×600 default, which `WizLayoutScope` classifies as medium.
const Size _phone = Size(390, 844);

void main() {
  Widget opener(AppScope scope) => scope.wrap(
    HomesNoticeListener(
      child: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showHomesSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  /// Builds the fixture, runs [body] and tears it down inside the tester's
  /// zone — `AppScope`'s doc says why neither end can happen in `setUp`.
  Future<void> withScope(
    WidgetTester tester,
    Future<void> Function(AppScope scope) body,
  ) async {
    await setSurface(tester, _phone);
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await body(scope);
    } finally {
      await scope.dispose();
    }
  }

  testWidgets('lists every home with its counts, the active one marked', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      await pumpRouted(tester, opener(scope));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Homes'), findsOneWidget);
      expect(find.text('3 rooms · 6 lights'), findsOneWidget);
      expect(find.text('1 room · 1 light'), findsOneWidget);
      var active = tester.widget<WizListRow>(
        find.widgetWithText(WizListRow, 'Kaverappa House'),
      );
      expect(active.active, isTrue);
      expect(
        tester
            .widget<WizListRow>(find.widgetWithText(WizListRow, 'Studio'))
            .active,
        isFalse,
      );
      expect(
        tester
            .widget<WizButton>(find.widgetWithText(WizButton, 'ADD HOME'))
            .enabled,
        isFalse,
      );
    });
  });

  testWidgets('tapping a home switches to it and closes', (tester) async {
    await withScope(tester, (scope) async {
      var router = await pumpRouted(
        tester,
        opener(scope),
        targets: [AppRoutes.home],
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // The row, not `find.text('Studio')`: the new-home field's placeholder
      // is the same word.
      await tester.tap(find.widgetWithText(WizListRow, 'Studio'));
      await tester.pumpAndSettle();
      expect((await scope.seed.settings.get()).activeHomeId, 'h2');
      expect(find.text('Homes'), findsNothing);
      expect(currentLocation(router), AppRoutes.home);
    });
  });

  testWidgets('adding a home activates it, toasts and goes to discovery', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      var router = await pumpRouted(
        tester,
        opener(scope),
        targets: [AppRoutes.discover],
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(WizTextField), 'Cabin');
      await tester.pump();
      expect(
        tester
            .widget<WizButton>(find.widgetWithText(WizButton, 'ADD HOME'))
            .enabled,
        isTrue,
      );
      await tester.tap(find.text('ADD HOME'));
      await tester.pumpAndSettle();
      expect(scope.homes.state.activeHome?.name, 'Cabin');
      expect(scope.toasts.toasts.single.title, 'Cabin created');
      expect(
        scope.toasts.toasts.single.body,
        'Discover the lights on this network',
      );
      expect(currentLocation(router), AppRoutes.discover);
      expect(scope.homes.state.notice, isNull);
      // The toast's own 3.2 s dismiss clock is running; let it finish, or the
      // tester reports a timer still pending after the tree is gone.
      await tester.pump(ToastController.defaultDuration);
    });
  });
}
