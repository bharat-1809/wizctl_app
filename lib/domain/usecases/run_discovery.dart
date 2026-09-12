import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../repositories/light_repository.dart';
import '../services/clock.dart';
import '../services/device_gateway.dart';
import '../services/live_state_mapper.dart';
import '../services/live_state_store.dart';
import '../services/network_monitor.dart';

enum DiscoveryMode {
  /// Probe the home's known addresses, then broadcast.
  quick,

  /// The unicast sweep of the /24, on the user's request only.
  sweep,
}

sealed class DiscoveryUpdate extends Equatable {
  const DiscoveryUpdate();
}

final class PhaseChanged extends DiscoveryUpdate {
  final DiscoveryProgress progress;
  const PhaseChanged(this.progress);
  @override
  List<Object?> get props => [progress];
}

final class DeviceFound extends DiscoveryUpdate {
  final DiscoveredDevice device;
  final LiveState? initial;
  const DeviceFound(this.device, this.initial);
  @override
  List<Object?> get props => [device, initial];
}

final class DeviceUpdated extends DiscoveryUpdate {
  final DiscoveredDevice device;
  const DeviceUpdated(this.device);
  @override
  List<Object?> get props => [device];
}

final class DiscoveryFinished extends DiscoveryUpdate {
  final List<DiscoveredDevice> devices;
  final String? subnet;

  /// Address ranges a sweep chunk failed to probe (spec §5.7); a failed
  /// chunk does not abort discovery, so the result may be partial.
  final List<String> failedRanges;
  const DiscoveryFinished(
    this.devices,
    this.subnet, {
    this.failedRanges = const [],
  });
  @override
  List<Object?> get props => [devices, subnet, failedRanges];
}

final class DiscoveryFailed extends DiscoveryUpdate {
  final DeviceFailure failure;
  const DiscoveryFailed(this.failure);
  @override
  List<Object?> get props => [failure];
}

/// The discovery sequence (spec §5.7).
class RunDiscovery {
  final DeviceGateway _gateway;
  final LightRepository _lights;
  final LiveStateStore _store;
  final NetworkInfo _network;
  final Clock _clock;

  RunDiscovery({
    required DeviceGateway gateway,
    required LightRepository lights,
    required LiveStateStore store,
    required NetworkInfo network,
    required Clock clock,
  }) : _gateway = gateway, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _network = network, // ignore: prefer_initializing_formals
       _clock = clock; // ignore: prefer_initializing_formals

  Stream<DiscoveryUpdate> call({
    required String homeId,
    required DiscoveryMode mode,
    bool probeKnown = true,
  }) async* {
    var known = await _lights.getByHome(homeId);
    var knownByMac = {for (var l in known) l.mac: l};
    var byMac = <String, DiscoveredDevice>{};
    var failedRanges = <String>[];

    // The range the sweep says it walked. It knows better than the monitor,
    // which may have moved on, or have no address at all (spec §5.7.5).
    String? sweptSubnet;

    Future<(DiscoveredDevice, LiveState?)> enrich(DiscoveredLight raw) async {
      var device = DiscoveredDevice.fromDiscovered(
        raw,
        alreadySaved: knownByMac.containsKey(raw.mac),
      );
      if (device.moduleName == null) {
        try {
          var config = await _gateway.readConfig(raw.ip);
          device = device.copyWith(
            moduleName: config.moduleName,
            bulbClass:
                config.bulbClass ?? BulbClass.fromModuleName(config.moduleName),
            fwVersion: config.fwVersion,
          );
        } on DeviceException {
          // Older firmware: keep what discovery gave us.
        }
      }
      LiveState? initial;
      try {
        var state = await _gateway.readState(raw.ip);
        var saved = knownByMac[raw.mac];
        var previous = saved == null ? LiveState.initial : _store.of(saved.id);
        initial = LiveStateMapper.fromLightState(
          state,
          previous: previous,
          now: _clock.now(),
        );
        if (saved != null) _store.put(saved.id, initial);
      } on DeviceException {
        initial = null;
      }
      return (device, initial);
    }

    // Yields the right update for a raw reply, or null when it adds nothing.
    Future<DiscoveryUpdate?> absorb(DiscoveredLight raw) async {
      var existing = byMac[raw.mac];
      if (existing == null) {
        var (device, initial) = await enrich(raw);
        byMac[raw.mac] = device;
        return DeviceFound(device, initial);
      }
      if (existing.moduleName == null && raw.moduleName != null) {
        var richer = existing.copyWith(
          moduleName: raw.moduleName,
          bulbClass: raw.bulbClass,
          fwVersion: raw.fwVersion,
        );
        byMac[raw.mac] = richer;
        return DeviceUpdated(richer);
      }
      return null;
    }

    try {
      if (mode == DiscoveryMode.quick) {
        if (probeKnown && known.isNotEmpty) {
          yield PhaseChanged(
            DiscoveryProgress(
              phase: DiscoveryPhase.probingKnown,
              total: known.length,
            ),
          );
          await for (var event in _gateway.probe(known.map((l) => l.ip))) {
            switch (event) {
              case ScanProgress p:
                yield PhaseChanged(
                  DiscoveryProgress(
                    phase: DiscoveryPhase.probingKnown,
                    probed: p.addressesProbed,
                    total: p.addressCount,
                    fraction: p.fraction,
                  ),
                );
              case ScanFound f:
                var u = await absorb(f.light);
                if (u != null) yield u;
              case ScanUpdated u:
                var up = await absorb(u.light);
                if (up != null) yield up;
              case ScanFailed f:
                failedRanges.add(f.addressRange);
              case ScanDone _:
                break;
            }
          }
        }
        yield const PhaseChanged(
          DiscoveryProgress(phase: DiscoveryPhase.broadcasting),
        );
        for (var raw in await _gateway.broadcast()) {
          var u = await absorb(raw);
          if (u != null) yield u;
        }
      } else {
        yield const PhaseChanged(
          DiscoveryProgress(phase: DiscoveryPhase.sweeping),
        );
        await for (var event in _gateway.sweep()) {
          switch (event) {
            case ScanProgress p:
              sweptSubnet = p.subnet ?? sweptSubnet;
              yield PhaseChanged(
                DiscoveryProgress(
                  phase: DiscoveryPhase.sweeping,
                  probed: p.addressesProbed,
                  total: p.addressCount,
                  fraction: p.fraction,
                  subnet: p.subnet,
                ),
              );
            case ScanFound f:
              var u = await absorb(f.light);
              if (u != null) yield u;
            case ScanUpdated u:
              var up = await absorb(u.light);
              if (up != null) yield up;
            case ScanFailed f:
              failedRanges.add(f.addressRange);
            case ScanDone _:
              break;
          }
        }
      }
      yield DiscoveryFinished(
        byMac.values.toList(),
        sweptSubnet ?? await _network.currentSubnet(),
        failedRanges: failedRanges,
      );
    } on DeviceException catch (e) {
      yield DiscoveryFailed(e.failure);
    }
  }
}
