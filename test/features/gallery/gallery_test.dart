import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/motion/breathe.dart';
import 'package:wizctl_app/core/motion/rise_in.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_chip.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/layout/wiz_grid.dart';
import 'package:wizctl_app/core/widgets/wiz_panel.dart';
import 'package:wizctl_app/core/widgets/wiz_pressable.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';
import 'package:wizctl_app/core/widgets/wiz_rail.dart';
import 'package:wizctl_app/core/widgets/wiz_readout.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_art.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_segmented_control.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet_route.dart';
import 'package:wizctl_app/core/widgets/wiz_skeleton.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/core/widgets/wiz_toast.dart';
import 'package:wizctl_app/core/widgets/wiz_toast_layer.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/core/widgets/wiz_top_bar.dart';
import 'package:wizctl_app/features/gallery/gallery_dials.dart';
import 'package:wizctl_app/features/gallery/gallery_feedback.dart';
import 'package:wizctl_app/features/gallery/gallery_fields.dart';
import 'package:wizctl_app/features/gallery/gallery_hero.dart';
import 'package:wizctl_app/features/gallery/gallery_keys.dart';
import 'package:wizctl_app/features/gallery/gallery_navigation.dart';
import 'package:wizctl_app/features/gallery/gallery_rows.dart';
import 'package:wizctl_app/features/gallery/gallery_scenes.dart';
import 'package:wizctl_app/features/gallery/gallery_states.dart';
import 'package:wizctl_app/features/gallery/gallery_switches.dart';
import 'package:wizctl_app/features/gallery/gallery_wheel.dart';
import 'package:wizctl_app/features/gallery/gallery_wordmark.dart';

/// A phone-wide surface tall enough that the gallery's `ListView.builder`
/// builds every section: a lazy list only builds what is near the viewport,
/// and a missing widget below the fold reads exactly like one that was never
/// added.
const Size _wholeGallery = Size(390, 12000);

/// Wide enough to land in `WidthClass.expanded`, where the toast stack goes
/// bottom-right instead of above the tab bar.
const Size _desktopWindow = Size(1200, 12000);

/// Long enough to drain every `RiseIn` stagger timer (one per section, 55 ms
/// apart) and settle the entrances.
const Duration _settled = Duration(milliseconds: 1500);

/// How many `.dart` files `lib/core/widgets` holds. The coverage map below
/// is a literal and cannot notice a new widget on its own; this count can,
/// and failing it is the prompt to go and add the demo.
const int _kitWidgetFiles = 55;

/// `byType` compares runtime types exactly, so a generic widget built as
/// `WizTabBar<SomeEnum>` never matches the bare `WizTabBar` type literal.
/// A subtype test does match, because Dart's generics are covariant.
Finder _byGeneric<T>(String name) =>
    find.byWidgetPredicate((w) => w is T, description: name);

/// A widget in the section that is supposed to demonstrate it.
///
/// Unscoped, this test is much weaker than it looks: kit widgets are built
/// out of each other, so `find.byType(WizSpinner)` matches the one
/// `WizStatusBanner` builds for its loading tone, and would keep passing
/// after the deliberate spinner demo was deleted. Scoping each entry to its
/// own section is what makes "a future widget cannot be forgotten silently"
/// actually true.
Finder _inSection<S extends Widget>(Finder widget) =>
    find.descendant(of: find.byType(S), matching: widget);

