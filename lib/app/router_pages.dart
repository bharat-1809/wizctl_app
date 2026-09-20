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
import '../features/home/view/home_screen.dart';
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
import '../features/rooms/view/room_screen.dart';
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
  Page<void> _fade(GoRouterState state, Widget child) => wizFadePage<void>(
    key: state.pageKey,
    motion: motion,
    child: Scaffold(backgroundColor: Colors.transparent, body: child),
  );

  /// The active home, for the pages whose bloc is built per home. The redirect
  /// keeps every one of them behind a home, so this is null only for a frame
  /// while one is being switched.
  String? _activeHome(BuildContext context) =>
      context.read<HomesBloc>().state.activeHomeId;

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
      child: const HomeScreen(),
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
      child: const RoomScreen(),
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

  Page<void> modes(BuildContext context, GoRouterState state) {
    var homeId = _activeHome(context) ?? '';
    return _fade(
      state,
      BlocProvider(
        create: (_) =>
            modesBlocFor(WholeHomeTarget(homeId))..add(const ModesSubscribed()),
        child: ModesNoticeListener(child: ModesScreen(homeId: homeId)),
      ),
    );
  }

  /// Settings has no bloc of its own: it reads the app-scope cubits the root
  /// provides (spec §10.7).
  Page<void> settings(BuildContext context, GoRouterState state) =>
      _fade(state, const SettingsScreen());

  Page<void> discover(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => DiscoveryBloc(
        homeId: _activeHome(context),
        runDiscovery: deps.runDiscovery,
        saveDiscoveredLight: deps.saveDiscoveredLight,
        learnHomeSubnet: deps.learnHomeSubnet,
        sync: deps.sync,
      ),
      child: const DiscoveryNoticeListener(child: DiscoveryScreen()),
    ),
  );

  Page<void> gallery(BuildContext context, GoRouterState state) =>
      _fade(state, const GalleryPage());
}
