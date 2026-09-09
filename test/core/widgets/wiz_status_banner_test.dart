import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';

import '../../support/wiz_test_app.dart';

/// The glyph a banner drew, whatever its tone.
WizIcon _glyph(WidgetTester tester) =>
    tester.widget<WizIcon>(find.byType(WizIcon));

void main() {
  testWidgets('banner shows copy, an action, and a spinner when loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const WizStatusBanner(
                status: WizStatus.error,
                title: 'Not on the home network',
                body: 'Join the home network.',
                action: Text('Retry'),
              ),
              const WizStatusBanner(
                status: WizStatus.loading,
                title: 'Sweeping 192.168.1.0/24',
                body: '12 of 254 addresses',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Not on the home network'), findsOneWidget);
    expect(find.text('Join the home network.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(WizSpinner), findsOneWidget);
  });

  testWidgets('a body and an action are both optional', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: WizStatusBanner(
            status: WizStatus.success,
            title: '4 lights answered',
          ),
        ),
      ),
    );
    expect(find.text('4 lights answered'), findsOneWidget);
    expect(find.byType(WizSpinner), findsNothing);
    expect(_glyph(tester).icon, WizIcons.check);
  });

  testWidgets('every resolved tone draws its own glyph in its own colour', (
    tester,
  ) async {
    var c = WizColors.standard;
    var expected = <WizStatus, (WizIconData, Color)>{
      WizStatus.success: (WizIcons.check, c.signalOnline),
      WizStatus.error: (WizIcons.x, c.signalDanger),
      WizStatus.warn: (WizIcons.wifi, c.signalWarn),
      WizStatus.info: (WizIcons.terminal, c.textSecondary),
    };
    for (var entry in expected.entries) {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 350,
            child: WizStatusBanner(status: entry.key, title: entry.key.name),
          ),
        ),
      );
      var icon = _glyph(tester);
      expect(icon.icon, entry.value.$1, reason: '${entry.key} glyph');
      expect(icon.color, entry.value.$2, reason: '${entry.key} colour');
      expect(icon.size, WizStatusBanner.glyph);
    }
  });

  testWidgets('an action key stays its own node inside the band', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var retries = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: WizStatusBanner(
            status: WizStatus.error,
            title: 'No reply from this light',
            action: WizButton(
              label: 'Retry',
              size: WizButtonSize.sm,
              onPressed: () => retries++,
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('^Retry')), findsOneWidget);
    await tester.tap(find.byType(WizButton));
    await tester.pumpAndSettle();
    expect(retries, 1);
    handle.dispose();
  });

  testWidgets('only an error banner interrupts a screen reader', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: WizStatusBanner(
            status: WizStatus.error,
            title: 'No reply from this light',
          ),
        ),
      ),
    );
    // The flag has to sit on the node holding the copy, not on the band
    // above it: an explicit-children container absorbs no words, so a screen
    // reader would announce an empty region.
    expect(
      tester.getSemantics(find.text('No reply from this light')),
      isSemantics(isLiveRegion: true, label: 'No reply from this light'),
    );

    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: WizStatusBanner(
            status: WizStatus.info,
            title: 'Rooms live in this home only',
            body: 'Nothing is uploaded',
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Rooms live in this home only')),
      isSemantics(
        isLiveRegion: false,
        label: 'Rooms live in this home only\nNothing is uploaded',
      ),
    );
    handle.dispose();
  });
}