/// Builds the whole app on [size] and settles the entrances. Returns the
/// queue it was given, already registered for disposal.
Future<ToastController> _pumpGallery(
  WidgetTester tester, {
  Size size = _wholeGallery,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  var toasts = ToastController();
  addTearDown(toasts.dispose);

  await tester.pumpWidget(
    WizCtlApp(
      services: AppServices(feedback: NoopFeedbackService(), toasts: toasts),
    ),
  );
  // The gallery loops for ever (badge dot, skeleton sheen, spinner, the lit
  // hero's breathe, the indeterminate filament), so the tree never settles
  // and `pumpAndSettle` would time out. Bounded pumps only.
  await tester.pump(_settled);
  return toasts;
}

void main() {
  testWidgets('the gallery shows one of every kit widget', (tester) async {
    await _pumpGallery(tester);

    // Spec §11.2's kit, one entry per widget.
    //
    // What this guards: a demo *deleted* from a section fails here rather
    // than quietly vanishing from the screen the design is reviewed on. It
    // cannot guard the opposite — this map is a literal, so a widget newly
    // added to `core/widgets` is simply absent from it and nothing fails.
    // The file-count test below is what forces a visit to this map when a
    // widget file appears.
    //
    // `WizSheet` is not here: it is a route, so its coverage is the
    // ModeRow-tap test further down. `wizFadePage` has no demo at all until
    // Plan 4 lands the router (see `GalleryScreen`'s doc).
    var kit = <String, Finder>{
      'WizButton': _inSection<GalleryKeys>(find.byType(WizButton)),
      'WizChip': _inSection<GalleryKeys>(find.byType(WizChip)),
      'WizIconKey': _inSection<GalleryKeys>(find.byType(WizIconKey)),
      'WizToggle': _inSection<GallerySwitches>(find.byType(WizToggle)),
      'WizPowerKey': _inSection<GallerySwitches>(find.byType(WizPowerKey)),
      'WizDial': _inSection<GalleryDials>(find.byType(WizDial)),
      'WizSlider': _inSection<GalleryDials>(find.byType(WizSlider)),
      'WizReadout': _inSection<GalleryDials>(find.byType(WizReadout)),
      'WizPanel': _inSection<GalleryDials>(find.byType(WizPanel)),
      'WizColorWheel': _inSection<GalleryWheel>(find.byType(WizColorWheel)),
      'WizSegmentedControl': _inSection<GalleryScenes>(
        _byGeneric<WizSegmentedControl<Object?>>('WizSegmentedControl'),
      ),
      'WizSceneTile': _inSection<GalleryScenes>(find.byType(WizSceneTile)),
      // `WizSceneArt` has no standalone demo: it is the painter behind the
      // tiles and the mode row, which is how spec §11.2 describes it.
      'WizSceneArt': _inSection<GalleryScenes>(find.byType(WizSceneArt)),
      'WizGrid': _inSection<GalleryScenes>(find.byType(WizGrid)),
      'ModeRow': _inSection<GalleryScenes>(find.byType(ModeRow)),
      'WizTabBar': _inSection<GalleryNavigation>(
        _byGeneric<WizTabBar<Object?>>('WizTabBar'),
      ),
      'WizRail': _inSection<GalleryNavigation>(
        _byGeneric<WizRail<Object?>>('WizRail'),
      ),
      'WizListRow': _inSection<GalleryRows>(find.byType(WizListRow)),
      'WizBadge': _inSection<GalleryRows>(find.byType(WizBadge)),
      'WizStatTile': _inSection<GalleryRows>(find.byType(WizStatTile)),
      'RoomCard': _inSection<GalleryRows>(find.byType(RoomCard)),
      'LightCard': _inSection<GalleryRows>(find.byType(LightCard)),
      'FixtureHero': _inSection<GalleryHero>(find.byType(FixtureHero)),
      'Breathe': _inSection<GalleryHero>(find.byType(Breathe)),
      'WizFilamentBar': _inSection<GalleryStates>(find.byType(WizFilamentBar)),
      // Keyed, not scoped to the section: `WizStatusBanner` and `WizToast`
      // build their own spinner for the loading tone, so a section-wide
      // finder would keep passing after the demo itself was deleted.
      'WizSpinner': find.descendant(
        of: find.byKey(GalleryStates.spinnerRow),
        matching: find.byType(WizSpinner),
      ),
      'WizSkeleton': _inSection<GalleryStates>(find.byType(WizSkeleton)),
      'WizStatusBanner': _inSection<GalleryStates>(
        find.byType(WizStatusBanner),
      ),
      'WizToast': _inSection<GalleryStates>(find.byType(WizToast)),
      'WizEmptyState': _inSection<GalleryStates>(find.byType(WizEmptyState)),
      'WizTextField': _inSection<GalleryFields>(find.byType(WizTextField)),
      // These four have no section of their own: the header and the load-in
      // belong to the screen, and the toast stack to `WizCtlApp`.
      'WizTopBar': find.byType(WizTopBar),
      'RiseIn': find.byType(RiseIn),
      'WizToastLayer': find.byType(WizToastLayer),
      // Never built directly by anything: `WizSurface` is what every panel,
      // key and card is made of, and `WizPressable` is the one press recipe
      // under all of them (spec §11.2). Present is all there is to check.
      'WizSurface': find.byType(WizSurface),
      'WizPressable': find.byType(WizPressable),
    };

    for (var entry in kit.entries) {
      expect(
        entry.value,
        findsWidgets,
        reason: 'no ${entry.key} in the gallery',
      );
    }
  });

  test('every kit widget file is accounted for in the coverage map', () {
    // `flutter test` runs from the package root, as `test/assets/
    // fonts_test.dart` already relies on.
    var files = Directory('lib/core/widgets')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    expect(
      files.length,
      _kitWidgetFiles,
      reason:
          'adding a widget file: add its demo to the gallery, its entry to '
          'the map above, and bump this count',
    );
  });

  testWidgets('the toast stack goes bottom-right on a desktop window', (
    tester,
  ) async {
    await _pumpGallery(tester, size: _desktopWindow);

    // The branch in `WizCtlApp` that picks the placement by width class.
    var layer = tester.widget<WizToastLayer>(find.byType(WizToastLayer));
    expect(layer.placement, WizToastPlacement.bottomRight);

    // And what that placement actually lays out: a fixed 340-wide column
    // pinned to the right edge, not stretched between both (spec §10.9).
    var box = tester.widget<Positioned>(
      find.descendant(
        of: find.byType(WizToastLayer),
        matching: find.byType(Positioned),
      ),
    );
    expect(box.width, WizToastLayer.desktopWidth);
    expect(box.left, isNull);
  });

  testWidgets('the toast stack sits above the tab bar on a phone', (
    tester,
  ) async {
    await _pumpGallery(tester);

    var layer = tester.widget<WizToastLayer>(find.byType(WizToastLayer));
    expect(layer.placement, WizToastPlacement.aboveTabBar);
  });

  testWidgets('the Feedback section has one key per FeedbackKind', (
    tester,
  ) async {
    await _pumpGallery(tester);

    expect(
      find.descendant(
        of: find.byType(GalleryFeedback),
        matching: find.byType(WizButton),
      ),
      findsNWidgets(FeedbackKind.values.length),
    );
  });

  testWidgets('the rail carries the wordmark and the mode row opens a sheet', (
    tester,
  ) async {
    await _pumpGallery(tester);

    expect(find.text(GalleryWordmark.wordmark), findsOneWidget);

    // `WizSheet` is a route, not a widget in the tree, so it can only be
    // covered by opening it.
    expect(find.byType(WizSheetRoute), findsNothing);
    await tester.tap(find.byType(ModeRow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WizSheetRoute), findsOneWidget);
  });

  testWidgets('a toast pushed from the gallery reaches the app-level layer', (
    tester,
  ) async {
    await _pumpGallery(tester);

    var before = find.byType(WizToast).evaluate().length;
    await tester.tap(find.widgetWithText(WizButton, 'SUCCESS TOAST'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The layer lives on `WizCtlApp`, not on the screen, so the toast the
    // gallery pushed has to surface through the app's own stack.
    expect(
      find.descendant(
        of: find.byType(WizToastLayer),
        matching: find.byType(WizToast),
      ),
      findsOneWidget,
    );
    expect(find.byType(WizToast), findsNWidgets(before + 1));

    // Let the 3.2 s auto-dismiss clock run out rather than leaving it armed.
    await tester.pump(ToastController.defaultDuration);
    await tester.pump(const Duration(milliseconds: 300));
  });
}
