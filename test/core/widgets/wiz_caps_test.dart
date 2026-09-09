import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/wiz_pressable.dart';
import 'package:wizctl_app/core/widgets/wiz_rail.dart';
import 'package:wizctl_app/core/widgets/wiz_segmented_control.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';

import '../../support/wiz_test_app.dart';

/// The one raised cap each of these controls moves between its items. There
/// is never more than one on screen: nothing cross-fades.
final Finder _cap = find.byKey(const Key('wiz-cap'));

const List<WizSegment<String>> _segments = [
  WizSegment(value: 'colour', label: 'Colour'),
  WizSegment(value: 'static', label: 'Static'),
  WizSegment(value: 'dynamic', label: 'Dynamic'),
];

/// The focus node the press recipe owns for the item that renders [label] —
/// requested directly rather than tabbed to, so the test does not depend on
/// where the app's traversal happens to start.
FocusNode _focusOf(WidgetTester tester, Finder label) => tester
    .widget<FocusableActionDetector>(
      find.descendant(
        of: find.ancestor(of: label, matching: find.byType(WizPressable)),
        matching: find.byType(FocusableActionDetector),
      ),
    )
    .focusNode!;

void main() {
  testWidgets('the segmented cap sits under the selected segment and travels', (
    tester,
  ) async {
    var feedback = RecordingFeedbackService();
    var value = 'colour';
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 330,
          child: StatefulBuilder(
            builder: (context, setState) {
              return WizSegmentedControl<String>(
                segments: _segments,
                value: value,
                onChanged: (v) => setState(() => value = v),
              );
            },
          ),
        ),
        feedback: feedback,
      ),
    );
    await tester.pumpAndSettle();
    var cap = tester.getRect(_cap);
    var first = tester.getRect(find.text('COLOUR'));
    expect(cap.center.dx, closeTo(first.center.dx, 1));
    await tester.tap(find.text('DYNAMIC'));
    await tester.pumpAndSettle();
    expect(value, 'dynamic');
    var moved = tester.getRect(_cap);
    expect(
      moved.center.dx,
      closeTo(tester.getRect(find.text('DYNAMIC')).center.dx, 1),
    );
    expect(feedback.played, [FeedbackKind.tick]);
    expect(
      tester.getSize(find.byType(WizSegmentedControl<String>)).height,
      44 + 8,
    );
  });

  testWidgets('the tab bar is 72 tall and its amber cap follows the tab', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var value = 'home';
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: StatefulBuilder(
            builder: (context, setState) {
              return WizTabBar<String>(
                tabs: const [
                  WizTab(value: 'home', icon: WizIcons.house, label: 'Home'),
                  WizTab(
                    value: 'rooms',
                    icon: WizIcons.layoutGrid,
                    label: 'Rooms',
                  ),
                  WizTab(
                    value: 'scenes',
                    icon: WizIcons.sparkles,
                    label: 'Scenes',
                  ),
                  WizTab(
                    value: 'settings',
                    icon: WizIcons.slidersHorizontal,
                    label: 'Settings',
                  ),
                ],
                value: value,
                onChanged: (v) => setState(() => value = v),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WizTabBar<String>)).height, 72);
    await tester.tap(find.bySemanticsLabel('Scenes'));
    await tester.pumpAndSettle();
    expect(value, 'scenes');
    var cap = tester.getRect(_cap);
    expect(
      cap.center.dx,
      closeTo(tester.getCenter(find.bySemanticsLabel('Scenes')).dx, 1),
    );
    handle.dispose();
  });

  testWidgets('the rail is 264 wide, 72 collapsed, and selects on tap', (
    tester,
  ) async {
    var value = 'living';
    Widget rail(bool collapsed) => StatefulBuilder(
      builder: (context, setState) {
        return WizRail<String>(
          collapsed: collapsed,
          brand: const Text('WIZCTL'),
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
                WizRailItem(
                  value: 'bedroom',
                  label: 'Bedroom',
                  icon: WizIcons.bed,
                  meta: '2',
                ),
              ],
            ),
            WizRailSection(
              title: 'House',
              items: [
                WizRailItem(
                  value: 'settings',
                  label: 'Settings',
                  icon: WizIcons.slidersHorizontal,
                ),
              ],
            ),
          ],
          value: value,
          onChanged: (v) => setState(() => value = v),
        );
      },
    );
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(height: 600, child: rail(false)),
        size: const Size(1280, 800),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WizRail<String>)).width, 264);
    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    expect(value, 'bedroom');
    expect(
      tester.getRect(_cap).center.dy,
      closeTo(tester.getRect(find.text('Bedroom')).center.dy, 1),
      reason: 'the rail cap travels down the list too',
    );
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(height: 600, child: rail(true)),
        size: const Size(900, 800),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WizRail<String>)).width, 72);
    expect(find.text('Bedroom'), findsNothing);
  });

  testWidgets('a focused segment commits on Enter and on Space', (
    tester,
  ) async {
    // The highlight only shows when the last interaction was a key.
    var previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = previous);

    var feedback = RecordingFeedbackService();
    var value = 'colour';
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 330,
          child: StatefulBuilder(
            builder: (context, setState) => WizSegmentedControl<String>(
              segments: _segments,
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
        feedback: feedback,
      ),
    );
    await tester.pumpAndSettle();

    _focusOf(tester, find.text('STATIC')).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, 'static');

    _focusOf(tester, find.text('DYNAMIC')).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, 'dynamic');
    expect(
      tester.getRect(_cap).center.dx,
      closeTo(tester.getRect(find.text('DYNAMIC')).center.dx, 1),
      reason: 'the cap travels for a keyboard commit too',
    );
    expect(feedback.played, [
      FeedbackKind.tick,
      FeedbackKind.tick,
    ], reason: 'the change is the cue, not the key press');
  });

  testWidgets('assistive tech sees which segment is selected', (tester) async {
    var handle = tester.ensureSemantics();
    var value = 'colour';
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 330,
          child: StatefulBuilder(
            builder: (context, setState) => WizSegmentedControl<String>(
              segments: _segments,
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // One node per segment, addressed by pattern: the pressable's plain
    // label merges with the uppercased word the item draws, exactly as it
    // does everywhere else in the kit (see `wiz_scene_tile_test.dart`).
    expect(find.semantics.byLabel(RegExp('Colour')), findsOne);
    expect(
      find.semantics.byLabel(RegExp('Colour')),
      isSemantics(
        isButton: true,
        isEnabled: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      find.semantics.byLabel(RegExp('Dynamic')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );

    tester.semantics.tap(find.semantics.byLabel(RegExp('Dynamic')));
    await tester.pumpAndSettle();
    expect(value, 'dynamic');
    expect(
      find.semantics.byLabel(RegExp('Dynamic')),
      isSemantics(isSelected: true),
    );
    expect(
      find.semantics.byLabel(RegExp('Colour')),
      isSemantics(isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('the cap re-measures when the track is resized', (tester) async {
    // A surface resize relays out without rebuilding the control, so this
    // only passes if the track measures itself from its constraints.
    await setSurface(tester, const Size(330, 600));
    var value = 'dynamic';
    await tester.pumpWidget(
      wizTestApp(
        WizSegmentedControl<String>(
          segments: _segments,
          value: value,
          onChanged: (v) => value = v,
        ),
      ),
    );
    await tester.pumpAndSettle();
    var narrow = tester.getRect(_cap);
    expect(
      narrow.center.dx,
      closeTo(tester.getRect(find.text('DYNAMIC')).center.dx, 1),
    );

    tester.view.physicalSize = const Size(400, 600);
    await tester.pumpAndSettle();
    var wide = tester.getRect(_cap);
    expect(
      wide.center.dx,
      closeTo(tester.getRect(find.text('DYNAMIC')).center.dx, 1),
      reason: 'the cap re-centres under the selected segment',
    );
    expect(
      wide.width,
      greaterThan(narrow.width),
      reason: 'and grows with it, rather than keeping the stale rect',
    );
  });

  testWidgets('a collapsed rail names its items with tooltips', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          height: 600,
          child: WizRail<String>(
            collapsed: true,
            brand: const Text('WIZCTL'),
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
                  WizRailItem(
                    value: 'bedroom',
                    label: 'Bedroom',
                    icon: WizIcons.bed,
                  ),
                ],
              ),
            ],
            value: 'living',
            onChanged: (_) {},
          ),
        ),
        size: const Size(900, 800),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Living Room'), findsOne);
    expect(find.byTooltip('Bedroom'), findsOne);
    expect(
      find.text('Living Room'),
      findsNothing,
      reason: 'the label is the tooltip, not a rendered row',
    );
  });
}
