import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets(
    'a lit light card shows the rail; a plug shows none; unreachable shows the line',
    (tester) async {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LightCard(
                  name: 'Ceiling dome light',
                  meta: 'Cozy',
                  icon: WizIcons.lampCeiling,
                  on: true,
                  brightness: 70,
                  onToggle: (_) {},
                  onBrightness: (_) {},
                ),
                LightCard(
                  name: 'Plug by the TV',
                  meta: 'Power on',
                  icon: WizIcons.power,
                  on: true,
                  brightness: 100,
                  control: WizBrightnessControl.none,
                  onToggle: (_) {},
                ),
                LightCard(
                  name: 'Hallway',
                  meta: '192.168.1.118',
                  icon: WizIcons.lightbulb,
                  on: false,
                  unreachable: true,
                  brightness: 50,
                  onToggle: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(WizSlider), findsOneWidget);
      expect(find.text('No response on the local network'), findsOneWidget);
      expect(find.byType(WizToggle), findsNWidgets(3));
      // Every card clears the touch floor on the well and padding alone.
      for (var i = 0; i < 3; i++) {
        expect(
          tester.getSize(find.byType(LightCard).at(i)).height,
          greaterThanOrEqualTo(WizSpace.standard.hitMin),
        );
      }
    },
  );

  testWidgets('the meter draws the read-only percentage', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Desk lamp',
            meta: 'Warm white',
            icon: WizIcons.lightbulb,
            on: true,
            brightness: 64,
            control: WizBrightnessControl.meter,
            onToggle: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(WizSlider), findsNothing);
    expect(find.text('64%'), findsOneWidget);
  });

  testWidgets('tapping the toggle does not open the card', (tester) async {
    var opened = 0;
    var toggled = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Bedside bulb',
            meta: '2700K white',
            icon: WizIcons.lightbulb,
            on: false,
            brightness: 30,
            onToggle: (_) => toggled++,
            onTap: () => opened++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(opened, 0);
    await tester.tap(find.text('Bedside bulb'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('the card, its toggle and its rail are three nodes', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Ceiling dome light',
            meta: 'Cozy',
            icon: WizIcons.lampCeiling,
            on: true,
            brightness: 70,
            onToggle: (_) {},
            onBrightness: (_) {},
            onTap: () {},
          ),
        ),
      ),
    );

    var card = tester.getSemantics(find.text('Ceiling dome light'));
    // Read off the card node rather than through `find.byType`, which
    // resolves to the nearest *enclosing* node and so would answer with the
    // card for all three — passing every flag below even on a tree that had
    // collapsed into one node.
    var children = <SemanticsNode>[];
    card.visitChildren((child) {
      children.add(child);
      return true;
    });
    var toggle = children.first;
    var slider = children.last;

    // Distinct ids, in a card that kept exactly the two controls as nodes of
    // their own: the switch above, the rail below.
    expect(children, hasLength(2));
    expect({card.id, toggle.id, slider.id}, hasLength(3));

    expect(card, isSemantics(isButton: true, hasTapAction: true));
    expect(card.label, contains('Ceiling dome light'));
    // Named once. The pressable is handed no label of its own, so the copy
    // inside it is the whole name and assistive tech reads it one time.
    expect('Ceiling dome light'.allMatches(card.label), hasLength(1));
    expect(
      toggle,
      isSemantics(
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        label: 'Ceiling dome light',
      ),
    );
    expect(
      slider,
      isSemantics(isSlider: true, label: 'Brightness', value: '70%'),
    );
    handle.dispose();
  });

  testWidgets('an unreachable card reports its switch as disabled', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Hallway',
            meta: '192.168.1.118',
            icon: WizIcons.lightbulb,
            on: false,
            unreachable: true,
            brightness: 50,
            onToggle: (_) {},
            onTap: () {},
          ),
        ),
      ),
    );

    var card = tester.getSemantics(find.text('Hallway'));
    expect(card, isSemantics(isButton: true, hasTapAction: true));
    expect(card.label, contains('No response on the local network'));
    // Named once here too: a disabled switch must not pour its own label
    // into the card's.
    expect('Hallway'.allMatches(card.label), hasLength(1));
    var children = <SemanticsNode>[];
    card.visitChildren((child) {
      children.add(child);
      return true;
    });
    // No rail on a light that is not answering, so the switch is the card's
    // only control — and it is dead until the light comes back.
    expect(children, hasLength(1));
    expect(
      children.single,
      isSemantics(hasEnabledState: true, isEnabled: false, isToggled: false),
    );
    handle.dispose();
  });

  testWidgets('room card counts', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 170,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoomCard(
                name: 'Living Room',
                icon: WizIcons.sofa,
                lightCount: 3,
                onCount: 2,
                on: true,
                onToggle: (_) {},
                onTap: () {},
              ),
              RoomCard(
                name: 'Bedroom',
                icon: WizIcons.bed,
                lightCount: 1,
                onCount: 0,
                on: false,
                onToggle: (_) {},
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('3 lights · 2 on'), findsOneWidget);
    expect(find.text('1 light · all off'), findsOneWidget);
  });

  testWidgets('a room master switch flips without opening the room', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var opened = 0;
    bool? switched;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 170,
          child: RoomCard(
            name: 'Kitchen',
            icon: WizIcons.sofa,
            lightCount: 1,
            onCount: 1,
            on: true,
            onToggle: (v) => switched = v,
            onTap: () => opened++,
          ),
        ),
      ),
    );
    expect(find.text('1 light · 1 on'), findsOneWidget);

    // The tile is one button, named once by the copy inside it, with the
    // master switch a node of its own.
    var tile = tester.getSemantics(find.text('Kitchen'));
    expect(tile, isSemantics(isButton: true, hasTapAction: true));
    expect('Kitchen'.allMatches(tile.label), hasLength(1));
    var children = <SemanticsNode>[];
    tile.visitChildren((child) {
      children.add(child);
      return true;
    });
    expect(children, hasLength(1));
    expect(
      children.single,
      isSemantics(hasToggledState: true, isToggled: true, label: 'Kitchen'),
    );

    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(switched, false);
    expect(opened, 0);
    await tester.tap(find.text('Kitchen'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    handle.dispose();
  });
}
