import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/copy/strings.dart';
import '../core/feedback/feedback_scope.dart';
import '../core/layout/wiz_layout.dart';
import '../core/theme/wiz_theme.dart';
import '../core/widgets/toast_controller.dart';
import '../core/widgets/wiz_app_background.dart';
import '../core/widgets/wiz_toast_layer.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/repositories/room_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/live_state_store.dart';
import '../domain/usecases/usecases.dart';
import '../features/modes/bloc/light_modes_bloc.dart';
import '../features/modes/modes_bloc_factory.dart';
import 'blocs/blink_cubit.dart';
import 'blocs/homes_bloc.dart';
import 'blocs/homes_event.dart';
import 'blocs/homes_state.dart';
import 'blocs/inspector_cubit.dart';
import 'blocs/network_cubit.dart';
import 'blocs/settings_cubit.dart';
import 'blocs/unreachable_cubit.dart';
import 'bootstrap.dart';
import 'command_toasts.dart';
import 'dependencies.dart';
import 'lifecycle.dart';
import 'router.dart';
import 'router_pages.dart';
import 'shell_deps.dart';

/// The root (spec §7, §9): the app-scope blocs, the providers the screens read
/// by type, the router, and the chassis the kit's theme, background and toast
/// stack wrap around every screen.
///
/// Stateful because everything here is built once and torn down once: a bloc
/// rebuilt on a frame would drop its subscriptions, and the router has to
/// outlive every navigation.
class WizCtlApp extends StatefulWidget {
  final AppServices services;

  const WizCtlApp({super.key, required this.services});

  @override
  State<WizCtlApp> createState() => _WizCtlAppState();
}

class _WizCtlAppState extends State<WizCtlApp> {
  AppDependencies get _deps => widget.services.deps;
  late final HomesBloc _homes;
  late final SettingsCubit _settings;
  late final NetworkCubit _network;
  late final BlinkCubit _blink;
  late final InspectorCubit _inspector;
  late final UnreachableCubit _unreachable;
  late final CommandToastListener _commandToasts;
  late final AppLifecycleDriver _lifecycle;
  late final HomesListenable _homesListenable;
  late final ShellDeps _shellDeps;
  late final GoRouter _router;

  /// The tokens read without a context: the router, the toast listener and the
  /// lifecycle driver are all built before the first frame, where
  /// `Theme.of(context)` has nothing to answer with. It is the same object
  /// `buildWizThemeData` installs.
  static final WizTheme _theme = WizTheme.standard;

  LightModesBloc _modesBlocFor(ModeTarget target) => LightModesBloc(
    target: target,
    rooms: _deps.rooms,
    lights: _deps.lights,
    store: _deps.store,
    applyColour: _deps.applyColour,
    applyWhite: _deps.applyWhite,
    applyScene: _deps.applyScene,
    setSpeed: _deps.setSpeed,
  );

  @override
  void initState() {
    super.initState();
    var services = widget.services;
    // The snapshot bootstrap read, so the redirect knows on the first frame
    // whether a home exists and a second launch opens on Home rather than
    // flashing the first run (spec §9).
    _homes = HomesBloc(
      homes: _deps.homes,
      rooms: _deps.rooms,
      lights: _deps.lights,
      settings: _deps.settings,
      createHome: _deps.createHome,
      switchHome: _deps.switchHome,
      renameHome: _deps.renameHome,
      deleteHome: _deps.deleteHome,
      initial: HomesState.snapshot(services.homes, services.settings),
    )..add(const HomesSubscribed());
    _settings = SettingsCubit(
      settings: _deps.settings,
      feedback: services.feedback,
      debugFlags: _deps.debugFlags,
      initial: services.settings,
    )..subscribe();
    _network = NetworkCubit(
      network: _deps.network,
      settings: _deps.settings,
      homes: _deps.homes,
    )..subscribe();
    _blink = BlinkCubit(blink: _deps.blinkLight);
    _inspector = InspectorCubit();
    _unreachable = UnreachableCubit(
      lights: _deps.lights,
      store: _deps.store,
      settings: _deps.settings,
    )..subscribe();
    _commandToasts = CommandToastListener(
      toasts: services.toasts,
      pipeline: _deps.pipeline,
      lights: _deps.lights,
      delay: _theme.motion.toastDelay,
    )..start();
    _lifecycle = AppLifecycleDriver(
      sync: _deps.sync,
      network: _deps.network,
      homes: _homes,
    )..start();
    _homesListenable = HomesListenable(_homes);
    _shellDeps = (
      homes: _deps.homes,
      rooms: _deps.rooms,
      lights: _deps.lights,
      settings: _deps.settings,
      store: _deps.store,
      sync: _deps.sync,
      setPower: _deps.setPower,
      setBrightness: _deps.setBrightness,
      setKelvin: _deps.setKelvin,
      setSpeed: _deps.setSpeed,
      setFixture: _deps.setFixture,
      renameLight: _deps.renameLight,
      forgetLight: _deps.forgetLight,
      addRoom: _deps.addRoom,
      renameRoom: _deps.renameRoom,
      deleteRoom: _deps.deleteRoom,
      runDiscovery: _deps.runDiscovery,
      saveDiscoveredLight: _deps.saveDiscoveredLight,
      learnHomeSubnet: _deps.learnHomeSubnet,
      finishOnboarding: _deps.finishOnboarding,
      ids: _deps.ids,
    );
    _router = buildRouter(
      homes: _homes,
      listenable: _homesListenable,
      motion: _theme.motion,
      pages: AppPages(
        deps: _shellDeps,
        modesBlocFor: _modesBlocFor,
        motion: _theme.motion,
      ),
    );
  }

