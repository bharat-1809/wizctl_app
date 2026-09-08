# Plan 1: wizctl package 1.1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the three additive APIs the WizCtl app needs to the `wizctl` Dart package (streaming subnet scan, `ControlSignal.fromState`, `retry` on `WizLight`) and release them as 1.1.0 on branch `sharma/app-support`.

**Architecture:** All changes are additive inside `lib/src/`. The existing `probeAddresses` and `scanSubnet` become thin collectors over new `Stream<ScanEvent>` generators built on `StreamController` so cancellation closes the socket. Every test runs offline against the loopback `FakeBulb`, which moves to `test/support/fake_bulb.dart` so several test files can share it.

**Tech Stack:** Dart 3.13 (SDK ^3.9.0 in pubspec), `package:test`, `package:lints/recommended`.

**Spec:** `/Users/bharat/Bharat/github/wizctl_app/docs/superpowers/specs/2026-09-08-wizctl-app-design.md` §3 (Package changes).

## Global Constraints

- Work in a git worktree of `/Users/bharat/Bharat/github/wizctl` on branch `sharma/app-support` (create with the `superpowers:using-git-worktrees` skill). All paths below are relative to that worktree root.
- Never touch `main` directly. Commit after every task with the trailer lines `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01LHFwuJ7FsQYePfr5j1T1Pe`.
- Tests are offline only (AGENTS.md): loopback `FakeBulb`, unroutable TEST-NET addresses, ports far from 38899. Never a real light.
- CI commands must stay green: `dart format --output=none --set-exit-if-changed lib bin test example`, `dart analyze --fatal-infos lib bin test example`, `dart test`, `dart pub publish --dry-run`.
- Style: comments explain why; public API gets dartdoc; local variables use `var` (the repo enables `unnecessary_final`); `constants.dart` holds tuning numbers with a comment each.
- `cliVersion` in `lib/src/constants.dart` must equal `version` in `pubspec.yaml`; `CHANGELOG.md` needs a `## 1.1.0` heading (`test/version_test.dart` enforces both).
- Every `socket.listen` passes `onError`; `RawDatagramSocket.send` failures are asynchronous (AGENTS.md).

---

### Task 1: Worktree and shared FakeBulb harness

**Files:**
- Create: `test/support/fake_bulb.dart`
- Modify: `test/discovery_test.dart:1-90` (remove the inline `ReplyMode` and `FakeBulb`, import the support file)

**Interfaces:**
- Produces: `enum ReplyMode { sourcePort, fixedPort }`; `class FakeBulb { static Future<FakeBulb> start({required int listenPort, required ReplyMode replyMode, int replyToPort = 0, String mac = 'a8bb50aabbcc', Set<String> supportedMethods, int ignoreFirst = 0}); int requestCount; int get port; void close(); }`. `ignoreFirst` is new: the bulb silently drops that many requests before answering (models a sleeping bulb whose first datagrams are lost). `getPilot` replies carry `state: true, dimming: 70, temp: 2700` in addition to the MAC so state-restore tests have something to capture.

- [ ] **Step 1: Create the worktree**

Use the `superpowers:using-git-worktrees` skill to create a worktree for branch `sharma/app-support` from `main`. Record the absolute worktree path; Plan 2 Task 1 writes it into the app's `pubspec_overrides.yaml`. Run `dart pub get` inside the worktree and `dart test test/discovery_test.dart` once to confirm the baseline is green.

- [ ] **Step 2: Move FakeBulb into a support file with the two new abilities**

Create `test/support/fake_bulb.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:wizctl/wizctl.dart';

/// How a bulb's firmware decides where to send its registration reply.
enum ReplyMode {
  /// Replies to the source port of the datagram it received.
  sourcePort,

  /// Replies to a well-known port on the sender's IP, ignoring the source
  /// port. This is what real WiZ firmware does with the WiZ port (38899).
  fixedPort,
}

/// A stand-in for a WiZ bulb that answers over loopback, so tests never
/// depend on a real network. See AGENTS.md.
class FakeBulb {
  final RawDatagramSocket _socket;
  final String mac;

  /// Number of requests this bulb has received (including ignored ones).
  int requestCount = 0;

  int _toIgnore;

  FakeBulb._(this._socket, this.mac, this._toIgnore);

  int get port => _socket.port;

  static Future<FakeBulb> start({
    required int listenPort,
    required ReplyMode replyMode,
    int replyToPort = 0,
    String mac = 'a8bb50aabbcc',
    Set<String> supportedMethods = const {
      methodRegistration,
      methodGetSystemConfig,
      methodGetPilot,
      methodSetPilot,
    },
    // A bulb in Wi-Fi power save loses the first datagrams sent to it;
    // dropping requests models that so retry behaviour can be tested.
    int ignoreFirst = 0,
  }) async {
    var socket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      listenPort,
      reuseAddress: true,
      reusePort: true,
    );
    socket.broadcastEnabled = true;
    var bulb = FakeBulb._(socket, mac, ignoreFirst);

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      var datagram = socket.receive();
      if (datagram == null) return;

      Map<String, dynamic> request;
      try {
        request =
            jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
      // Only answer requests; never react to a reply (avoids a self-send loop
      // when the bulb and the reply port are the same socket).
      var method = request[keyMethod];
      if (method is! String || !supportedMethods.contains(method)) return;
      if (request.containsKey(keyResult)) return;
      bulb.requestCount++;
      if (bulb._toIgnore > 0) {
        bulb._toIgnore--;
        return;
      }

      // getPilot carries the MAC and the pilot but no module name;
      // getSystemConfig has the module name.
      var result = <String, dynamic>{keyMac: mac, 'success': true};
      if (method == methodGetPilot) {
        result[keyState] = true;
        result[keyDimming] = 70;
        result[keyTemperature] = 2700;
      } else {
        result[keyModuleName] = 'ESP01_SHRGB_03';
      }

      var reply = utf8.encode(
        jsonEncode({keyMethod: method, 'env': 'pro', keyResult: result}),
      );
      var target = replyMode == ReplyMode.sourcePort
          ? datagram.port
          : replyToPort;
      socket.send(reply, datagram.address, target);
    }, onError: (Object _) {});

    return bulb;
  }

  void close() => _socket.close();
}
```

