import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/wiz_fade_page.dart';
import '../core/theme/wiz_motion.dart';
import '../domain/entities/entities.dart';
import '../features/discovery/bloc/discovery_bloc.dart';
import '../features/discovery/view/discovery_screen.dart';
import '../features/discovery/widgets/discovery_notice_listener.dart';
import '../features/home/bloc/home_screen_bloc.dart';
import '../features/home/bloc/home_screen_event.dart';
import '../features/home/view/home_page.dart';
import '../features/lights/bloc/light_bloc.dart';
import '../features/lights/bloc/light_event.dart';
import '../features/lights/view/light_screen.dart';
import '../features/lights/widgets/light_notice_listener.dart';
import '../features/modes/bloc/light_modes_event.dart';
import '../features/modes/modes_bloc_factory.dart';
import '../features/modes/view/modes_screen.dart';
import '../features/modes/widgets/modes_notice_listener.dart';
import '../features/onboarding/bloc/onboarding_bloc.dart';
import '../features/onboarding/view/onboarding_screen.dart';
import '../features/onboarding/widgets/onboarding_notice_listener.dart';
import '../features/rooms/bloc/room_bloc.dart';
import '../features/rooms/bloc/room_event.dart';
import '../features/rooms/bloc/rooms_list_bloc.dart';
import '../features/rooms/bloc/rooms_list_event.dart';
import '../features/rooms/view/room_page.dart';
import '../features/rooms/view/rooms_screen.dart';
import '../features/rooms/widgets/rooms_notice_listener.dart';
import '../features/settings/view/settings_screen.dart';
import 'blocs/homes_bloc.dart';
import 'gallery_page.dart';
import 'routes.dart';
import 'shell_deps.dart';

/// Builds each route's page: a fade transition around the screen, with the
/// screen's bloc created in that page's own subtree and closed with it
/// (spec §8, route-scoped blocs are created in route builders and closed on
/// pop).
///
/// Every bloc is created lazily *inside* the page — never handed in — for two
/// reasons. A bloc that outlived its route would keep its poll scope and its
/// repository watches after the screen had gone; and a screen whose subject
/// is already gone when it mounts (an id that names nothing) has to see that
/// first state, which only happens if its listener is subscribed before the
/// bloc emits.
class AppPages {
  final ShellDeps deps;
  final ModesBlocFactory modesBlocFor;
  final WizMotion motion;

  AppPages({
    required this.deps,
    required this.modesBlocFor,
    required this.motion,
  });

  /// The 300 ms opacity fade of spec §9, around the one `Scaffold` every
  /// screen needs: the kit's screens are bodies, not scaffolds, and a text
  /// field or a sheet inside one needs the `Material` a `Scaffold` carries.
  /// Transparent, because `WizAppBackground` paints the chassis above the
  /// router and a coloured scaffold would hide it.
  ///
  /// [scaffold] is false for the one screen that builds its own, so that no
  /// page ends up with two.
  Page<void> _fade(GoRouterState state, Widget child, {bool scaffold = true}) =>
      wizFadePage<void>(
        key: state.pageKey,
        motion: motion,
        child: scaffold
            ? Scaffold(backgroundColor: Colors.transparent, body: child)
            : child,
      );

