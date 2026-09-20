import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/navigation.dart';
import 'package:wizctl_app/app/routes.dart';

import '../support/router_harness.dart';

/// A page whose only control is a Back that calls [popOr].
class _BackPage extends StatelessWidget {
  const _BackPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => popOr(context, AppRoutes.rooms),
        child: const Text('back'),
      ),
    ),
  );
}

void main() {
  testWidgets('a pushed screen pops back to what pushed it', (tester) async {
    var router = await pumpRouted(
      tester,
      const _BackPage(),
      targets: [AppRoutes.rooms],
    );
    // The same page pushed on top of itself: `pumpRouted` builds one screen
    // of its own, and what matters here is that there is something under the
    // one being popped, not what it is.
    router.push('/');
    await tester.pumpAndSettle();
    // `skipOffstage: false`: the page a pushed one covers is still built,
    // but the overlay keeps it off stage and a plain finder skips it.
    expect(find.byType(_BackPage, skipOffstage: false), findsNWidgets(2));

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.byType(_BackPage, skipOffstage: false), findsOneWidget);
    expect(
      currentLocation(router),
      '/',
      reason: 'it popped rather than going to the fallback',
    );
  });

  testWidgets('at a root it goes to the fallback instead', (tester) async {
    var router = await pumpRouted(
      tester,
      const _BackPage(),
      targets: [AppRoutes.rooms],
    );
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.rooms);
  });

  test("a light's parent is its room, or home when it has none", () {
    expect(lightParent('living'), AppRoutes.room('living'));
    expect(
      lightParent(null),
      AppRoutes.home,
      reason: 'an id that names no light has no room to go back to either',
    );
  });
}
