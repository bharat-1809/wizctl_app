import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_bloc.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_event.dart';
import 'package:wizctl_app/features/modes/view/modes_screen.dart';
import 'package:wizctl_app/features/modes/widgets/modes_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// The Scenes tab is a phone screen (spec §10.5), and its target sheet is a
/// bottom sheet rather than a centred dialog there (spec §11.2), so every
/// case runs on a phone surface rather than the tester's 800×600 default,
/// which `WizLayoutScope` would classify as medium.
const Size _phone = Size(390, 844);

void main() {
  Widget screen(AppScope scope, LightModesBloc bloc) => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const ModesNoticeListener(child: ModesScreen(homeId: 'h1')),
    ),
  );

  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone: a bloc built in `setUp` runs its event handlers outside
  /// that zone, where `pump` never reaches them, and one closed outside the
  /// body deadlocks — `AppScope`'s doc has both halves.
  Future<void> withModes(
    WidgetTester tester,
    Future<void> Function(AppScope scope, LightModesBloc bloc) body,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    var bloc = LightModesBloc(
      target: const WholeHomeTarget('h1'),
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      applyColour: scope.applyColour,
      applyWhite: scope.applyWhite,
      applyScene: scope.applyScene,
      setSpeed: scope.setSpeed,
    )..add(const ModesSubscribed());
    try {
      await body(scope, bloc);
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  testWidgets('the tab names the target and counts the scenes truthfully', (
    tester,
  ) async {
    await withModes(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      expect(find.text('Light modes'), findsOneWidget);
      expect(
        find.text(
          'Colour, ${staticScenes.length} static and '
          '${dynamicScenes.length} dynamic scenes',
        ),
        findsOneWidget,
      );
      expect(find.text('APPLY TO'), findsOneWidget);
      expect(find.text('Whole home'), findsOneWidget);
    });
  });

  testWidgets('the target sheet lists home, rooms and lights and re-targets', (
    tester,
  ) async {
    await withModes(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      await tester.tap(find.text('Whole home'));
      await tester.pumpAndSettle();
      expect(find.text('Apply scenes to'), findsOneWidget);
      expect(find.widgetWithText(WizListRow, 'Whole home'), findsOneWidget);
      expect(find.text('6 lights'), findsOneWidget);
      expect(find.text('Bedside bulb'), findsOneWidget);
      expect(find.text('192.168.1.115'), findsOneWidget);
      await tester.tap(find.text('Bedroom'));
      await tester.pumpAndSettle();
      expect(bloc.state.target, const RoomTarget('bedroom'));
      expect(
        find.text('Bedroom'),
        findsOneWidget,
        reason: 'the well key now names it',
      );
    });
  });
}