  /// The first run (spec §10.1). Its two blocs live and die with this route:
  /// once a home exists the redirect makes `/setup` unreachable, and a bloc
  /// kept across that redirect would still be reporting a finished setup.
  Page<void> setup(BuildContext context, GoRouterState state) => _fade(
    state,
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OnboardingBloc(
            finishOnboarding: deps.finishOnboarding,
            ids: deps.ids,
          ),
        ),
        BlocProvider(
          create: (_) => DiscoveryBloc(
            onboarding: true,
            runDiscovery: deps.runDiscovery,
            saveDiscoveredLight: deps.saveDiscoveredLight,
            learnHomeSubnet: deps.learnHomeSubnet,
            sync: deps.sync,
          ),
        ),
      ],
      child: const OnboardingNoticeListener(child: OnboardingScreen()),
    ),
  );

  Page<void> home(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => HomeScreenBloc(
        homes: deps.homes,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        settings: deps.settings,
        setPower: deps.setPower,
        sync: deps.sync,
      )..add(const HomeScreenSubscribed()),
      child: const HomePage(),
    ),
  );

  Page<void> rooms(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => RoomsListBloc(
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        settings: deps.settings,
        addRoom: deps.addRoom,
        renameRoom: deps.renameRoom,
        deleteRoom: deps.deleteRoom,
      )..add(const RoomsListSubscribed()),
      child: const RoomsNoticeListener(child: RoomsScreen()),
    ),
  );

  Page<void> room(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => RoomBloc(
        roomId: state.pathParameters[AppRoutes.roomParam]!,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        sync: deps.sync,
      )..add(const RoomSubscribed()),
      child: const RoomPage(),
    ),
  );

  /// On a phone the detail screen; Task 21 adds the desktop reading, where
  /// the light is selected into the inspector over its room.
  Page<void> light(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => LightBloc(
        lightId: state.pathParameters[AppRoutes.lightParam]!,
        lights: deps.lights,
        rooms: deps.rooms,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        setSpeed: deps.setSpeed,
        setFixture: deps.setFixture,
        renameLight: deps.renameLight,
        forgetLight: deps.forgetLight,
        sync: deps.sync,
      )..add(const LightSubscribed()),
      child: const LightNoticeListener(child: LightScreen()),
    ),
  );

  Page<void> modes(BuildContext context, GoRouterState state) => _fade(
    state,
    _ForActiveHome(
      builder: (context, active) {
        var homeId = active ?? '';
        return BlocProvider(
          key: ValueKey(homeId),
          create: (_) =>
              modesBlocFor(WholeHomeTarget(homeId))
                ..add(const ModesSubscribed()),
          child: ModesNoticeListener(child: ModesScreen(homeId: homeId)),
        );
      },
    ),
  );

  /// Settings has no bloc of its own: it reads the app-scope cubits the root
  /// provides (spec §10.7).
  Page<void> settings(BuildContext context, GoRouterState state) =>
      _fade(state, const SettingsScreen());

  Page<void> discover(BuildContext context, GoRouterState state) => _fade(
    state,
    _ForActiveHome(
      builder: (context, homeId) => BlocProvider(
        key: ValueKey(homeId),
        create: (_) => DiscoveryBloc(
          homeId: homeId,
          runDiscovery: deps.runDiscovery,
          saveDiscoveredLight: deps.saveDiscoveredLight,
          learnHomeSubnet: deps.learnHomeSubnet,
          sync: deps.sync,
        ),
        child: const DiscoveryNoticeListener(child: DiscoveryScreen()),
      ),
    ),
  );

  /// The one page without the shared scaffold: `GalleryScreen` builds its own
  /// (Plan 2), and the back key floats over it in the same stack.
  Page<void> gallery(BuildContext context, GoRouterState state) =>
      _fade(state, const GalleryPage(), scaffold: false);
}

/// Builds for the home that is active now, and rebuilds when that changes.
///
/// The pages whose bloc belongs to one home — the Scenes tab and discovery —
/// are branches of the shell, so they stay mounted while the user is
/// elsewhere. Reading the home once where the page is built would leave a bloc
/// applying scenes to, or saving lights into, the home the user has just left.
/// Watching it here rebuilds those pages wherever the switch happens, and the
/// `ValueKey` on the provider below is what disposes the old bloc and builds
/// one for the new home.
class _ForActiveHome extends StatelessWidget {
  final Widget Function(BuildContext context, String? homeId) builder;

  const _ForActiveHome({required this.builder});

  @override
  Widget build(BuildContext context) => builder(
    context,
    context.select<HomesBloc, String?>((bloc) => bloc.state.activeHomeId),
  );
}
