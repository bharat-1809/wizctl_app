import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';
import 'package:wizctl_app/core/widgets/wiz_toast.dart';
import 'package:wizctl_app/core/widgets/wiz_toast_layer.dart';

import '../../support/wiz_test_app.dart';

/// The stack the layer positions its toasts in.
Positioned _frame(WidgetTester tester) => tester.widget<Positioned>(
  find
      .descendant(
        of: find.byType(WizToastLayer),
        matching: find.byType(Positioned),
      )
      .first,
);

Widget _host(
  ToastController c, {
  WizToastPlacement placement = WizToastPlacement.aboveTabBar,
  double bottomInset = 0,
}) => wizTestApp(
  SizedBox(
    width: 390,
    height: 600,
    child: Stack(
      children: [
        WizToastLayer(
          controller: c,
          placement: placement,
          bottomInset: bottomInset,
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('the layer renders the controller queue and dismisses', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var c = ToastController();
    await tester.pumpWidget(_host(c));
    c.push(
      tone: WizToastTone.success,
      title: 'Cozy applied',
      body: 'to the whole home',
    );
    await tester.pumpAndSettle();
    expect(find.text('Cozy applied'), findsOneWidget);
    expect(find.text('to the whole home'), findsOneWidget);
    expect(find.byType(WizToast), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.byType(WizToast), findsNothing);
    handle.dispose();
    c.dispose();
  });

  testWidgets('the live region is the node that carries the words', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    var c = ToastController();
    await tester.pumpWidget(_host(c));
    c.push(
      tone: WizToastTone.info,
      title: 'Room saved',
      body: 'Kitchen is empty',
    );
    await tester.pumpAndSettle();
    // The flag on its own announces nothing: the node carrying it has to be
    // the one holding the copy, or a screen reader reads out an empty
    // region. Title and body merge into it; the keys stay outside.
    expect(
      tester.getSemantics(find.text('Room saved')),
      isSemantics(isLiveRegion: true, label: 'Room saved\nKitchen is empty'),
    );
    expect(find.semantics.byLabel('Room saved\nKitchen is empty'), findsOne);
    handle.dispose();
    c.dispose();
  });

  testWidgets('a toast with no keys still announces itself once', (
    tester,
  ) async {
    var handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wizTestApp(
        const SizedBox(
          width: 350,
          child: WizToast(
            data: WizToastData(
              id: 't0',
              tone: WizToastTone.success,
              title: 'Cozy applied',
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Cozy applied')),
      isSemantics(isLiveRegion: true, label: 'Cozy applied'),
    );
    expect(find.semantics.byLabel('Cozy applied'), findsOne);
    handle.dispose();
  });

  testWidgets('an action key fires the toast action', (tester) async {
    var handle = tester.ensureSemantics();
    var retries = 0;
    var c = ToastController();
    await tester.pumpWidget(_host(c));
    c.push(
      tone: WizToastTone.error,
      title: 'No response after 3 tries',
      body: '192.168.1.24 did not answer on port 38899',
      actionLabel: 'Retry',
      onAction: () => retries++,
    );
    await tester.pumpAndSettle();
    // A key inside the live region stays its own node rather than merging
    // into it, named exactly as the caller labelled it.
    expect(find.bySemanticsLabel('Retry'), findsOneWidget);
    await tester.tap(find.byType(WizButton));
    await tester.pumpAndSettle();
    expect(retries, 1);
    handle.dispose();
    c.dispose();
  });

  testWidgets('a loading toast spins, stays, and says nothing', (tester) async {
    var feedback = RecordingFeedbackService();
    var c = ToastController(feedback: feedback);
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 390,
          height: 600,
          child: Stack(
            children: [
              WizToastLayer(
                controller: c,
                placement: WizToastPlacement.aboveTabBar,
              ),
            ],
          ),
        ),
        feedback: feedback,
      ),
    );
    var id = c.push(tone: WizToastTone.loading, title: 'Sending to Hallway');
    // Bounded pumps only: the spinner never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WizSpinner), findsOneWidget);
    expect(feedback.played, isEmpty);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(WizToast), findsOneWidget);

    c.update(id, tone: WizToastTone.success, title: 'Sent');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WizSpinner), findsNothing);
    expect(feedback.played, [FeedbackKind.confirm]);
    expect(
      tester.widgetList<WizIcon>(find.byType(WizIcon)).map((i) => i.icon),
      contains(WizIcons.check),
    );
    c.dispose();
  });

  testWidgets('every resolved tone draws its own glyph', (tester) async {
    var c = WizColors.standard;
    var expected = <WizToastTone, (WizIconData, Color)>{
      WizToastTone.success: (WizIcons.check, c.signalOnline),
      WizToastTone.error: (WizIcons.x, c.signalDanger),
      WizToastTone.info: (WizIcons.zap, c.textSecondary),
    };
    for (var entry in expected.entries) {
      await tester.pumpWidget(
        wizTestApp(
          SizedBox(
            width: 350,
            child: WizToast(
              data: WizToastData(
                id: 't0',
                tone: entry.key,
                title: entry.key.name,
              ),
            ),
          ),
        ),
      );
      var icon = tester.widget<WizIcon>(find.byType(WizIcon));
      expect(icon.icon, entry.value.$1, reason: '${entry.key} glyph');
      expect(icon.color, entry.value.$2, reason: '${entry.key} colour');
      expect(icon.size, WizToast.glyph);
    }
  });

  testWidgets('reduced motion lands a toast in place on the first frame', (
    tester,
  ) async {
    var moving = ToastController();
    await tester.pumpWidget(_host(moving));
    moving.push(tone: WizToastTone.success, title: 'Cozy applied');
    await tester.pumpAndSettle();
    var settled = tester.getRect(find.byType(WizToast));

    var still = ToastController();
    await tester.pumpWidget(
      wizTestApp(
        reducedMotion(
          SizedBox(
            width: 390,
            height: 600,
            child: Stack(
              children: [
                WizToastLayer(
                  controller: still,
                  placement: WizToastPlacement.aboveTabBar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    still.push(tone: WizToastTone.success, title: 'Cozy applied');
    // One frame only: with animations off there is no entrance left to play,
    // so the toast is already where the moving one ends up.
    await tester.pump();
    expect(tester.getRect(find.byType(WizToast)), settled);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(WizToast),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
    moving.dispose();
    still.dispose();
  });

  testWidgets('the queue stacks newest above oldest, above the tab bar', (
    tester,
  ) async {
    var space = WizSpace.standard;
    var c = ToastController();
    await tester.pumpWidget(_host(c, bottomInset: 34));
    c.push(tone: WizToastTone.info, title: 'first');
    c.push(tone: WizToastTone.info, title: 'second');
    await tester.pumpAndSettle();

    var frame = _frame(tester);
    expect(frame.left, space.s6);
    expect(frame.right, space.s6);
    expect(frame.bottom, space.tabBar + space.tabBarFloat + 34);
    expect(frame.width, isNull);
    expect(
      tester.getTopLeft(find.text('second')).dy,
      lessThan(tester.getTopLeft(find.text('first')).dy),
      reason: 'the newest toast rises above the ones already up',
    );
    c.dispose();
  });

  testWidgets('on desktop the stack is a fixed width in the bottom corner', (
    tester,
  ) async {
    var space = WizSpace.standard;
    var c = ToastController();
    await tester.pumpWidget(_host(c, placement: WizToastPlacement.bottomRight));
    c.push(tone: WizToastTone.success, title: 'Saved');
    await tester.pumpAndSettle();

    var frame = _frame(tester);
    expect(frame.left, isNull);
    expect(frame.right, space.s8);
    expect(frame.bottom, space.s8);
    expect(frame.width, WizToastLayer.desktopWidth);
    c.dispose();
  });
  testWidgets('a toast rises in on the panel duration and the settle curve', (
    tester,
  ) async {
    var c = ToastController();
    await tester.pumpWidget(_host(c));
    c.push(tone: WizToastTone.success, title: 'Cozy applied');
    await tester.pump();

    // The entrance is the builder wrapped round the toast; the keys inside
    // it run presses of their own on other tokens.
    var enter = tester.widget<TweenAnimationBuilder<double>>(
      find
          .ancestor(
            of: find.byType(WizToast),
            matching: find.byType(TweenAnimationBuilder<double>),
          )
          .first,
    );
    expect(enter.duration, WizMotion.standard.panel);
    expect(enter.curve, WizMotion.standard.settle);

    await tester.pumpAndSettle();
    c.dispose();
  });
}
