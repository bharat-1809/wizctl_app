import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl_app/app/router.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';

import 'app_scope.dart';
import 'wiz_test_app.dart';

/// Pumps [home] at `/` inside a `GoRouter` whose other locations are
/// [targets], each showing its own path as text, and returns the router so
/// a test can read where a tap went:
/// `router.routerDelegate.currentConfiguration.uri.toString()`.
///
/// [wrap] installs providers around the whole app (blocs, a toast
/// controller).
///
/// [size] is the *surface*, not only the MediaQuery: a screen reads its width
/// class off the constraints `WizLayoutScope` measures, so a MediaQuery alone
/// would lay the phone's screens out at the tester's 800×600 default — which
/// is a medium width, with the desktop gutter and twice the grid columns.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget home, {
  List<String> targets = const [],
  Size size = const Size(390, 844),
  FeedbackService? feedback,
  Widget Function(Widget child)? wrap,
}) async {
  await setSurface(tester, size);
  var router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      for (var t in targets)
        GoRoute(
          path: t,
          builder: (context, state) => Scaffold(
            body: Text(state.uri.toString(), key: const Key('routed-to')),
          ),
        ),
    ],
  );
  addTearDown(router.dispose);
  Widget app = FeedbackScope(
    service: feedback ?? RecordingFeedbackService(),
    child: MaterialApp.router(
      theme: buildWizThemeData(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: WizLayoutScope(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  if (wrap != null) app = wrap(app);
  await tester.pumpWidget(app);
  return router;
}

/// Pumps the app's own router (Task 19) over [scope]'s fakes and providers, on
/// a phone surface unless [size] says otherwise, and returns it so a test can
/// drive it and read where it went.
///
/// Not `WizCtlApp`: this is the router, the shell and the route pages over the
/// fixture's blocs, without the bootstrap graph. The homes listenable the
/// router refreshes on is built and torn down here, as the app root does.
///
/// The caller still disposes [scope] inside its own test body — the active
/// home arms a poll timer, which must be cancelled before the tester looks for
/// pending timers.
Future<GoRouter> pumpAppRouter(
  WidgetTester tester,
  AppScope scope, {
  Size size = const Size(390, 844),
}) async {
  await setSurface(tester, size);
  var listenable = HomesListenable(scope.homes);
  addTearDown(listenable.dispose);
  var router = buildRouter(
    homes: scope.homes,
    listenable: listenable,
    motion: scope.motion,
    pages: scope.pages,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    scope.wrap(
      FeedbackScope(
        service: scope.feedback,
        child: MaterialApp.router(
          theme: buildWizThemeData(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: WizLayoutScope(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    ),
  );
  return router;
}

/// Where the router is now, counting a pushed page as where it is.
///
/// A `context.push` appends an [ImperativeRouteMatch] and leaves the match
/// list's own `uri` on the location that was showing before, so the plain
/// `uri` reports a push as if nothing had happened. The pushed location is the
/// uri of the imperative match's own list.
String currentLocation(GoRouter router) {
  var list = router.routerDelegate.currentConfiguration;
  return _pushedIn(list.matches) ?? list.uri.toString();
}

/// The location of the last pushed match in [matches], or null if the top of
/// that list was reached by a `go`.
///
/// It looks inside a shell, because a push from a screen in a
/// `StatefulShellRoute` branch lands in *that branch's* match list: the top
/// level then holds nothing but the [ShellRouteMatch], whose own uri is still
/// the branch's location. A light pushed over its room is exactly that case.
String? _pushedIn(List<RouteMatchBase> matches) {
  var last = matches.lastOrNull;
  if (last is ImperativeRouteMatch) return last.matches.uri.toString();
  if (last is ShellRouteMatch) return _pushedIn(last.matches);
  return null;
}
