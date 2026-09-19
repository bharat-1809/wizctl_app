import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';

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

/// Where the router is now.
String currentLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();
