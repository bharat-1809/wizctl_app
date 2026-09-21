import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_event.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';
import 'package:wizctl_app/features/rooms/widgets/rooms_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// The Rooms tab is a phone screen (spec §10.6), and its sheets are bottom
/// sheets rather than centred dialogs there (spec §11.2), so every case runs
/// on a phone surface rather than the tester's 800×600 default, which
/// `WizLayoutScope` would classify as medium.
const Size _phone = Size(390, 844);

void main() {
  Widget screen(AppScope scope, RoomsListBloc bloc) => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const RoomsNoticeListener(child: RoomsScreen()),
    ),
  );

  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone: a bloc built in `setUp` runs its event handlers outside
  /// that zone, where `pump` never reaches them, and one closed outside the
  /// body deadlocks — `AppScope`'s doc has both halves.
  Future<void> withRooms(
    WidgetTester tester,
    Future<void> Function(AppScope scope, RoomsListBloc bloc) body,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    var bloc = RoomsListBloc(
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      settings: scope.seed.settings,
      addRoom: AddRoom(rooms: scope.seed.rooms, ids: scope.ids),
      renameRoom: RenameRoom(rooms: scope.seed.rooms),
      deleteRoom: DeleteRoom(
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
      ),
    )..add(const RoomsListSubscribed());
    try {
      await body(scope, bloc);
    } finally {
      unawaited(bloc.close());
      await scope.dispose();
    }
  }

  testWidgets('lists the rooms with counts and the stored note', (
    tester,
  ) async {
    await withRooms(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('3 rooms · 6 lights'), findsOneWidget);
      expect(find.text('3 lights · 2 on'), findsOneWidget);
      expect(find.text('2 lights · 0 on'), findsOneWidget);
      expect(find.text('1 light · 1 on'), findsOneWidget);
      expect(find.text('ADD ROOM'), findsOneWidget);
      expect(
        find.text(
          "Rooms are stored in this home's config file on this machine. "
          'Nothing is uploaded.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('tapping a row opens the room', (tester) async {
    await withRooms(tester, (scope, bloc) async {
      var router = await pumpRouted(
        tester,
        screen(scope, bloc),
        targets: [AppRoutes.roomPattern],
        size: _phone,
      );
      await tester.pump();
      await tester.tap(find.text('Kitchen'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), '/rooms/kitchen');
    });
  });

  testWidgets('the add sheet saves a room and toasts', (tester) async {
    await withRooms(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      await tester.tap(find.byType(WizIconKey).first);
      await tester.pumpAndSettle();
      expect(find.text('Add a room'), findsOneWidget);
      expect(
        tester
            .widget<WizButton>(find.widgetWithText(WizButton, 'SAVE ROOM'))
            .enabled,
        isFalse,
      );
      await tester.enterText(find.byType(WizTextField), 'Study');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Lamp'));
      await tester.tap(find.text('SAVE ROOM'));
      await tester.pumpAndSettle();
      expect(find.text('Study'), findsOneWidget);
      expect(scope.toasts.toasts.single.title, 'Room saved');
      expect(
        scope.toasts.toasts.single.body,
        'Study is empty — discover lights for it',
      );
      var saved = await scope.seed.rooms.getByHome('h1');
      expect(saved, hasLength(4));
      expect(
        saved.last.glyph,
        RoomGlyph.lampDesk,
        reason: 'the glyph the picker was tapped on',
      );
    });
  });

  testWidgets('long-pressing a room with lights offers rename but not delete', (
    tester,
  ) async {
    await withRooms(tester, (scope, bloc) async {
      await pumpRouted(tester, screen(scope, bloc), size: _phone);
      await tester.pump();
      await tester.longPress(find.text('Living Room'));
      await tester.pumpAndSettle();
      expect(find.text('Rename room'), findsOneWidget);
      var delete = tester.widget<WizListRow>(
        find.widgetWithText(WizListRow, 'Delete room'),
      );
      expect(delete.onTap, isNull);
      expect(find.text('Move its lights first'), findsOneWidget);
      await tester.tap(find.text('Rename room'));
      await tester.pumpAndSettle();
      expect(
        find.text('Rename room'),
        findsOneWidget,
        reason: 'the sheet title',
      );
      await tester.enterText(find.byType(WizTextField), 'Lounge');
      await tester.tap(find.text('SAVE ROOM'));
      await tester.pumpAndSettle();
      expect(find.text('Lounge'), findsOneWidget);
    });
  });
}
