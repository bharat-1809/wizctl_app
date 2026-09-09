import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/theme/wiz_type.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_readout.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_top_bar.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('top bar shows title and subtitle with slots', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: WizTopBar(
            title: 'Living Room',
            subtitle: '3 lights',
            trailing: Text('T'),
          ),
        ),
      ),
    );
    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text('3 lights'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(
      tester.getSize(find.byType(WizTopBar)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('list rows tap and long-press with feedback', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0, longs = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: WizListRow(
            icon: WizIcons.sofa,
            title: 'Living Room',
            meta: '3 lights · 1 on',
            onTap: () => taps++,
            onLongPress: () => longs++,
          ),
        ),
        feedback: feedback,
      ),
    );
    await tester.tap(find.text('Living Room'));
    await tester.longPress(find.text('Living Room'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(longs, 1);
    expect(feedback.played.first, FeedbackKind.press);
  });

  testWidgets('badge, stat tile and empty state render their copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WizBadge(
                label: 'Live',
                tone: WizBadgeTone.online,
                dot: true,
              ),
              const WizStatTile(
                icon: WizIcons.thermometer,
                label: 'Colour temp',
                value: '2700',
                unit: 'K',
              ),
              WizEmptyState(
                icon: WizIcons.radio,
                title: 'Nothing found yet',
                body: 'Lights answer on your local network.',
                action: const Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('LIVE'), findsOneWidget);
    expect(tester.getSize(find.byType(WizBadge)).height, 22);
    expect(find.text('COLOUR TEMP'), findsOneWidget);
    expect(find.text('2700'), findsOneWidget);
    expect(find.text('Nothing found yet'), findsOneWidget);
  });

  testWidgets('a badge hugs its label rather than the width it is offered', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WizBadge(label: 'Live', tone: WizBadgeTone.online, dot: true),
            ],
          ),
        ),
      ),
    );
    var space = WizSpace.standard;
    var pad = space.s4 + space.s1 / 2;
    expect(
      tester.getSize(find.byType(WizBadge)).width,
      moreOrLessEquals(
        tester.getSize(find.text('LIVE')).width +
            2 * pad +
            WizBadge.dotSize +
            space.s3,
      ),
    );
  });

  testWidgets('a stat tile sets its unit in the face of the value', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const WizStatTile(
          icon: WizIcons.thermometer,
          label: 'Colour temp',
          value: '2700',
          unit: 'K',
        ),
      ),
    );
    // StatTile.jsx gives the unit its own size, weight and colour and
    // nothing else: it stays on the display face it is nested in.
    var unit = tester.widget<Text>(find.text('K'));
    expect(unit.style!.fontFamily, WizType.familyDisplay);
    expect(unit.style!.fontSize, WizStatTile.unitSize);
    expect(unit.style!.fontWeight, WizStatTile.unitWeight);
    expect(unit.style!.color, WizColors.standard.textTertiary);
  });

  testWidgets('a readout sizes its unit against the numeral it follows', (
    tester,
  ) async {
    // The sizes come from the type tokens rather than from 18 / 34 written
    // out here, so the test still describes the readout if a token moves.
    var type = WizType.standard;
    var numerals = <WizReadoutSize, double>{
      WizReadoutSize.sm: type.readoutSm.fontSize!,
      WizReadoutSize.md: type.readout.fontSize!,
      WizReadoutSize.lg: WizReadout.lgSize,
    };
    for (var entry in numerals.entries) {
      // One size per pump: the same value string in three readouts at once
      // would match three widgets and say nothing about which is wrong.
      await tester.pumpWidget(
        wizTestApp(
          WizReadout(
            value: '2700',
            unit: 'K',
            label: 'Colour temp',
            size: entry.key,
          ),
        ),
      );
      var value = tester.widget<Text>(find.text('2700'));
      var unit = tester.widget<Text>(find.text('K'));
      expect(value.style!.fontSize, entry.value, reason: '${entry.key}');
      expect(
        unit.style!.fontSize,
        entry.value * WizReadout.unitRatio,
        reason: '${entry.key}',
      );
      expect(value.style!.fontFamily, WizType.familyDisplay);
      expect(find.text('COLOUR TEMP'), findsOneWidget);
    }
    await tester.pumpWidget(
      wizTestApp(const WizReadout(value: '2700', unit: 'K', mono: true)),
    );
    var mono = tester.widget<Text>(find.text('2700'));
    expect(mono.style!.fontFamily, WizType.familyMono);
    expect(mono.style!.fontSize, type.readout.fontSize);
  });
}
