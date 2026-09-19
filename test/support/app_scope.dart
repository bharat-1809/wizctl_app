import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/blocs/homes_bloc.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/blocs/inspector_cubit.dart';
import 'package:wizctl_app/app/blocs/network_cubit.dart';
import 'package:wizctl_app/app/blocs/settings_cubit.dart';
import 'package:wizctl_app/app/debug_flags_holder.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/repositories/home_repository.dart';
import 'package:wizctl_app/domain/repositories/light_repository.dart';
import 'package:wizctl_app/domain/repositories/room_repository.dart';
import 'package:wizctl_app/domain/repositories/settings_repository.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import 'fakes.dart';
import 'seed.dart';

/// Everything a screen test needs around a screen: the logic services over
/// the fakes, and the app-scope blocs provided the way the shell provides
/// them (Task 19). Route blocs are built by each test from the use-case
/// getters below.
///
/// Build it inside the `testWidgets` body, not in `setUp`: the blocs
/// subscribe where they are built, and a bloc built outside the tester's
/// zone runs its event handlers on real microtasks that `pump` never
/// flushes.
class AppScope {
  final SeedHome seed;
  final gateway = FakeGateway();
  final clock = FakeClock();
  final ids = SequenceIds();
  final toasts = ToastController();
  final flags = DebugFlagsHolder();
  final feedback = RecordingFeedbackService();
  late final NetworkMonitor monitor;
  late final DeviceCommandPipeline pipeline;
  late final RefreshStates refresh;
  late final SyncCoordinator sync;
  late final TargetResolver resolver;
  late final HomesBloc homes;
  late final NetworkCubit network;
  late final BlinkCubit blink;
  late final SettingsCubit settingsCubit;
  late final InspectorCubit inspector;

  AppScope(this.seed, {String? subnet = '192.168.1'}) {
    for (var l in seed.all) {
      var s = seed.store.of(l.id);
      gateway.states[l.ip] = LightState(
        isOn: s.isOn,
        dimming: s.brightness,
        temperature: s.active == ActiveChannel.white ? s.kelvin : null,
        sceneId: s.active == ActiveChannel.scene ? s.sceneId : null,
        r: s.active == ActiveChannel.colour ? s.rgb.r : null,
        g: s.active == ActiveChannel.colour ? s.rgb.g : null,
        b: s.active == ActiveChannel.colour ? s.rgb.b : null,
        rssi: s.rssi,
      );
    }
    monitor = NetworkMonitor(FakeNetworkInfo(subnet));
    resolver = TargetResolver(seed.lights);
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async {
        var id = (await seed.settings.get()).activeHomeId;
        return id == null ? null : (await seed.homes.get(id))?.subnet;
      },
      clock: clock,
      ids: ids,
    );
    refresh = RefreshStates(
      gateway: gateway,
      store: seed.store,
      lights: seed.lights,
      clock: clock,
    );
    sync = SyncCoordinator(
      refresh: refresh,
      lights: seed.lights,
      settings: seed.settings,
    );
    homes = HomesBloc(
      homes: seed.homes,
      rooms: seed.rooms,
      lights: seed.lights,
      settings: seed.settings,
      createHome: CreateHome(
        homes: seed.homes,
        settings: seed.settings,
        ids: ids,
        clock: clock,
      ),
      switchHome: SwitchHome(settings: seed.settings),
      renameHome: RenameHome(homes: seed.homes),
      deleteHome: DeleteHome(homes: seed.homes, settings: seed.settings),
    );
    network = NetworkCubit(
      network: monitor,
      settings: seed.settings,
      homes: seed.homes,
    );
    blink = BlinkCubit(
      blink: BlinkLight(gateway: gateway, clock: clock),
    );
    settingsCubit = SettingsCubit(
      settings: seed.settings,
      feedback: feedback,
      debugFlags: flags,
    );
    inspector = InspectorCubit();
  }

  SetPower get setPower =>
      SetPower(resolver: resolver, store: seed.store, pipeline: pipeline);
  SetBrightness get setBrightness =>
      SetBrightness(resolver: resolver, store: seed.store, pipeline: pipeline);
  SetKelvin get setKelvin =>
      SetKelvin(resolver: resolver, store: seed.store, pipeline: pipeline);
  SetSpeed get setSpeed =>
      SetSpeed(resolver: resolver, store: seed.store, pipeline: pipeline);
  ApplyColour get applyColour =>
      ApplyColour(resolver: resolver, store: seed.store, pipeline: pipeline);
  ApplyWhite get applyWhite =>
      ApplyWhite(resolver: resolver, store: seed.store, pipeline: pipeline);
  ApplyScene get applyScene =>
      ApplyScene(resolver: resolver, store: seed.store, pipeline: pipeline);

  /// Subscribes the app-scope blocs and activates the seed's home, as the
  /// lifecycle driver does at start.
  Future<void> start() async {
    await monitor.refresh();
    homes.add(const HomesSubscribed());
    network.subscribe();
    settingsCubit.subscribe();
    sync.activateHome((await seed.settings.get()).activeHomeId);
  }

  Widget wrap(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<HomesBloc>.value(value: homes),
      BlocProvider<NetworkCubit>.value(value: network),
      BlocProvider<BlinkCubit>.value(value: blink),
      BlocProvider<SettingsCubit>.value(value: settingsCubit),
      BlocProvider<InspectorCubit>.value(value: inspector),
    ],
    // The repositories and the store by type, the way the shell provides them
    // (Task 19), so a view that reads one straight off the context — the modes
    // target sheet does — finds it here too.
    child: MultiRepositoryProvider(
      providers: [
        // `RepositoryProvider` is a `Provider`, which asserts against
        // `Listenable` values, and `ToastController` is a `ChangeNotifier`;
        // `context.read<ToastController>()` resolves from either.
        ChangeNotifierProvider<ToastController>.value(value: toasts),
        RepositoryProvider<HomeRepository>.value(value: seed.homes),
        RepositoryProvider<RoomRepository>.value(value: seed.rooms),
        RepositoryProvider<LightRepository>.value(value: seed.lights),
        RepositoryProvider<SettingsRepository>.value(value: seed.settings),
        RepositoryProvider<LiveStateStore>.value(value: seed.store),
      ],
      child: child,
    ),
  );

  /// Tears the fixture down, from inside the `testWidgets` body like the
  /// rest of it.
  ///
  /// [HomesBloc] is closed without being awaited. `Bloc.close()` awaits
  /// `StreamSubscription.cancel()`, whose future is often the SDK's shared
  /// null future in the root zone, and awaiting one of those inside
  /// `flutter_test`'s fake-async zone never resumes — the deadlock
  /// `lib/core/util/latest.dart` documents, reached here from inside the
  /// bloc package rather than from our own code. Every route bloc a test
  /// builds needs the same treatment. The cubits are zone-safe (Task 4) and
  /// are awaited; the services below hold the timers the tester checks for
  /// once the body returns, so they are disposed either way.
  Future<void> dispose() async {
    unawaited(homes.close());
    await network.close();
    await blink.close();
    await settingsCubit.close();
    await inspector.close();
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
    toasts.dispose();
    seed.store.dispose();
  }
}
