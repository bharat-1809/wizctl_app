import 'dart:async';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/light_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import 'cli_config_exporter.dart';

/// Keeps the CLI config in step with the active home, debounced.
class CliExportListener {
  final SettingsRepository _settings;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final CliConfigExporter _exporter;

  /// How long edits are coalesced before the config is rewritten (spec §16).
  final Duration debounce;

  StreamSubscription<AppSettings>? _settingsSub;
  StreamSubscription<List<Room>>? _roomsSub;
  StreamSubscription<List<Light>>? _lightsSub;
  String? _homeId;
  List<Room> _latestRooms = [];
  List<Light> _latestLights = [];
  Timer? _timer;

  /// True once a change armed the timer and until that export has run: the
  /// latest rooms and lights outlive a flush, so they can't mark the export.
  bool _pending = false;

  CliExportListener({
    required SettingsRepository settings,
    required RoomRepository rooms,
    required LightRepository lights,
    required CliConfigExporter exporter,
    this.debounce = const Duration(milliseconds: 500),
  }) : _settings = settings, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _exporter = exporter; // ignore: prefer_initializing_formals

  void start() {
    _settingsSub ??= _settings.watch().listen((s) {
      if (s.activeHomeId == _homeId) return;
      _homeId = s.activeHomeId;
      _resubscribe();
    });
  }

  void _resubscribe() {
    _roomsSub?.cancel();
    _lightsSub?.cancel();
    var homeId = _homeId;
    if (homeId == null) return;
    _roomsSub = _rooms.watchByHome(homeId).listen((rooms) {
      _latestRooms = rooms;
      _schedule();
    });
    _lightsSub = _lights.watchByHome(homeId).listen((lights) {
      _latestLights = lights;
      _schedule();
    });
  }

  void _schedule() {
    _pending = true;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_flush()));
  }

  Future<void> _flush() {
    if (!_pending) return Future.value();
    _pending = false;
    return _exporter.export(lights: _latestLights, rooms: _latestRooms);
  }

  /// Cancels the debounce and writes any pending export before dropping the
  /// subscriptions, so edits made just before shutdown still reach the CLI.
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _flush();
    await _settingsSub?.cancel();
    await _roomsSub?.cancel();
    await _lightsSub?.cancel();
    _settingsSub = null;
    _roomsSub = null;
    _lightsSub = null;
  }
}
