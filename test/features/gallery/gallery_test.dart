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
import 'package:wizctl_app/features/gallery/gallery_feedback.dart';
import 'package:wizctl_app/features/gallery/gallery_section.dart';

/// A phone-wide surface tall enough that the gallery's `ListView.builder`
/// builds every section: a lazy list only builds what is near the viewport,
/// and a missing widget below the fold reads exactly like one that was never
/// added.
const Size _wholeGallery = Size(390, 12000);

/// Long enough to drain every `RiseIn` stagger timer (one per section, 55 ms
/// apart) and settle the entrances.
const Duration _settled = Duration(milliseconds: 1500);

/// `byType` compares runtime types exactly, so a generic widget built as
/// `WizTabBar<SomeEnum>` never matches the bare `WizTabBar` type literal.
/// A subtype test does match, because Dart's generics are covariant.
Finder _byGeneric<T>(String name) =>
    find.byWidgetPredicate((w) => w is T, description: name);

void main() {
  testWidgets('the gallery shows one of every kit widget', (tester) async {
    tester.view.physicalSize = _wholeGallery;
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
    // The gallery loops for ever, so `pumpAndSettle` would time out.
    await tester.pump(_settled);

    // Spec §11.2's kit, one entry per widget. A widget added to `core/widgets`
    // without a demo here fails this test rather than quietly missing from
    // the screen the design is reviewed on.
    var kit = <String, Finder>{
      'WizButton': find.byType(WizButton),
      'WizChip': find.byType(WizChip),
      'WizIconKey': find.byType(WizIconKey),
      'WizToggle': find.byType(WizToggle),
      'WizPowerKey': find.byType(WizPowerKey),
      'WizDial': find.byType(WizDial),
      'WizSlider': find.byType(WizSlider),
      'WizColorWheel': find.byType(WizColorWheel),
      'WizSceneTile': find.byType(WizSceneTile),
      'WizSceneArt': find.byType(WizSceneArt),
      'WizSegmentedControl': _byGeneric<WizSegmentedControl<Object?>>(
        'WizSegmentedControl',
      ),
      'WizTabBar': _byGeneric<WizTabBar<Object?>>('WizTabBar'),
      'WizRail': _byGeneric<WizRail<Object?>>('WizRail'),
      'WizTopBar': find.byType(WizTopBar),
      'WizListRow': find.byType(WizListRow),
      'WizBadge': find.byType(WizBadge),
      'WizStatTile': find.byType(WizStatTile),
      'WizReadout': find.byType(WizReadout),
      'WizEmptyState': find.byType(WizEmptyState),
      'WizFilamentBar': find.byType(WizFilamentBar),
      'WizSkeleton': find.byType(WizSkeleton),
      'WizSpinner': find.byType(WizSpinner),
      'WizStatusBanner': find.byType(WizStatusBanner),
      'WizToast': find.byType(WizToast),
      'WizToastLayer': find.byType(WizToastLayer),
      'WizTextField': find.byType(WizTextField),
      'WizPanel': find.byType(WizPanel),
      'WizSurface': find.byType(WizSurface),
      'WizPressable': find.byType(WizPressable),
      'WizGrid': find.byType(WizGrid),
      'RoomCard': find.byType(RoomCard),
      'LightCard': find.byType(LightCard),
      'FixtureHero': find.byType(FixtureHero),
      'ModeRow': find.byType(ModeRow),
      // The motion helpers, applied where they belong: the sections stagger
      // in, and the lit emission readout breathes.
      'RiseIn': find.byType(RiseIn),
      'Breathe': find.byType(Breathe),
    };

    for (var entry in kit.entries) {
      expect(
        entry.value,
        findsWidgets,
        reason: 'no ${entry.key} in the gallery',
      );
    }
  });

  testWidgets('the Feedback section has one key per FeedbackKind', (
    tester,
  ) async {
    tester.view.physicalSize = _wholeGallery;
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
    await tester.pump(_settled);

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
    tester.view.physicalSize = _wholeGallery;
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
    await tester.pump(_settled);

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
    tester.view.physicalSize = _wholeGallery;
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
    await tester.pump(_settled);

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
