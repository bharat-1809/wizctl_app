import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/repositories/light_repository.dart';
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
      // The app half is the mock `setUpAll` installed; the package half is read
      // from the package, so a `wizctl` bump does not break this.
      expect(find.text(Strings.version('0.1.0', cliVersion)), findsOneWidget);
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
      // Every one of the five, so a mis-wired index cannot pass by landing on
      // a neighbour. In tree order: Re-scan on launch and Sound & haptics from
      // `SettingsRows`, then the three prototype switches. Both persisted
      // toggles start on (`AppSettings.defaults`) and the three flags start
      // off (`DebugFlags.none`), so each tap flips a different value.
      var toggles = find.byType(WizToggle);
      expect(toggles, findsNWidgets(5));

      await tester.tap(toggles.at(0));
      await tester.pumpAndSettle();
      expect(scope.settingsCubit.state.rescanOnLaunch, isFalse);
      expect((await scope.seed.settings.get()).rescanOnLaunch, isFalse);

      await tester.tap(toggles.at(1));
      await tester.pumpAndSettle();
      expect(scope.settingsCubit.state.feedbackEnabled, isFalse);
      expect(scope.feedback.enabled, isFalse);

      await tester.tap(toggles.at(2));
      await tester.pumpAndSettle();
      expect(scope.flags.value.offNetwork, isTrue);

      await tester.tap(toggles.at(3));
      await tester.pumpAndSettle();
      expect(scope.flags.value.forceTimeout, isTrue);

      await tester.tap(toggles.at(4));
      await tester.pumpAndSettle();
      expect(scope.flags.value.findNothing, isTrue);

      // Nothing else moved on the way: each setter touched its own value only.
      expect(
        scope.settingsCubit.state.debugFlags,
        const DebugFlags(
          offNetwork: true,
          forceTimeout: true,
          findNothing: true,
        ),
      );
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

  testWidgets('a clipboard that refuses is a toast, not a crash', (
    tester,
  ) async {
    await withSettings(tester, (scope) async {
      var messenger = tester.binding.defaultBinaryMessenger;
      // Only the clipboard refuses: `MaterialApp` drives the rest of this
      // channel (the overlay style, the switcher description) and a handler
      // that threw for everything would fail the test on those instead.
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'unavailable');
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
      await tester.tap(find.text('CLI parity'));
      await tester.pumpAndSettle();
      var toast = scope.toasts.toasts.single;
      expect(toast.title, 'Could not reach the clipboard');
      expect(toast.tone, WizToastTone.error);
    });
  });

  testWidgets('a read that fails leaves the CLI row inert', (tester) async {
    await withSettings(tester, (scope) async {
      // Only the row's own read fails. The repository is overridden for the
      // screen's subtree, so `HomesBloc` — which also reads by home, for its
      // counts — keeps the working one it was built with and the rest of the
      // screen still draws.
      await pumpRouted(
        tester,
        scope.wrap(
          RepositoryProvider<LightRepository>.value(
            value: _FailingLights(scope.seed.lights),
            child: const SettingsScreen(),
          ),
        ),
        size: _desktop,
      );
      await tester.pumpAndSettle();
      // The whole-home line is true of any home, so it stays; the chevron and
      // the tap go, rather than offering a command about a light it could not
      // name.
      expect(find.text('wizctl on -t "Whole home"'), findsOneWidget);
      var row = tester.widget<WizListRow>(
        find.ancestor(
          of: find.text('CLI parity'),
          matching: find.byType(WizListRow),
        ),
      );
      expect(row.onTap, isNull);
      expect(row.trailing, isNull);
      expect(scope.toasts.toasts, isEmpty);
    });
  });
}

/// A [LightRepository] whose `getByHome` always fails, everything else
/// delegated: the read the CLI-parity row makes, and only that one.
class _FailingLights implements LightRepository {
  final LightRepository _inner;
  _FailingLights(this._inner);

  @override
  Future<List<Light>> getByHome(String homeId) async =>
      throw StateError('database closed');

  @override
  Stream<List<Light>> watchByHome(String homeId) => _inner.watchByHome(homeId);
  @override
  Stream<List<Light>> watchByRoom(String roomId) => _inner.watchByRoom(roomId);
  @override
  Stream<Light?> watch(String id) => _inner.watch(id);
  @override
  Future<List<Light>> getByRoom(String roomId) => _inner.getByRoom(roomId);
  @override
  Future<Light?> get(String id) => _inner.get(id);
  @override
  Future<Light?> getByMac(String homeId, String mac) =>
      _inner.getByMac(homeId, mac);
  @override
  Future<void> insert(Light light) => _inner.insert(light);
  @override
  Future<void> update(Light light) => _inner.update(light);
  @override
  Future<void> delete(String id) => _inner.delete(id);
}
