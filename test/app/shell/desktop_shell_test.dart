import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/desktop_rail.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/layout/wiz_breakpoints.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet_route.dart';
import 'package:wizctl_app/features/desktop/view/grid_screen.dart';
import 'package:wizctl_app/features/desktop/view/inspector_body.dart';
import 'package:wizctl_app/features/desktop/view/inspector_panel.dart';
import 'package:wizctl_app/features/desktop/widgets/inspector_facts.dart';
import 'package:wizctl_app/features/lights/bloc/light_bloc.dart';
import 'package:wizctl_app/features/lights/bloc/light_event.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';
import '../../support/wiz_test_app.dart';

/// The narrowest window that gets the desktop chrome: one pixel over
/// `WizBreakpoints.compactMax`, which is where the medium class begins. The
/// rail is collapsed to 72 here, so the content column is only 649 wide — a
/// second `WizLayoutScope` around it would measure that as compact and swap
/// the phone's rows back in.
const Size _narrowestDesktop = Size(WizBreakpoints.compactMax + 1, 800);

/// An expanded window: wide enough for the inspector column.
const Size _expanded = Size(1200, 800);

/// Two bounded pumps: the route page and its bloc's first emission each need a
/// frame, and `pumpAndSettle` never returns with a poll timer running.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('Settings in the desktop shell keeps its CLI rows at the '
      'narrowest desktop width', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      var router = await pumpAppRouter(tester, scope, size: _narrowestDesktop);
      await settle(tester);
      expect(
        find.byType(DesktopRail),
        findsOneWidget,
        reason: 'medium is a desktop class',
      );

      router.go(AppRoutes.settings);
      await settle(tester);
      expect(find.text(Strings.configFile), findsOneWidget);
      expect(find.text(Strings.configFilePath), findsOneWidget);
      expect(
        find.text(Strings.discoveryMeta),
        findsNothing,
        reason: "the phone's Discovery row belongs to the compact class only",
      );
      expect(find.text(Strings.homeLivesOnMachine), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await scope.dispose();
    }
  });

  testWidgets('switching home clears the light the inspector held', (
    tester,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await pumpAppRouter(tester, scope, size: _expanded);
      await settle(tester);
      expect(find.byType(GridScreen), findsOneWidget);

      await tester.tap(find.text('Bedside bulb'));
      await settle(tester);
      expect(scope.inspector.state, 'bedside');

      scope.homes.add(const HomeSwitched('h2'));
      await settle(tester);
      expect(
        scope.inspector.state,
        isNull,
        reason: 'a light of the home just left names nothing in the new one',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await scope.dispose();
    }
  });

  testWidgets('resizing across the column boundary keeps the selection and '
      'opens no dialog', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await pumpAppRouter(tester, scope, size: _expanded);
      await settle(tester);
      await tester.tap(find.text('Bedside bulb'));
      await settle(tester);
      expect(find.byType(InspectorPanel), findsOneWidget);
      expect(find.byType(InspectorBody), findsOneWidget);

      await setSurface(tester, _narrowestDesktop);
      await settle(tester);
      expect(
        find.byType(InspectorPanel),
        findsNothing,
        reason: 'the medium class has no third column',
      );
      expect(
        scope.inspector.state,
        'bedside',
        reason: 'a resize is not a change of mind about which light',
      );
      expect(
        find.byType(WizSheetRoute),
        findsNothing,
        reason: 'and it is not a new pick either, so no dialog opens over it',
      );

      await setSurface(tester, _expanded);
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(InspectorPanel),
          matching: find.text('Bedside bulb'),
        ),
        findsOneWidget,
        reason: 'widening it back shows the light that was held all along',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await scope.dispose();
    }
  });

  testWidgets('the medium dialog closes when its light is forgotten, and still '
      'toasts', (tester) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await pumpAppRouter(tester, scope, size: _narrowestDesktop);
      await settle(tester);
      scope.inspector.select('strip');
      await settle(tester);
      expect(
        find.byType(WizSheetRoute),
        findsOneWidget,
        reason: 'the medium class shows the inspector as a dialog',
      );

      // The body's own bloc rather than a tap on FORGET: the sheet caps at 86 %
      // of the window, so that key is below the fold here, and what is under
      // test is the contract — the light goes, and the dialog goes with it
      // rather than staying up over controls that no longer reach anything.
      BlocProvider.of<LightBloc>(tester.element(find.byType(InspectorFacts)))
          .add(const LightForgotten());
      await settle(tester);
      expect(find.byType(WizSheetRoute), findsNothing);
      expect(scope.inspector.state, isNull);
      expect(
        scope.toasts.toasts.single.title,
        'Shelf strip forgotten',
        reason: 'navigate: false skips the leave, never the toast',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await scope.dispose();
    }
  });
}
