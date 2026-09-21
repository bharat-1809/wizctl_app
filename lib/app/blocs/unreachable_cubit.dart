import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/util/latest.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/light_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/active_home.dart';
import '../../domain/services/live_state_store.dart';

/// The active home's lights that are not answering, in repository order; the
/// unreachable banner (spec §15) and the desktop "Not answering" tile read it.
///
/// [switchLatest] gives the home side: a home switch drops the previous home's
/// lights, which `asyncExpand` would not — it pauses the active-home stream
/// until the inner one ends, and a repository watch never ends.
class UnreachableCubit extends Cubit<List<Light>> {
  final LightRepository _lights;
  final LiveStateStore _store;
  final SettingsRepository _settings;
  StreamSubscription<List<Light>>? _subscription;

  UnreachableCubit({
    required LightRepository lights,
    required LiveStateStore store,
    required SettingsRepository settings,
  }) : _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       super(const []);

  void subscribe() {
    _subscription ??= switchLatest(
      activeHomeIds(_settings),
      _forHome,
    ).listen(emit);
  }

  /// The silent lights of the home with [id]: nothing at all with no active
  /// home, which is what the first run shows before a home exists.
  Stream<List<Light>> _forHome(String? id) => id == null
      ? Stream.value(const <Light>[])
      : combineLatest2(_lights.watchByHome(id), _store.watchAll()).map((pair) {
          var (lights, states) = pair;
          return [
            for (var light in lights)
              if (!(states[light.id] ?? LiveState.initial).reachable) light,
          ];
        });

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
