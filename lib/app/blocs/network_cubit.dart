import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/util/latest.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/active_home.dart';
import '../../domain/services/network_monitor.dart';
import 'network_state.dart';

/// The wrong-network banner's state (spec §5.9, §15).
///
/// It pairs the monitor's subnet with the active home's and recomputes
/// `isOffNetwork` on every value of either, rather than subscribing to
/// `watchOffNetwork`, which captures the subnet it compares against at
/// subscribe time and so would keep comparing against the home the user has
/// left. [switchLatest] gives the home side of that pair: a home switch
/// drops the previous home's subnet stream.
class NetworkCubit extends Cubit<NetworkState> {
  final NetworkMonitor _network;
  final SettingsRepository _settings;
  final HomeRepository _homes;
  StreamSubscription<(String?, String?)>? _subscription;

  NetworkCubit({
    required NetworkMonitor network,
    required SettingsRepository settings,
    required HomeRepository homes,
  }) : _network = network, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _homes = homes, // ignore: prefer_initializing_formals
       super(NetworkState.initial);

  void subscribe() {
    _subscription ??=
        combineLatest2(
          switchLatest(activeHomeIds(_settings), _subnetOf),
          _network.watchSubnet(),
        ).listen((pair) {
          var (home, current) = pair;
          emit(
            state.copyWith(
              offNetwork: _network.isOffNetwork(home),
              currentSubnet: current,
              clearCurrent: current == null,
              homeSubnet: home,
              clearHome: home == null,
            ),
          );
        });
  }

  /// The subnet of the home with [id], as it is learned and relearned; null
  /// with no active home, while the home has no subnet yet, and for a home
  /// that has been deleted.
  Stream<String?> _subnetOf(String? id) => id == null
      ? Stream.value(null)
      : _homes.watchAll().map((all) {
          for (var home in all) {
            if (home.id == id) return home.subnet;
          }
          return null;
        }).distinct();

  /// Re-reads the interfaces now (spec §15, "Retry"). Still elsewhere
  /// afterwards is a notice; back on the home subnet the banner simply goes.
  Future<void> retry() async {
    await _network.refresh();
    if (_network.isOffNetwork(state.homeSubnet)) {
      emit(state.copyWith(notice: StillOffNotice(_network.current)));
    }
  }

  void clearNotice() => emit(state.copyWith(clearNotice: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
