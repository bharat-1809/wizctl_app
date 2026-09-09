import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/wiz_pressable.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

/// The rail's own hit box, which `WizSlider` keys so its gesture area can be
/// found from outside.
final railTrack = find.byKey(const Key('wiz-slider-track'));

/// The nodes hanging directly off [node], in traversal order.
List<SemanticsNode> childrenOf(SemanticsNode node) {
  var children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

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

      // Both controls a card carries take a finger, not a stylus: the switch
      // pads its 33-tall track out to the floor, and the rail's box is the
      // floor with the 14 track centred in it.
      var floor = WizSpace.standard.hitMin;
      expect(
        tester.getSize(find.byType(WizToggle).first).height,
        greaterThanOrEqualTo(floor),
      );
      expect(tester.getSize(railTrack).height, greaterThanOrEqualTo(floor));
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
    var feedback = RecordingFeedbackService();
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
        feedback: feedback,
      ),
    );
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(opened, 0);
    // The switch claims the gesture, so the card never goes down: the only
    // cue is the switch closing. `arenaResolved` is what buys this — a card
    // that sank on the raw pointer down would have played `press` first.
    expect(feedback.played, [FeedbackKind.toggleOn]);

    feedback.played.clear();
    await tester.tap(find.text('Bedside bulb'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    // The card is silent under the finger: its own cue would fire at the
    // arena's tap-down deadline, which a finger holding the rail's handle
    // reaches too, and the card would then click twice and sink under the
    // handle. `LightCard.jsx` has no pointer-down cue either.
    expect(feedback.played, isEmpty);
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
    var children = childrenOf(card);
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
      isSemantics(
        isSlider: true,
        value: '70%',
        isEnabled: true,
        hasIncreaseAction: true,
      ),
    );
    // The rail holds its own header, so the card's label is the card's copy
    // and the brightness is announced once, on the rail.
    expect(slider.label, contains('Brightness'));
    expect(card.label, isNot(contains('BRIGHTNESS')));
    handle.dispose();
  });

  testWidgets('a rail with nowhere to report is inert', (tester) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Ceiling dome light',
            icon: WizIcons.lampCeiling,
            on: true,
            brightness: 70,
            onToggle: (_) {},
            onTap: () {},
          ),
        ),
      ),
    );

    var card = tester.getSemantics(find.text('Ceiling dome light'));
    var slider = childrenOf(card).last;
    // Drawn, and readable, but not offered as something to adjust.
    expect(
      slider,
      isSemantics(
        isSlider: true,
        value: '70%',
        hasEnabledState: true,
        isEnabled: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
    );
    // And still a node of its own: an inert rail annotates with no actions,
    // so unheld it would dissolve into the card, taking the card's copy with
    // it and leaving the card button unnamed.
    expect(card, isSemantics(isButton: true, hasTapAction: true));
    expect('Ceiling dome light'.allMatches(card.label), hasLength(1));
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
    // No rail on a light that is not answering, so the switch is the card's
    // only control — and it is dead until the light comes back.
    var children = childrenOf(card);
    expect(children, hasLength(1));
    expect(
      children.single,
      isSemantics(hasEnabledState: true, isEnabled: false, isToggled: false),
    );
    handle.dispose();
  });

  testWidgets('dragging the rail reports the end of the change', (
    tester,
  ) async {
    double? ended;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Ceiling dome light',
            icon: WizIcons.lampCeiling,
            on: true,
            brightness: 70,
            onToggle: (_) {},
            onBrightness: (_) {},
            onBrightnessEnd: (v) => ended = v,
          ),
        ),
      ),
    );
    await tester.drag(railTrack, const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(ended, isNotNull);
    expect(ended, lessThan(70));
  });

  testWidgets('a selected card wears the amber ring', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: LightCard(
            name: 'Ceiling dome light',
            icon: WizIcons.lampCeiling,
            on: false,
            brightness: 70,
            selected: true,
            onToggle: (_) {},
          ),
        ),
      ),
    );
    var ringed = tester
        .widgetList<WizSurface>(find.byType(WizSurface))
        .where((s) => s.glow.isNotEmpty)
        .toList();
    expect(ringed, hasLength(1));
    expect(ringed.single.glow.single.color, WizColors.standard.amber500);
    expect(ringed.single.glow.single.spreadRadius, WizSpace.standard.keyBorder);
  });

  testWidgets('a card with no meta and no handlers is inert copy', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: LightCard(
            name: 'Bedside bulb',
            icon: WizIcons.lightbulb,
            on: false,
            brightness: 30,
          ),
        ),
      ),
    );
    // No meta row: the card's whole copy is its name.
    expect(find.byType(LightCard), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Bedside bulb')).label,
      'Bedside bulb',
    );
    // The only pressable is the switch's own, and it is disabled: a card
    // given no `onTap` builds no button of its own.
    expect(find.byType(WizPressable), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(WizToggle)),
      isSemantics(hasEnabledState: true, isEnabled: false, hasTapAction: false),
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
    var feedback = RecordingFeedbackService();
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
        feedback: feedback,
      ),
    );
    expect(find.text('1 light · 1 on'), findsOneWidget);

    // The tile is one button, named once by the copy inside it, with the
    // master switch a node of its own.
    var tile = tester.getSemantics(find.text('Kitchen'));
    expect(tile, isSemantics(isButton: true, hasTapAction: true));
    expect('Kitchen'.allMatches(tile.label), hasLength(1));
    var children = childrenOf(tile);
    expect(children, hasLength(1));
    expect(
      children.single,
      isSemantics(hasToggledState: true, isToggled: true, label: 'Kitchen'),
    );

    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(switched, false);
    expect(opened, 0);
    expect(feedback.played, [FeedbackKind.toggleOff]);

    feedback.played.clear();
    await tester.tap(find.text('Kitchen'));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(feedback.played, [FeedbackKind.press]);
    handle.dispose();
  });
}
