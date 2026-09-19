import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_bloc.dart';
import 'package:wizctl_app/features/modes/view/modes_sheet.dart';
import 'package:wizctl_app/features/modes/widgets/swatch_row.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// The sheet is a bottom sheet on a phone and a centred dialog above it
/// (spec §11.2), so every case names the surface it runs on rather than
/// taking the tester's 800×600 default, which `WizLayoutScope` classifies as
/// medium.
const Size _phone = Size(390, 844);
const Size _desktop = Size(1200, 800);

void main() {
  /// Builds the fixture, runs [body] and tears it down inside the tester's
  /// zone — `AppScope`'s doc says why neither end can happen in `setUp`.
  /// [blocFor] records every bloc it builds so they are all closed here: the
  /// cases leave the sheet up, so the `whenComplete` inside `showModesSheet`
  /// never runs.
  Future<void> withScope(
    WidgetTester tester,
    Future<void> Function(
      AppScope scope,
      Widget Function(ModeTarget target) opener,
    )
    body,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    var blocs = <LightModesBloc>[];
    LightModesBloc blocFor(ModeTarget target) {
      var bloc = LightModesBloc(
        target: target,
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        store: scope.seed.store,
        applyColour: scope.applyColour,
        applyWhite: scope.applyWhite,
        applyScene: scope.applyScene,
        setSpeed: scope.setSpeed,
      );
      blocs.add(bloc);
      return bloc;
    }

    Widget opener(ModeTarget target) => scope.wrap(
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                showModesSheet(context, target: target, blocFor: blocFor),
            child: const Text('open'),
          ),
        ),
      ),
    );

    try {
      await body(scope, opener);
    } finally {
      for (var bloc in blocs) {
        unawaited(bloc.close());
      }
      await scope.dispose();
    }
  }

  testWidgets(
    'a room sheet: title, three tabs, the wheel and both swatch rows',
    (tester) async {
      await withScope(tester, (scope, opener) async {
        await pumpRouted(
          tester,
          opener(const RoomTarget('living')),
          size: _phone,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Light mode · Living Room'), findsOneWidget);
        expect(find.text('COLOUR'), findsOneWidget);
        expect(find.text('STATIC'), findsOneWidget);
        expect(find.text('DYNAMIC'), findsOneWidget);
        expect(find.byType(WizColorWheel), findsOneWidget);
        expect(find.byType(Swatch), findsNWidgets(12));
        expect(find.byType(WhiteTile), findsNWidgets(6));
        expect(find.text('2700K'), findsOneWidget);
      });
    },
  );

  testWidgets('a swatch writes the colour to the RGB lights', (tester) async {
    await withScope(tester, (scope, opener) async {
      await pumpRouted(
        tester,
        opener(const RoomTarget('living')),
        size: _phone,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Red'));
      await tester.pump();
      await tester.pump();
      expect(scope.gateway.sends.map((s) => s.$1), [
        '192.168.1.104',
        '192.168.1.107',
      ]);
      expect(scope.gateway.sends.first.$2.r, 255);
    });
  });

  testWidgets(
    'a dim-only light gets no wheel and colour is refused with a toast',
    (tester) async {
      await withScope(tester, (scope, opener) async {
        await pumpRouted(
          tester,
          opener(const LightTarget('hall')),
          size: _phone,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byType(WizColorWheel), findsNothing);
        await tester.tap(find.bySemanticsLabel('Red'));
        await tester.pumpAndSettle();
        expect(scope.toasts.toasts.single.title, 'No colour bulb here');
        expect(scope.toasts.toasts.single.body, 'Colour needs an RGB bulb.');
      });
    },
  );

  testWidgets(
    'the static tab lists the static scenes; a tap applies and toasts',
    (tester) async {
      await withScope(tester, (scope, opener) async {
        await pumpRouted(
          tester,
          opener(const RoomTarget('living')),
          size: _phone,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('STATIC'));
        await tester.pumpAndSettle();
        expect(find.byType(WizSceneTile), findsNWidgets(staticScenes.length));
        expect(
          find.text('Static scenes hold one look. The bulb ignores speed.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Cozy'));
        await tester.pumpAndSettle();
        expect(scope.gateway.sends, hasLength(3));
        expect(scope.toasts.toasts.single.title, 'Cozy applied');
        expect(scope.toasts.toasts.single.body, 'to Living Room');
      });
    },
  );

  testWidgets(
    'the dynamic tab shows the speed rail once all lights share a dynamic scene',
    (tester) async {
      await withScope(tester, (scope, opener) async {
        await pumpRouted(
          tester,
          opener(const RoomTarget('living')),
          size: _phone,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('DYNAMIC'));
        await tester.pumpAndSettle();
        expect(find.byType(WizSlider), findsNothing);
        expect(find.byType(WizSceneTile), findsNWidgets(dynamicScenes.length));
        await tester.tap(find.text('Ocean'));
        await tester.pumpAndSettle();
        expect(find.byType(WizSlider), findsOneWidget);
        // `WizSlider` uppercases its label, the way every control label in
        // the kit is drawn.
        expect(find.text('SPEED — OCEAN'), findsOneWidget);
        expect(
          find.text('Dynamic scenes cycle. Speed runs from 10 to 200.'),
          findsOneWidget,
        );
      });
    },
  );

  testWidgets(
    'on a wide surface the sheet is a dialog with the desktop wheel',
    (tester) async {
      await withScope(tester, (scope, opener) async {
        await pumpRouted(
          tester,
          opener(const WholeHomeTarget('h1')),
          size: _desktop,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Light mode · whole home'), findsOneWidget);
        expect(
          tester.widget<WizColorWheel>(find.byType(WizColorWheel)).size,
          216,
        );
      });
    },
  );
}
