import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../data/cli/cli_config_exporter.dart';
import '../data/cli/cli_export_listener.dart';
import '../data/db/app_database.dart';
import '../data/device/fault_injecting_gateway.dart';
import '../data/device/fault_injecting_network_info.dart';
import '../data/device/wiz_device_gateway.dart';
import '../data/ids/uuid_ids.dart';
import '../data/network/network_info.dart';
import '../data/repositories/drift_home_repository.dart';
import '../data/repositories/drift_light_repository.dart';
import '../data/repositories/drift_live_state_persistence.dart';
import '../data/repositories/drift_room_repository.dart';
import '../data/repositories/drift_settings_repository.dart';
import '../data/repositories/live_state_persister.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/repositories/room_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/clock.dart';
import '../domain/services/device_command_pipeline.dart';
import '../domain/services/device_gateway.dart';
import '../domain/services/id_generator.dart';
import '../domain/services/live_state_store.dart';
import '../domain/services/network_monitor.dart';
import '../domain/services/sync_coordinator.dart';
import '../domain/services/target_resolver.dart';
import '../domain/usecases/usecases.dart';
import 'debug_flags_holder.dart';

/// Everything the screens need, built once. No service locator: the app
/// hands these down with RepositoryProvider.
class AppDependencies {
  final AppDatabase database;
  final HomeRepository homes;
  final RoomRepository rooms;
  final LightRepository lights;
  final SettingsRepository settings;
  final LiveStateStore store;
  final LiveStatePersister persister;
  final DeviceGateway gateway;
  final NetworkInfo networkInfo;
  final NetworkMonitor network;
  final TargetResolver resolver;
  final DeviceCommandPipeline pipeline;
  final RefreshStates refreshStates;
  final SyncCoordinator sync;
  final RunDiscovery runDiscovery;
  final BlinkLight blinkLight;
  final SetPower setPower;
  final SetBrightness setBrightness;
  final SetKelvin setKelvin;
  final SetSpeed setSpeed;
  final ApplyColour applyColour;
  final ApplyWhite applyWhite;
  final ApplyScene applyScene;
  final CreateHome createHome;
  final SwitchHome switchHome;
  final RenameHome renameHome;
  final DeleteHome deleteHome;
  final LearnHomeSubnet learnHomeSubnet;
  final AddRoom addRoom;
  final RenameRoom renameRoom;
  final DeleteRoom deleteRoom;
  final RenameLight renameLight;
  final MoveLight moveLight;
  final SetFixture setFixture;
  final ForgetLight forgetLight;
  final SaveDiscoveredLight saveDiscoveredLight;
  final FinishOnboarding finishOnboarding;
  final CliExportListener? cliExport;
  final DebugFlagsHolder debugFlags;
  final Clock clock;
  final IdGenerator ids;

  const AppDependencies._({
    required this.database,
    required this.homes,
    required this.rooms,
    required this.lights,
    required this.settings,
    required this.store,
    required this.persister,
    required this.gateway,
    required this.networkInfo,
    required this.network,
    required this.resolver,
    required this.pipeline,
    required this.refreshStates,
    required this.sync,
    required this.runDiscovery,
    required this.blinkLight,
    required this.setPower,
    required this.setBrightness,
    required this.setKelvin,
    required this.setSpeed,
    required this.applyColour,
    required this.applyWhite,
    required this.applyScene,
    required this.createHome,
    required this.switchHome,
    required this.renameHome,
    required this.deleteHome,
    required this.learnHomeSubnet,
    required this.addRoom,
    required this.renameRoom,
    required this.deleteRoom,
    required this.renameLight,
    required this.moveLight,
    required this.setFixture,
    required this.forgetLight,
    required this.saveDiscoveredLight,
    required this.finishOnboarding,
    required this.cliExport,
    required this.debugFlags,
    required this.clock,
    required this.ids,
  });

