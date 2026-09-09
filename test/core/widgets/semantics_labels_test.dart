import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_chip.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_rail.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_segmented_control.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';

import '../../support/wiz_test_app.dart';

/// A surface big enough to hold one of everything without a scroll view,
/// so every part is laid out and every node is in the tree.
const Size _bench = Size(1200, 1800);

Widget _bed() => SizedBox(
  width: 360,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WizButton(label: 'Retry', onPressed: () {}),
      WizChip(label: 'Kitchen', onTap: () {}),
      WizSegmentedControl<String>(
        segments: const [
          WizSegment(value: 'colour', label: 'Colour'),
          WizSegment(value: 'white', label: 'White'),
        ],
        value: 'colour',
        onChanged: (_) {},
      ),
      WizTabBar<String>(
        tabs: const [
          WizTab(value: 'home', icon: WizIcons.house, label: 'Home'),
          WizTab(value: 'scenes', icon: WizIcons.sparkles, label: 'Scenes'),
        ],
        value: 'home',
        onChanged: (_) {},
      ),
      SizedBox(
        height: 200,
        child: WizRail<String>(
          sections: const [
            WizRailSection(
              title: 'Rooms',
              items: [
                WizRailItem(
                  value: 'living',
                  label: 'Living Room',
                  icon: WizIcons.sofa,
                  meta: '3',
                ),
              ],
            ),
          ],
          value: 'living',
          onChanged: (_) {},
        ),
      ),
      SizedBox(
        height: 120,
        child: WizSceneTile(
          sceneId: 6,
          selected: false,
          height: 120,
          onTap: () {},
        ),
      ),
      WizListRow(
        icon: WizIcons.lampDesk,
        title: 'Hallway spot',
        meta: 'Warm white',
        onTap: () {},
      ),
      ModeRow(art: const FlatModeArt(), name: 'Ocean', onTap: () {}),
      LightCard(
        name: 'Desk lamp',
        meta: '192.168.1.24',
        on: true,
        brightness: 70,
        onToggle: (_) {},
        onBrightness: (_) {},
        onTap: () {},
      ),
      RoomCard(
        name: 'Bedroom',
        icon: WizIcons.bed,
        lightCount: 3,
        onCount: 2,
        on: true,
        onToggle: (_) {},
        onTap: () {},
      ),
    ],
  ),
);

void main() {
  testWidgets('no kit part announces the same line twice', (tester) async {
    await setSurface(tester, _bench);
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(wizTestApp(_bed(), size: _bench));
    await tester.pumpAndSettle();

    // Every node in the tree, not only the ones named below: a label whose
    // lines repeat is a part saying the same words twice, whatever drew it.
    expect(
      find.semantics.byPredicate((node) {
        var lines = node.label.split('\n');
        return lines.toSet().length != lines.length;
      }, describeMatch: (_) => 'SemanticsNodes announcing a line twice'),
      findsNothing,
    );

    // A pressable given a label is named by exactly that label: the copy it
    // draws — a button's uppercase cap, a segment's, a tile's name — is its
    // own node's business and is not announced again.
    for (var label in [
      'Retry',
      'Kitchen',
      'Colour',
      'White',
      'Home',
      'Scenes',
      // The rail's count rides in the label, since the meta drawn beside
      // the name is excluded with the rest of the row's copy.
      'Living Room, 3',
      'Cozy',
    ]) {
      expect(
        find.semantics.byLabel(label),
        findsOne,
        reason: 'no node labelled exactly "$label"',
      );
    }

    // A pressable that gives no label of its own is named by the copy it
    // draws, which stays in the tree.
    expect(find.semantics.byLabel('Hallway spot\nWarm white'), findsOne);
    expect(find.semantics.byLabel('LIGHT MODE\nOcean'), findsOne);
    expect(find.semantics.byLabel('Desk lamp\n192.168.1.24'), findsOne);
    expect(find.semantics.byLabel('Bedroom\n3 lights · 2 on'), findsOne);

    // The card's rail: its header draws "BRIGHTNESS 70%", which the node
    // already says as a label and a value.
    expect(
      find.semantics.byLabel('Brightness'),
      isSemantics(isSlider: true, value: '70%'),
    );

    handle.dispose();
  });

  testWidgets('a labelled pressable is still a focus stop', (tester) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(WizButton(label: 'Retry', onPressed: () {})),
    );
    // Excluding the cap's copy must not take the focus flags off the node
    // with it: a key that cannot be focused cannot be reached by keyboard
    // or by switch control.
    expect(
      find.semantics.byLabel('Retry'),
      isSemantics(isButton: true, isFocusable: true),
    );
    handle.dispose();
  });
}
