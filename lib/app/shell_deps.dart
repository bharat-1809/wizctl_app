import '../domain/repositories/home_repository.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/repositories/room_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/id_generator.dart';
import '../domain/services/live_state_store.dart';
import '../domain/services/sync_coordinator.dart';
import '../domain/usecases/usecases.dart';

/// The repositories, services and use cases the route pages and the shells
/// build their blocs from. `WizCtlApp` provides one over the real graph;
/// tests provide one over fakes.
///
/// A record rather than `AppDependencies` itself: this is exactly what the
/// routes need, so a page cannot reach the database, the gateway or the
/// pipeline through it, and a test can build one without a graph.
typedef ShellDeps = ({
  HomeRepository homes,
  RoomRepository rooms,
  LightRepository lights,
  SettingsRepository settings,
  LiveStateStore store,
  SyncCoordinator sync,
  SetPower setPower,
  SetBrightness setBrightness,
  SetKelvin setKelvin,
  SetSpeed setSpeed,
  SetFixture setFixture,
  RenameLight renameLight,
  ForgetLight forgetLight,
  AddRoom addRoom,
  RenameRoom renameRoom,
  DeleteRoom deleteRoom,
  RunDiscovery runDiscovery,
  SaveDiscoveredLight saveDiscoveredLight,
  LearnHomeSubnet learnHomeSubnet,
  FinishOnboarding finishOnboarding,
  IdGenerator ids,
});