  /// Only the desktop builds share a filesystem with the CLI (spec §16).
  static bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static Future<AppDependencies> build({
    AppDatabase? database,
    DeviceGateway? gateway,
    NetworkInfo? networkInfo,
    bool? exportCli,
    Directory Function()? homeDirectory,
    DebugFlagsHolder? debugFlags,
    Clock clock = const SystemClock(),
    IdGenerator? ids,
  }) async {
    var db = database ?? AppDatabase(driftDatabase(name: 'wizctl'));
    var flags = debugFlags ?? DebugFlagsHolder();
    var idGen = ids ?? UuidIds();

    var homes = DriftHomeRepository(db);
    var rooms = DriftRoomRepository(db);
    var lights = DriftLightRepository(db);
    var settings = DriftSettingsRepository(db);
    var persistence = DriftLiveStatePersistence(db);

    var store = LiveStateStore()..seed(await persistence.load());
    var persister = LiveStatePersister(store: store, persistence: persistence)
      ..start();

    DeviceGateway device = gateway ?? WizDeviceGateway();
    NetworkInfo info = networkInfo ?? IoNetworkInfo();
    if (kDebugMode) {
      device = FaultInjectingGateway(
        device,
        flags: () => flags.value,
        clock: clock,
      );
      info = FaultInjectingNetworkInfo(info, flags: () => flags.value);
    }
    var network = NetworkMonitor(info);

    Future<String?> homeSubnet() async {
      var id = (await settings.get()).activeHomeId;
      return id == null ? null : (await homes.get(id))?.subnet;
    }

    var resolver = TargetResolver(lights);
    var pipeline = DeviceCommandPipeline(
      gateway: device,
      store: store,
      network: network,
      homeSubnet: homeSubnet,
      clock: clock,
      ids: idGen,
    );
    var refresh = RefreshStates(
      gateway: device,
      store: store,
      lights: lights,
      clock: clock,
    );
    var sync = SyncCoordinator(
      refresh: refresh,
      lights: lights,
      settings: settings,
    );

    CliExportListener? cli;
    if (exportCli ?? _isDesktop) {
      cli = CliExportListener(
        settings: settings,
        rooms: rooms,
        lights: lights,
        exporter: CliConfigExporter(
          homeDirectory:
              homeDirectory ?? CliConfigExporter.defaultHomeDirectory,
        ),
      )..start();
    }

    return AppDependencies._(
      database: db,
      homes: homes,
      rooms: rooms,
      lights: lights,
      settings: settings,
      store: store,
      persister: persister,
      gateway: device,
      networkInfo: info,
      network: network,
      resolver: resolver,
      pipeline: pipeline,
      refreshStates: refresh,
      sync: sync,
      runDiscovery: RunDiscovery(
        gateway: device,
        lights: lights,
        store: store,
        network: info,
        clock: clock,
      ),
      blinkLight: BlinkLight(gateway: device, clock: clock),
      setPower: SetPower(resolver: resolver, store: store, pipeline: pipeline),
      setBrightness: SetBrightness(
        resolver: resolver,
        store: store,
        pipeline: pipeline,
      ),
      setKelvin: SetKelvin(
        resolver: resolver,
        store: store,
        pipeline: pipeline,
      ),
      setSpeed: SetSpeed(resolver: resolver, store: store, pipeline: pipeline),
      applyColour: ApplyColour(
        resolver: resolver,
        store: store,
        pipeline: pipeline,
      ),
      applyWhite: ApplyWhite(
        resolver: resolver,
        store: store,
        pipeline: pipeline,
      ),
      applyScene: ApplyScene(
        resolver: resolver,
        store: store,
        pipeline: pipeline,
      ),
      createHome: CreateHome(
        homes: homes,
        settings: settings,
        ids: idGen,
        clock: clock,
      ),
      switchHome: SwitchHome(settings: settings),
      renameHome: RenameHome(homes: homes),
      deleteHome: DeleteHome(homes: homes, settings: settings),
      learnHomeSubnet: LearnHomeSubnet(homes: homes),
      addRoom: AddRoom(rooms: rooms, ids: idGen),
      renameRoom: RenameRoom(rooms: rooms),
      deleteRoom: DeleteRoom(rooms: rooms, lights: lights),
      renameLight: RenameLight(lights: lights),
      moveLight: MoveLight(lights: lights),
      setFixture: SetFixture(lights: lights),
      forgetLight: ForgetLight(lights: lights, store: store),
      saveDiscoveredLight: SaveDiscoveredLight(
        lights: lights,
        store: store,
        ids: idGen,
        clock: clock,
      ),
      finishOnboarding: FinishOnboarding(
        homes: homes,
        rooms: rooms,
        lights: lights,
        settings: settings,
        store: store,
        ids: idGen,
        clock: clock,
      ),
      cliExport: cli,
      debugFlags: flags,
      clock: clock,
      ids: idGen,
    );
  }

  Future<void> dispose() async {
    sync.dispose();
    pipeline.dispose();
    network.dispose();
    await cliExport?.dispose();
    await persister.dispose();
    store.dispose();
    await database.close();
  }
}
