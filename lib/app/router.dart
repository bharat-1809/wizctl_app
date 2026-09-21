import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/wiz_motion.dart';
import 'blocs/homes_bloc.dart';
import 'router_pages.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

/// Wakes the router the moment the first home is written or the last one
/// deleted, so the `/setup` redirect re-evaluates.
///
/// Only that — not every homes emission. A refresh re-parses the current
/// location, which is work on every count, rename and switch, and on a pushed
/// screen it re-runs the whole match list. Nothing else the redirect reads
/// changes with a home's name or counts, and the pages that follow the active
/// home watch the bloc themselves (`AppPages`).
///
/// Owned by whoever builds the router (`WizCtlApp`) and disposed beside it:
/// `GoRouter.dispose` leaves a `refreshListenable` it was handed alone.
class HomesListenable extends ChangeNotifier {
  late final StreamSubscription<bool> _subscription;

  HomesListenable(HomesBloc homes) {
    // Seeded with what the bloc already says, rather than `Stream.distinct()`,
    // which always lets the first event through: the router was built from
    // that same state, so an emission that repeats it is not a change.
    var hasHome = homes.state.hasHome;
    _subscription = homes.stream.map((s) => s.hasHome).listen((next) {
      if (next == hasHome) return;
      hasHome = next;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// The routes of spec §9: `/setup` outside the shell, one stateful shell with
/// five branches (the four tabs and discovery), and the debug gallery.
///
/// The shell's builder picks the phone or the desktop chrome by width, so a
/// resize keeps the route and its blocs.
///
/// A light lives in the Rooms branch rather than at the root, so opening one
/// from a room keeps the tab bar and Back pops to the room it came from.
GoRouter buildRouter({
  required HomesBloc homes,
  required HomesListenable listenable,
  required WizMotion motion,
  required AppPages pages,
  GlobalKey<NavigatorState>? rootNavigatorKey,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: homes.state.hasHome ? AppRoutes.home : AppRoutes.setup,
    refreshListenable: listenable,
    // The home is read off the bloc rather than the state's `extra`: the
    // redirect runs on every navigation, and on every appearance or loss of a
    // home through the listenable above, and the bloc is the one place that
    // knows whether a home exists at all.
    redirect: (context, state) {
      var hasHome = homes.state.hasHome;
      var location = state.matchedLocation;
      // The gallery is a developer tool rather than a place in the app, and it
      // needs no home, so the first run does not stand in front of it.
      if (kDebugMode && location == AppRoutes.gallery) return null;
      if (!hasHome && location != AppRoutes.setup) return AppRoutes.setup;
      if (hasHome && location == AppRoutes.setup) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.setup, pageBuilder: pages.setup),
      // Debug only, and pushed over whatever is on show (spec §18): the
      // gallery is a developer tool, not a place in the app.
      if (kDebugMode)
        GoRoute(path: AppRoutes.gallery, pageBuilder: pages.gallery),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, pageBuilder: pages.home)],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rooms,
                pageBuilder: pages.rooms,
                routes: [
                  GoRoute(
                    path: ':${AppRoutes.roomParam}',
                    pageBuilder: pages.room,
                  ),
                ],
              ),
              GoRoute(path: AppRoutes.lightPattern, pageBuilder: pages.light),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.modes, pageBuilder: pages.modes)],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.settings, pageBuilder: pages.settings),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.discover, pageBuilder: pages.discover),
            ],
          ),
        ],
      ),
    ],
  );
}
