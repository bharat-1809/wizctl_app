import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/features/settings/view/settings_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

/// The phone, 390 wide so `WizLayoutScope` classifies it compact — and 2000
/// tall (P69) because every case here names a panel below the fold, and
/// `ScreenScroll`'s lazy list would never build the prototype switches or the
/// About caption at the phone's own 844.
const Size _phone = Size(390, 2000);

/// A desktop, where the subtitle says "machine" and the two CLI rows replace
/// the Discovery row.
const Size _desktop = Size(1200, 800);

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'WizCtl',
      packageName: 'com.dotstudios.wizctlApp',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

  /// Builds the fixture, runs [body] and tears it down inside the tester's
  /// zone (P56): a bloc built in `setUp` runs its handlers where `pump` never
  /// reaches them, and one closed outside the body deadlocks.
  Future<void> withSettings(
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

  testWidgets('the phone rows, in order, with the caption', (tester) async {
    await withSettings(tester, (scope) async {
      await pumpRouted(
        tester,
        scope.wrap(const SettingsScreen()),
        size: _phone,
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('This home lives on this device'), findsOneWidget);
      expect(find.text('One light did not answer'), findsOneWidget);
      var rows = tester
          .widgetList<WizListRow>(find.byType(WizListRow))
          .map((r) => r.title)
          .toList();
      expect(rows.take(4), [
        'Kaverappa House',
        'Discovery',
        'Re-scan on launch',
        'Sound & haptics',
      ]);
      expect(
        find.text('Clicks and vibration on every control'),
        findsOneWidget,
      );
      expect(
        find.text(
          'No account, no cloud. Lights are reached over UDP on port 38899 '
          'on your own network.',
        ),
        findsOneWidget,
      );
      expect(find.text('PROTOTYPE SWITCHES'), findsOneWidget);
      expect(rows.skip(4), [
        'Wrong network',
        'Force command timeout',
        'Discovery finds nothing',
        'Widget gallery',
      ]);
      expect(find.text('WizCtl 0.1.0 · wizctl 1.1.0'), findsOneWidget);
      expect(find.text('Config file'), findsNothing);
    });
  });

  testWidgets('the toggles reach the cubit', (tester) async {
    await withSettings(tester, (scope) async {
      await pumpRouted(
        tester,
        scope.wrap(const SettingsScreen()),
        size: _phone,
      );
      await tester.pumpAndSettle();
      // In tree order: Re-scan on launch, Sound & haptics, then the three
      // prototype switches.
      var toggles = find.byType(WizToggle);
      await tester.tap(toggles.at(1));
      await tester.pump();
      expect(scope.feedback.enabled, isFalse);
      await tester.tap(toggles.at(2));
      await tester.pump();
      expect(scope.flags.value.offNetwork, isTrue);
    });
  });

  testWidgets('rename home and the navigation rows', (tester) async {
    await withSettings(tester, (scope) async {
      var router = await pumpRouted(
        tester,
        scope.wrap(const SettingsScreen()),
        size: _phone,
        targets: [AppRoutes.discover, AppRoutes.gallery],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaverappa House'));
      await tester.pumpAndSettle();
      expect(find.text('Rename home'), findsOneWidget);
      await tester.enterText(find.byType(WizTextField), 'Kaverappa Villa');
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();
      expect(scope.homes.state.activeHome?.name, 'Kaverappa Villa');
      await tester.tap(find.text('Discovery'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), AppRoutes.discover);
      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Widget gallery'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), AppRoutes.gallery);
    });
  });

  testWidgets('a blank name leaves the home alone', (tester) async {
    await withSettings(tester, (scope) async {
      await pumpRouted(
        tester,
        scope.wrap(const SettingsScreen()),
        size: _phone,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaverappa House'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(WizTextField), '   ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();
      expect(scope.homes.state.activeHome?.name, 'Kaverappa House');
      // The sheet is still up, so it is dismissed before the scope goes.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('on a desktop: machine, the two CLI rows, no Discovery row, '
      'copy works', (tester) async {
    await withSettings(tester, (scope) async {
      var copied = <String>[];
      var messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pumpRouted(
        tester,
        scope.wrap(const SettingsScreen()),
        size: _desktop,
      );
      await tester.pumpAndSettle();
      expect(find.text('This home lives on this machine'), findsOneWidget);
      expect(find.text('Discovery'), findsNothing);
      expect(find.text('Config file'), findsOneWidget);
      expect(
        find.textContaining('~/.config/wizctl/config.json'),
        findsOneWidget,
      );
      expect(
        find.text('Aliases and rooms are exported here for the CLI'),
        findsOneWidget,
      );
      expect(find.text('Clicks on every control'), findsOneWidget);
      expect(find.text('wizctl on -t "Ceiling dome light"'), findsOneWidget);
      await tester.tap(find.text('CLI parity'));
      await tester.pumpAndSettle();
      expect(copied.single, 'wizctl on -t "Ceiling dome light"');
      expect(scope.toasts.toasts.single.title, 'Copied to the clipboard');
      // The CLI row reads its light once: a rebuild of the screen — a toggle
      // is enough — must not drop the command back to the whole-home fallback.
      await tester.tap(find.byType(WizToggle).at(1));
      await tester.pump();
      expect(find.text('wizctl on -t "Ceiling dome light"'), findsOneWidget);
    });
  });
}