  /// Build order reversed. The route blocs are closed by the pages that own
  /// them, so only the app-scope ones are here; the graph belongs to whoever
  /// called `bootstrap`, and so does the toast controller.
  ///
  /// Nothing is awaited: `dispose` is synchronous, and a `Bloc.close()` awaited
  /// from here would only hold the frame.
  @override
  void dispose() {
    _router.dispose();
    _homesListenable.dispose();
    _lifecycle.dispose();
    unawaited(_commandToasts.dispose());
    unawaited(_unreachable.close());
    unawaited(_inspector.close());
    unawaited(_blink.close());
    unawaited(_network.close());
    unawaited(_settings.close());
    unawaited(_homes.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var services = widget.services;
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomesBloc>.value(value: _homes),
        BlocProvider<SettingsCubit>.value(value: _settings),
        BlocProvider<NetworkCubit>.value(value: _network),
        BlocProvider<BlinkCubit>.value(value: _blink),
        BlocProvider<InspectorCubit>.value(value: _inspector),
        BlocProvider<UnreachableCubit>.value(value: _unreachable),
      ],
      // The repositories, the use cases a sheet reaches for and the graph the
      // shells build their blocs from, by type — the same set `AppScope.wrap`
      // gives a screen test, so a screen that finds one there finds it here.
      child: MultiRepositoryProvider(
        providers: [
          // `RepositoryProvider` is a `Provider`, which asserts against
          // `Listenable` values, and `ToastController` is a `ChangeNotifier`;
          // `context.read<ToastController>()` resolves from either.
          ChangeNotifierProvider<ToastController>.value(value: services.toasts),
          RepositoryProvider<HomeRepository>.value(value: _deps.homes),
          RepositoryProvider<RoomRepository>.value(value: _deps.rooms),
          RepositoryProvider<LightRepository>.value(value: _deps.lights),
          RepositoryProvider<SettingsRepository>.value(value: _deps.settings),
          RepositoryProvider<LiveStateStore>.value(value: _deps.store),
          RepositoryProvider<AddRoom>.value(value: _deps.addRoom),
          RepositoryProvider<ModesBlocFactory>.value(value: _modesBlocFor),
          RepositoryProvider<ShellDeps>.value(value: _shellDeps),
        ],
        child: FeedbackScope(
          service: services.feedback,
          child: BlocBuilder<HomesBloc, HomesState>(
            // Only the window title reads the home up here, so only its name
            // is worth a rebuild of the whole app.
            buildWhen: (a, b) => a.activeHome?.name != b.activeHome?.name,
            builder: (context, homes) => MaterialApp.router(
              onGenerateTitle: (_) {
                var home = homes.activeHome;
                return home == null
                    ? Strings.windowSetup
                    : Strings.windowTitle(home.name);
              },
              debugShowCheckedModeBanner: false,
              theme: buildWizThemeData(),
              routerConfig: _router,
              // One `WizLayoutScope` for the window, above the router: a
              // content frame must never re-scope it, or a row inside the frame
              // would read the frame's width as the window's.
              //
              // The toast layer wraps the root navigator, so it paints above
              // every route — sheets included, which are root-navigator routes.
              builder: (context, child) => WizLayoutScope(
                // A transparent `Material` at the window level (P90). The
                // rail, the inspector column, the tab bar and the toast stack
                // all sit outside the routed page's own `Scaffold`, and with
                // no `Material` above them their text falls back to
                // `WidgetsApp`'s error style — a yellow double underline under
                // every label. `MaterialType.transparency` paints nothing,
                // absorbs no hit tests and clips nothing, so all it
                // contributes is the theme's ambient text style; the routed
                // page's own Scaffold nests underneath it harmlessly.
                child: Material(
                  type: MaterialType.transparency,
                  child: WizAppBackground(
                    child: _ToastOverlay(
                      toasts: services.toasts,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the toast stack over the current screen: above the floating tab bar
/// on a phone, bottom-right on anything wider (spec §11.2).
///
/// It lives here rather than on each screen so that a toast pushed by a
/// command outlives the screen that started it.
class _ToastOverlay extends StatelessWidget {
  final ToastController toasts;
  final Widget child;

  const _ToastOverlay({required this.toasts, required this.child});

  @override
  Widget build(BuildContext context) {
    var compact = context.layout.widthClass.isCompact;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        WizToastLayer(
          controller: toasts,
          placement: compact
              ? WizToastPlacement.aboveTabBar
              : WizToastPlacement.bottomRight,
          // The safe-area inset only: the placement adds the tab bar's own
          // height and float on top of it.
          bottomInset: MediaQuery.paddingOf(context).bottom,
        ),
      ],
    );
  }
}