- [ ] **Step 3: Point discovery_test.dart at the support file**

In `test/discovery_test.dart` delete lines 8–90 (the `ReplyMode` enum and `FakeBulb` class) and replace the imports at the top with:

```dart
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:wizctl/wizctl.dart';

import 'support/fake_bulb.dart';
```

Remove the now-unused `dart:convert` import.

- [ ] **Step 4: Run the suite to verify nothing changed**

Run: `dart test test/discovery_test.dart`
Expected: all tests PASS (same count as before the move).

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib bin test example
dart analyze --fatal-infos lib bin test example
git add test/support/fake_bulb.dart test/discovery_test.dart
git commit -m "test: share the FakeBulb harness across test files"
```

---

### Task 2: ScanEvent types and a streaming probeAddresses

**Files:**
- Create: `lib/src/scan_event.dart`
- Modify: `lib/src/discovery.dart:1249-1349` (`probeAddresses` becomes a collector over the new stream)
- Modify: `lib/wizctl.dart` (export)
- Test: `test/scan_stream_test.dart`

**Interfaces:**
- Produces:

```dart
sealed class ScanEvent { const ScanEvent(); }
final class ScanProgress extends ScanEvent {
  final int addressesProbed;   // distinct addresses probed at least once so far; never decreases
  final int addressCount;      // addresses in this scan
  final double fraction;       // overall completion in [0, 1], counting every round
  final String? subnet;        // "192.168.1" for a subnet sweep, null for an address list
}
final class ScanFound extends ScanEvent { final DiscoveredLight light; }    // first reply from a MAC
final class ScanUpdated extends ScanEvent { final DiscoveredLight light; }  // richer reply for a MAC already found
final class ScanDone extends ScanEvent { final List<DiscoveredLight> lights; }
static Stream<ScanEvent> WizDiscovery.probeAddressesStream({required Iterable<String> addresses, Duration timeout = defaultDiscoveryTimeout, int port = wizPort, int localPort = wizPort, InternetAddress? bindAddress, int rounds = subnetScanRounds, String? subnet});
```

- [ ] **Step 1: Write the failing tests**

Create `test/scan_stream_test.dart`:

```dart
import 'dart:async';

import 'package:test/test.dart';
import 'package:wizctl/wizctl.dart';

import 'support/fake_bulb.dart';

