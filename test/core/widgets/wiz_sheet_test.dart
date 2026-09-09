import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet.dart';

import '../../support/wiz_test_app.dart';

const Key _sheet = Key('wiz-sheet');
const Key _handle = Key('wiz-sheet-handle');

Widget opener({double? maxWidth, ValueChanged<String?>? onClosed}) => Builder(
  builder: (context) {
    return TextButton(
      onPressed: () {
        var closed = showWizSheet<String>(
          context,
          title: 'Add a room',
          builder: (_) => const Text('Body'),
          footer: const [Text('Cancel')],
          maxWidth: maxWidth,
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
    // Spec §11.2, "max height 86 %".
    expect(sheet.height, lessThanOrEqualTo(844 * 0.86));
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

  testWidgets('dragging the sheet down far enough dismisses it', (
    tester,
  ) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    await tester.drag(find.byKey(_handle), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
  });

  testWidgets('a short drag springs the sheet back', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    var settled = tester.getRect(find.byKey(_sheet));
    await tester.drag(find.byKey(_handle), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);
    expect(tester.getRect(find.byKey(_sheet)), settled);
  });

  testWidgets('a flick dismisses even from a short drag', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await open(tester);
    await tester.fling(find.byKey(_handle), const Offset(0, 60), 1600);
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
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
