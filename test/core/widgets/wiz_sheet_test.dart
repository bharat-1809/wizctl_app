import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet.dart';

import '../../support/wiz_test_app.dart';

const Key _sheet = Key('wiz-sheet');
const Key _handle = Key('wiz-sheet-handle');

/// Spec §11.2, "max height 86 %", against the 844-tall test surface.
const double _cap = 844 * 0.86;

Widget _shortBody(BuildContext context) => const Text('Body');

Widget opener({
  double? maxWidth,
  bool scrollable = true,
  WidgetBuilder body = _shortBody,
  ValueChanged<String?>? onClosed,
}) => Builder(
  builder: (context) {
    return TextButton(
      onPressed: () {
        var closed = showWizSheet<String>(
          context,
          title: 'Add a room',
          builder: body,
          footer: const [Text('Cancel')],
          maxWidth: maxWidth,
          scrollable: scrollable,
        );
        if (onClosed != null) closed.then(onClosed);
      },
      child: const Text('open'),
    );
  },
);

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The sheet's own scroll view, or the viewport the body brought with it.
ScrollableState scroller(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable));

void main() {
  testWidgets('compact widths get a bottom sheet with a grab handle', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    expect(find.text('Add a room'), findsOneWidget);
    expect(find.byKey(_handle), findsOneWidget);
    var sheet = tester.getRect(find.byKey(_sheet));
    expect(sheet.bottom, 844);
    expect(sheet.width, 390);
    // A one-line body is nowhere near the cap: the sheet wraps it.
    expect(sheet.height, lessThan(_cap / 2));
  });

  testWidgets('expanded widths get a centred dialog', (tester) async {
    await setSurface(tester, const Size(1280, 800));
    await tester.pumpWidget(wizTestApp(opener(), size: const Size(1280, 800)));
    await open(tester);
    expect(find.byKey(_handle), findsNothing);
    var sheet = tester.getRect(find.byKey(_sheet));
    expect(sheet.width, 520);
    expect(sheet.center.dx, closeTo(640, 1));
    expect(sheet.center.dy, closeTo(400, 1));
  });

  testWidgets('maxWidth widens the dialog past the 520 default', (
    tester,
  ) async {
    await setSurface(tester, const Size(1280, 800));
    await tester.pumpWidget(
      wizTestApp(opener(maxWidth: 680), size: const Size(1280, 800)),
    );
    await open(tester);
    expect(tester.getRect(find.byKey(_sheet)).width, 680);
  });

  testWidgets('a tall body fills the sheet to its 86 % cap and scrolls', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(
      wizTestApp(opener(body: (_) => const SizedBox(height: 2000))),
    );
    await open(tester);
    var sheet = tester.getRect(find.byKey(_sheet));
    expect(sheet.height, closeTo(_cap, 1));
    expect(sheet.bottom, 844);

    // The body gives, not the sheet: a drag inside it scrolls and leaves the
    // sheet exactly where it was.
    expect(scroller(tester).position.pixels, 0);
    await tester.dragFrom(const Offset(195, 700), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scroller(tester).position.pixels, greaterThan(0));
    expect(tester.getRect(find.byKey(_sheet)), sheet);
  });

  testWidgets('scrollable: false hands a viewport body the bounded height', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(
      wizTestApp(
        opener(
          scrollable: false,
          body: (_) =>
              ListView(children: [for (var i = 0; i < 50; i++) Text('row $i')]),
        ),
      ),
    );
    await open(tester);
    // Wrapping a ListView in the sheet's own scroll view would hand it an
    // unbounded height and throw.
    expect(tester.takeException(), isNull);
    var sheet = tester.getRect(find.byKey(_sheet));
    expect(sheet.height, closeTo(_cap, 1));

    await tester.dragFrom(const Offset(195, 700), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scroller(tester).position.pixels, greaterThan(0));
    expect(tester.getRect(find.byKey(_sheet)), sheet);
  });

  testWidgets('tapping the scrim closes', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
  });

  testWidgets('tapping the sheet itself does not close it', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    // Inside the sheet's box but outside its 28 radius, so the surface's own
    // decoration does not answer the hit test: the sheet has to stop the
    // pointer itself rather than let it fall through to the scrim.
    await tester.tapAt(
      tester.getRect(find.byKey(_sheet)).topLeft + const Offset(2, 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);
  });

  testWidgets('escape closes and completes the future with null', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    // A sentinel, so `isNull` proves the future completed rather than that it
    // never resolved.
    String? result = 'unset';
    await tester.pumpWidget(wizTestApp(opener(onClosed: (v) => result = v)));
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
    expect(result, isNull);
  });

  testWidgets('popping from the body completes the future with its result', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    String? result = 'unset';
    await tester.pumpWidget(
      wizTestApp(
        opener(
          onClosed: (v) => result = v,
          body: (context) => TextButton(
            onPressed: () => Navigator.of(context).pop('ok'),
            child: const Text('save'),
          ),
        ),
      ),
    );
    await open(tester);
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
    expect(result, 'ok');
  });

  testWidgets("a drag past a share of the sheet's own height dismisses it", (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    // A one-line sheet is a fraction of the 86 % cap, so this only dismisses
    // if the threshold is measured against the sheet, not against the window.
    var height = tester.getRect(find.byKey(_sheet)).height;
    await tester.drag(find.byKey(_handle), Offset(0, height * 0.5));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
  });

  testWidgets('a short drag springs the sheet back', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    var settled = tester.getRect(find.byKey(_sheet));
    await tester.drag(find.byKey(_handle), Offset(0, settled.height * 0.2));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);
    expect(tester.getRect(find.byKey(_sheet)), settled);
  });

  testWidgets('a flick dismisses from a drag too short to count', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(
      wizTestApp(opener(body: (_) => const SizedBox(height: 2000))),
    );
    await open(tester);
    // A sheet at the full 86 %: 60 px is nowhere near `dismissFraction` of it,
    // so the same 60 px taken slowly springs back and the flick below is
    // carried by its speed alone.
    await tester.drag(find.byKey(_handle), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);

    await tester.fling(find.byKey(_handle), const Offset(0, 60), 1600);
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
  });

  testWidgets('the home indicator pads the sheet and the keyboard lifts it', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    var plain = tester.getRect(find.byKey(_sheet));
    expect(plain.bottom, 844);

    // A home indicator: the sheet still runs to the bottom edge, and grows by
    // the inset so its content clears it.
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpAndSettle();
    var padded = tester.getRect(find.byKey(_sheet));
    expect(padded.bottom, 844);
    expect(padded.height, closeTo(plain.height + 34, 0.01));

    // The software keyboard: the sheet lifts clear of it, and `padding` no
    // longer carries an indicator the keyboard is covering, so the two never
    // pad the sheet twice over.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = FakeViewPadding.zero;
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    var lifted = tester.getRect(find.byKey(_sheet));
    expect(lifted.bottom, 844 - 300);
    expect(lifted.height, closeTo(plain.height, 0.01));
    // The cap follows whatever the keyboard leaves of the window.
    expect(lifted.height, lessThanOrEqualTo((844 - 300) * 0.86));
  });

  testWidgets('the sheet names and scopes its route', (tester) async {
    var semantics = tester.ensureSemantics();
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    // Exactly one node carries the name: the title inside merges into the
    // sheet's content node, so this is the route scope itself.
    var named = find.bySemanticsLabel('Add a room');
    expect(named, findsOneWidget);
    expect(
      tester.getSemantics(named),
      isSemantics(label: 'Add a room', scopesRoute: true, namesRoute: true),
    );
    // The dismiss affordance is the route's own barrier and nothing else: the
    // scrim painted over it answers taps but publishes no second, unlabelled
    // full-screen tap target of its own.
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(BackdropFilter)),
      isSemantics(hasTapAction: false),
    );
    semantics.dispose();
  });

  testWidgets('reduced motion puts the sheet in place on the first frame', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(wizTestApp(opener()));
    await tester.tap(find.text('open'));
    await tester.pump();
    // First frame of the transition: the rise has not played, so the sheet is
    // still below where it comes to rest.
    expect(tester.getRect(find.byKey(_sheet)).bottom, greaterThan(844));

    await tester.pumpWidget(
      MediaQuery(
        // The platform's "reduce motion" switch, above the app so the route
        // inherits it too.
        data: const MediaQueryData(disableAnimations: true),
        child: wizTestApp(opener()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(tester.getRect(find.byKey(_sheet)).bottom, 844);
  });
}
