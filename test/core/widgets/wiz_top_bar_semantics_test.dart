import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/core/widgets/wiz_top_bar.dart';

import '../../support/wiz_test_app.dart';

/// Wide enough for the bar's titles and both slots to lay out without
/// ellipsising anything away.
const double _barWidth = 360;

/// The bar where every screen puts it: the first item of a lazy list.
/// `ScreenScroll` is a `ListView.separated`, and a list wraps each item in
/// `IndexedSemantics`, which *is* a semantics boundary — so every annotation
/// inside the item merges into that one node unless the bar keeps its own
/// children explicit. Bare in a column the bar separates on its own, which is
/// why this test scrolls: the bug only shows where the screens live (P67).
Widget _bar({
  String? subtitle = 'Living Room',
  bool back = true,
  Widget? trailing,
}) => ListView(
  children: [
    SizedBox(
      width: _barWidth,
      child: WizTopBar(
        title: 'Shelf strip',
        subtitle: subtitle,
        leading: back
            ? WizIconKey(
                icon: WizIcons.chevronLeft,
                semanticsLabel: 'Back',
                onPressed: () {},
              )
            : null,
        trailing: trailing,
      ),
    ),
  ],
);

void main() {
  testWidgets('a bar whose only labelled control is Back keeps it its own '
      'node, without the titles', (tester) async {
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(wizTestApp(_bar()));

      expect(find.semantics.byLabel('Back'), findsOne);
      // The failure this pins: a labelled `WizPressable` annotates without a
      // node of its own, so inside the list item's boundary the title and
      // sub-line beside it pour into its label and the bar reads as one
      // button called "Back / Shelf strip / Living Room".
      expect(
        find.semantics.byPredicate(
          (node) => node.label.contains('Back') && node.label.contains('Shelf'),
          describeMatch: (_) => 'nodes announcing Back and the title together',
        ),
        findsNothing,
      );
      // Three nodes, not four: the bar's own words are one stop, so a screen
      // reader hears "Shelf strip, Living Room" and moves on rather than
      // stopping twice on what is one heading. Only the controls are separate.
      expect(find.semantics.byLabel('Shelf strip\nLiving Room'), findsOne);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('a bar with a labelled trailing control reads as two controls', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        wizTestApp(
          _bar(
            trailing: WizToggle(
              value: true,
              onChanged: (_) {},
              semanticsLabel: 'Shelf strip power',
            ),
          ),
        ),
      );

      // Two buttons cannot share a node — `isButton` collides — so this bar
      // escaped P67 on its own. It is here so the kit fix keeps it that way.
      expect(find.semantics.byLabel('Back'), findsOne);
      expect(find.semantics.byLabel('Shelf strip power'), findsOne);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('a bar with no controls and no sub-line is just its title', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(wizTestApp(_bar(back: false, subtitle: null)));

      // The plainest bar the screens use — a tab's heading. Nothing to reach,
      // so nothing is a control, and the container the kit fix adds must not
      // invent a stop or split a title that has nothing under it.
      expect(find.semantics.byLabel('Back'), findsNothing);
      expect(find.semantics.byLabel('Shelf strip'), findsOne);
    } finally {
      handle.dispose();
    }
  });
}