void main() {
  group('WizDiscovery.probeAddressesStream', () {
    const bulbPort = 39421;
    const replyPort = 39422;

    test('emits progress, found and done for a single reachable bulb',
        () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
      );
      addTearDown(bulb.close);

      var events = await WizDiscovery.probeAddressesStream(
        addresses: const ['127.0.0.1'],
        port: bulbPort,
        localPort: replyPort,
        timeout: Duration(seconds: 2),
        rounds: 1,
      ).toList();

      expect(events.first, isA<ScanProgress>());
      var progress = events.whereType<ScanProgress>().toList();
      expect(progress.last.addressesProbed, 1);
      expect(progress.last.addressCount, 1);
      expect(progress.last.fraction, 1.0);
      expect(progress.last.subnet, isNull);
      expect(events.whereType<ScanFound>(), hasLength(1));
      expect(events.whereType<ScanFound>().single.light.mac, 'a8bb50aabbcc');
      expect(events.last, isA<ScanDone>());
      expect((events.last as ScanDone).lights, hasLength(1));
    });

    test('progress never decreases across rounds', () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
      );
      addTearDown(bulb.close);

      var progress = await WizDiscovery.probeAddressesStream(
        addresses: const ['127.0.0.1', '127.0.0.2', '127.0.0.3'],
        port: bulbPort,
        localPort: replyPort,
        timeout: Duration(seconds: 3),
        rounds: 2,
      ).where((e) => e is ScanProgress).cast<ScanProgress>().toList();

      for (var i = 1; i < progress.length; i++) {
        expect(progress[i].addressesProbed,
            greaterThanOrEqualTo(progress[i - 1].addressesProbed));
        expect(progress[i].fraction,
            greaterThanOrEqualTo(progress[i - 1].fraction));
      }
      expect(progress.last.addressesProbed, 3);
      expect(progress.last.fraction, 1.0);
      expect(progress.first.fraction, lessThan(1.0));
    });

    test('reports an updated light when the richer reply lands later',
        () async {
      // getSystemConfig and getPilot are both sent; whichever answers second
      // that carries more detail must surface as ScanUpdated, and ScanDone
      // must hold the richer record.
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
      );
      addTearDown(bulb.close);

      var events = await WizDiscovery.probeAddressesStream(
        addresses: const ['127.0.0.1'],
        port: bulbPort,
        localPort: replyPort,
        timeout: Duration(seconds: 2),
        rounds: 1,
      ).toList();

      var done = events.last as ScanDone;
      expect(done.lights.single.moduleName, 'ESP01_SHRGB_03');
      var found = events.whereType<ScanFound>().single;
      if (found.light.moduleName == null) {
        expect(events.whereType<ScanUpdated>(), isNotEmpty);
      }
    });

    test('cancelling stops probing', () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
      );
      addTearDown(bulb.close);

      var firstProgress = Completer<void>();
      var subscription = WizDiscovery.probeAddressesStream(
        addresses: const ['127.0.0.1'],
        port: bulbPort,
        localPort: replyPort,
        timeout: Duration(seconds: 3),
        rounds: 2,
      ).listen((event) {
        if (event is ScanProgress && !firstProgress.isCompleted) {
          firstProgress.complete();
        }
      });
      await firstProgress.future;
      await subscription.cancel();

      // Round two would fire after subnetScanRoundInterval (800ms). Two
      // probes per address were sent in round one; no more may arrive.
      await Future.delayed(Duration(milliseconds: 1500));
      expect(bulb.requestCount, 2);
    });

    test('an empty address list completes with an empty ScanDone', () async {
      var events = await WizDiscovery.probeAddressesStream(
        addresses: const [],
        port: bulbPort,
        localPort: replyPort,
      ).toList();
      expect(events, hasLength(1));
      expect(events.single, isA<ScanDone>());
      expect((events.single as ScanDone).lights, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/scan_stream_test.dart`
Expected: compile error, `probeAddressesStream` and `ScanEvent` undefined.

- [ ] **Step 3: Add the event types**

Create `lib/src/scan_event.dart`:

```dart
import 'state.dart';

/// What a streaming scan reports while it runs.
///
/// Consumers that only want the result can wait for [ScanDone]; a UI can show
/// [ScanProgress] as a determinate bar and list lights as [ScanFound] arrives.
sealed class ScanEvent {
  const ScanEvent();
}

/// A batch of probes has been sent.
final class ScanProgress extends ScanEvent {
  /// Distinct addresses probed at least once so far. Never decreases, so it
  /// can be shown as "n of 254 addresses" even though every address is probed
  /// more than once.
  final int addressesProbed;

  /// Number of addresses in this scan.
  final int addressCount;

  /// Overall completion in `[0, 1]`, counting every round.
  final double fraction;

  /// The `a.b.c` prefix being swept, or null when probing an address list.
  final String? subnet;

  const ScanProgress({
    required this.addressesProbed,
    required this.addressCount,
    required this.fraction,
    this.subnet,
  });

  @override
  String toString() =>
      'ScanProgress($addressesProbed/$addressCount, ${(fraction * 100).round()}%)';
}

/// A light answered for the first time.
final class ScanFound extends ScanEvent {
  final DiscoveredLight light;
  const ScanFound(this.light);
}

/// A light already reported by [ScanFound] answered again with more detail
/// (a `getSystemConfig` reply landing after a `getPilot` one).
final class ScanUpdated extends ScanEvent {
  final DiscoveredLight light;
  const ScanUpdated(this.light);
}

/// The scan finished; [lights] is the deduplicated result.
final class ScanDone extends ScanEvent {
  final List<DiscoveredLight> lights;
  const ScanDone(this.lights);
}
```

- [ ] **Step 4: Implement probeAddressesStream and make probeAddresses a collector**

In `lib/src/discovery.dart` add `import 'scan_event.dart';` and replace the whole `probeAddresses` method (lines 1235–1349 of the original file, dartdoc included) with:

```dart
  /// Asks specific addresses whether a light is listening there.
  ///
  /// This is the reliable half of [scanSubnet]. Probing a handful of known
  /// addresses succeeds where sweeping a whole subnet does not, and the reason
  /// is the kernel rather than the lights: `net.link.ether.inet.maxhold` caps
  /// how many datagrams may be queued awaiting ARP resolution (16 on macOS).
  /// Sweeping a /24 queues one against every empty address, the hold queue
  /// overflows, and probes aimed at addresses that *do* have a light behind
  /// them get dropped along with the rest. The table only drains on
  /// `net.link.ether.inet.prune_intvl`, so a sweep can stay unproductive for
  /// minutes afterwards. Probing addresses you already know never fills it.
  ///
  /// Prefer this for lights already in a config file, and fall back to
  /// [scanSubnet] to find ones you have not seen before. For progress and
  /// lights as they answer, use [probeAddressesStream].
  static Future<List<DiscoveredLight>> probeAddresses({
    required Iterable<String> addresses,
    Duration timeout = defaultDiscoveryTimeout,
    int port = wizPort,
    int localPort = wizPort,
    InternetAddress? bindAddress,
    int rounds = subnetScanRounds,
  }) async {
    await for (var event in probeAddressesStream(
      addresses: addresses,
      timeout: timeout,
      port: port,
      localPort: localPort,
      bindAddress: bindAddress,
      rounds: rounds,
    )) {
      if (event is ScanDone) return event.lights;
    }
    return [];
  }

  /// Streaming form of [probeAddresses].
  ///
  /// Emits a [ScanProgress] after every batch of probes, a [ScanFound] the
  /// first time a MAC answers, a [ScanUpdated] when a richer reply for that
  /// MAC lands later, and finally one [ScanDone]. Cancelling the subscription
  /// stops probing and closes the socket. Each address is probed with both
  /// `getSystemConfig` and `getPilot` (see [probeAddresses] for why).
  ///
  /// [subnet] is only carried through into [ScanProgress.subnet] so a caller
  /// sweeping a subnet can show it; it does not change what is probed.
  static Stream<ScanEvent> probeAddressesStream({
    required Iterable<String> addresses,
    Duration timeout = defaultDiscoveryTimeout,
    int port = wizPort,
    int localPort = wizPort,
    InternetAddress? bindAddress,
    int rounds = subnetScanRounds,
    String? subnet,
  }) {
    var targets = addresses.toList();
    late StreamController<ScanEvent> controller;
    RawDatagramSocket? socket;
    var cancelled = false;

    Future<void> run() async {
      if (targets.isEmpty) {
        controller.add(const ScanDone([]));
        await controller.close();
        return;
      }
      StreamSubscription<RawSocketEvent>? subscription;
      try {
        socket = await WizProtocol.openBroadcastSocket(
          localPort: localPort,
          bindAddress: bindAddress,
        );
        if (cancelled) return;
        var s = socket!;

        // Keyed by MAC: a bulb answers both probes, and the two replies carry
        // different amounts of detail.
        var byMac = <String, DiscoveredLight>{};

        subscription = s.listen((event) {
          if (event != RawSocketEvent.read) return;
          var datagram = s.receive();
          if (datagram == null) return;
          try {
            var response =
                jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
            // Requests carry `params`, replies carry `result`; skip our own.
            if (response.containsKey(keyParams)) return;

            var light = DiscoveredLight.fromJson(
              response,
              datagram.address.address,
            );
            if (light.mac.isEmpty) return;

            var known = byMac[light.mac];
            if (known == null) {
              byMac[light.mac] = light;
              WizLogger.info('Found ${light.mac} at ${light.ip}');
              if (!cancelled) controller.add(ScanFound(light));
            } else if (known.moduleName == null && light.moduleName != null) {
              // A getSystemConfig reply landing after a getPilot one: keep
              // the richer of the two.
              byMac[light.mac] = light;
              if (!cancelled) controller.add(ScanUpdated(light));
            }
          } catch (_) {
            // Ignore malformed responses
          }
        }, onError: _ignoreAsyncSocketError);

        var probes = [
          utf8.encode(
            jsonEncode({keyMethod: methodGetSystemConfig, keyParams: {}}),
          ),
          utf8.encode(jsonEncode({keyMethod: methodGetPilot, keyParams: {}})),
        ];
        var deadline = DateTime.now().add(timeout);
        var slots = targets.length * rounds;

        for (var round = 0; round < rounds && !cancelled; round++) {
          if (round > 0) await Future.delayed(subnetScanRoundInterval);
          if (cancelled) break;

          var sent = 0;
          var unreachable = 0;
          for (
            var start = 0;
            start < targets.length && !cancelled;
            start += subnetScanBatchSize
          ) {
            var batch = targets.skip(start).take(subnetScanBatchSize).toList();
            for (var ip in batch) {
              var address = InternetAddress(ip);
              for (var probe in probes) {
                // Failures here are reported asynchronously (see
                // [_ignoreAsyncSocketError]), but guard anyway: a synchronous
                // throw for one address must not abort the rest.
                try {
                  s.send(probe, address, port);
                } on SocketException {
                  unreachable++;
                }
              }
            }
            sent += batch.length;
            controller.add(
              ScanProgress(
                addressesProbed: round == 0 ? sent : targets.length,
                addressCount: targets.length,
                fraction: (round * targets.length + sent) / slots,
                subnet: subnet,
              ),
            );
            // Let the ARP hold queue drain before queuing the next batch.
            await Future.delayed(subnetScanBatchInterval);
          }
          WizLogger.verbose(
            'Round ${round + 1}/$rounds probed ${targets.length} address(es) '
            '($unreachable unreachable)',
          );
        }

        if (!cancelled) {
          // Collect for whatever is left of the window.
          var remaining = deadline.difference(DateTime.now());
          if (remaining > Duration.zero) await Future.delayed(remaining);
        }
        if (!cancelled) controller.add(ScanDone(byMac.values.toList()));
      } catch (e, st) {
        if (!cancelled) controller.addError(e, st);
      } finally {
        await subscription?.cancel();
        socket?.close();
        if (!controller.isClosed) await controller.close();
      }
    }

    controller = StreamController<ScanEvent>(
      onListen: run,
      onCancel: () {
        cancelled = true;
        // Closing the socket here makes an in-flight send fail fast instead
        // of the loop running to its next await.
        socket?.close();
      },
    );
    return controller.stream;
  }
```

Add the export to `lib/wizctl.dart`:

```dart
export 'src/scan_event.dart';
```

- [ ] **Step 5: Run the new and the old tests**

Run: `dart test test/scan_stream_test.dart test/discovery_test.dart`
Expected: all PASS. The old `probeAddresses` tests exercise the collector path.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib bin test example
dart analyze --fatal-infos lib bin test example
git add lib/src/scan_event.dart lib/src/discovery.dart lib/wizctl.dart test/scan_stream_test.dart
git commit -m "feat: stream progress and lights from probeAddresses"
```

---

### Task 3: scanSubnetStream

**Files:**
- Modify: `lib/src/discovery.dart` (`scanSubnet` becomes a collector; add `scanSubnetStream`)
- Test: `test/scan_stream_test.dart` (append a group)

**Interfaces:**
- Consumes: `probeAddressesStream`, `ScanEvent` types from Task 2.
- Produces: `static Stream<ScanEvent> WizDiscovery.scanSubnetStream({String? subnet, Duration timeout = defaultDiscoveryTimeout, int port = wizPort, int localPort = wizPort, InternetAddress? bindAddress, int rounds = subnetScanRounds})`. Progress is cumulative across the 64-address chunks, `subnet` is the swept prefix, and a chunk that fails outright is logged and skipped without losing earlier finds.

- [ ] **Step 1: Write the failing tests**

Append to `test/scan_stream_test.dart` inside `main()`:

```dart
  group('WizDiscovery.scanSubnetStream', () {
    const unusedPort = 39423;

    test('sweeps a whole /24 with cumulative progress and finishes empty',
        () async {
      // TEST-NET-1 is reserved and unroutable, so nothing answers and every
      // send fails asynchronously; the stream must still progress to the
      // end and finish with an empty ScanDone.
      var events = await WizDiscovery.scanSubnetStream(
        subnet: '192.0.2',
        port: unusedPort,
        localPort: 0,
        timeout: Duration(seconds: 1),
        rounds: 1,
      ).toList();

      var progress = events.whereType<ScanProgress>().toList();
      expect(progress, isNotEmpty);
      expect(progress.every((p) => p.subnet == '192.0.2'), isTrue);
      expect(progress.every((p) => p.addressCount == 254), isTrue);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i].addressesProbed,
            greaterThanOrEqualTo(progress[i - 1].addressesProbed));
      }
      expect(progress.last.addressesProbed, 254);
      expect(progress.last.fraction, closeTo(1.0, 0.001));
      expect(events.last, isA<ScanDone>());
      expect((events.last as ScanDone).lights, isEmpty);
    });

    test('scanSubnet still returns the collected list', () async {
      var lights = await WizDiscovery.scanSubnet(
        subnet: '192.0.2',
        port: unusedPort,
        localPort: 0,
        timeout: Duration(seconds: 1),
        rounds: 1,
      );
      expect(lights, isEmpty);
    });

    test('cancelling a sweep completes without a ScanDone', () async {
      var received = <ScanEvent>[];
      var subscription = WizDiscovery.scanSubnetStream(
        subnet: '192.0.2',
        port: unusedPort,
        localPort: 0,
        timeout: Duration(seconds: 1),
        rounds: 1,
      ).listen(received.add);
      await Future.delayed(Duration(milliseconds: 600));
      await subscription.cancel();
      await Future.delayed(Duration(seconds: 2));
      expect(received.whereType<ScanDone>(), isEmpty);
      expect(received.whereType<ScanProgress>().last.addressesProbed,
          lessThan(254));
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/scan_stream_test.dart`
Expected: compile error, `scanSubnetStream` undefined.

- [ ] **Step 3: Implement scanSubnetStream and make scanSubnet a collector**

In `lib/src/discovery.dart` replace the whole `scanSubnet` method (its dartdoc included) with:

```dart
  /// Finds lights by probing every address on a subnet directly, one at a time.
  ///
  /// Use this when [discover] comes back empty on a network where the lights
  /// are demonstrably reachable. On some networks lights never answer the
  /// discovery broadcast even though they respond to unicast immediately —
  /// access points filter broadcast to wireless clients, and Wi-Fi power save
  /// on the bulb means broadcast frames are only delivered on the access
  /// point's DTIM schedule and are easily missed. Either way no implementation
  /// of the WiZ protocol can find those lights by broadcasting, while asking
  /// each address in turn works reliably.
  ///
  /// [subnet] is the first three octets to scan, e.g. `'192.168.0'`, and
  /// defaults to this machine's own subnet (a /24 is assumed: Dart's
  /// [NetworkInterface] does not expose netmasks). [rounds] defaults to 2 so
  /// a cold ARP cache does not hide lights. Probes go out in batches (see
  /// [subnetScanBatchSize]), so a /24 takes several seconds per round whatever
  /// [timeout] says; [timeout] governs how long to keep listening after the
  /// last probe of each chunk. For progress use [scanSubnetStream].
  ///
  /// **Returns:** The lights that answered, deduplicated by MAC address.
  static Future<List<DiscoveredLight>> scanSubnet({
    String? subnet,
    Duration timeout = defaultDiscoveryTimeout,
    int port = wizPort,
    int localPort = wizPort,
    InternetAddress? bindAddress,
    int rounds = subnetScanRounds,
  }) async {
    await for (var event in scanSubnetStream(
      subnet: subnet,
      timeout: timeout,
      port: port,
      localPort: localPort,
      bindAddress: bindAddress,
      rounds: rounds,
    )) {
      if (event is ScanDone) return event.lights;
    }
    return [];
  }

  /// Streaming form of [scanSubnet].
  ///
  /// Progress is cumulative over the whole /24 even though the sweep runs in
  /// chunks of [subnetScanChunkSize] addresses on fresh sockets. A chunk that
  /// fails outright is logged and skipped so lights already found are kept.
  /// Cancelling the subscription stops the sweep.
  static Stream<ScanEvent> scanSubnetStream({
    String? subnet,
    Duration timeout = defaultDiscoveryTimeout,
    int port = wizPort,
    int localPort = wizPort,
    InternetAddress? bindAddress,
    int rounds = subnetScanRounds,
  }) {
    late StreamController<ScanEvent> controller;
    StreamSubscription<ScanEvent>? inner;
    var cancelled = false;

    Future<void> run() async {
      try {
        var base = subnet ?? await _defaultSubnetBase();
        if (base == null) {
          throw WizConnectionError('Could not determine a local subnet to scan');
        }
        var skip = await _localAddresses();
        var addresses = [
          for (var host = 1; host <= 254; host++)
            if (!skip.contains('$base.$host')) '$base.$host',
        ];
        WizLogger.info('Scanning $base.1-254 on port $port');

        var byMac = <String, DiscoveredLight>{};
        var probedBefore = 0;
        for (
          var start = 0;
          start < addresses.length && !cancelled;
          start += subnetScanChunkSize
        ) {
          var chunk = addresses.skip(start).take(subnetScanChunkSize).toList();
          // Forward the chunk's events, rebasing progress onto the whole
          // address list. A completer bridges the inner subscription so
          // cancellation can reach it.
          var chunkDone = Completer<void>();
          inner = probeAddressesStream(
            addresses: chunk,
            timeout: timeout,
            port: port,
            localPort: localPort,
            bindAddress: bindAddress,
            rounds: rounds,
            subnet: base,
          ).listen(
            (event) {
              if (cancelled) return;
              switch (event) {
                case ScanProgress p:
                  controller.add(
                    ScanProgress(
                      addressesProbed: probedBefore + p.addressesProbed,
                      addressCount: addresses.length,
                      fraction:
                          (probedBefore + p.fraction * chunk.length) /
                          addresses.length,
                      subnet: base,
                    ),
                  );
                case ScanFound f:
                  var known = byMac[f.light.mac];
                  if (known == null) {
                    byMac[f.light.mac] = f.light;
                    controller.add(f);
                  } else if (known.moduleName == null &&
                      f.light.moduleName != null) {
                    byMac[f.light.mac] = f.light;
                    controller.add(ScanUpdated(f.light));
                  }
                case ScanUpdated u:
                  byMac[u.light.mac] = u.light;
                  controller.add(u);
                case ScanDone _:
                  break;
              }
            },
            onError: (Object e) {
              // A chunk that fails outright must not lose the ones already
              // found.
              WizLogger.warn(
                'Scan chunk ${chunk.first}-${chunk.last} failed: $e',
              );
            },
            onDone: () {
              if (!chunkDone.isCompleted) chunkDone.complete();
            },
            cancelOnError: true,
          );
          await chunkDone.future;
          probedBefore += chunk.length;
        }
        if (!cancelled) controller.add(ScanDone(byMac.values.toList()));
      } catch (e, st) {
        if (!cancelled) controller.addError(e, st);
      } finally {
        if (!controller.isClosed) await controller.close();
      }
    }

    controller = StreamController<ScanEvent>(
      onListen: run,
      onCancel: () async {
        cancelled = true;
        await inner?.cancel();
      },
    );
    return controller.stream;
  }
```

Note: when a chunk's inner stream errors with `cancelOnError: true`, `onDone` is not called; `onError` must therefore complete the completer too. Change the `onError` handler to:

```dart
            onError: (Object e) {
              WizLogger.warn(
                'Scan chunk ${chunk.first}-${chunk.last} failed: $e',
              );
              if (!chunkDone.isCompleted) chunkDone.complete();
            },
```

- [ ] **Step 4: Run the tests**

Run: `dart test test/scan_stream_test.dart test/discovery_test.dart`
Expected: all PASS (the sweep tests take about 10 s each; that is expected).

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib bin test example
dart analyze --fatal-infos lib bin test example
git add lib/src/discovery.dart test/scan_stream_test.dart
git commit -m "feat: stream progress and lights from a subnet sweep"
```

---

### Task 4: ControlSignal.fromState

**Files:**
- Modify: `lib/src/control_signal.dart` (add the factory after the named constructors)
- Test: `test/control_signal_from_state_test.dart`

**Interfaces:**
- Produces: `factory ControlSignal.fromState(LightState state)`.

- [ ] **Step 1: Write the failing tests**

Create `test/control_signal_from_state_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:wizctl/wizctl.dart';

void main() {
  group('ControlSignal.fromState', () {
    test('restores a scene with its speed and brightness', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: true, dimming: 80, sceneId: 6, speed: 120),
      );
      expect(signal.toJson(), {
        keyState: true,
        keyDimming: 80,
        keySceneId: 6,
        keySpeed: 120,
      });
    });

    test('a scene wins over colour and temperature values also present', () {
      // Bulbs report the last colour alongside an active scene.
      var signal = ControlSignal.fromState(
        const LightState(
          isOn: true,
          dimming: 50,
          sceneId: 1,
          r: 255,
          g: 0,
          b: 0,
          temperature: 2700,
        ),
      );
      expect(signal.toJson(), {
        keyState: true,
        keyDimming: 50,
        keySceneId: 1,
      });
    });

    test('restores a colour temperature', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: true, dimming: 70, temperature: 2700),
      );
      expect(signal.toJson(), {
        keyState: true,
        keyDimming: 70,
        keyTemperature: 2700,
      });
    });

    test('restores an rgb colour with its white channels', () {
      var signal = ControlSignal.fromState(
        const LightState(
          isOn: true,
          dimming: 40,
          r: 255,
          g: 120,
          b: 60,
          coldWhite: 0,
          warmWhite: 30,
        ),
      );
      expect(signal.toJson(), {
        keyState: true,
        keyDimming: 40,
        keyRed: 255,
        keyGreen: 120,
        keyBlue: 60,
        keyColdWhite: 0,
        keyWarmWhite: 30,
      });
    });

    test('restores bare white channels', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: true, warmWhite: 200),
      );
      expect(signal.toJson(), {keyState: true, keyWarmWhite: 200});
    });

    test('an off light restores as off with its channel', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: false, dimming: 30, temperature: 4000),
      );
      expect(signal.state, isFalse);
      expect(signal.temperature, 4000);
    });

    test('scene id 0 means no scene', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: true, sceneId: 0, temperature: 3000),
      );
      expect(signal.sceneId, isNull);
      expect(signal.temperature, 3000);
    });

    test('never throws for out-of-range values a bulb reported', () {
      var signal = ControlSignal.fromState(
        const LightState(
          isOn: true,
          dimming: 5,
          sceneId: 4,
          speed: 500,
          temperature: 20000,
        ),
      );
      expect(signal.dimming, minBrightness);
      expect(signal.speed, maxSpeed);
    });

    test('drops an unsupported temperature instead of throwing', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: true, temperature: 20000, r: 1, g: 2, b: 3),
      );
      expect(signal.temperature, isNull);
      expect(signal.r, 1);
    });

    test('a state with no channel restores power and brightness only', () {
      var signal = ControlSignal.fromState(
        const LightState(isOn: true, dimming: 100),
      );
      expect(signal.toJson(), {keyState: true, keyDimming: 100});
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/control_signal_from_state_test.dart`
Expected: compile error, `ControlSignal.fromState` undefined.

- [ ] **Step 3: Implement the factory**

In `lib/src/control_signal.dart` add `import 'state.dart';` and insert after `ControlSignal.speed(int value) : this(speed: value);`:

```dart
  /// The signal that puts a light back into [state].
  ///
  /// Built for "blink to identify": capture with `getState()`, drive the bulb,
  /// then send this to restore it. Exactly one channel is chosen, in the
  /// order the bulb itself prioritises: an active scene (id > 0) wins over a
  /// colour temperature, which wins over RGB, which wins over bare white
  /// channels. Bulbs report the last colour alongside an active scene, so
  /// sending everything back would not restore what the user saw.
  ///
  /// Values a bulb reported are trusted but clamped rather than rejected, so
  /// this never throws: brightness to 10–100, speed to 10–200. A colour
  /// temperature outside 1000–10000 K is dropped.
  factory ControlSignal.fromState(LightState state) {
    var dimming = state.dimming?.clamp(minBrightness, maxBrightness);
    var scene = state.sceneId;
    if (scene != null && scene > 0) {
      return ControlSignal(
        state: state.isOn,
        dimming: dimming,
        sceneId: scene,
        speed: state.speed?.clamp(minSpeed, maxSpeed),
      );
    }
    var temperature = state.temperature;
    if (temperature != null &&
        temperature >= minTemperature &&
        temperature <= maxTemperature) {
      return ControlSignal(
        state: state.isOn,
        dimming: dimming,
        temperature: temperature,
      );
    }
    if (state.r != null && state.g != null && state.b != null) {
      return ControlSignal(
        state: state.isOn,
        dimming: dimming,
        r: state.r!.clamp(minColorValue, maxColorValue),
        g: state.g!.clamp(minColorValue, maxColorValue),
        b: state.b!.clamp(minColorValue, maxColorValue),
        coldWhite: state.coldWhite?.clamp(minColorValue, maxColorValue),
        warmWhite: state.warmWhite?.clamp(minColorValue, maxColorValue),
      );
    }
    return ControlSignal(
      state: state.isOn,
      dimming: dimming,
      coldWhite: state.coldWhite?.clamp(minColorValue, maxColorValue),
      warmWhite: state.warmWhite?.clamp(minColorValue, maxColorValue),
    );
  }
```

- [ ] **Step 4: Run the tests**

Run: `dart test test/control_signal_from_state_test.dart`
Expected: all PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib bin test example
dart analyze --fatal-infos lib bin test example
git add lib/src/control_signal.dart test/control_signal_from_state_test.dart
git commit -m "feat: build a restore signal from a captured LightState"
```

---

### Task 5: Retry configuration on WizLight

**Files:**
- Modify: `lib/src/light.dart` (field, constructor, every `WizProtocol.send` call)
- Test: `test/light_retry_test.dart`

**Interfaces:**
- Produces: `WizLight(String ip, {int port = wizPort, Duration timeout = defaultTimeout, RetryConfig? retry})` with `final RetryConfig? retry;` forwarded as `retry: retry` to every `WizProtocol.send` in the class. `null` keeps the library default.

- [ ] **Step 1: Write the failing tests**

Create `test/light_retry_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:wizctl/wizctl.dart';

import 'support/fake_bulb.dart';

void main() {
  group('WizLight retry', () {
    const bulbPort = 39431;

    test('a light exposes its retry config', () {
      var light = WizLight(
        '192.168.1.100',
        retry: const RetryConfig.fixed(
          count: 2,
          interval: Duration(milliseconds: 100),
        ),
      );
      expect(light.retry?.count, 2);
      expect(WizLight('192.168.1.100').retry, isNull);
    });

    test('three attempts reach a bulb that drops the first two', () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
        ignoreFirst: 2,
      );
      addTearDown(bulb.close);

      var light = WizLight(
        '127.0.0.1',
        port: bulbPort,
        timeout: Duration(milliseconds: 300),
        retry: const RetryConfig.fixed(
          count: 2,
          interval: Duration(milliseconds: 50),
        ),
      );
      var state = await light.getState();
      expect(state.isOn, isTrue);
      expect(bulb.requestCount, 3);
    });

    test('a single attempt times out against the same bulb', () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
        ignoreFirst: 1,
      );
      addTearDown(bulb.close);

      var light = WizLight(
        '127.0.0.1',
        port: bulbPort,
        timeout: Duration(milliseconds: 300),
        retry: const RetryConfig.none(),
      );
      await expectLater(light.getState(), throwsA(isA<WizTimeoutError>()));
      expect(bulb.requestCount, 1);
    });

    test('send honours the retry config too', () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
        ignoreFirst: 1,
      );
      addTearDown(bulb.close);

      var light = WizLight(
        '127.0.0.1',
        port: bulbPort,
        timeout: Duration(milliseconds: 300),
        retry: const RetryConfig.fixed(
          count: 1,
          interval: Duration(milliseconds: 50),
        ),
      );
      await light.send(ControlSignal.on());
      expect(bulb.requestCount, 2);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/light_retry_test.dart`
Expected: compile error, no named parameter `retry`.

- [ ] **Step 3: Add the field and forward it**

In `lib/src/light.dart` add `import 'retry_config.dart';`, then change the fields and constructor to:

```dart
  final String ip;

  /// The UDP port to communicate on (default: 38899).
  final int port;

  /// Per-attempt timeout for UDP operations.
  final Duration timeout;

  /// Retry strategy for every request this light sends.
  ///
  /// `null` keeps the library default (six attempts with exponential
  /// backoff). An interactive client wants something tighter, for instance
  /// three attempts with a one-second timeout, so a dead bulb is reported in
  /// a few seconds rather than twenty.
  final RetryConfig? retry;

  /// Cached bulb configuration.
  BulbConfig? _cachedConfig;

  /// Creates a new [WizLight] instance.
  ///
  /// [ip] - The IP address of the WiZ light.
  /// [port] - The UDP port (defaults to [wizPort]).
  /// [timeout] - Per-attempt timeout (defaults to [defaultTimeout]).
  /// [retry] - Retry strategy (defaults to the library default).
  WizLight(
    this.ip, {
    this.port = wizPort,
    this.timeout = defaultTimeout,
    this.retry,
  });
```

Then add `retry: retry,` to every `WizProtocol.send(` call in the class: `getState`, `getSystemConfig`, `getKelvinRange`, `send`, `reboot`, `reset`. For example `send` becomes:

```dart
  Future<void> send(ControlSignal signal) async {
    await WizProtocol.send(
      ip: ip,
      message: signal.toMessage(),
      port: port,
      timeout: timeout,
      retry: retry,
    );
  }
```

Leave `==` and `hashCode` as they are (identity is ip and port).

- [ ] **Step 4: Run the tests**

Run: `dart test test/light_retry_test.dart test/wizctl_test.dart`
Expected: all PASS.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib bin test example
dart analyze --fatal-infos lib bin test example
git add lib/src/light.dart test/light_retry_test.dart
git commit -m "feat: let WizLight carry a retry config"
```

---

### Task 6: Release housekeeping for 1.1.0

**Files:**
- Modify: `pubspec.yaml` (version), `lib/src/constants.dart` (`cliVersion`), `CHANGELOG.md`, `README.md` (streaming snippet), `example/wizctl_example.dart` (stream example)

- [ ] **Step 1: Bump versions and changelog**

`pubspec.yaml`: `version: 1.1.0`. `lib/src/constants.dart`: `const String cliVersion = '1.1.0';`. `CHANGELOG.md` becomes:

```markdown
## 1.1.0

- `WizDiscovery.scanSubnetStream` and `WizDiscovery.probeAddressesStream` report
  progress and lights as they answer (`ScanProgress`, `ScanFound`, `ScanUpdated`,
  `ScanDone`); cancelling the subscription stops the scan. `scanSubnet` and
  `probeAddresses` are unchanged and now built on them.
- `ControlSignal.fromState` builds the signal that restores a captured
  `LightState`, for blink-to-identify.
- `WizLight` accepts a `retry` configuration used by every request it sends.

## 1.0.0

- Initial release
```

- [ ] **Step 2: Document the stream in README and the example**

In `README.md`, after the `scanSubnet` Dart snippet in "When discovery finds nothing", add:

```markdown
For a progress bar and lights as they answer, use the streaming form:

```dart
await for (var event in WizDiscovery.scanSubnetStream()) {
  switch (event) {
    case ScanProgress p:
      print('${p.addressesProbed} of ${p.addressCount} addresses');
    case ScanFound f:
      print('Found ${f.light.ip}');
    case ScanUpdated _:
      break;
    case ScanDone d:
      print('${d.lights.length} lights');
  }
}
```
```

In `README.md` "Control Examples" add:

```dart
// Blink to identify: capture, drive, restore
final captured = await light.getState();
await light.send(ControlSignal(state: true, r: 255, g: 176, b: 32, dimming: 100));
await Future.delayed(Duration(seconds: 2));
await light.send(ControlSignal.fromState(captured));

// Tighter retries for an interactive client
final quick = WizLight(
  '192.168.1.100',
  timeout: Duration(seconds: 1),
  retry: RetryConfig.exponential(count: 2, initialInterval: Duration(milliseconds: 250), maxInterval: Duration(seconds: 1)),
);
```

In `example/wizctl_example.dart` after the existing discovery section add:

```dart
  // Streaming discovery: progress and lights as they answer
  await for (var event in WizDiscovery.scanSubnetStream(
    timeout: Duration(seconds: 3),
  )) {
    if (event is ScanProgress) {
      print('Probed ${event.addressesProbed} of ${event.addressCount}');
    } else if (event is ScanFound) {
      print('Found ${event.light.ip} (${event.light.mac})');
    }
  }
```

- [ ] **Step 3: Run the full CI set**

```bash
dart format --output=none --set-exit-if-changed lib bin test example
dart analyze --fatal-infos lib bin test example
dart test
dart pub publish --dry-run
```
Expected: format clean, analyze clean, all tests pass, dry run reports 0 warnings.

- [ ] **Step 4: Commit and push, open the PR**

```bash
git add pubspec.yaml lib/src/constants.dart CHANGELOG.md README.md example/wizctl_example.dart
git commit -m "chore: prepare 1.1.0 release"
git push -u origin sharma/app-support
gh pr create --title "feat: streaming discovery, state restore, retry on WizLight (1.1.0)" --body "$(cat <<'PRBODY'
## Summary
- `WizDiscovery.scanSubnetStream` / `probeAddressesStream` with cancellation
- `ControlSignal.fromState` for blink-to-identify
- `retry` on `WizLight`
- Version 1.1.0

Needed by the WizCtl Flutter app (spec in wizctl_app/docs/superpowers/specs).

## Test plan
- [ ] `dart test` green locally and in CI
- [ ] `dart pub publish --dry-run` clean

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01LHFwuJ7FsQYePfr5j1T1Pe
PRBODY
)"
```

Do not merge or publish; the user decides when to merge and whether to publish to pub.dev.
