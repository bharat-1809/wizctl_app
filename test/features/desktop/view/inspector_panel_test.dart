import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet_route.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/desktop/view/inspector_panel.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// A desktop window wide enough for the column (spec §14, the expanded class),
/// and one past 1600 for the wide reading.
///
/// The height is the column's, not a real window's: the inspector is one
/// scroll from the name to the Forget key, and on an 800-tall surface that key
/// is drawn outside the viewport, where a tap cannot reach it.
/// `light_screen_test.dart` buys the same guarantee the same way.
const Size _expanded = Size(1200, 1400);
const Size _wide = Size(1700, 1400);

/// Long enough for a sheet's rise, the hero's warm-up and a write to reach the
/// fake bulb. Every wait here is a bounded pump: the live badge's dot pulses
/// and a lit hero breathes for ever, so `pumpAndSettle` would time out.
const Duration _settled = Duration(milliseconds: 500);

void main() {
  /// The panel as `DesktopShell` mounts it (Task 20): the content column takes
  /// what is left, so the panel is offered loose constraints and can take its
  /// own width. A route's child is laid out tight, and a `Container(width:)`
  /// enforces the parent's constraints over its own — pumped bare, the panel
  /// would measure the whole window.
  Widget panelInShell(AppScope scope) => scope.wrap(
    const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SizedBox.shrink()),
        InspectorPanel(),
      ],
    ),
  );

  /// Builds the fixture, runs [body] and tears it down, all inside the
  /// tester's zone (P56): a bloc built in `setUp` runs its handlers where
  /// `pump` never reaches them, and one closed outside the body deadlocks.
  Future<void> withScope(
    WidgetTester tester,
    Future<void> Function(AppScope scope) body,
  ) async {
    var scope = AppScope(SeedHome());
    await scope.start();
    try {
      await body(scope);
    } finally {
      await scope.dispose();
    }
  }

  Finder inSheet(String text) => find.descendant(
    of: find.byType(WizSheetRoute),
    matching: find.text(text),
  );

  testWidgets('nothing selected is the empty state, in a 352 column', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      await pumpRouted(tester, panelInShell(scope), size: _expanded);
      await tester.pump(_settled);
      expect(find.byType(WizEmptyState), findsOneWidget);
      expect(find.text('No light selected'), findsOneWidget);
      expect(
        find.text('Pick a light on the left to control it.'),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(InspectorPanel)).width, 352);
    });
  });

  testWidgets('a wide window widens the column to 400', (tester) async {
    await withScope(tester, (scope) async {
      scope.inspector.select('dome');
      await pumpRouted(tester, panelInShell(scope), size: _wide);
      await tester.pump(_settled);
      expect(tester.getSize(find.byType(InspectorPanel)).width, 400);
      expect(find.text('Ceiling dome light'), findsOneWidget);
    });
  });

  testWidgets(
    'a selected RGB light: name, address, badge, compact hero, dials, key, '
    'tiles, mode row, facts, keys',
    (tester) async {
      await withScope(tester, (scope) async {
        scope.inspector.select('dome');
        await pumpRouted(tester, panelInShell(scope), size: _expanded);
        await tester.pump(_settled);
        expect(find.text('Ceiling dome light'), findsOneWidget);
        expect(find.text('192.168.1.104 · RGB'), findsOneWidget);
        expect(tester.widget<WizBadge>(find.byType(WizBadge)).label, 'Live');
        expect(
          tester.widget<FixtureHero>(find.byType(FixtureHero)).compact,
          isTrue,
        );
        expect(find.byType(WizDial), findsNWidgets(2));
        expect(
          tester.widget<WizPowerKey>(find.byType(WizPowerKey)).size,
          WizPowerKeySize.md,
        );
        expect(find.widgetWithText(WizStatTile, 'CLASS'), findsOneWidget);
        expect(find.widgetWithText(WizStatTile, 'SCENE'), findsOneWidget);
        expect(
          find.text('Cozy'),
          findsNWidgets(2),
          reason: 'the tile and the mode row',
        );
        expect(find.byType(ModeRow), findsOneWidget);
        expect(find.text('a8bb50f1c204'), findsOneWidget);
        expect(find.text('udp 38899 · fw 1.25.0'), findsOneWidget);
        expect(find.text('RENAME'), findsOneWidget);
        expect(find.text('FORGET'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'a bulb with no scene on reads out its brightness; forgetting it from the '
    'inspector clears the selection',
    (tester) async {
      await withScope(tester, (scope) async {
        scope.inspector.select('strip');
        await pumpRouted(tester, panelInShell(scope), size: _expanded);
        await tester.pump(_settled);
        expect(find.widgetWithText(WizStatTile, 'BRIGHTNESS'), findsOneWidget);
        expect(find.widgetWithText(WizStatTile, 'SCENE'), findsNothing);

        await tester.tap(find.text('FORGET'));
        await tester.pump();
        await tester.pump(_settled);
        expect(find.text('Forget Shelf strip?'), findsOneWidget);
        await tester.tap(inSheet('FORGET'));
        await tester.pump();
        await tester.pump(_settled);
        expect(scope.inspector.state, isNull);
        expect(find.byType(WizEmptyState), findsOneWidget);
        expect(scope.toasts.toasts.single.title, 'Shelf strip forgotten');
      });
    },
  );

  testWidgets('a plug: the power tile, the socket note and no dials', (
    tester,
  ) async {
    await withScope(tester, (scope) async {
      // Inserted by hand rather than seeded (P29): `SeedHome` has no socket
      // and the light counts in other tests depend on it. The live state *and*
      // the fake bulb are both scripted, because `AppScope` copies the seed's
      // states into the gateway in its constructor — a light added afterwards
      // is not in that copy, and the bloc's read-on-open (spec §5.8) would
      // find nothing at the address and report the plug as silent.
      await scope.seed.lights.insert(
        Light(
          id: 'plug',
          homeId: 'h1',
          roomId: 'kitchen',
          name: 'Kettle plug',
          ip: '192.168.1.130',
          mac: 'a8bb50f24001',
          moduleName: null,
          bulbClass: BulbClass.socket,
          fixture: Fixture.socket,
          fwVersion: '1.25.0',
          sortIndex: 6,
          addedAt: scope.seed.added,
        ),
      );
      scope.seed.store.put(
        'plug',
        LiveState.initial.copyWith(
          isOn: true,
          brightness: 100,
          reachable: true,
        ),
      );
      scope.gateway.states['192.168.1.130'] = const LightState(
        isOn: true,
        dimming: 100,
      );

      scope.inspector.select('plug');
      await pumpRouted(tester, panelInShell(scope), size: _expanded);
      await tester.pump(_settled);
      expect(find.widgetWithText(WizStatTile, 'CLASS'), findsOneWidget);
      expect(find.text('Socket'), findsOneWidget);
      expect(find.widgetWithText(WizStatTile, 'POWER'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      expect(find.text(Strings.plugOnlyNote), findsOneWidget);
      expect(find.byType(WizDial), findsNothing);
      expect(
        find.byType(ModeRow),
        findsNothing,
        reason: 'a socket has no scene channel to open',
      );
    });
  });

  testWidgets('a selection that names nothing falls back to the empty state '
      'and clears itself', (tester) async {
    await withScope(tester, (scope) async {
      // The cubit is cleared on a home switch and nothing else (Task 20), so
      // a light forgotten while it was selected leaves an id that names
      // nothing. The column reads that as no selection rather than drawing a
      // blank.
      scope.inspector.select('ghost');
      await pumpRouted(tester, panelInShell(scope), size: _expanded);
      await tester.pump(_settled);
      expect(find.byType(WizEmptyState), findsOneWidget);
      expect(scope.inspector.state, isNull, reason: 'the stale id goes too');
    });
  });
}
