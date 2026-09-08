# Plan 3: WizCtl Domain, Data and Services Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and fully test the app's logic layer: domain entities and rules, the live-state store, the command pipeline, sync and network services, every use case, the drift database and repositories, the device gateway over `wizctl` 1.1.0, the CLI config exporter, and one composition root that Plan 4's screens plug into.

**Architecture:** Clean architecture with the dependency rule pointing inward. `lib/domain` is pure Dart (it imports `wizctl` only for its value types: `BulbClass`, `WizScene`, `ControlSignal`, `LightState`, `DiscoveredLight`, `BulbConfig`, `ScanEvent`, `RetryConfig`). `lib/data` implements the domain's repository and gateway interfaces with drift, `WizLight`/`WizDiscovery`, `dart:io` networking and the file system. `lib/app/dependencies.dart` wires everything once. "Streams in, use cases out": blocs (Plan 4) subscribe to repository and store streams and call use cases; nothing in this plan imports Flutter widgets.

**Tech Stack:** Dart 3.13, `wizctl` 1.1.0 (Plan 1), `drift` + `drift_flutter` + `drift_dev`, `equatable`, `uuid`, `mocktail`, `fake_async`, `flutter_test`.

**Spec:** `/Users/bharat/Bharat/github/wizctl_app/docs/superpowers/specs/2026-09-08-wizctl-app-design.md` §3 to §9, §16, §18, §19.

## Global Constraints

- Project root `/Users/bharat/Bharat/github/wizctl_app`; Plan 2 Task 1 must have run (project scaffolded, `wizctl` resolvable through `pubspec_overrides.yaml`). Plans 2 and 3 are otherwise independent and may run in parallel on separate branches; merge Plan 2 first.
- `lib/domain/**` may import `package:equatable`, `package:wizctl` and `dart:async`/`dart:math`. It must never import `package:flutter/*`, `drift`, `dart:io`, or anything under `lib/data` or `lib/features`. A test in Task 1 enforces this with a source scan.
- `flutter analyze --fatal-infos`, `dart format --output=none --set-exit-if-changed lib test` and `flutter test` must be clean after every task. Run `dart run build_runner build --delete-conflicting-outputs` after changing drift tables.
- Ranges from the library, never invented: brightness 10–100, kelvin 2200–6500 step 50, speed 10–200, scenes ids 1–35 and 1000. Reference `wizctl` constants (`minBrightness`, `maxBrightness`, `minSpeed`, `maxSpeed`, `typicalMinTemperature`, `typicalMaxTemperature`, `defaultSpeed`) rather than literals.
- Time and randomness are injected (`Clock`, `IdGenerator`) so every test is deterministic and uses `fakeAsync` where timers matter.
- Every use case is one class with one `call`; every service has one responsibility; files stay under roughly 300 lines.
- Commit after every task with the trailers `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01LHFwuJ7FsQYePfr5j1T1Pe`.

---

### Task 1: Domain entities

**Files:**
- Create: `lib/domain/entities/home.dart`, `room.dart`, `light.dart`, `rgb.dart`, `live_state.dart`, `discovered_device.dart`, `mode_target.dart`, `mode_summary.dart`, `discovery_progress.dart`, `device_failure.dart`, `command_report.dart`, `app_settings.dart`, `debug_flags.dart`, `lib/domain/entities/entities.dart` (barrel)
- Test: `test/domain/entities_test.dart`, `test/domain/layering_test.dart`

**Interfaces:**
- Produces (all `Equatable`, all `const`-constructible, all with `copyWith` where mutation is meaningful):

```dart
class Home { String id; String name; String? subnet; DateTime createdAt; int sortIndex; }
enum RoomGlyph { sofa, bed, utensils, bath, lampDesk, trees; String get iconName; String get storageName; static RoomGlyph parse(String); }
class Room { String id; String homeId; String name; RoomGlyph glyph; int sortIndex; }
enum Fixture { bulb, dome, desk, strip, socket; String get label; String get iconName; static Fixture parse(String); static Fixture defaultFor(BulbClass?); }
class Light { String id; String homeId; String roomId; String name; String ip; String mac; String? moduleName; BulbClass? bulbClass; Fixture fixture; String? fwVersion; int sortIndex; DateTime addedAt; String get className; }
class Rgb { int r, g, b; static const warm = Rgb(255, 224, 188); static const amber = Rgb(255, 176, 32); }
enum ActiveChannel { white, colour, scene }
class LiveState { bool isOn; int brightness; int kelvin; Rgb rgb; int sceneId; int speed; ActiveChannel active; bool reachable; int? rssi; DateTime? updatedAt; static const initial; }
class DiscoveredDevice { String ip; String mac; String? moduleName; BulbClass? bulbClass; String? fwVersion; bool alreadySaved; String get displayName; static String nameFor(BulbClass?); factory DiscoveredDevice.fromDiscovered(DiscoveredLight, {bool alreadySaved}); }
sealed class ModeTarget { String get key; }  WholeHomeTarget(homeId) key 'home:<id>'; RoomTarget(roomId) key 'room:<id>'; LightTarget(lightId) key 'light:<id>'
sealed class ModeArt { SceneArt(sceneId); SolidArt(Rgb); FlatArt(); }
class ModeSummary { String name; ModeArt art; bool isDynamicScene; bool isStaticScene; int? sceneId; static const nothingSet; static const mixed; }
enum DiscoveryPhase { probingKnown, broadcasting, sweeping }
class DiscoveryProgress { DiscoveryPhase phase; int probed; int total; double fraction; String? subnet; }
sealed class DeviceFailure { String get message; }  TimeoutFailure(ip, attempts); UnreachableFailure(ip, cause); UnsupportedFailure(ip, method); OffNetworkFailure(homeSubnet, currentSubnet); InvalidArgumentFailure(message)
class DeviceException implements Exception { DeviceFailure failure; }
sealed class CommandReport { String get id; }  CommandPending(id, lightIds, description); CommandSucceeded(id); CommandFailed(id, lightId, lightName, ip, failure); CommandRetryFailed(id, lightId, lightName)
class AppSettings { String? activeHomeId; bool feedbackEnabled; bool rescanOnLaunch; static const defaults; }
class DebugFlags { bool offNetwork; bool forceTimeout; bool findNothing; static const none; }
```

- [ ] **Step 1: Write the failing tests**

`test/domain/entities_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  test('room glyphs round-trip through storage names and map to icons', () {
    for (var g in RoomGlyph.values) {
      expect(RoomGlyph.parse(g.storageName), g);
    }
    expect(RoomGlyph.utensils.iconName, 'utensils-crossed');
    expect(RoomGlyph.lampDesk.iconName, 'lamp-desk');
    expect(RoomGlyph.parse('garbage'), RoomGlyph.sofa);
  });

  test('fixtures have labels, icons and class defaults', () {
    expect(Fixture.dome.label, 'Ceiling light');
    expect(Fixture.strip.iconName, 'waves-horizontal');
    expect(Fixture.defaultFor(BulbClass.socket), Fixture.socket);
    expect(Fixture.defaultFor(BulbClass.rgb), Fixture.bulb);
    expect(Fixture.defaultFor(null), Fixture.bulb);
    expect(Fixture.parse('desk'), Fixture.desk);
    expect(Fixture.parse('nope'), Fixture.bulb);
  });

  test('a light reports its class name, Unknown when unclassified', () {
    var light = Light(id: 'l', homeId: 'h', roomId: 'r', name: 'Bedside bulb', ip: '192.168.1.115', mac: 'a8bb50f21177',
        bulbClass: BulbClass.rgb, fixture: Fixture.bulb, sortIndex: 0, addedAt: DateTime(2026, 9, 8));
    expect(light.className, 'RGB');
    expect(light.copyWith(bulbClass: null, clearBulbClass: true).className, 'Unknown');
    expect(light.copyWith(name: 'Lamp'), isNot(equals(light)));
    expect(light.copyWith(), equals(light));
  });

  test('initial live state matches the prototype defaults', () {
    const s = LiveState.initial;
    expect(s.isOn, isFalse);
    expect(s.brightness, 60);
    expect(s.kelvin, 2700);
    expect(s.rgb, Rgb.warm);
    expect(s.sceneId, 6);
    expect(s.speed, 100);
    expect(s.active, ActiveChannel.white);
    expect(s.reachable, isFalse);
  });

  test('discovered devices are named from their class', () {
    expect(DiscoveredDevice.nameFor(BulbClass.rgb), 'WiZ RGB');
    expect(DiscoveredDevice.nameFor(BulbClass.tw), 'WiZ Tunable White');
    expect(DiscoveredDevice.nameFor(BulbClass.dw), 'WiZ Dimmable');
    expect(DiscoveredDevice.nameFor(BulbClass.socket), 'WiZ Smart Plug');
    expect(DiscoveredDevice.nameFor(BulbClass.fanDim), 'WiZ Fan Dimmer');
    expect(DiscoveredDevice.nameFor(null), 'WiZ device');
    var d = DiscoveredDevice.fromDiscovered(const DiscoveredLight(ip: '192.168.1.126', mac: 'abc', moduleName: 'ESP01_SHRGB1C_31', fwVersion: '1.25.0'));
    expect(d.bulbClass, BulbClass.rgb);
    expect(d.displayName, 'WiZ RGB');
    expect(d.alreadySaved, isFalse);
  });

  test('targets have stable keys', () {
    expect(const WholeHomeTarget('h1').key, 'home:h1');
    expect(const RoomTarget('r1').key, 'room:r1');
    expect(const LightTarget('l1').key, 'light:l1');
    expect(const RoomTarget('r1'), const RoomTarget('r1'));
  });

  test('failures carry readable messages', () {
    expect(const TimeoutFailure('192.168.1.5', 3).message, contains('192.168.1.5'));
    expect(const OffNetworkFailure('192.168.1', '10.0.0').message, contains('10.0.0'));
    expect(DeviceException(const TimeoutFailure('x', 1)).toString(), contains('x'));
  });

  test('settings and flags have defaults', () {
    expect(AppSettings.defaults.feedbackEnabled, isTrue);
    expect(AppSettings.defaults.rescanOnLaunch, isTrue);
    expect(AppSettings.defaults.activeHomeId, isNull);
    expect(DebugFlags.none.forceTimeout, isFalse);
    expect(ModeSummary.mixed.name, 'Mixed');
    expect(ModeSummary.nothingSet.art, const FlatArt());
  });
}
```

`test/domain/layering_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the domain layer imports nothing from Flutter, drift, dart:io or outer layers', () {
    var files = Directory('lib/domain').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    var forbidden = RegExp(r"import '(package:flutter/|package:drift|dart:io|package:wizctl_app/data|package:wizctl_app/features|package:wizctl_app/app|package:wizctl_app/core)");
    for (var f in files) {
      var bad = forbidden.allMatches(f.readAsStringSync()).map((m) => m.group(0)).toList();
      expect(bad, isEmpty, reason: '${f.path} imports $bad');
    }
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain`
Expected: compile errors.

- [ ] **Step 3: Implement the entities**

`lib/domain/entities/home.dart`:

```dart
import 'package:equatable/equatable.dart';

/// A device holds one or more homes; a home holds rooms; a room holds lights.
class Home extends Equatable {
  final String id;
  final String name;

  /// The `a.b.c` prefix of the network this home's lights live on, learned at
  /// setup or first discovery. Null until known.
  final String? subnet;
  final DateTime createdAt;
  final int sortIndex;

  const Home({required this.id, required this.name, this.subnet, required this.createdAt, this.sortIndex = 0});

  Home copyWith({String? name, String? subnet, int? sortIndex}) =>
      Home(id: id, name: name ?? this.name, subnet: subnet ?? this.subnet, createdAt: createdAt, sortIndex: sortIndex ?? this.sortIndex);

  @override
  List<Object?> get props => [id, name, subnet, createdAt, sortIndex];
}
```

`lib/domain/entities/room.dart`:

```dart
import 'package:equatable/equatable.dart';

/// The six room glyphs the design offers. [iconName] is the WizCtl icon
/// name; [storageName] is what the database stores.
enum RoomGlyph {
  sofa('sofa'),
  bed('bed'),
  utensils('utensils-crossed'),
  bath('bath'),
  lampDesk('lamp-desk'),
  trees('trees');

  final String iconName;
  const RoomGlyph(this.iconName);

  String get storageName => name;

  static RoomGlyph parse(String value) => values.firstWhere((g) => g.name == value, orElse: () => RoomGlyph.sofa);
}

class Room extends Equatable {
  final String id;
  final String homeId;
  final String name;
  final RoomGlyph glyph;
  final int sortIndex;

  const Room({required this.id, required this.homeId, required this.name, required this.glyph, this.sortIndex = 0});

  Room copyWith({String? name, RoomGlyph? glyph, int? sortIndex}) =>
      Room(id: id, homeId: homeId, name: name ?? this.name, glyph: glyph ?? this.glyph, sortIndex: sortIndex ?? this.sortIndex);

  @override
  List<Object?> get props => [id, homeId, name, glyph, sortIndex];
}
```

`lib/domain/entities/light.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

/// "Show it as": cosmetic only. It picks the shape drawn on the hero and
/// never gates a control; what a bulb supports comes from its class.
enum Fixture {
  bulb('Bulb', 'lightbulb'),
  dome('Ceiling light', 'lamp-ceiling'),
  desk('Lamp', 'lamp-desk'),
  strip('Light strip', 'waves-horizontal'),
  socket('Plug', 'power');

  final String label;
  final String iconName;
  const Fixture(this.label, this.iconName);

  static Fixture parse(String value) => values.firstWhere((f) => f.name == value, orElse: () => Fixture.bulb);

  /// A discovered socket defaults to Plug; everything else to Bulb.
  static Fixture defaultFor(BulbClass? bulbClass) => bulbClass == BulbClass.socket ? Fixture.socket : Fixture.bulb;
}

class Light extends Equatable {
  final String id;
  final String homeId;
  final String roomId;

  /// The user's alias. It replaces the address everywhere.
  final String name;
  final String ip;
  final String mac;
  final String? moduleName;
  final BulbClass? bulbClass;
  final Fixture fixture;
  final String? fwVersion;
  final int sortIndex;
  final DateTime addedAt;

  const Light({
    required this.id,
    required this.homeId,
    required this.roomId,
    required this.name,
    required this.ip,
    required this.mac,
    this.moduleName,
    this.bulbClass,
    required this.fixture,
    this.fwVersion,
    this.sortIndex = 0,
    required this.addedAt,
  });

  String get className => bulbClass?.displayName ?? 'Unknown';

  Light copyWith({
    String? roomId,
    String? name,
    String? ip,
    String? moduleName,
    BulbClass? bulbClass,
    bool clearBulbClass = false,
    Fixture? fixture,
    String? fwVersion,
    int? sortIndex,
  }) =>
      Light(
        id: id,
        homeId: homeId,
        roomId: roomId ?? this.roomId,
        name: name ?? this.name,
        ip: ip ?? this.ip,
        mac: mac,
        moduleName: moduleName ?? this.moduleName,
        bulbClass: clearBulbClass ? null : (bulbClass ?? this.bulbClass),
        fixture: fixture ?? this.fixture,
        fwVersion: fwVersion ?? this.fwVersion,
        sortIndex: sortIndex ?? this.sortIndex,
        addedAt: addedAt,
      );

  @override
  List<Object?> get props => [id, homeId, roomId, name, ip, mac, moduleName, bulbClass, fixture, fwVersion, sortIndex, addedAt];
}
```

`lib/domain/entities/rgb.dart`:

```dart
import 'package:equatable/equatable.dart';

class Rgb extends Equatable {
  final int r;
  final int g;
  final int b;

  const Rgb(this.r, this.g, this.b);

  /// The prototype's default "last colour": a warm white.
  static const Rgb warm = Rgb(255, 224, 188);

  /// Tungsten amber, what blink drives an RGB bulb to.
  static const Rgb amber = Rgb(255, 176, 32);

  @override
  List<Object?> get props => [r, g, b];

  @override
  String toString() => 'Rgb($r, $g, $b)';
}
```

`lib/domain/entities/live_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'rgb.dart';

/// Which channel the bulb is currently showing. Writing a colour sets
/// colour; a kelvin or the temp dial sets white; a scene sets scene.
enum ActiveChannel { white, colour, scene }

/// What a light is doing right now. Every channel keeps its last value so
/// the modes sheet can show the last colour or kelvin.
class LiveState extends Equatable {
  final bool isOn;
  final int brightness;
  final int kelvin;
  final Rgb rgb;
  final int sceneId;
  final int speed;
  final ActiveChannel active;
  final bool reachable;
  final int? rssi;
  final DateTime? updatedAt;

  const LiveState({
    required this.isOn,
    required this.brightness,
    required this.kelvin,
    required this.rgb,
    required this.sceneId,
    required this.speed,
    required this.active,
    required this.reachable,
    this.rssi,
    this.updatedAt,
  });

  /// A light never read yet (prototype defaults).
  static const LiveState initial = LiveState(
    isOn: false, brightness: 60, kelvin: 2700, rgb: Rgb.warm, sceneId: 6, speed: 100,
    active: ActiveChannel.white, reachable: false,
  );

  LiveState copyWith({
    bool? isOn,
    int? brightness,
    int? kelvin,
    Rgb? rgb,
    int? sceneId,
    int? speed,
    ActiveChannel? active,
    bool? reachable,
    int? rssi,
    DateTime? updatedAt,
  }) =>
      LiveState(
        isOn: isOn ?? this.isOn,
        brightness: brightness ?? this.brightness,
        kelvin: kelvin ?? this.kelvin,
        rgb: rgb ?? this.rgb,
        sceneId: sceneId ?? this.sceneId,
        speed: speed ?? this.speed,
        active: active ?? this.active,
        reachable: reachable ?? this.reachable,
        rssi: rssi ?? this.rssi,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [isOn, brightness, kelvin, rgb, sceneId, speed, active, reachable, rssi, updatedAt];
}
```

`lib/domain/entities/discovered_device.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

/// A light that answered discovery, before it has a name or a room.
class DiscoveredDevice extends Equatable {
  final String ip;
  final String mac;
  final String? moduleName;
  final BulbClass? bulbClass;
  final String? fwVersion;

  /// Its MAC already belongs to the active home.
  final bool alreadySaved;

  const DiscoveredDevice({
    required this.ip,
    required this.mac,
    this.moduleName,
    this.bulbClass,
    this.fwVersion,
    this.alreadySaved = false,
  });

  factory DiscoveredDevice.fromDiscovered(DiscoveredLight light, {bool alreadySaved = false}) => DiscoveredDevice(
        ip: light.ip,
        mac: light.mac,
        moduleName: light.moduleName,
        bulbClass: light.bulbClass,
        fwVersion: light.fwVersion,
        alreadySaved: alreadySaved,
      );

  String get displayName => nameFor(bulbClass);

  static String nameFor(BulbClass? bulbClass) => switch (bulbClass) {
        BulbClass.rgb => 'WiZ RGB',
        BulbClass.tw => 'WiZ Tunable White',
        BulbClass.dw => 'WiZ Dimmable',
        BulbClass.socket => 'WiZ Smart Plug',
        BulbClass.fanDim => 'WiZ Fan Dimmer',
        null => 'WiZ device',
      };

  DiscoveredDevice copyWith({String? moduleName, BulbClass? bulbClass, String? fwVersion, bool? alreadySaved}) => DiscoveredDevice(
        ip: ip,
        mac: mac,
        moduleName: moduleName ?? this.moduleName,
        bulbClass: bulbClass ?? this.bulbClass,
        fwVersion: fwVersion ?? this.fwVersion,
        alreadySaved: alreadySaved ?? this.alreadySaved,
      );

  @override
  List<Object?> get props => [ip, mac, moduleName, bulbClass, fwVersion, alreadySaved];
}
```

`lib/domain/entities/mode_target.dart`:

```dart
import 'package:equatable/equatable.dart';

/// What a light-mode write or a scene applies to.
sealed class ModeTarget extends Equatable {
  const ModeTarget();

  String get key;

  @override
  List<Object?> get props => [key];
}

final class WholeHomeTarget extends ModeTarget {
  final String homeId;
  const WholeHomeTarget(this.homeId);

  @override
  String get key => 'home:$homeId';
}

final class RoomTarget extends ModeTarget {
  final String roomId;
  const RoomTarget(this.roomId);

  @override
  String get key => 'room:$roomId';
}

final class LightTarget extends ModeTarget {
  final String lightId;
  const LightTarget(this.lightId);

  @override
  String get key => 'light:$lightId';
}
```

`lib/domain/entities/mode_summary.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'rgb.dart';

sealed class ModeArt extends Equatable {
  const ModeArt();
}

final class SceneArt extends ModeArt {
  final int sceneId;
  const SceneArt(this.sceneId);

  @override
  List<Object?> get props => [sceneId];
}

final class SolidArt extends ModeArt {
  final Rgb rgb;
  const SolidArt(this.rgb);

  @override
  List<Object?> get props => [rgb];
}

final class FlatArt extends ModeArt {
  const FlatArt();

  @override
  List<Object?> get props => const [];
}

/// What the Light mode row reads for a light, a room or the home.
class ModeSummary extends Equatable {
  final String name;
  final ModeArt art;
  final bool isDynamicScene;
  final bool isStaticScene;
  final int? sceneId;

  const ModeSummary({required this.name, required this.art, this.isDynamicScene = false, this.isStaticScene = false, this.sceneId});

  static const ModeSummary nothingSet = ModeSummary(name: 'Nothing set', art: FlatArt());
  static const ModeSummary mixed = ModeSummary(name: 'Mixed', art: FlatArt());

  @override
  List<Object?> get props => [name, art, isDynamicScene, isStaticScene, sceneId];
}
```

`lib/domain/entities/discovery_progress.dart`:

```dart
import 'package:equatable/equatable.dart';

enum DiscoveryPhase { probingKnown, broadcasting, sweeping }

/// Progress of a discovery run; [fraction] is null-safe for the filament
/// bar (broadcast has no count, so probed and total are 0 and fraction 0).
class DiscoveryProgress extends Equatable {
  final DiscoveryPhase phase;
  final int probed;
  final int total;
  final double fraction;
  final String? subnet;

  const DiscoveryProgress({required this.phase, this.probed = 0, this.total = 0, this.fraction = 0, this.subnet});

  bool get isDeterminate => total > 0;

  @override
  List<Object?> get props => [phase, probed, total, fraction, subnet];
}
```

`lib/domain/entities/device_failure.dart`:

```dart
import 'package:equatable/equatable.dart';

/// Why a device operation failed, in the app's vocabulary. Copy for the
/// user lives in the presentation layer; these carry the facts.
sealed class DeviceFailure extends Equatable {
  const DeviceFailure();

  String get message;
}

final class TimeoutFailure extends DeviceFailure {
  final String ip;
  final int attempts;
  const TimeoutFailure(this.ip, this.attempts);

  @override
  String get message => '$ip did not answer after $attempts tries';

  @override
  List<Object?> get props => [ip, attempts];
}

final class UnreachableFailure extends DeviceFailure {
  final String ip;
  final String cause;
  const UnreachableFailure(this.ip, this.cause);

  @override
  String get message => 'Cannot reach $ip: $cause';

  @override
  List<Object?> get props => [ip, cause];
}

final class UnsupportedFailure extends DeviceFailure {
  final String ip;
  final String method;
  const UnsupportedFailure(this.ip, this.method);

  @override
  String get message => '$ip does not support $method';

  @override
  List<Object?> get props => [ip, method];
}

final class OffNetworkFailure extends DeviceFailure {
  final String? homeSubnet;
  final String? currentSubnet;
  const OffNetworkFailure(this.homeSubnet, this.currentSubnet);

  @override
  String get message => 'This device is on ${currentSubnet ?? 'no network'}, not ${homeSubnet ?? 'the home network'}';

  @override
  List<Object?> get props => [homeSubnet, currentSubnet];
}

final class InvalidArgumentFailure extends DeviceFailure {
  @override
  final String message;
  const InvalidArgumentFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceException implements Exception {
  final DeviceFailure failure;
  const DeviceException(this.failure);

  @override
  String toString() => 'DeviceException: ${failure.message}';
}
```

`lib/domain/entities/command_report.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'device_failure.dart';

/// How a write reports back. The toast layer turns these into toasts.
sealed class CommandReport extends Equatable {
  const CommandReport();

  String get id;
}

final class CommandPending extends CommandReport {
  @override
  final String id;
  final List<String> lightIds;
  final String description;
  const CommandPending(this.id, this.lightIds, this.description);

  @override
  List<Object?> get props => [id, lightIds, description];
}

final class CommandSucceeded extends CommandReport {
  @override
  final String id;
  const CommandSucceeded(this.id);

  @override
  List<Object?> get props => [id];
}

final class CommandFailed extends CommandReport {
  @override
  final String id;
  final String lightId;
  final String lightName;
  final String ip;
  final DeviceFailure failure;
  const CommandFailed(this.id, this.lightId, this.lightName, this.ip, this.failure);

  @override
  List<Object?> get props => [id, lightId, lightName, ip, failure];
}

final class CommandRetryFailed extends CommandReport {
  @override
  final String id;
  final String lightId;
  final String lightName;
  const CommandRetryFailed(this.id, this.lightId, this.lightName);

  @override
  List<Object?> get props => [id, lightId, lightName];
}
```

`lib/domain/entities/app_settings.dart`:

```dart
import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String? activeHomeId;
  final bool feedbackEnabled;
  final bool rescanOnLaunch;

  const AppSettings({this.activeHomeId, this.feedbackEnabled = true, this.rescanOnLaunch = true});

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({String? activeHomeId, bool clearActiveHome = false, bool? feedbackEnabled, bool? rescanOnLaunch}) => AppSettings(
        activeHomeId: clearActiveHome ? null : (activeHomeId ?? this.activeHomeId),
        feedbackEnabled: feedbackEnabled ?? this.feedbackEnabled,
        rescanOnLaunch: rescanOnLaunch ?? this.rescanOnLaunch,
      );

  @override
  List<Object?> get props => [activeHomeId, feedbackEnabled, rescanOnLaunch];
}
```

`lib/domain/entities/debug_flags.dart`:

```dart
import 'package:equatable/equatable.dart';

/// The prototype switches. Only debug builds ever set these.
class DebugFlags extends Equatable {
  final bool offNetwork;
  final bool forceTimeout;
  final bool findNothing;

  const DebugFlags({this.offNetwork = false, this.forceTimeout = false, this.findNothing = false});

  static const DebugFlags none = DebugFlags();

  DebugFlags copyWith({bool? offNetwork, bool? forceTimeout, bool? findNothing}) => DebugFlags(
        offNetwork: offNetwork ?? this.offNetwork,
        forceTimeout: forceTimeout ?? this.forceTimeout,
        findNothing: findNothing ?? this.findNothing,
      );

  @override
  List<Object?> get props => [offNetwork, forceTimeout, findNothing];
}
```

`lib/domain/entities/entities.dart`:

```dart
export 'app_settings.dart';
export 'command_report.dart';
export 'debug_flags.dart';
export 'device_failure.dart';
export 'discovered_device.dart';
export 'discovery_progress.dart';
export 'home.dart';
export 'light.dart';
export 'live_state.dart';
export 'mode_summary.dart';
export 'mode_target.dart';
export 'rgb.dart';
export 'room.dart';
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): entities"
```

---

### Task 2: Capability rules and the live-state mapper

**Files:**
- Create: `lib/domain/services/capability_rules.dart`, `lib/domain/services/live_state_mapper.dart`
- Test: `test/domain/services/capability_rules_test.dart`, `test/domain/services/live_state_mapper_test.dart`

**Interfaces:**
- Produces: `class CapabilityRules { static bool brightness(BulbClass?); static bool kelvin(BulbClass?); static bool colour(BulbClass?); static bool scenes(BulbClass?); static bool isDynamicScene(int sceneId); static bool speed(LiveState); }`; `class LiveStateMapper { static LiveState fromLightState(LightState state, {required LiveState previous, required DateTime now}); static int snapKelvin(int); }`.

- [ ] **Step 1: Write the failing tests**

`test/domain/services/capability_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/capability_rules.dart';

void main() {
  test('capabilities per class, spec §5.1', () {
    expect(CapabilityRules.brightness(BulbClass.socket), isFalse);
    expect(CapabilityRules.brightness(BulbClass.dw), isTrue);
    expect(CapabilityRules.brightness(null), isTrue);
    expect(CapabilityRules.kelvin(BulbClass.rgb), isTrue);
    expect(CapabilityRules.kelvin(BulbClass.tw), isTrue);
    expect(CapabilityRules.kelvin(BulbClass.dw), isFalse);
    expect(CapabilityRules.kelvin(BulbClass.fanDim), isFalse);
    expect(CapabilityRules.kelvin(null), isTrue);
    expect(CapabilityRules.colour(BulbClass.rgb), isTrue);
    expect(CapabilityRules.colour(BulbClass.tw), isFalse);
    expect(CapabilityRules.colour(null), isTrue);
    expect(CapabilityRules.scenes(BulbClass.socket), isFalse);
    expect(CapabilityRules.scenes(BulbClass.dw), isTrue);
  });

  test('speed only while on a dynamic scene', () {
    expect(CapabilityRules.isDynamicScene(1), isTrue);
    expect(CapabilityRules.isDynamicScene(6), isFalse);
    expect(CapabilityRules.isDynamicScene(1000), isTrue);
    expect(CapabilityRules.isDynamicScene(999), isFalse);
    expect(CapabilityRules.speed(LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 1)), isTrue);
    expect(CapabilityRules.speed(LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 6)), isFalse);
    expect(CapabilityRules.speed(LiveState.initial.copyWith(active: ActiveChannel.white, sceneId: 1)), isFalse);
  });
}
```

`test/domain/services/live_state_mapper_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_mapper.dart';

void main() {
  final now = DateTime(2026, 9, 8, 12);

  test('a scene wins, keeping other channels from before', () {
    var prev = LiveState.initial.copyWith(rgb: const Rgb(1, 2, 3), kelvin: 4000);
    var s = LiveStateMapper.fromLightState(
      const LightState(isOn: true, dimming: 80, sceneId: 5, speed: 150, rssi: -52, r: 255, g: 0, b: 0, temperature: 2700),
      previous: prev, now: now,
    );
    expect(s.active, ActiveChannel.scene);
    expect(s.sceneId, 5);
    expect(s.speed, 150);
    expect(s.brightness, 80);
    expect(s.isOn, isTrue);
    expect(s.rgb, const Rgb(1, 2, 3));
    expect(s.kelvin, 4000);
    expect(s.rssi, -52);
    expect(s.reachable, isTrue);
    expect(s.updatedAt, now);
  });

  test('temperature maps to white, snapped to 50 and clamped', () {
    var s = LiveStateMapper.fromLightState(const LightState(isOn: true, temperature: 2712), previous: LiveState.initial, now: now);
    expect(s.active, ActiveChannel.white);
    expect(s.kelvin, 2700);
    expect(LiveStateMapper.snapKelvin(7000), 6500);
    expect(LiveStateMapper.snapKelvin(1000), 2200);
    expect(LiveStateMapper.snapKelvin(3524), 3500);
    expect(LiveStateMapper.snapKelvin(3526), 3550);
  });

  test('rgb maps to colour; missing dimming keeps the previous brightness', () {
    var prev = LiveState.initial.copyWith(brightness: 45);
    var s = LiveStateMapper.fromLightState(const LightState(isOn: false, r: 255, g: 120, b: 60), previous: prev, now: now);
    expect(s.active, ActiveChannel.colour);
    expect(s.rgb, const Rgb(255, 120, 60));
    expect(s.brightness, 45);
    expect(s.isOn, isFalse);
  });

  test('scene id 0 is not a scene; white channels only keep the previous kelvin', () {
    var s = LiveStateMapper.fromLightState(const LightState(isOn: true, sceneId: 0, warmWhite: 200, dimming: 200), previous: LiveState.initial, now: now);
    expect(s.active, ActiveChannel.white);
    expect(s.kelvin, LiveState.initial.kelvin);
    expect(s.brightness, maxBrightness);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/services`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/domain/services/capability_rules.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/live_state.dart';

/// Which controls a bulb class gets (spec §5.1). An unknown class is
/// treated as fully capable, matching the library's own defaults, so a
/// bulb the app cannot classify is never left without controls.
class CapabilityRules {
  CapabilityRules._();

  static bool brightness(BulbClass? c) => c?.supportsBrightness ?? true;

  static bool kelvin(BulbClass? c) => c?.supportsTemperature ?? true;

  static bool colour(BulbClass? c) => c?.supportsColor ?? true;

  static bool scenes(BulbClass? c) => c != BulbClass.socket;

  static bool isDynamicScene(int sceneId) => WizScene.fromId(sceneId)?.isDynamic ?? false;

  /// The speed rail exists only while the bulb is on a dynamic scene.
  static bool speed(LiveState state) => state.active == ActiveChannel.scene && isDynamicScene(state.sceneId);
}
```

`lib/domain/services/live_state_mapper.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/live_state.dart';
import '../entities/rgb.dart';

/// Turns a bulb's reported pilot into the app's live state (spec §5.2).
class LiveStateMapper {
  LiveStateMapper._();

  static const int kelvinStep = 50;

  static int snapKelvin(int kelvin) =>
      ((kelvin / kelvinStep).round() * kelvinStep).clamp(typicalMinTemperature, typicalMaxTemperature);

  static LiveState fromLightState(LightState state, {required LiveState previous, required DateTime now}) {
    var brightness = (state.dimming ?? previous.brightness).clamp(minBrightness, maxBrightness);
    var base = previous.copyWith(
      isOn: state.isOn,
      brightness: brightness,
      rssi: state.rssi ?? previous.rssi,
      reachable: true,
      updatedAt: now,
    );
    var sceneId = state.sceneId;
    if (sceneId != null && sceneId > 0) {
      return base.copyWith(
        active: ActiveChannel.scene,
        sceneId: sceneId,
        speed: (state.speed ?? previous.speed).clamp(minSpeed, maxSpeed),
      );
    }
    var temperature = state.temperature;
    if (temperature != null) {
      return base.copyWith(active: ActiveChannel.white, kelvin: snapKelvin(temperature));
    }
    if (state.r != null && state.g != null && state.b != null) {
      return base.copyWith(active: ActiveChannel.colour, rgb: Rgb(state.r!, state.g!, state.b!));
    }
    return base.copyWith(active: ActiveChannel.white);
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): capability rules and live-state mapping"
```

---

### Task 3: Mode summarizer and room aggregates

**Files:**
- Create: `lib/domain/services/mode_summarizer.dart`, `lib/domain/services/room_aggregates.dart`
- Test: `test/domain/services/mode_summarizer_test.dart`, `test/domain/services/room_aggregates_test.dart`

**Interfaces:**
- Produces: `typedef LiveLight = ({Light light, LiveState state});`; `class ModeSummarizer { static ModeSummary summarize(List<LiveLight> lights); static String sceneName(int id); static bool sceneSelected(List<LiveLight>, int sceneId); static bool colourSelected(List<LiveLight>, Rgb); static bool whiteSelected(List<LiveLight>, int kelvin); static bool allOnOneDynamicScene(List<LiveLight>); }`; `class RoomAggregates { int brightness; int kelvin; bool canKelvin; String? kelvinNote; bool anyOn; int onCount; int unreachableCount; static RoomAggregates of(List<LiveLight>); }`. `kelvinNote` copy: "No bulb in this room has a white channel to tune." / "Colour temp reaches <k> of <n> bulbs."; `Rgb`-to-kelvin art uses `SolidArt`.

- [ ] **Step 1: Write the failing tests**

`test/domain/services/mode_summarizer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/mode_summarizer.dart';

Light light(String id, BulbClass? cls) => Light(id: id, homeId: 'h', roomId: 'r', name: id, ip: '10.0.0.$id', mac: id, bulbClass: cls, fixture: Fixture.bulb, addedAt: DateTime(2026));

void main() {
  LiveLight ll(String id, BulbClass? cls, LiveState s) => (light: light(id, cls), state: s);
  const white = LiveState.initial;
  final scene = LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 6, isOn: true);
  final dyn = LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 1, isOn: true);
  final colour = LiveState.initial.copyWith(active: ActiveChannel.colour, rgb: const Rgb(255, 120, 60), isOn: true);

  test('empty is Nothing set; mismatch is Mixed', () {
    expect(ModeSummarizer.summarize([]), ModeSummary.nothingSet);
    expect(ModeSummarizer.summarize([ll('a', BulbClass.rgb, scene), ll('b', BulbClass.rgb, colour)]), ModeSummary.mixed);
  });

  test('a shared scene names it with art and flags', () {
    var s = ModeSummarizer.summarize([ll('a', BulbClass.rgb, scene), ll('b', BulbClass.tw, scene)]);
    expect(s.name, 'Cozy');
    expect(s.art, const SceneArt(6));
    expect(s.isStaticScene, isTrue);
    expect(s.isDynamicScene, isFalse);
    expect(ModeSummarizer.summarize([ll('a', BulbClass.rgb, dyn)]).isDynamicScene, isTrue);
  });

  test('sockets are ignored when any other bulb is present', () {
    var socket = ll('p', BulbClass.socket, LiveState.initial.copyWith(isOn: true));
    expect(ModeSummarizer.summarize([socket, ll('a', BulbClass.rgb, scene)]).name, 'Cozy');
    expect(ModeSummarizer.summarize([socket]).name, 'Power on');
    expect(ModeSummarizer.summarize([ll('p', BulbClass.socket, LiveState.initial)]).name, 'Power off');
  });

  test('colour, dimmable and white summaries', () {
    var c = ModeSummarizer.summarize([ll('a', BulbClass.rgb, colour)]);
    expect(c.name, 'Colour');
    expect(c.art, const SolidArt(Rgb(255, 120, 60)));
    var d = ModeSummarizer.summarize([ll('a', BulbClass.dw, white)]);
    expect(d.name, 'Warm white');
    expect(d.art, const SolidArt(Rgb(255, 201, 141)));
    var w = ModeSummarizer.summarize([ll('a', BulbClass.tw, white.copyWith(kelvin: 4000))]);
    expect(w.name, '4000K white');
    expect(w.art, isA<SolidArt>());
  });

  test('selection helpers require every light to agree', () {
    var both = [ll('a', BulbClass.rgb, colour), ll('b', BulbClass.rgb, colour)];
    expect(ModeSummarizer.colourSelected(both, const Rgb(255, 120, 60)), isTrue);
    expect(ModeSummarizer.colourSelected([...both, ll('c', BulbClass.rgb, scene)], const Rgb(255, 120, 60)), isFalse);
    expect(ModeSummarizer.whiteSelected([ll('a', BulbClass.tw, white)], 2700), isTrue);
    expect(ModeSummarizer.sceneSelected([ll('a', BulbClass.rgb, scene)], 6), isTrue);
    expect(ModeSummarizer.sceneSelected([], 6), isFalse);
    expect(ModeSummarizer.allOnOneDynamicScene([ll('a', BulbClass.rgb, dyn), ll('b', BulbClass.rgb, dyn)]), isTrue);
    expect(ModeSummarizer.allOnOneDynamicScene([ll('a', BulbClass.rgb, dyn), ll('b', BulbClass.rgb, scene)]), isFalse);
  });
}
```

`test/domain/services/room_aggregates_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/mode_summarizer.dart';
import 'package:wizctl_app/domain/services/room_aggregates.dart';

LiveLight ll(String id, BulbClass? cls, LiveState s) =>
    (light: Light(id: id, homeId: 'h', roomId: 'r', name: id, ip: id, mac: id, bulbClass: cls, fixture: Fixture.bulb, addedAt: DateTime(2026)), state: s);

void main() {
  test('averages brightness over dimmable lights and kelvin over white-capable ones, snapped to 50', () {
    var a = RoomAggregates.of([
      ll('a', BulbClass.rgb, LiveState.initial.copyWith(brightness: 70, kelvin: 2450, isOn: true)),
      ll('b', BulbClass.tw, LiveState.initial.copyWith(brightness: 30, kelvin: 4000)),
      ll('c', BulbClass.socket, LiveState.initial.copyWith(brightness: 100, isOn: true)),
    ]);
    expect(a.brightness, 50);
    expect(a.kelvin, 3250);
    expect(a.canKelvin, isTrue);
    expect(a.kelvinNote, 'Colour temp reaches 2 of 3 bulbs.');
    expect(a.anyOn, isTrue);
    expect(a.onCount, 2);
  });

  test('no white channel at all', () {
    var a = RoomAggregates.of([ll('a', BulbClass.dw, LiveState.initial), ll('b', BulbClass.socket, LiveState.initial)]);
    expect(a.canKelvin, isFalse);
    expect(a.kelvinNote, 'No bulb in this room has a white channel to tune.');
    expect(a.anyOn, isFalse);
  });

  test('all capable means no note; empty rooms default', () {
    expect(RoomAggregates.of([ll('a', BulbClass.rgb, LiveState.initial)]).kelvinNote, isNull);
    var e = RoomAggregates.of([]);
    expect(e.brightness, minBrightness);
    expect(e.kelvin, 2700);
    expect(e.canKelvin, isFalse);
    expect(e.kelvinNote, isNull);
  });

  test('unreachable count', () {
    var a = RoomAggregates.of([ll('a', BulbClass.rgb, LiveState.initial.copyWith(reachable: false)), ll('b', BulbClass.rgb, LiveState.initial.copyWith(reachable: true))]);
    expect(a.unreachableCount, 1);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/services`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/domain/services/mode_summarizer.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'capability_rules.dart';

typedef LiveLight = ({Light light, LiveState state});

/// What the Light mode row says for a set of lights (spec §5.3), and the
/// selection rules the modes sheet uses.
class ModeSummarizer {
  ModeSummarizer._();

  /// The dimmable-white swatch colour (kelvin 2700 stop).
  static const Rgb dimmableWarm = Rgb(255, 201, 141);

  static String sceneName(int id) => WizScene.fromId(id)?.displayName ?? 'Scene $id';

  static List<LiveLight> _dropSockets(List<LiveLight> lights) {
    if (lights.length > 1 && lights.any((l) => l.light.bulbClass != BulbClass.socket)) {
      return lights.where((l) => l.light.bulbClass != BulbClass.socket).toList();
    }
    return lights;
  }

  static ModeSummary summarize(List<LiveLight> input) {
    if (input.isEmpty) return ModeSummary.nothingSet;
    var lights = _dropSockets(input);
    var first = lights.first.state;
    var same = lights.every((l) =>
        l.state.active == first.active && l.state.sceneId == first.sceneId && l.state.rgb == first.rgb && l.state.kelvin == first.kelvin);
    if (!same) return ModeSummary.mixed;

    if (first.active == ActiveChannel.scene) {
      var dynamic = CapabilityRules.isDynamicScene(first.sceneId);
      return ModeSummary(name: sceneName(first.sceneId), art: SceneArt(first.sceneId), isDynamicScene: dynamic, isStaticScene: !dynamic, sceneId: first.sceneId);
    }
    if (first.active == ActiveChannel.colour) {
      return ModeSummary(name: 'Colour', art: SolidArt(first.rgb));
    }
    if (lights.every((l) => l.light.bulbClass == BulbClass.socket)) {
      return ModeSummary(name: first.isOn ? 'Power on' : 'Power off', art: const FlatArt());
    }
    if (lights.every((l) => l.light.bulbClass == BulbClass.dw)) {
      return const ModeSummary(name: 'Warm white', art: SolidArt(dimmableWarm));
    }
    return ModeSummary(name: '${first.kelvin}K white', art: SolidArt(kelvinRgb(first.kelvin)));
  }

  static bool sceneSelected(List<LiveLight> lights, int sceneId) =>
      lights.isNotEmpty && lights.every((l) => l.state.active == ActiveChannel.scene && l.state.sceneId == sceneId);

  static bool colourSelected(List<LiveLight> lights, Rgb rgb) =>
      lights.isNotEmpty && lights.every((l) => l.state.active == ActiveChannel.colour && l.state.rgb == rgb);

  static bool whiteSelected(List<LiveLight> lights, int kelvin) =>
      lights.isNotEmpty && lights.every((l) => l.state.active == ActiveChannel.white && l.state.kelvin == kelvin);

  static bool allOnOneDynamicScene(List<LiveLight> lights) {
    if (lights.isEmpty) return false;
    var id = lights.first.state.sceneId;
    return CapabilityRules.isDynamicScene(id) && sceneSelected(lights, id);
  }

  /// The kelvin ramp (spec §5.5) in the domain's integer form.
  static Rgb kelvinRgb(int kelvin) {
    const stops = [(2200, Rgb(255, 178, 92)), (2700, Rgb(255, 201, 141)), (3500, Rgb(255, 224, 188)), (4500, Rgb(255, 244, 230)), (5500, Rgb(242, 246, 255)), (6500, Rgb(220, 233, 255))];
    if (kelvin <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      var (k1, c1) = stops[i];
      if (kelvin <= k1) {
        var (k0, c0) = stops[i - 1];
        var t = (kelvin - k0) / (k1 - k0);
        int mix(int a, int b) => (a + (b - a) * t).round();
        return Rgb(mix(c0.r, c1.r), mix(c0.g, c1.g), mix(c0.b, c1.b));
      }
    }
    return stops.last.$2;
  }
}
```

`lib/domain/services/room_aggregates.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'capability_rules.dart';
import 'live_state_mapper.dart';
import 'mode_summarizer.dart';

/// The whole-room panel's numbers and note (spec §5.4).
class RoomAggregates {
  final int brightness;
  final int kelvin;
  final bool canKelvin;
  final String? kelvinNote;
  final bool anyOn;
  final int onCount;
  final int unreachableCount;

  const RoomAggregates({
    required this.brightness,
    required this.kelvin,
    required this.canKelvin,
    required this.kelvinNote,
    required this.anyOn,
    required this.onCount,
    required this.unreachableCount,
  });

  static const String noWhiteChannel = 'No bulb in this room has a white channel to tune.';

  static RoomAggregates of(List<LiveLight> lights) {
    var dimmable = lights.where((l) => CapabilityRules.brightness(l.light.bulbClass)).toList();
    var tunable = lights.where((l) => CapabilityRules.kelvin(l.light.bulbClass)).toList();
    var brightness = dimmable.isEmpty ? minBrightness : (dimmable.map((l) => l.state.brightness).reduce((a, b) => a + b) / dimmable.length).round();
    var kelvin = tunable.isEmpty ? LiveState.initial.kelvin : LiveStateMapper.snapKelvin((tunable.map((l) => l.state.kelvin).reduce((a, b) => a + b) / tunable.length).round());
    String? note;
    if (lights.isNotEmpty && tunable.isEmpty) {
      note = noWhiteChannel;
    } else if (tunable.length < lights.length) {
      note = 'Colour temp reaches ${tunable.length} of ${lights.length} bulbs.';
    }
    var on = lights.where((l) => l.state.isOn && l.state.reachable).length;
    return RoomAggregates(
      brightness: brightness,
      kelvin: kelvin,
      canKelvin: tunable.isNotEmpty,
      kelvinNote: note,
      anyOn: on > 0,
      onCount: on,
      unreachableCount: lights.where((l) => !l.state.reachable).length,
    );
  }
}
```

Note: `onCount` counts lights that are on and reachable, matching the prototype's "on" count that excludes unreachable lights; the test's `LiveState.initial` has `reachable: false`, so adjust the first test's states with `reachable: true` for the two lit lights before running.

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): mode summary and room aggregates"
```

---

### Task 4: LiveStateStore

**Files:**
- Create: `lib/domain/services/live_state_store.dart`
- Test: `test/domain/services/live_state_store_test.dart`

**Interfaces:**
- Produces: `class LiveStateStore { LiveState of(String lightId); Map<String, LiveState> get snapshot; Stream<Map<String, LiveState>> watchAll(); Stream<LiveState> watch(String lightId); void put(String lightId, LiveState state); void update(String lightId, LiveState Function(LiveState) change); void seed(Map<String, LiveState> states); void remove(String lightId); void dispose(); }`. `watchAll` and `watch` replay the current value on listen; `watch` emits only when that light's state changes.

- [ ] **Step 1: Write the failing test**

`test/domain/services/live_state_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

void main() {
  test('unknown lights read as initial; puts and updates notify', () async {
    var store = LiveStateStore();
    expect(store.of('x'), LiveState.initial);
    var seen = <LiveState>[];
    var sub = store.watch('a').listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    store.put('a', LiveState.initial.copyWith(isOn: true));
    store.update('a', (s) => s.copyWith(brightness: 42));
    store.put('b', LiveState.initial);
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((s) => s.brightness), [60, 60, 42]);
    expect(seen.last.isOn, isTrue);
    expect(store.snapshot.keys, containsAll(['a', 'b']));
    await sub.cancel();
    store.dispose();
  });

  test('seed replaces everything and watchAll replays', () async {
    var store = LiveStateStore();
    store.seed({'a': LiveState.initial.copyWith(kelvin: 4000)});
    var first = await store.watchAll().first;
    expect(first['a']!.kelvin, 4000);
    store.remove('a');
    expect(store.snapshot, isEmpty);
    store.dispose();
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/services/live_state_store_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/domain/services/live_state_store.dart`:

```dart
import 'dart:async';

import '../entities/live_state.dart';

/// The in-memory truth about what every light is doing. Repositories hold
/// what the user configured; this holds what the bulbs reported or what
/// the app just wrote optimistically. Screens project it; use cases mutate
/// it; a data-layer listener persists it.
class LiveStateStore {
  final Map<String, LiveState> _states = {};
  final StreamController<Map<String, LiveState>> _all = StreamController.broadcast();

  LiveState of(String lightId) => _states[lightId] ?? LiveState.initial;

  Map<String, LiveState> get snapshot => Map.unmodifiable(_states);

  Stream<Map<String, LiveState>> watchAll() async* {
    yield snapshot;
    yield* _all.stream;
  }

  Stream<LiveState> watch(String lightId) async* {
    var last = of(lightId);
    yield last;
    await for (var all in _all.stream) {
      var next = all[lightId] ?? LiveState.initial;
      if (next != last) {
        last = next;
        yield next;
      }
    }
  }

  void put(String lightId, LiveState state) {
    _states[lightId] = state;
    _emit();
  }

  void update(String lightId, LiveState Function(LiveState current) change) => put(lightId, change(of(lightId)));

  void seed(Map<String, LiveState> states) {
    _states
      ..clear()
      ..addAll(states);
    _emit();
  }

  void remove(String lightId) {
    if (_states.remove(lightId) != null) _emit();
  }

  void _emit() {
    if (!_all.isClosed) _all.add(snapshot);
  }

  void dispose() => _all.close();
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): LiveStateStore"
```

---

### Task 5: Repository and gateway interfaces, clock, ids, target resolver

**Files:**
- Create: `lib/domain/repositories/home_repository.dart`, `room_repository.dart`, `light_repository.dart`, `settings_repository.dart`, `live_state_persistence.dart`, `lib/domain/services/device_gateway.dart`, `lib/domain/services/clock.dart`, `lib/domain/services/id_generator.dart`, `lib/domain/services/target_resolver.dart`, `test/support/fakes.dart`
- Test: `test/domain/services/target_resolver_test.dart`

**Interfaces:**

```dart
abstract interface class HomeRepository { Stream<List<Home>> watchAll(); Future<List<Home>> getAll(); Future<Home?> get(String id); Future<void> insert(Home home); Future<void> update(Home home); Future<void> delete(String id); }
abstract interface class RoomRepository { Stream<List<Room>> watchByHome(String homeId); Future<List<Room>> getByHome(String homeId); Future<Room?> get(String id); Future<void> insert(Room room); Future<void> update(Room room); Future<void> delete(String id); }
abstract interface class LightRepository { Stream<List<Light>> watchByHome(String homeId); Stream<List<Light>> watchByRoom(String roomId); Stream<Light?> watch(String id); Future<List<Light>> getByHome(String homeId); Future<List<Light>> getByRoom(String roomId); Future<Light?> get(String id); Future<Light?> getByMac(String homeId, String mac); Future<void> insert(Light light); Future<void> update(Light light); Future<void> delete(String id); }
abstract interface class SettingsRepository { Stream<AppSettings> watch(); Future<AppSettings> get(); Future<void> save(AppSettings settings); }
abstract interface class LiveStatePersistence { Future<Map<String, LiveState>> load(); Future<void> save(Map<String, LiveState> states); }
abstract interface class DeviceGateway { Future<LightState> readState(String ip); Future<BulbConfig> readConfig(String ip); Future<void> send(String ip, ControlSignal signal); Future<List<DiscoveredLight>> broadcast(); Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}); Stream<ScanEvent> sweep({String? subnet}); }   // all throw DeviceException
abstract interface class Clock { DateTime now(); Future<void> delay(Duration duration); }  class SystemClock implements Clock
abstract interface class IdGenerator { String next(); }
class TargetResolver { TargetResolver(LightRepository lights); Future<List<Light>> resolve(ModeTarget target); }
```

`test/support/fakes.dart` provides in-memory `FakeHomeRepository`, `FakeRoomRepository`, `FakeLightRepository`, `FakeSettingsRepository`, `FakeLiveStatePersistence`, `FakeClock` (manual `now`, `delay` completes immediately and records durations), `SequenceIds` (`IdGenerator` yielding `id1, id2, ...`), and `FakeGateway` (scripted responses per ip, records sends, can throw `DeviceException` per ip, `broadcast`/`probe`/`sweep` results settable). Later tasks use these.

- [ ] **Step 1: Write the failing test**

`test/domain/services/target_resolver_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';

import '../../support/fakes.dart';

void main() {
  Light light(String id, String room) => Light(id: id, homeId: 'h1', roomId: room, name: id, ip: id, mac: id, bulbClass: BulbClass.rgb, fixture: Fixture.bulb, addedAt: DateTime(2026));

  test('resolves whole home, room and light targets', () async {
    var lights = FakeLightRepository()..seed([light('a', 'r1'), light('b', 'r1'), light('c', 'r2')]);
    var resolver = TargetResolver(lights);
    expect((await resolver.resolve(const WholeHomeTarget('h1'))).map((l) => l.id), ['a', 'b', 'c']);
    expect((await resolver.resolve(const RoomTarget('r1'))).map((l) => l.id), ['a', 'b']);
    expect((await resolver.resolve(const LightTarget('c'))).map((l) => l.id), ['c']);
    expect(await resolver.resolve(const LightTarget('zzz')), isEmpty);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/services/target_resolver_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the interfaces and helpers**

`lib/domain/repositories/home_repository.dart`:

```dart
import '../entities/home.dart';

abstract interface class HomeRepository {
  Stream<List<Home>> watchAll();
  Future<List<Home>> getAll();
  Future<Home?> get(String id);
  Future<void> insert(Home home);
  Future<void> update(Home home);
  Future<void> delete(String id);
}
```

`lib/domain/repositories/room_repository.dart`:

```dart
import '../entities/room.dart';

abstract interface class RoomRepository {
  Stream<List<Room>> watchByHome(String homeId);
  Future<List<Room>> getByHome(String homeId);
  Future<Room?> get(String id);
  Future<void> insert(Room room);
  Future<void> update(Room room);
  Future<void> delete(String id);
}
```

`lib/domain/repositories/light_repository.dart`:

```dart
import '../entities/light.dart';

abstract interface class LightRepository {
  Stream<List<Light>> watchByHome(String homeId);
  Stream<List<Light>> watchByRoom(String roomId);
  Stream<Light?> watch(String id);
  Future<List<Light>> getByHome(String homeId);
  Future<List<Light>> getByRoom(String roomId);
  Future<Light?> get(String id);
  Future<Light?> getByMac(String homeId, String mac);
  Future<void> insert(Light light);
  Future<void> update(Light light);
  Future<void> delete(String id);
}
```

`lib/domain/repositories/settings_repository.dart`:

```dart
import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();
  Future<AppSettings> get();
  Future<void> save(AppSettings settings);
}
```

`lib/domain/repositories/live_state_persistence.dart`:

```dart
import '../entities/live_state.dart';

/// Last-known live state, so dials show real values at launch while the
/// first refresh runs.
abstract interface class LiveStatePersistence {
  Future<Map<String, LiveState>> load();
  Future<void> save(Map<String, LiveState> states);
}
```

`lib/domain/services/device_gateway.dart`:

```dart
import 'package:wizctl/wizctl.dart';

/// The boundary to the bulbs. Every method throws [DeviceException] on
/// failure; streams error with it. Timeouts and retries are the
/// implementation's concern (spec §5.8, §5.11).
abstract interface class DeviceGateway {
  Future<LightState> readState(String ip);
  Future<BulbConfig> readConfig(String ip);
  Future<void> send(String ip, ControlSignal signal);
  Future<List<DiscoveredLight>> broadcast();
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1});
  Stream<ScanEvent> sweep({String? subnet});
}
```

`lib/domain/services/clock.dart`:

```dart
abstract interface class Clock {
  DateTime now();
  Future<void> delay(Duration duration);
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Future<void> delay(Duration duration) => Future<void>.delayed(duration);
}
```

`lib/domain/services/id_generator.dart`:

```dart
abstract interface class IdGenerator {
  String next();
}
```

`lib/domain/services/target_resolver.dart`:

```dart
import '../entities/light.dart';
import '../entities/mode_target.dart';
import '../repositories/light_repository.dart';

/// Which lights a target means, in repository order.
class TargetResolver {
  final LightRepository _lights;

  TargetResolver(this._lights);

  Future<List<Light>> resolve(ModeTarget target) async => switch (target) {
        WholeHomeTarget(:var homeId) => _lights.getByHome(homeId),
        RoomTarget(:var roomId) => _lights.getByRoom(roomId),
        LightTarget(:var lightId) => [?await _lights.get(lightId)],
      };
}
```

(`[?x]` is a null-aware element; if the SDK rejects it, write `(await _lights.get(lightId)) case var l? ? [l] : <Light>[]` as an explicit `if`.)

- [ ] **Step 4: Write the shared fakes**

`test/support/fakes.dart`:

```dart
import 'dart:async';

import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/repositories/home_repository.dart';
import 'package:wizctl_app/domain/repositories/light_repository.dart';
import 'package:wizctl_app/domain/repositories/live_state_persistence.dart';
import 'package:wizctl_app/domain/repositories/room_repository.dart';
import 'package:wizctl_app/domain/repositories/settings_repository.dart';
import 'package:wizctl_app/domain/services/clock.dart';
import 'package:wizctl_app/domain/services/device_gateway.dart';
import 'package:wizctl_app/domain/services/id_generator.dart';

/// A broadcast stream that replays its latest value to new listeners.
class _Replay<T> {
  T value;
  final _controller = StreamController<T>.broadcast();
  _Replay(this.value);
  Stream<T> get stream async* {
    yield value;
    yield* _controller.stream;
  }

  void set(T next) {
    value = next;
    _controller.add(next);
  }
}

class FakeHomeRepository implements HomeRepository {
  final Map<String, Home> _homes = {};
  late final _Replay<List<Home>> _all = _Replay(_list());
  List<Home> _list() => _homes.values.toList()..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  void _notify() => _all.set(_list());
  void seed(List<Home> homes) {
    for (var h in homes) {
      _homes[h.id] = h;
    }
    _notify();
  }

  @override
  Stream<List<Home>> watchAll() => _all.stream;
  @override
  Future<List<Home>> getAll() async => _list();
  @override
  Future<Home?> get(String id) async => _homes[id];
  @override
  Future<void> insert(Home home) async {
    _homes[home.id] = home;
    _notify();
  }

  @override
  Future<void> update(Home home) => insert(home);
  @override
  Future<void> delete(String id) async {
    _homes.remove(id);
    _notify();
  }
}

class FakeRoomRepository implements RoomRepository {
  final Map<String, Room> _rooms = {};
  final _changes = StreamController<void>.broadcast();
  void seed(List<Room> rooms) {
    for (var r in rooms) {
      _rooms[r.id] = r;
    }
    _changes.add(null);
  }

  List<Room> _byHome(String homeId) => _rooms.values.where((r) => r.homeId == homeId).toList()..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  @override
  Stream<List<Room>> watchByHome(String homeId) async* {
    yield _byHome(homeId);
    yield* _changes.stream.map((_) => _byHome(homeId));
  }

  @override
  Future<List<Room>> getByHome(String homeId) async => _byHome(homeId);
  @override
  Future<Room?> get(String id) async => _rooms[id];
  @override
  Future<void> insert(Room room) async {
    _rooms[room.id] = room;
    _changes.add(null);
  }

  @override
  Future<void> update(Room room) => insert(room);
  @override
  Future<void> delete(String id) async {
    _rooms.remove(id);
    _changes.add(null);
  }
}

class FakeLightRepository implements LightRepository {
  final Map<String, Light> _lights = {};
  final _changes = StreamController<void>.broadcast();
  void seed(List<Light> lights) {
    for (var l in lights) {
      _lights[l.id] = l;
    }
    _changes.add(null);
  }

  List<Light> _sorted(Iterable<Light> l) => l.toList()..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  List<Light> byHome(String homeId) => _sorted(_lights.values.where((l) => l.homeId == homeId));
  List<Light> byRoom(String roomId) => _sorted(_lights.values.where((l) => l.roomId == roomId));
  @override
  Stream<List<Light>> watchByHome(String homeId) async* {
    yield byHome(homeId);
    yield* _changes.stream.map((_) => byHome(homeId));
  }

  @override
  Stream<List<Light>> watchByRoom(String roomId) async* {
    yield byRoom(roomId);
    yield* _changes.stream.map((_) => byRoom(roomId));
  }

  @override
  Stream<Light?> watch(String id) async* {
    yield _lights[id];
    yield* _changes.stream.map((_) => _lights[id]);
  }

  @override
  Future<List<Light>> getByHome(String homeId) async => byHome(homeId);
  @override
  Future<List<Light>> getByRoom(String roomId) async => byRoom(roomId);
  @override
  Future<Light?> get(String id) async => _lights[id];
  @override
  Future<Light?> getByMac(String homeId, String mac) async => _lights.values.where((l) => l.homeId == homeId && l.mac == mac).firstOrNull;
  @override
  Future<void> insert(Light light) async {
    _lights[light.id] = light;
    _changes.add(null);
  }

  @override
  Future<void> update(Light light) => insert(light);
  @override
  Future<void> delete(String id) async {
    _lights.remove(id);
    _changes.add(null);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  late final _Replay<AppSettings> _settings = _Replay(AppSettings.defaults);
  @override
  Stream<AppSettings> watch() => _settings.stream;
  @override
  Future<AppSettings> get() async => _settings.value;
  @override
  Future<void> save(AppSettings settings) async => _settings.set(settings);
}

class FakeLiveStatePersistence implements LiveStatePersistence {
  Map<String, LiveState> stored = {};
  int saves = 0;
  @override
  Future<Map<String, LiveState>> load() async => stored;
  @override
  Future<void> save(Map<String, LiveState> states) async {
    stored = Map.of(states);
    saves++;
  }
}

class FakeClock implements Clock {
  DateTime current;
  final List<Duration> delays = [];
  FakeClock([DateTime? start]) : current = start ?? DateTime(2026, 9, 8, 12);
  @override
  DateTime now() => current;
  @override
  Future<void> delay(Duration duration) async {
    delays.add(duration);
    current = current.add(duration);
  }
}

class SequenceIds implements IdGenerator {
  int _n = 0;
  @override
  String next() => 'id${++_n}';
}

/// Scripted bulbs. Each ip has a state; sends are recorded and applied to
/// the state so a later read sees them. `failing` ips throw on every call.
class FakeGateway implements DeviceGateway {
  final Map<String, LightState> states = {};
  final Map<String, BulbConfig> configs = {};
  final Map<String, DeviceFailure> failing = {};
  final List<(String ip, ControlSignal signal)> sends = [];
  final List<String> reads = [];
  List<DiscoveredLight> broadcastResult = [];
  List<ScanEvent> probeEvents = [];
  List<ScanEvent> sweepEvents = [];
  Duration sendLatency = Duration.zero;

  void _check(String ip) {
    var f = failing[ip];
    if (f != null) throw DeviceException(f);
  }

  @override
  Future<LightState> readState(String ip) async {
    reads.add(ip);
    _check(ip);
    return states[ip] ?? const LightState(isOn: false);
  }

  @override
  Future<BulbConfig> readConfig(String ip) async {
    _check(ip);
    return configs[ip] ?? const BulbConfig();
  }

  @override
  Future<void> send(String ip, ControlSignal signal) async {
    if (sendLatency > Duration.zero) await Future<void>.delayed(sendLatency);
    sends.add((ip, signal));
    _check(ip);
    var s = states[ip] ?? const LightState(isOn: false);
    states[ip] = LightState(
      isOn: signal.state ?? s.isOn,
      dimming: signal.dimming ?? s.dimming,
      r: signal.r ?? (signal.temperature != null || signal.sceneId != null ? null : s.r),
      g: signal.g ?? (signal.temperature != null || signal.sceneId != null ? null : s.g),
      b: signal.b ?? (signal.temperature != null || signal.sceneId != null ? null : s.b),
      temperature: signal.temperature ?? (signal.r != null || signal.sceneId != null ? null : s.temperature),
      sceneId: signal.sceneId ?? (signal.r != null || signal.temperature != null ? 0 : s.sceneId),
      speed: signal.speed ?? s.speed,
      mac: s.mac,
    );
  }

  @override
  Future<List<DiscoveredLight>> broadcast() async => broadcastResult;

  @override
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}) => Stream.fromIterable(probeEvents);

  @override
  Stream<ScanEvent> sweep({String? subnet}) => Stream.fromIterable(sweepEvents);
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain test/support
git commit -m "feat(domain): repository and gateway interfaces, clock, ids, target resolver, test fakes"
```

---

### Task 6: NetworkMonitor and NetworkInfo

**Files:**
- Create: `lib/domain/services/network_monitor.dart`, `lib/data/network/network_info.dart`
- Test: `test/domain/services/network_monitor_test.dart`, `test/data/network/network_info_test.dart`

**Interfaces:**
- Produces: `abstract interface class NetworkInfo { Future<String?> currentSubnet(); }` (in domain, next to the monitor); `class NetworkMonitor { NetworkMonitor(NetworkInfo info, {Duration interval = 5 s}); String? get current; Stream<String?> watchSubnet(); bool isOffNetwork(String? homeSubnet); Stream<bool> watchOffNetwork(String? homeSubnet); Future<void> refresh(); void start(); void stop(); void dispose(); }`; `class IoNetworkInfo implements NetworkInfo` (data) with `static String? subnetOf(List<String> addresses)` (RFC1918 preference, same as the package) exposed for tests.

- [ ] **Step 1: Write the failing tests**

`test/domain/services/network_monitor_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

class ScriptedInfo implements NetworkInfo {
  String? subnet;
  int calls = 0;
  ScriptedInfo(this.subnet);
  @override
  Future<String?> currentSubnet() async {
    calls++;
    return subnet;
  }
}

void main() {
  test('off network when the home has a subnet and the current one differs or is missing', () async {
    var info = ScriptedInfo('192.168.1');
    var m = NetworkMonitor(info);
    await m.refresh();
    expect(m.isOffNetwork('192.168.1'), isFalse);
    expect(m.isOffNetwork('10.0.0'), isTrue);
    expect(m.isOffNetwork(null), isFalse);
    info.subnet = null;
    await m.refresh();
    expect(m.isOffNetwork('192.168.1'), isTrue);
    m.dispose();
  });

  test('polls on the interval while started and emits changes', () {
    fakeAsync((async) {
      var info = ScriptedInfo('192.168.1');
      var m = NetworkMonitor(info, interval: const Duration(seconds: 5));
      var seen = <bool>[];
      m.watchOffNetwork('192.168.1').listen(seen.add);
      m.start();
      async.elapse(const Duration(seconds: 1));
      info.subnet = '10.0.0';
      async.elapse(const Duration(seconds: 5));
      info.subnet = '192.168.1';
      async.elapse(const Duration(seconds: 5));
      m.stop();
      async.elapse(const Duration(seconds: 20));
      expect(info.calls, 3);
      expect(seen, [false, true, false]);
      m.dispose();
    });
  });
}
```

`test/data/network/network_info_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/network/network_info.dart';

void main() {
  test('prefers RFC1918 space over a VPN address and drops loopback', () {
    expect(IoNetworkInfo.subnetOf(['100.64.3.9', '192.168.1.42']), '192.168.1');
    expect(IoNetworkInfo.subnetOf(['127.0.0.1', '10.20.30.40']), '10.20.30');
    expect(IoNetworkInfo.subnetOf(['172.16.5.5']), '172.16.5');
    expect(IoNetworkInfo.subnetOf(['100.64.3.9']), '100.64.3');
    expect(IoNetworkInfo.subnetOf(['127.0.0.1']), isNull);
    expect(IoNetworkInfo.subnetOf([]), isNull);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/services/network_monitor_test.dart test/data`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/domain/services/network_monitor.dart`:

```dart
import 'dart:async';

/// Where this device is on the network right now.
abstract interface class NetworkInfo {
  /// The `a.b.c` prefix of the LAN address, or null with no IPv4 address.
  Future<String?> currentSubnet();
}

/// Off network = the home has a subnet and this device is not on it
/// (spec §5.9). No SSID reads, no location permission.
class NetworkMonitor {
  final NetworkInfo _info;
  final Duration interval;
  final StreamController<String?> _subnet = StreamController.broadcast();
  String? _current;
  Timer? _timer;
  bool _known = false;

  NetworkMonitor(this._info, {this.interval = const Duration(seconds: 5)});

  String? get current => _current;

  Stream<String?> watchSubnet() async* {
    if (_known) yield _current;
    yield* _subnet.stream;
  }

  bool isOffNetwork(String? homeSubnet) {
    if (homeSubnet == null) return false;
    if (!_known) return false;
    return _current != homeSubnet;
  }

  Stream<bool> watchOffNetwork(String? homeSubnet) =>
      watchSubnet().map((_) => isOffNetwork(homeSubnet)).distinct();

  Future<void> refresh() async {
    var next = await _info.currentSubnet();
    var changed = !_known || next != _current;
    _known = true;
    _current = next;
    if (changed && !_subnet.isClosed) _subnet.add(next);
  }

  void start() {
    _timer?.cancel();
    unawaited(refresh());
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _subnet.close();
  }
}
```

`lib/data/network/network_info.dart`:

```dart
import 'dart:io';

import '../../domain/services/network_monitor.dart';

/// Reads the interfaces with `dart:io`. Same preference as the wizctl
/// package: RFC1918 first, so a VPN adapter never wins over the LAN.
class IoNetworkInfo implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async {
    var interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false);
    return subnetOf([for (var i in interfaces) for (var a in i.addresses) a.address]);
  }

  static String? subnetOf(List<String> addresses) {
    String? fallback;
    for (var address in addresses) {
      var octets = address.split('.');
      if (octets.length != 4) continue;
      if (octets[0] == '127') continue;
      var base = octets.take(3).join('.');
      if (_isPrivate(octets)) return base;
      fallback ??= base;
    }
    return fallback;
  }

  static bool _isPrivate(List<String> octets) {
    var first = int.tryParse(octets[0]);
    var second = int.tryParse(octets[1]);
    if (first == null || second == null) return false;
    return first == 10 || (first == 192 && second == 168) || (first == 172 && second >= 16 && second <= 31);
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain test/data && dart format lib test && flutter analyze --fatal-infos
git add lib/domain lib/data test/domain test/data
git commit -m "feat: NetworkMonitor and IoNetworkInfo"
```

---
### Task 7: DeviceCommandPipeline

**Files:**
- Create: `lib/domain/services/device_command_pipeline.dart`
- Test: `test/domain/services/device_command_pipeline_test.dart`

**Interfaces:**
- Produces: `class CommandItem { Light light; ControlSignal signal; LiveState Function(LiveState) patch; }`; `class CommandBatch { List<CommandItem> items; String? description; String? throttleKey; }`; `class DeviceCommandPipeline { DeviceCommandPipeline({required DeviceGateway gateway, required LiveStateStore store, required NetworkMonitor network, required Future<String?> Function() homeSubnet, required Clock clock, required IdGenerator ids, Duration throttle = 120 ms}); Stream<CommandReport> get reports; Future<void> run(CommandBatch batch); Future<void> retry(String reportId); void dispose(); }`.
- Behaviour (spec §5.11): off network fails fast with one `CommandFailed(OffNetworkFailure)` and no patch; otherwise patches are applied optimistically, `CommandPending` is emitted, every item is sent in parallel, failures revert that light and mark it unreachable with a `CommandFailed`, and `CommandSucceeded` is emitted when every item succeeded. Batches sharing a `throttleKey` coalesce: while one is in flight the newest replaces any waiting one; the waiting one is sent when the in-flight one completes and at least `throttle` has passed since the previous send. Default description: "Sending to <name>" or "Sending to <n> lights".

- [ ] **Step 1: Write the failing test**

`test/domain/services/device_command_pipeline_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';

class _Net implements NetworkInfo {
  String? subnet = '192.168.1';
  @override
  Future<String?> currentSubnet() async => subnet;
}

Light light(String id, {String? name}) => Light(id: id, homeId: 'h', roomId: 'r', name: name ?? id, ip: '192.168.1.$id', mac: id, bulbClass: BulbClass.rgb, fixture: Fixture.bulb, addedAt: DateTime(2026));

void main() {
  late FakeGateway gateway;
  late LiveStateStore store;
  late _Net net;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late List<CommandReport> reports;

  setUp(() async {
    gateway = FakeGateway();
    store = LiveStateStore();
    net = _Net();
    monitor = NetworkMonitor(net);
    await monitor.refresh();
    pipeline = DeviceCommandPipeline(gateway: gateway, store: store, network: monitor, homeSubnet: () async => '192.168.1', clock: FakeClock(), ids: SequenceIds());
    reports = [];
    pipeline.reports.listen(reports.add);
  });

  CommandBatch batch(List<Light> lights, int brightness, {String? key}) => CommandBatch(
    items: [for (var l in lights) CommandItem(light: l, signal: ControlSignal(dimming: brightness), patch: (s) => s.copyWith(brightness: brightness))],
    throttleKey: key,
  );

  test('applies optimistically, sends, and reports pending then succeeded', () async {
    await pipeline.run(batch([light('1', name: 'Hallway')], 70));
    expect(store.of('1').brightness, 70);
    expect(store.of('1').reachable, isTrue);
    expect(gateway.sends.single.$1, '192.168.1.1');
    expect(gateway.sends.single.$2.dimming, 70);
    expect(reports, [const CommandPending('id1', ['1'], 'Sending to Hallway'), const CommandSucceeded('id1')]);
  });

  test('a failing light reverts, goes unreachable and can be retried', () async {
    store.put('1', LiveState.initial.copyWith(brightness: 30, reachable: true));
    gateway.failing['192.168.1.1'] = const TimeoutFailure('192.168.1.1', 3);
    await pipeline.run(batch([light('1'), light('2')], 70));
    expect(store.of('1').brightness, 30);
    expect(store.of('1').reachable, isFalse);
    expect(store.of('2').brightness, 70);
    expect(reports.whereType<CommandFailed>().single.lightId, '1');
    expect(reports.whereType<CommandSucceeded>(), isEmpty);
    expect(reports.first, isA<CommandPending>());
    expect((reports.first as CommandPending).description, 'Sending to 2 lights');

    gateway.failing.clear();
    await pipeline.retry('id1');
    expect(store.of('1').brightness, 70);
    expect(store.of('1').reachable, isTrue);
    expect(reports.last, const CommandSucceeded('id1'));

    gateway.failing['192.168.1.1'] = const TimeoutFailure('192.168.1.1', 3);
    await pipeline.run(batch([light('1')], 80));
    await pipeline.retry('id2');
    expect(reports.last, isA<CommandRetryFailed>());
    expect(store.of('1').brightness, 70);
  });

  test('off network fails fast without sending or patching', () async {
    net.subnet = '10.0.0';
    await monitor.refresh();
    await pipeline.run(batch([light('1')], 70));
    expect(gateway.sends, isEmpty);
    expect(store.of('1').brightness, LiveState.initial.brightness);
    expect(reports.single, isA<CommandFailed>());
    expect((reports.single as CommandFailed).failure, isA<OffNetworkFailure>());
  });

  test('batches with one throttle key coalesce to first and last', () {
    fakeAsync((async) {
      gateway.sendLatency = const Duration(milliseconds: 50);
      pipeline.run(batch([light('1')], 20, key: 'b'));
      pipeline.run(batch([light('1')], 40, key: 'b'));
      pipeline.run(batch([light('1')], 60, key: 'b'));
      expect(store.of('1').brightness, 60);
      async.elapse(const Duration(milliseconds: 500));
      expect(gateway.sends.map((s) => s.$2.dimming), [20, 60]);
      expect(store.of('1').brightness, 60);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/services/device_command_pipeline_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/domain/services/device_command_pipeline.dart`:

```dart
import 'dart:async';

import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'clock.dart';
import 'device_gateway.dart';
import 'id_generator.dart';
import 'live_state_store.dart';
import 'network_monitor.dart';

class CommandItem {
  final Light light;
  final ControlSignal signal;
  final LiveState Function(LiveState current) patch;

  const CommandItem({required this.light, required this.signal, required this.patch});
}

class CommandBatch {
  final List<CommandItem> items;
  final String? description;

  /// Batches sharing a key coalesce while one is in flight (dial drags).
  final String? throttleKey;

  const CommandBatch({required this.items, this.description, this.throttleKey});
}

class _Attempt {
  final CommandItem item;
  final LiveState previous;
  const _Attempt(this.item, this.previous);
}

/// Every write goes through here: optimistic in the store, honest in the
/// reports (spec §5.11).
class DeviceCommandPipeline {
  final DeviceGateway _gateway;
  final LiveStateStore _store;
  final NetworkMonitor _network;
  final Future<String?> Function() _homeSubnet;
  final Clock _clock;
  final IdGenerator _ids;
  final Duration throttle;

  final StreamController<CommandReport> _reports = StreamController.broadcast();
  final Map<String, _Attempt> _failed = {};
  final Set<String> _inFlight = {};
  final Map<String, CommandBatch> _waiting = {};
  final Map<String, DateTime> _lastSent = {};

  DeviceCommandPipeline({
    required DeviceGateway gateway,
    required LiveStateStore store,
    required NetworkMonitor network,
    required Future<String?> Function() homeSubnet,
    required Clock clock,
    required IdGenerator ids,
    this.throttle = const Duration(milliseconds: 120),
  })  : _gateway = gateway,
        _store = store,
        _network = network,
        _homeSubnet = homeSubnet,
        _clock = clock,
        _ids = ids;

  Stream<CommandReport> get reports => _reports.stream;

  String _describe(CommandBatch batch) =>
      batch.description ?? (batch.items.length == 1 ? 'Sending to ${batch.items.single.light.name}' : 'Sending to ${batch.items.length} lights');

  Future<void> run(CommandBatch batch) async {
    if (batch.items.isEmpty) return;
    var home = await _homeSubnet();
    if (_network.isOffNetwork(home)) {
      var first = batch.items.first.light;
      _emit(CommandFailed(_ids.next(), first.id, first.name, first.ip, OffNetworkFailure(home, _network.current)));
      return;
    }
    // Optimistic: the UI shows the new value at once, whatever happens next.
    var attempts = [for (var item in batch.items) _Attempt(item, _store.of(item.light.id))];
    for (var a in attempts) {
      _store.update(a.item.light.id, a.item.patch);
    }
    var key = batch.throttleKey;
    if (key != null && _inFlight.contains(key)) {
      _waiting[key] = batch;
      return;
    }
    if (key != null) _inFlight.add(key);
    try {
      await _send(attempts, _describe(batch), key);
    } finally {
      if (key != null) {
        _inFlight.remove(key);
        var next = _waiting.remove(key);
        if (next != null) {
          var since = _clock.now().difference(_lastSent[key] ?? _clock.now());
          if (since < throttle) await _clock.delay(throttle - since);
          // Re-run resolves the latest value for this key; its patches were
          // already applied when it was queued, so re-applying is harmless.
          unawaited(run(next));
        }
      }
    }
  }

  Future<void> _send(List<_Attempt> attempts, String description, String? key) async {
    var id = _ids.next();
    _emit(CommandPending(id, [for (var a in attempts) a.item.light.id], description));
    if (key != null) _lastSent[key] = _clock.now();
    var results = await Future.wait(attempts.map((a) => _sendOne(id, a)));
    if (results.every((ok) => ok)) _emit(CommandSucceeded(id));
  }

  Future<bool> _sendOne(String id, _Attempt a) async {
    var light = a.item.light;
    try {
      await _gateway.send(light.ip, a.item.signal);
      _store.update(light.id, (s) => s.copyWith(reachable: true, updatedAt: _clock.now()));
      return true;
    } on DeviceException catch (e) {
      _store.put(light.id, a.previous.copyWith(reachable: false));
      _failed[id] = a;
      _emit(CommandFailed(id, light.id, light.name, light.ip, e.failure));
      return false;
    } catch (e) {
      _store.put(light.id, a.previous.copyWith(reachable: false));
      _failed[id] = a;
      _emit(CommandFailed(id, light.id, light.name, light.ip, UnreachableFailure(light.ip, '$e')));
      return false;
    }
  }

  /// Re-send the failed light's signal once.
  Future<void> retry(String reportId) async {
    var a = _failed.remove(reportId);
    if (a == null) return;
    var light = a.item.light;
    var before = _store.of(light.id);
    _store.update(light.id, a.item.patch);
    try {
      await _gateway.send(light.ip, a.item.signal);
      _store.update(light.id, (s) => s.copyWith(reachable: true, updatedAt: _clock.now()));
      _emit(CommandSucceeded(reportId));
    } catch (_) {
      _store.put(light.id, before.copyWith(reachable: false));
      _emit(CommandRetryFailed(reportId, light.id, light.name));
    }
  }

  void _emit(CommandReport report) {
    if (!_reports.isClosed) _reports.add(report);
  }

  void dispose() => _reports.close();
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): the optimistic device command pipeline"
```

---

### Task 8: Control use cases

**Files:**
- Create: `lib/domain/usecases/set_power.dart`, `set_brightness.dart`, `set_kelvin.dart`, `set_speed.dart`, `apply_colour.dart`, `apply_white.dart`, `apply_scene.dart`, `lib/domain/usecases/usecases.dart` (barrel, grows in later tasks)
- Test: `test/domain/usecases/control_usecases_test.dart`

**Interfaces:**
- Each takes `({required TargetResolver resolver, required LiveStateStore store, required DeviceCommandPipeline pipeline})` and has:

```dart
SetPower.call(ModeTarget target, bool on) → Future<void>
SetBrightness.call(ModeTarget target, int value) → Future<void>          // throttle 'brightness:<key>', clamps 10–100, eligible: brightness capability
SetKelvin.call(ModeTarget target, int kelvin) → Future<void>              // throttle 'kelvin:<key>', snaps to 50, eligible: kelvin capability
SetSpeed.call(ModeTarget target, int speed) → Future<void>                // throttle 'speed:<key>', eligible: currently on a dynamic scene
ApplyColour.call(ModeTarget target, Rgb rgb) → Future<int>                // eligible count; RGB only
ApplyWhite.call(ModeTarget target, int kelvin) → Future<int>              // RGB and TW
ApplyScene.call(ModeTarget target, int sceneId, {int? speed}) → Future<int> // all but sockets; speed only for dynamic scenes
```

- [ ] **Step 1: Write the failing test**

`test/domain/usecases/control_usecases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';

class _Net implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async => '192.168.1';
}

Light light(String id, BulbClass cls) => Light(id: id, homeId: 'h', roomId: 'r', name: id, ip: '192.168.1.$id', mac: id, bulbClass: cls, fixture: Fixture.bulb, addedAt: DateTime(2026));

void main() {
  late FakeGateway gateway;
  late LiveStateStore store;
  late FakeLightRepository lights;
  late DeviceCommandPipeline pipeline;
  late TargetResolver resolver;

  setUp(() async {
    gateway = FakeGateway();
    store = LiveStateStore();
    lights = FakeLightRepository()..seed([light('1', BulbClass.rgb), light('2', BulbClass.tw), light('3', BulbClass.dw), light('4', BulbClass.socket)]);
    var monitor = NetworkMonitor(_Net());
    await monitor.refresh();
    pipeline = DeviceCommandPipeline(gateway: gateway, store: store, network: monitor, homeSubnet: () async => '192.168.1', clock: FakeClock(), ids: SequenceIds());
    resolver = TargetResolver(lights);
  });

  test('power reaches everything', () async {
    await SetPower(resolver: resolver, store: store, pipeline: pipeline)(const WholeHomeTarget('h'), true);
    expect(gateway.sends, hasLength(4));
    expect(gateway.sends.every((s) => s.$2.state == true), isTrue);
    expect(store.of('4').isOn, isTrue);
  });

  test('brightness skips the plug, clamps and turns on', () async {
    await SetBrightness(resolver: resolver, store: store, pipeline: pipeline)(const WholeHomeTarget('h'), 150);
    expect(gateway.sends.map((s) => s.$1), ['192.168.1.1', '192.168.1.2', '192.168.1.3']);
    expect(gateway.sends.first.$2.dimming, maxBrightness);
    expect(gateway.sends.first.$2.state, isTrue);
    expect(store.of('1').brightness, 100);
    expect(store.of('4').brightness, LiveState.initial.brightness);
  });

  test('kelvin reaches only white-capable bulbs and snaps', () async {
    await SetKelvin(resolver: resolver, store: store, pipeline: pipeline)(const RoomTarget('r'), 2712);
    expect(gateway.sends.map((s) => s.$1), ['192.168.1.1', '192.168.1.2']);
    expect(gateway.sends.first.$2.temperature, 2700);
    expect(store.of('1').active, ActiveChannel.white);
    expect(store.of('1').kelvin, 2700);
  });

  test('speed reaches only lights on a dynamic scene', () async {
    store.put('1', LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 1));
    store.put('2', LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 6));
    await SetSpeed(resolver: resolver, store: store, pipeline: pipeline)(const WholeHomeTarget('h'), 150);
    expect(gateway.sends.map((s) => s.$1), ['192.168.1.1']);
    expect(store.of('1').speed, 150);
  });

  test('colour writes only to RGB and reports the count', () async {
    var n = await ApplyColour(resolver: resolver, store: store, pipeline: pipeline)(const WholeHomeTarget('h'), const Rgb(255, 0, 0));
    expect(n, 1);
    expect(gateway.sends.single.$2.r, 255);
    expect(store.of('1').active, ActiveChannel.colour);
    expect(store.of('1').isOn, isTrue);
    expect(await ApplyColour(resolver: resolver, store: store, pipeline: pipeline)(const LightTarget('2'), const Rgb(1, 1, 1)), 0);
  });

  test('white writes to RGB and TW; scenes to everything but plugs', () async {
    expect(await ApplyWhite(resolver: resolver, store: store, pipeline: pipeline)(const WholeHomeTarget('h'), 4000), 2);
    gateway.sends.clear();
    expect(await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(const WholeHomeTarget('h'), 1, speed: 150), 3);
    expect(gateway.sends.every((s) => s.$2.sceneId == 1 && s.$2.speed == 150 && s.$2.state == true), isTrue);
    gateway.sends.clear();
    expect(await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(const LightTarget('1'), 6), 1);
    expect(gateway.sends.single.$2.speed, isNull);
    expect(store.of('1').sceneId, 6);
    expect(store.of('1').active, ActiveChannel.scene);
    expect(await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(const LightTarget('4'), 6), 0);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/usecases`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/domain/usecases/target_command.dart` (shared base):

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/device_command_pipeline.dart';
import '../services/live_state_store.dart';
import '../services/target_resolver.dart';

/// Shared plumbing for writes aimed at a target: resolve the lights, keep
/// the eligible ones, build one item each, hand the batch to the pipeline.
abstract class TargetCommand {
  final TargetResolver resolver;
  final LiveStateStore store;
  final DeviceCommandPipeline pipeline;

  const TargetCommand({required this.resolver, required this.store, required this.pipeline});

  Future<int> dispatch(
    ModeTarget target, {
    required bool Function(Light light, LiveState state) eligible,
    required ControlSignal Function(Light light, LiveState state) signal,
    required LiveState Function(LiveState state) patch,
    String? throttleKey,
  }) async {
    var lights = await resolver.resolve(target);
    var items = [
      for (var light in lights)
        if (eligible(light, store.of(light.id))) CommandItem(light: light, signal: signal(light, store.of(light.id)), patch: patch),
    ];
    if (items.isEmpty) return 0;
    await pipeline.run(CommandBatch(items: items, throttleKey: throttleKey));
    return items.length;
  }
}
```

`lib/domain/usecases/set_power.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'target_command.dart';

class SetPower extends TargetCommand {
  const SetPower({required super.resolver, required super.store, required super.pipeline});

  Future<void> call(ModeTarget target, bool on) => dispatch(
        target,
        eligible: (_, __) => true,
        signal: (_, __) => ControlSignal(state: on),
        patch: (s) => s.copyWith(isOn: on),
      );
}
```

`lib/domain/usecases/set_brightness.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

class SetBrightness extends TargetCommand {
  const SetBrightness({required super.resolver, required super.store, required super.pipeline});

  Future<void> call(ModeTarget target, int value) {
    var v = value.clamp(minBrightness, maxBrightness);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.brightness(light.bulbClass),
      signal: (_, __) => ControlSignal(state: true, dimming: v),
      patch: (s) => s.copyWith(brightness: v, isOn: true),
      throttleKey: 'brightness:${target.key}',
    );
  }
}
```

`lib/domain/usecases/set_kelvin.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import '../services/live_state_mapper.dart';
import 'target_command.dart';

class SetKelvin extends TargetCommand {
  const SetKelvin({required super.resolver, required super.store, required super.pipeline});

  Future<void> call(ModeTarget target, int kelvin) {
    var k = LiveStateMapper.snapKelvin(kelvin);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.kelvin(light.bulbClass),
      signal: (_, __) => ControlSignal(temperature: k),
      patch: (s) => s.copyWith(kelvin: k, active: ActiveChannel.white),
      throttleKey: 'kelvin:${target.key}',
    );
  }
}
```

`lib/domain/usecases/set_speed.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

class SetSpeed extends TargetCommand {
  const SetSpeed({required super.resolver, required super.store, required super.pipeline});

  Future<void> call(ModeTarget target, int speed) {
    var v = speed.clamp(minSpeed, maxSpeed);
    return dispatch(
      target,
      eligible: (_, state) => CapabilityRules.speed(state),
      signal: (_, __) => ControlSignal(speed: v),
      patch: (s) => s.copyWith(speed: v),
      throttleKey: 'speed:${target.key}',
    );
  }
}
```

`lib/domain/usecases/apply_colour.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

/// Colour writes only to RGB bulbs. Returns how many took it; zero means
/// "No colour bulb here".
class ApplyColour extends TargetCommand {
  const ApplyColour({required super.resolver, required super.store, required super.pipeline});

  Future<int> call(ModeTarget target, Rgb rgb) => dispatch(
        target,
        eligible: (light, _) => CapabilityRules.colour(light.bulbClass),
        signal: (_, __) => ControlSignal(state: true, r: rgb.r, g: rgb.g, b: rgb.b),
        patch: (s) => s.copyWith(rgb: rgb, active: ActiveChannel.colour, isOn: true),
      );
}
```

`lib/domain/usecases/apply_white.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import '../services/live_state_mapper.dart';
import 'target_command.dart';

/// Whites write only to bulbs with a white channel. Zero means "No white
/// channel here".
class ApplyWhite extends TargetCommand {
  const ApplyWhite({required super.resolver, required super.store, required super.pipeline});

  Future<int> call(ModeTarget target, int kelvin) {
    var k = LiveStateMapper.snapKelvin(kelvin);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.kelvin(light.bulbClass),
      signal: (_, __) => ControlSignal(state: true, temperature: k),
      patch: (s) => s.copyWith(kelvin: k, active: ActiveChannel.white, isOn: true),
    );
  }
}
```

`lib/domain/usecases/apply_scene.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

/// Scenes reach everything but plugs. Speed travels with dynamic scenes only.
class ApplyScene extends TargetCommand {
  const ApplyScene({required super.resolver, required super.store, required super.pipeline});

  Future<int> call(ModeTarget target, int sceneId, {int? speed}) {
    var dynamic = CapabilityRules.isDynamicScene(sceneId);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.scenes(light.bulbClass),
      signal: (_, state) => ControlSignal(
        state: true,
        sceneId: sceneId,
        speed: dynamic ? (speed ?? state.speed).clamp(minSpeed, maxSpeed) : null,
      ),
      patch: (s) => s.copyWith(
        sceneId: sceneId,
        active: ActiveChannel.scene,
        isOn: true,
        speed: dynamic ? (speed ?? s.speed).clamp(minSpeed, maxSpeed) : s.speed,
      ),
    );
  }
}
```

`lib/domain/usecases/usecases.dart`:

```dart
export 'apply_colour.dart';
export 'apply_scene.dart';
export 'apply_white.dart';
export 'set_brightness.dart';
export 'set_kelvin.dart';
export 'set_power.dart';
export 'set_speed.dart';
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): power, brightness, kelvin, speed, colour, white and scene use cases"
```

---

### Task 9: RefreshStates and SyncCoordinator

**Files:**
- Create: `lib/domain/usecases/refresh_states.dart`, `lib/domain/services/sync_coordinator.dart`
- Modify: `lib/domain/usecases/usecases.dart` (export)
- Test: `test/domain/usecases/refresh_states_test.dart`, `test/domain/services/sync_coordinator_test.dart`

**Interfaces:**
- Produces: `class RefreshStates { RefreshStates({required DeviceGateway gateway, required LiveStateStore store, required LightRepository lights, required Clock clock, int concurrency = 8, int missesToUnreachable = 2}); Future<void> call(Iterable<String> lightIds); Future<void> forHome(String homeId); }`; `class PollScope { void update(Set<String> lightIds); void dispose(); }`; `class SyncCoordinator { SyncCoordinator({required RefreshStates refresh, required LightRepository lights, required SettingsRepository settings, Duration pollInterval = 10 s}); void activateHome(String? homeId); Future<void> onColdStart(); Future<void> onResumed(); void onPaused(); PollScope registerScope(Set<String> lightIds); void pauseForDiscovery(); void resumeAfterDiscovery(); Future<void> refreshAll(); void dispose(); }`.

- [ ] **Step 1: Write the failing tests**

`test/domain/usecases/refresh_states_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/usecases/refresh_states.dart';

import '../../support/fakes.dart';

Light light(String id) => Light(id: id, homeId: 'h', roomId: 'r', name: id, ip: '192.168.1.$id', mac: id, bulbClass: BulbClass.rgb, fixture: Fixture.bulb, addedAt: DateTime(2026));

void main() {
  test('reads every light, maps the state, and marks unreachable after two misses', () async {
    var gateway = FakeGateway();
    var store = LiveStateStore();
    var lights = FakeLightRepository()..seed([light('1'), light('2')]);
    gateway.states['192.168.1.1'] = const LightState(isOn: true, dimming: 80, temperature: 4000, rssi: -60);
    gateway.failing['192.168.1.2'] = const TimeoutFailure('192.168.1.2', 2);
    store.put('2', LiveState.initial.copyWith(reachable: true));
    var refresh = RefreshStates(gateway: gateway, store: store, lights: lights, clock: FakeClock());

    await refresh.forHome('h');
    expect(store.of('1').isOn, isTrue);
    expect(store.of('1').kelvin, 4000);
    expect(store.of('1').reachable, isTrue);
    expect(store.of('1').rssi, -60);
    expect(store.of('2').reachable, isTrue, reason: 'one miss is not unreachable');

    await refresh(['2']);
    expect(store.of('2').reachable, isFalse);

    gateway.failing.clear();
    gateway.states['192.168.1.2'] = const LightState(isOn: false);
    await refresh(['2']);
    expect(store.of('2').reachable, isTrue);
    expect(gateway.reads.where((ip) => ip == '192.168.1.2').length, 3);
  });

  test('ignores ids that no longer exist', () async {
    var refresh = RefreshStates(gateway: FakeGateway(), store: LiveStateStore(), lights: FakeLightRepository(), clock: FakeClock());
    await refresh(['ghost']);
  });
}
```

`test/domain/services/sync_coordinator_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/usecases/refresh_states.dart';

import '../../support/fakes.dart';

Light light(String id) => Light(id: id, homeId: 'h', roomId: 'r', name: id, ip: '192.168.1.$id', mac: id, bulbClass: BulbClass.rgb, fixture: Fixture.bulb, addedAt: DateTime(2026));

void main() {
  late FakeGateway gateway;
  late FakeLightRepository lights;
  late FakeSettingsRepository settings;
  late SyncCoordinator sync;

  setUp(() {
    gateway = FakeGateway();
    lights = FakeLightRepository()..seed([light('1'), light('2'), light('3')]);
    settings = FakeSettingsRepository();
    var refresh = RefreshStates(gateway: gateway, store: LiveStateStore(), lights: lights, clock: FakeClock());
    sync = SyncCoordinator(refresh: refresh, lights: lights, settings: settings, pollInterval: const Duration(seconds: 10));
  });

  test('polls the union of registered scopes every interval', () {
    fakeAsync((async) {
      sync.activateHome('h');
      var a = sync.registerScope({'1'});
      var b = sync.registerScope({'2'});
      async.elapse(const Duration(seconds: 10));
      expect(gateway.reads.toSet(), {'192.168.1.1', '192.168.1.2'});
      gateway.reads.clear();
      b.dispose();
      a.update({'3'});
      async.elapse(const Duration(seconds: 10));
      expect(gateway.reads, ['192.168.1.3']);
      gateway.reads.clear();
      sync.pauseForDiscovery();
      async.elapse(const Duration(seconds: 30));
      expect(gateway.reads, isEmpty);
      sync.resumeAfterDiscovery();
      async.elapse(const Duration(seconds: 10));
      expect(gateway.reads, ['192.168.1.3']);
      sync.dispose();
    });
  });

  test('cold start honours the re-scan setting; resume always refreshes all', () {
    fakeAsync((async) {
      sync.activateHome('h');
      settings.save(const AppSettings(activeHomeId: 'h', rescanOnLaunch: false));
      async.flushMicrotasks();
      sync.onColdStart();
      async.flushMicrotasks();
      expect(gateway.reads, isEmpty);
      sync.onResumed();
      async.flushMicrotasks();
      expect(gateway.reads.toSet(), {'192.168.1.1', '192.168.1.2', '192.168.1.3'});
      gateway.reads.clear();
      sync.onPaused();
      async.elapse(const Duration(seconds: 30));
      expect(gateway.reads, isEmpty);
      sync.dispose();
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/domain/usecases/refresh_states.dart`:

```dart
import '../entities/entities.dart';
import '../repositories/light_repository.dart';
import '../services/clock.dart';
import '../services/device_gateway.dart';
import '../services/live_state_mapper.dart';
import '../services/live_state_store.dart';

/// Reads the bulbs and updates the store (spec §5.8). One lost packet is
/// not "unreachable"; two consecutive misses are.
class RefreshStates {
  final DeviceGateway _gateway;
  final LiveStateStore _store;
  final LightRepository _lights;
  final Clock _clock;
  final int concurrency;
  final int missesToUnreachable;
  final Map<String, int> _misses = {};

  RefreshStates({
    required DeviceGateway gateway,
    required LiveStateStore store,
    required LightRepository lights,
    required Clock clock,
    this.concurrency = 8,
    this.missesToUnreachable = 2,
  })  : _gateway = gateway,
        _store = store,
        _lights = lights,
        _clock = clock;

  Future<void> forHome(String homeId) async => call((await _lights.getByHome(homeId)).map((l) => l.id));

  Future<void> call(Iterable<String> lightIds) async {
    var lights = <Light>[];
    for (var id in lightIds) {
      var light = await _lights.get(id);
      if (light != null) lights.add(light);
    }
    for (var start = 0; start < lights.length; start += concurrency) {
      await Future.wait(lights.skip(start).take(concurrency).map(_readOne));
    }
  }

  Future<void> _readOne(Light light) async {
    try {
      var state = await _gateway.readState(light.ip);
      _misses[light.id] = 0;
      _store.put(light.id, LiveStateMapper.fromLightState(state, previous: _store.of(light.id), now: _clock.now()));
    } on DeviceException {
      var misses = (_misses[light.id] ?? 0) + 1;
      _misses[light.id] = misses;
      if (misses >= missesToUnreachable) {
        _store.update(light.id, (s) => s.copyWith(reachable: false));
      }
    }
  }
}
```

`lib/domain/services/sync_coordinator.dart`:

```dart
import 'dart:async';

import '../repositories/light_repository.dart';
import '../repositories/settings_repository.dart';
import '../usecases/refresh_states.dart';

/// A screen's claim on polling: the lights it is showing right now.
class PollScope {
  final SyncCoordinator _owner;
  Set<String> _ids;

  PollScope._(this._owner, this._ids);

  void update(Set<String> lightIds) => _ids = lightIds;

  void dispose() => _owner._scopes.remove(this);
}

/// When the app reads the bulbs (spec §5.8): on cold start if the user
/// wants it, on resume, and every interval for whatever is on screen.
/// Polling pauses during discovery and while backgrounded.
class SyncCoordinator {
  final RefreshStates _refresh;
  final LightRepository _lights;
  final SettingsRepository _settings;
  final Duration pollInterval;
  final Set<PollScope> _scopes = {};
  String? _homeId;
  Timer? _timer;
  bool _background = false;
  bool _discovering = false;

  SyncCoordinator({
    required RefreshStates refresh,
    required LightRepository lights,
    required SettingsRepository settings,
    this.pollInterval = const Duration(seconds: 10),
  })  : _refresh = refresh,
        _lights = lights,
        _settings = settings;

  void activateHome(String? homeId) {
    _homeId = homeId;
    _restart();
  }

  PollScope registerScope(Set<String> lightIds) {
    var scope = PollScope._(this, lightIds);
    _scopes.add(scope);
    return scope;
  }

  Future<void> onColdStart() async {
    if ((await _settings.get()).rescanOnLaunch) await refreshAll();
  }

  Future<void> onResumed() async {
    _background = false;
    _restart();
    await refreshAll();
  }

  void onPaused() {
    _background = true;
    _timer?.cancel();
  }

  void pauseForDiscovery() => _discovering = true;

  void resumeAfterDiscovery() => _discovering = false;

  Future<void> refreshAll() async {
    var homeId = _homeId;
    if (homeId == null || _discovering) return;
    await _refresh.forHome(homeId);
  }

  /// One light now (after a retry, or when a detail screen opens), if it
  /// still exists.
  Future<void> refreshLight(String lightId) async {
    if (await _lights.get(lightId) == null) return;
    await _refresh([lightId]);
  }

  void _restart() {
    _timer?.cancel();
    if (_background || _homeId == null) return;
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (_discovering || _background) return;
    var ids = {for (var s in _scopes) ...s._ids};
    if (ids.isEmpty) return;
    await _refresh(ids);
  }

  void dispose() {
    _timer?.cancel();
    _scopes.clear();
  }
}
```

Add `export 'refresh_states.dart';` to `lib/domain/usecases/usecases.dart`.

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): RefreshStates and SyncCoordinator"
```

---

### Task 10: BlinkLight

**Files:**
- Create: `lib/domain/usecases/blink_light.dart`
- Modify: `lib/domain/usecases/usecases.dart`
- Test: `test/domain/usecases/blink_light_test.dart`

**Interfaces:**
- Produces: `class BlinkLight { BlinkLight({required DeviceGateway gateway, required Clock clock, Duration hold = 2 s}); Future<void> call(String ip, {BulbClass? bulbClass}); static ControlSignal blinkSignal(BulbClass? bulbClass, LightState captured); }`. Throws `DeviceException` if the read fails (no blink, the caller shows the timeout toast). Spec §5.10.

- [ ] **Step 1: Write the failing test**

`test/domain/usecases/blink_light_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/blink_light.dart';

import '../../support/fakes.dart';

void main() {
  test('reads, drives amber, holds two seconds, restores', () async {
    var gateway = FakeGateway();
    var clock = FakeClock();
    gateway.states['192.168.1.5'] = const LightState(isOn: true, dimming: 40, sceneId: 6, speed: 100);
    await BlinkLight(gateway: gateway, clock: clock)('192.168.1.5', bulbClass: BulbClass.rgb);
    expect(gateway.reads, ['192.168.1.5']);
    expect(gateway.sends, hasLength(2));
    var blink = gateway.sends.first.$2;
    expect((blink.r, blink.g, blink.b, blink.dimming, blink.state), (255, 176, 32, 100, true));
    expect(clock.delays, [const Duration(seconds: 2)]);
    var restore = gateway.sends.last.$2;
    expect(restore.sceneId, 6);
    expect(restore.dimming, 40);
    expect(restore.state, isTrue);
  });

  test('blink signals per class', () {
    const on = LightState(isOn: true, dimming: 50);
    const off = LightState(isOn: false, dimming: 50);
    expect(BlinkLight.blinkSignal(BulbClass.tw, on).temperature, 2700);
    expect(BlinkLight.blinkSignal(BulbClass.tw, on).dimming, 100);
    expect(BlinkLight.blinkSignal(BulbClass.dw, on).state, isFalse);
    expect(BlinkLight.blinkSignal(BulbClass.dw, off).state, isTrue);
    expect(BlinkLight.blinkSignal(BulbClass.dw, off).dimming, 100);
    expect(BlinkLight.blinkSignal(BulbClass.fanDim, on).state, isFalse);
    expect(BlinkLight.blinkSignal(BulbClass.socket, on).state, isFalse);
    expect(BlinkLight.blinkSignal(BulbClass.socket, off).state, isTrue);
    expect(BlinkLight.blinkSignal(BulbClass.socket, off).dimming, isNull);
    expect(BlinkLight.blinkSignal(null, on).r, 255);
  });

  test('a failed read means no blink', () async {
    var gateway = FakeGateway();
    gateway.failing['192.168.1.5'] = const TimeoutFailure('192.168.1.5', 2);
    await expectLater(BlinkLight(gateway: gateway, clock: FakeClock())('192.168.1.5'), throwsA(isA<DeviceException>()));
    expect(gateway.sends, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/usecases/blink_light_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/domain/usecases/blink_light.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../entities/rgb.dart';
import '../services/clock.dart';
import '../services/device_gateway.dart';

/// Blink to identify: read state, drive the bulb, wait, write the captured
/// state back. Not an animation; a real write and restore.
class BlinkLight {
  final DeviceGateway _gateway;
  final Clock _clock;
  final Duration hold;

  BlinkLight({required DeviceGateway gateway, required Clock clock, this.hold = const Duration(seconds: 2)})
      : _gateway = gateway,
        _clock = clock;

  /// What "blink" means per class (spec §5.10): RGB goes amber at full,
  /// tunable white goes 2700 K at full, dimmable and fan flip between off
  /// and full, a plug flips power. Unknown classes are treated as RGB.
  static ControlSignal blinkSignal(BulbClass? bulbClass, LightState captured) => switch (bulbClass) {
        BulbClass.rgb || null => ControlSignal(state: true, r: Rgb.amber.r, g: Rgb.amber.g, b: Rgb.amber.b, dimming: maxBrightness),
        BulbClass.tw => ControlSignal(state: true, temperature: 2700, dimming: maxBrightness),
        BulbClass.dw || BulbClass.fanDim => captured.isOn ? ControlSignal(state: false) : ControlSignal(state: true, dimming: maxBrightness),
        BulbClass.socket => ControlSignal(state: !captured.isOn),
      };

  Future<void> call(String ip, {BulbClass? bulbClass}) async {
    var captured = await _gateway.readState(ip);
    await _gateway.send(ip, blinkSignal(bulbClass, captured));
    await _clock.delay(hold);
    await _gateway.send(ip, ControlSignal.fromState(captured));
  }
}
```

Add `export 'blink_light.dart';` to the barrel.

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): BlinkLight"
```

---

### Task 11: RunDiscovery

**Files:**
- Create: `lib/domain/usecases/run_discovery.dart`
- Modify: `lib/domain/usecases/usecases.dart`
- Test: `test/domain/usecases/run_discovery_test.dart`

**Interfaces:**
- Produces: `enum DiscoveryMode { quick, sweep }`; `sealed class DiscoveryUpdate` with `PhaseChanged(DiscoveryProgress progress)`, `DeviceFound(DiscoveredDevice device, LiveState? initial)`, `DeviceUpdated(DiscoveredDevice device)`, `DiscoveryFinished(List<DiscoveredDevice> devices, String? subnet)`, `DiscoveryFailed(DeviceFailure failure)`; `class RunDiscovery { RunDiscovery({required DeviceGateway gateway, required LightRepository lights, required LiveStateStore store, required NetworkInfo network, required Clock clock}); Stream<DiscoveryUpdate> call({required String homeId, required DiscoveryMode mode, bool probeKnown = true}); }`.
- Behaviour (spec §5.7): `quick` = probe the home's known addresses (reachability, and the store updated for those lights) then broadcast; `sweep` = the unicast sweep with determinate progress. Every device is de-duplicated by MAC, enriched with `readConfig` when it lacks a module name and `readState` for its initial live state, and flagged `alreadySaved` when its MAC belongs to the home. Cancelling the stream cancels the underlying gateway stream.

- [ ] **Step 1: Write the failing test**

`test/domain/usecases/run_discovery_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/usecases/run_discovery.dart';

import '../../support/fakes.dart';

class _Net implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async => '192.168.1';
}

void main() {
  late FakeGateway gateway;
  late FakeLightRepository lights;
  late LiveStateStore store;
  late RunDiscovery run;

  setUp(() {
    gateway = FakeGateway();
    lights = FakeLightRepository()
      ..seed([Light(id: 'known', homeId: 'h', roomId: 'r', name: 'Hallway', ip: '192.168.1.118', mac: 'knownmac', bulbClass: BulbClass.dw, fixture: Fixture.bulb, addedAt: DateTime(2026))]);
    store = LiveStateStore();
    run = RunDiscovery(gateway: gateway, lights: lights, store: store, network: _Net(), clock: FakeClock());
  });

  test('quick mode probes known lights, then broadcasts, enriching new devices', () async {
    gateway.probeEvents = [
      const ScanProgress(addressesProbed: 1, addressCount: 1, fraction: 1),
      const ScanFound(DiscoveredLight(ip: '192.168.1.118', mac: 'knownmac', moduleName: 'ESP01_SHDW1C_31')),
      const ScanDone([DiscoveredLight(ip: '192.168.1.118', mac: 'knownmac', moduleName: 'ESP01_SHDW1C_31')]),
    ];
    gateway.states['192.168.1.118'] = const LightState(isOn: true, dimming: 50);
    gateway.broadcastResult = [const DiscoveredLight(ip: '192.168.1.126', mac: 'newmac')];
    gateway.configs['192.168.1.126'] = const BulbConfig(moduleName: 'ESP01_SHRGB1C_31', fwVersion: '1.25.0');
    gateway.states['192.168.1.126'] = const LightState(isOn: false, dimming: 70, temperature: 3000);

    var updates = await run(homeId: 'h', mode: DiscoveryMode.quick).toList();

    var phases = updates.whereType<PhaseChanged>().map((p) => p.progress.phase).toList();
    expect(phases.first, DiscoveryPhase.probingKnown);
    expect(phases, contains(DiscoveryPhase.broadcasting));
    var found = updates.whereType<DeviceFound>().toList();
    expect(found.map((f) => f.device.mac), ['knownmac', 'newmac']);
    expect(found.first.device.alreadySaved, isTrue);
    expect(store.of('known').isOn, isTrue, reason: 'known lights get their state refreshed');
    expect(found.last.device.bulbClass, BulbClass.rgb);
    expect(found.last.device.fwVersion, '1.25.0');
    expect(found.last.initial!.kelvin, 3000);
    var done = updates.last as DiscoveryFinished;
    expect(done.devices, hasLength(2));
    expect(done.subnet, '192.168.1');
  });

  test('sweep mode maps progress and richer replies', () async {
    gateway.sweepEvents = [
      const ScanProgress(addressesProbed: 16, addressCount: 254, fraction: 0.03, subnet: '192.168.1'),
      const ScanFound(DiscoveredLight(ip: '192.168.1.131', mac: 'm1')),
      const ScanUpdated(DiscoveredLight(ip: '192.168.1.131', mac: 'm1', moduleName: 'ESP01_SHTW1C_31')),
      const ScanProgress(addressesProbed: 254, addressCount: 254, fraction: 1, subnet: '192.168.1'),
      const ScanDone([DiscoveredLight(ip: '192.168.1.131', mac: 'm1', moduleName: 'ESP01_SHTW1C_31')]),
    ];
    var updates = await run(homeId: 'h', mode: DiscoveryMode.sweep).toList();
    var progress = updates.whereType<PhaseChanged>().map((p) => p.progress).toList();
    expect(progress.first.phase, DiscoveryPhase.sweeping);
    expect(progress.last.probed, 254);
    expect(progress.last.subnet, '192.168.1');
    expect(updates.whereType<DeviceFound>(), hasLength(1));
    expect(updates.whereType<DeviceUpdated>().single.device.bulbClass, BulbClass.tw);
    expect((updates.last as DiscoveryFinished).devices.single.bulbClass, BulbClass.tw);
  });

  test('a gateway failure surfaces as DiscoveryFailed', () async {
    gateway.failing['broadcast'] = const UnreachableFailure('255.255.255.255', 'no route');
    var updates = await run(homeId: 'h', mode: DiscoveryMode.quick, probeKnown: false).toList();
    expect(updates.last, isA<DiscoveryFailed>());
  });
}
```

For the failure test, extend `FakeGateway.broadcast` to throw when `failing['broadcast']` is set:

```dart
  @override
  Future<List<DiscoveredLight>> broadcast() async {
    _check('broadcast');
    return broadcastResult;
  }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/usecases/run_discovery_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/domain/usecases/run_discovery.dart`:

```dart
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
  const DiscoveryFinished(this.devices, this.subnet);
  @override
  List<Object?> get props => [devices, subnet];
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
  })  : _gateway = gateway,
        _lights = lights,
        _store = store,
        _network = network,
        _clock = clock;

  Stream<DiscoveryUpdate> call({required String homeId, required DiscoveryMode mode, bool probeKnown = true}) async* {
    var known = await _lights.getByHome(homeId);
    var knownByMac = {for (var l in known) l.mac: l};
    var byMac = <String, DiscoveredDevice>{};

    Future<(DiscoveredDevice, LiveState?)> enrich(DiscoveredLight raw) async {
      var device = DiscoveredDevice.fromDiscovered(raw, alreadySaved: knownByMac.containsKey(raw.mac));
      if (device.moduleName == null) {
        try {
          var config = await _gateway.readConfig(raw.ip);
          device = device.copyWith(moduleName: config.moduleName, bulbClass: config.bulbClass, fwVersion: config.fwVersion);
        } on DeviceException {
          // Older firmware: keep what discovery gave us.
        }
      }
      LiveState? initial;
      try {
        var state = await _gateway.readState(raw.ip);
        var saved = knownByMac[raw.mac];
        var previous = saved == null ? LiveState.initial : _store.of(saved.id);
        initial = LiveStateMapper.fromLightState(state, previous: previous, now: _clock.now());
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
        var richer = existing.copyWith(moduleName: raw.moduleName, bulbClass: raw.bulbClass, fwVersion: raw.fwVersion);
        byMac[raw.mac] = richer;
        return DeviceUpdated(richer);
      }
      return null;
    }

    try {
      if (mode == DiscoveryMode.quick) {
        if (probeKnown && known.isNotEmpty) {
          yield PhaseChanged(DiscoveryProgress(phase: DiscoveryPhase.probingKnown, total: known.length));
          await for (var event in _gateway.probe(known.map((l) => l.ip))) {
            switch (event) {
              case ScanProgress p:
                yield PhaseChanged(DiscoveryProgress(phase: DiscoveryPhase.probingKnown, probed: p.addressesProbed, total: p.addressCount, fraction: p.fraction));
              case ScanFound f:
                var u = await absorb(f.light);
                if (u != null) yield u;
              case ScanUpdated u:
                var up = await absorb(u.light);
                if (up != null) yield up;
              case ScanDone _:
                break;
            }
          }
        }
        yield const PhaseChanged(DiscoveryProgress(phase: DiscoveryPhase.broadcasting));
        for (var raw in await _gateway.broadcast()) {
          var u = await absorb(raw);
          if (u != null) yield u;
        }
      } else {
        yield const PhaseChanged(DiscoveryProgress(phase: DiscoveryPhase.sweeping));
        await for (var event in _gateway.sweep()) {
          switch (event) {
            case ScanProgress p:
              yield PhaseChanged(DiscoveryProgress(phase: DiscoveryPhase.sweeping, probed: p.addressesProbed, total: p.addressCount, fraction: p.fraction, subnet: p.subnet));
            case ScanFound f:
              var u = await absorb(f.light);
              if (u != null) yield u;
            case ScanUpdated u:
              var up = await absorb(u.light);
              if (up != null) yield up;
            case ScanDone _:
              break;
          }
        }
      }
      yield DiscoveryFinished(byMac.values.toList(), await _network.currentSubnet());
    } on DeviceException catch (e) {
      yield DiscoveryFailed(e.failure);
    }
  }
}
```

Add `export 'run_discovery.dart';` to the barrel.

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain test/support
git commit -m "feat(domain): RunDiscovery"
```

---

### Task 12: Home, room and light management use cases

**Files:**
- Create: `lib/domain/usecases/usecase_exceptions.dart`, `create_home.dart`, `switch_home.dart`, `rename_home.dart`, `delete_home.dart`, `add_room.dart`, `rename_room.dart`, `delete_room.dart`, `rename_light.dart`, `move_light.dart`, `set_fixture.dart`, `forget_light.dart`, `save_discovered_light.dart`, `finish_onboarding.dart`
- Modify: `lib/domain/usecases/usecases.dart`
- Test: `test/domain/usecases/management_usecases_test.dart`

**Interfaces:**

```dart
class DomainException implements Exception { String message; }
class LastHomeException extends DomainException; class RoomNotEmptyException extends DomainException; class AlreadySavedException extends DomainException; class EmptyNameException extends DomainException
CreateHome({homes, settings, ids, clock}).call(String name, {String? subnet}) → Future<Home>   // trims; empty → EmptyNameException; becomes active
SwitchHome({settings}).call(String homeId) → Future<void>
RenameHome({homes}).call(String id, String name) → Future<void>
DeleteHome({homes, settings}).call(String id) → Future<void>              // LastHomeException when it is the only one; active moves to the first remaining
AddRoom({rooms, ids}).call(String homeId, String name, RoomGlyph glyph) → Future<Room>   // sortIndex = current count
RenameRoom({rooms}).call(String id, String name) → Future<void>
DeleteRoom({rooms, lights}).call(String id) → Future<void>                 // RoomNotEmptyException while it holds lights
RenameLight({lights}).call(String id, String name) → Future<void>
MoveLight({lights}).call(String id, String roomId) → Future<void>
SetFixture({lights}).call(String id, Fixture fixture) → Future<void>
ForgetLight({lights, store}).call(String id) → Future<void>
SaveDiscoveredLight({lights, store, ids, clock}).call({required String homeId, required String roomId, required DiscoveredDevice device, required String alias, required Fixture fixture, LiveState? initial}) → Future<Light>   // AlreadySavedException on a duplicate MAC; empty alias falls back to the device name
class OnboardingRoom { String tempId; String name; RoomGlyph glyph; bool custom; }
class OnboardingLight { DiscoveredDevice device; String alias; String roomTempId; Fixture fixture; LiveState? initial; }
class OnboardingResult { String homeName; String? subnet; List<OnboardingRoom> rooms; List<OnboardingLight> lights; }
FinishOnboarding({homes, rooms, lights, settings, store, ids, clock}).call(OnboardingResult) → Future<Home>   // writes rooms that received a light plus custom rooms, in order; sets active
```

- [ ] **Step 1: Write the failing test**

`test/domain/usecases/management_usecases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';

void main() {
  late FakeHomeRepository homes;
  late FakeRoomRepository rooms;
  late FakeLightRepository lights;
  late FakeSettingsRepository settings;
  late LiveStateStore store;
  late SequenceIds ids;
  late FakeClock clock;

  setUp(() {
    homes = FakeHomeRepository();
    rooms = FakeRoomRepository();
    lights = FakeLightRepository();
    settings = FakeSettingsRepository();
    store = LiveStateStore();
    ids = SequenceIds();
    clock = FakeClock();
  });

  test('create, switch, rename and delete homes', () async {
    var create = CreateHome(homes: homes, settings: settings, ids: ids, clock: clock);
    var a = await create('  Kaverappa House ');
    expect(a.name, 'Kaverappa House');
    expect((await settings.get()).activeHomeId, a.id);
    await expectLater(create('   '), throwsA(isA<EmptyNameException>()));
    var b = await create('Studio', subnet: '10.0.0');
    expect((await settings.get()).activeHomeId, b.id);
    await SwitchHome(settings: settings)(a.id);
    expect((await settings.get()).activeHomeId, a.id);
    await RenameHome(homes: homes)(a.id, 'Home');
    expect((await homes.get(a.id))!.name, 'Home');
    await DeleteHome(homes: homes, settings: settings)(a.id);
    expect(await homes.getAll(), hasLength(1));
    expect((await settings.get()).activeHomeId, b.id);
    await expectLater(DeleteHome(homes: homes, settings: settings)(b.id), throwsA(isA<LastHomeException>()));
  });

  test('rooms: add with sort index, rename, delete only when empty', () async {
    var add = AddRoom(rooms: rooms, ids: ids);
    var living = await add('h', 'Living Room', RoomGlyph.sofa);
    var bed = await add('h', 'Bedroom', RoomGlyph.bed);
    expect(living.sortIndex, 0);
    expect(bed.sortIndex, 1);
    await RenameRoom(rooms: rooms)(bed.id, 'Bed room');
    expect((await rooms.get(bed.id))!.name, 'Bed room');
    lights.seed([Light(id: 'l', homeId: 'h', roomId: living.id, name: 'x', ip: 'i', mac: 'm', fixture: Fixture.bulb, addedAt: DateTime(2026))]);
    await expectLater(DeleteRoom(rooms: rooms, lights: lights)(living.id), throwsA(isA<RoomNotEmptyException>()));
    await DeleteRoom(rooms: rooms, lights: lights)(bed.id);
    expect(await rooms.getByHome('h'), hasLength(1));
  });

  test('lights: rename, move, fixture, forget, save discovered', () async {
    rooms.seed([const Room(id: 'r1', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa), const Room(id: 'r2', homeId: 'h', name: 'B', glyph: RoomGlyph.bed)]);
    var save = SaveDiscoveredLight(lights: lights, store: store, ids: ids, clock: clock);
    const device = DiscoveredDevice(ip: '192.168.1.126', mac: 'abc', moduleName: 'ESP01_SHRGB1C_31', bulbClass: BulbClass.rgb, fwVersion: '1.25.0');
    var light = await save(homeId: 'h', roomId: 'r1', device: device, alias: ' Bedside bulb ', fixture: Fixture.bulb, initial: LiveState.initial.copyWith(isOn: true));
    expect(light.name, 'Bedside bulb');
    expect(light.fwVersion, '1.25.0');
    expect(store.of(light.id).isOn, isTrue);
    await expectLater(save(homeId: 'h', roomId: 'r1', device: device, alias: 'again', fixture: Fixture.bulb), throwsA(isA<AlreadySavedException>()));
    var unnamed = await save(homeId: 'h', roomId: 'r1', device: device.copyWith(alreadySaved: false).copyWithMac('def'), alias: '', fixture: Fixture.desk);
    expect(unnamed.name, 'WiZ RGB');
    await RenameLight(lights: lights)(light.id, 'Lamp');
    await MoveLight(lights: lights)(light.id, 'r2');
    await SetFixture(lights: lights)(light.id, Fixture.strip);
    var updated = (await lights.get(light.id))!;
    expect((updated.name, updated.roomId, updated.fixture), ('Lamp', 'r2', Fixture.strip));
    await ForgetLight(lights: lights, store: store)(light.id);
    expect(await lights.get(light.id), isNull);
    expect(store.snapshot.containsKey(light.id), isFalse);
  });

  test('finish onboarding writes only used and custom rooms and activates the home', () async {
    var finish = FinishOnboarding(homes: homes, rooms: rooms, lights: lights, settings: settings, store: store, ids: ids, clock: clock);
    var home = await finish(OnboardingResult(
      homeName: 'Kaverappa House',
      subnet: '192.168.1',
      rooms: const [
        OnboardingRoom(tempId: 'living', name: 'Living Room', glyph: RoomGlyph.sofa, custom: false),
        OnboardingRoom(tempId: 'bedroom', name: 'Bedroom', glyph: RoomGlyph.bed, custom: false),
        OnboardingRoom(tempId: 'kitchen', name: 'Kitchen', glyph: RoomGlyph.utensils, custom: false),
        OnboardingRoom(tempId: 'study', name: 'Study', glyph: RoomGlyph.lampDesk, custom: true),
      ],
      lights: [
        OnboardingLight(device: const DiscoveredDevice(ip: '192.168.1.126', mac: 'a', bulbClass: BulbClass.rgb), alias: 'Ceiling dome light', roomTempId: 'living', fixture: Fixture.dome, initial: LiveState.initial.copyWith(isOn: true)),
        const OnboardingLight(device: DiscoveredDevice(ip: '192.168.1.140', mac: 'b', bulbClass: BulbClass.socket), alias: '', roomTempId: 'living', fixture: Fixture.socket),
      ],
    ));
    expect(home.subnet, '192.168.1');
    expect((await settings.get()).activeHomeId, home.id);
    var written = await rooms.getByHome(home.id);
    expect(written.map((r) => r.name), ['Living Room', 'Study']);
    var saved = await lights.getByHome(home.id);
    expect(saved.map((l) => l.name), ['Ceiling dome light', 'WiZ Smart Plug']);
    expect(saved.every((l) => l.roomId == written.first.id), isTrue);
    expect(store.of(saved.first.id).isOn, isTrue);
  });
}
```

Add to `DiscoveredDevice` (Task 1 file) a helper the test uses: `DiscoveredDevice copyWithMac(String mac)` returning the same device with another MAC.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/usecases/management_usecases_test.dart`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/domain/usecases/usecase_exceptions.dart`:

```dart
/// Failures the user can act on; presentation turns them into copy.
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);
  @override
  String toString() => message;
}

final class EmptyNameException extends DomainException {
  const EmptyNameException() : super('A name is required.');
}

final class LastHomeException extends DomainException {
  const LastHomeException() : super('A home is required. Add another before removing this one.');
}

final class RoomNotEmptyException extends DomainException {
  const RoomNotEmptyException() : super('Move its lights first.');
}

final class AlreadySavedException extends DomainException {
  const AlreadySavedException() : super('This light is already in this home.');
}
```

`lib/domain/usecases/create_home.dart`:

```dart
import '../entities/entities.dart';
import '../repositories/home_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/clock.dart';
import '../services/id_generator.dart';
import 'usecase_exceptions.dart';

class CreateHome {
  final HomeRepository _homes;
  final SettingsRepository _settings;
  final IdGenerator _ids;
  final Clock _clock;

  CreateHome({required HomeRepository homes, required SettingsRepository settings, required IdGenerator ids, required Clock clock})
      : _homes = homes, _settings = settings, _ids = ids, _clock = clock;

  Future<Home> call(String name, {String? subnet}) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var count = (await _homes.getAll()).length;
    var home = Home(id: _ids.next(), name: trimmed, subnet: subnet, createdAt: _clock.now(), sortIndex: count);
    await _homes.insert(home);
    await _settings.save((await _settings.get()).copyWith(activeHomeId: home.id));
    return home;
  }
}
```

`lib/domain/usecases/switch_home.dart`:

```dart
import '../repositories/settings_repository.dart';

class SwitchHome {
  final SettingsRepository _settings;
  SwitchHome({required SettingsRepository settings}) : _settings = settings;

  Future<void> call(String homeId) async => _settings.save((await _settings.get()).copyWith(activeHomeId: homeId));
}
```

`lib/domain/usecases/rename_home.dart`:

```dart
import '../repositories/home_repository.dart';
import 'usecase_exceptions.dart';

class RenameHome {
  final HomeRepository _homes;
  RenameHome({required HomeRepository homes}) : _homes = homes;

  Future<void> call(String id, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var home = await _homes.get(id);
    if (home != null) await _homes.update(home.copyWith(name: trimmed));
  }
}
```

`lib/domain/usecases/delete_home.dart`:

```dart
import '../repositories/home_repository.dart';
import '../repositories/settings_repository.dart';
import 'usecase_exceptions.dart';

class DeleteHome {
  final HomeRepository _homes;
  final SettingsRepository _settings;
  DeleteHome({required HomeRepository homes, required SettingsRepository settings}) : _homes = homes, _settings = settings;

  Future<void> call(String id) async {
    var all = await _homes.getAll();
    if (all.length <= 1) throw const LastHomeException();
    await _homes.delete(id);
    var settings = await _settings.get();
    if (settings.activeHomeId == id) {
      var remaining = all.where((h) => h.id != id).first;
      await _settings.save(settings.copyWith(activeHomeId: remaining.id));
    }
  }
}
```

`lib/domain/usecases/add_room.dart`:

```dart
import '../entities/entities.dart';
import '../repositories/room_repository.dart';
import '../services/id_generator.dart';
import 'usecase_exceptions.dart';

class AddRoom {
  final RoomRepository _rooms;
  final IdGenerator _ids;
  AddRoom({required RoomRepository rooms, required IdGenerator ids}) : _rooms = rooms, _ids = ids;

  Future<Room> call(String homeId, String name, RoomGlyph glyph) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var count = (await _rooms.getByHome(homeId)).length;
    var room = Room(id: _ids.next(), homeId: homeId, name: trimmed, glyph: glyph, sortIndex: count);
    await _rooms.insert(room);
    return room;
  }
}
```

`lib/domain/usecases/rename_room.dart`:

```dart
import '../repositories/room_repository.dart';
import 'usecase_exceptions.dart';

class RenameRoom {
  final RoomRepository _rooms;
  RenameRoom({required RoomRepository rooms}) : _rooms = rooms;

  Future<void> call(String id, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var room = await _rooms.get(id);
    if (room != null) await _rooms.update(room.copyWith(name: trimmed));
  }
}
```

`lib/domain/usecases/delete_room.dart`:

```dart
import '../repositories/light_repository.dart';
import '../repositories/room_repository.dart';
import 'usecase_exceptions.dart';

class DeleteRoom {
  final RoomRepository _rooms;
  final LightRepository _lights;
  DeleteRoom({required RoomRepository rooms, required LightRepository lights}) : _rooms = rooms, _lights = lights;

  Future<void> call(String id) async {
    if ((await _lights.getByRoom(id)).isNotEmpty) throw const RoomNotEmptyException();
    await _rooms.delete(id);
  }
}
```

`lib/domain/usecases/rename_light.dart`, `move_light.dart`, `set_fixture.dart`:

```dart
// rename_light.dart
import '../repositories/light_repository.dart';
import 'usecase_exceptions.dart';

class RenameLight {
  final LightRepository _lights;
  RenameLight({required LightRepository lights}) : _lights = lights;

  Future<void> call(String id, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var light = await _lights.get(id);
    if (light != null) await _lights.update(light.copyWith(name: trimmed));
  }
}

// move_light.dart
import '../repositories/light_repository.dart';

class MoveLight {
  final LightRepository _lights;
  MoveLight({required LightRepository lights}) : _lights = lights;

  Future<void> call(String id, String roomId) async {
    var light = await _lights.get(id);
    if (light != null) await _lights.update(light.copyWith(roomId: roomId));
  }
}

// set_fixture.dart
import '../entities/entities.dart';
import '../repositories/light_repository.dart';

class SetFixture {
  final LightRepository _lights;
  SetFixture({required LightRepository lights}) : _lights = lights;

  Future<void> call(String id, Fixture fixture) async {
    var light = await _lights.get(id);
    if (light != null) await _lights.update(light.copyWith(fixture: fixture));
  }
}
```

`lib/domain/usecases/forget_light.dart`:

```dart
import '../repositories/light_repository.dart';
import '../services/live_state_store.dart';

class ForgetLight {
  final LightRepository _lights;
  final LiveStateStore _store;
  ForgetLight({required LightRepository lights, required LiveStateStore store}) : _lights = lights, _store = store;

  Future<void> call(String id) async {
    await _lights.delete(id);
    _store.remove(id);
  }
}
```

`lib/domain/usecases/save_discovered_light.dart`:

```dart
import '../entities/entities.dart';
import '../repositories/light_repository.dart';
import '../services/clock.dart';
import '../services/id_generator.dart';
import '../services/live_state_store.dart';
import 'usecase_exceptions.dart';

class SaveDiscoveredLight {
  final LightRepository _lights;
  final LiveStateStore _store;
  final IdGenerator _ids;
  final Clock _clock;

  SaveDiscoveredLight({required LightRepository lights, required LiveStateStore store, required IdGenerator ids, required Clock clock})
      : _lights = lights, _store = store, _ids = ids, _clock = clock;

  Future<Light> call({
    required String homeId,
    required String roomId,
    required DiscoveredDevice device,
    required String alias,
    required Fixture fixture,
    LiveState? initial,
  }) async {
    if (await _lights.getByMac(homeId, device.mac) != null) throw const AlreadySavedException();
    var name = alias.trim().isEmpty ? device.displayName : alias.trim();
    var count = (await _lights.getByHome(homeId)).length;
    var light = Light(
      id: _ids.next(),
      homeId: homeId,
      roomId: roomId,
      name: name,
      ip: device.ip,
      mac: device.mac,
      moduleName: device.moduleName,
      bulbClass: device.bulbClass,
      fixture: fixture,
      fwVersion: device.fwVersion,
      sortIndex: count,
      addedAt: _clock.now(),
    );
    await _lights.insert(light);
    if (initial != null) _store.put(light.id, initial);
    return light;
  }
}
```

`lib/domain/usecases/finish_onboarding.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../entities/entities.dart';
import '../repositories/home_repository.dart';
import '../repositories/light_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/clock.dart';
import '../services/id_generator.dart';
import '../services/live_state_store.dart';
import 'usecase_exceptions.dart';

class OnboardingRoom extends Equatable {
  final String tempId;
  final String name;
  final RoomGlyph glyph;
  final bool custom;
  const OnboardingRoom({required this.tempId, required this.name, required this.glyph, required this.custom});
  @override
  List<Object?> get props => [tempId, name, glyph, custom];
}

class OnboardingLight extends Equatable {
  final DiscoveredDevice device;
  final String alias;
  final String roomTempId;
  final Fixture fixture;
  final LiveState? initial;
  const OnboardingLight({required this.device, required this.alias, required this.roomTempId, required this.fixture, this.initial});
  @override
  List<Object?> get props => [device, alias, roomTempId, fixture, initial];
}

class OnboardingResult extends Equatable {
  final String homeName;
  final String? subnet;
  final List<OnboardingRoom> rooms;
  final List<OnboardingLight> lights;
  const OnboardingResult({required this.homeName, this.subnet, required this.rooms, required this.lights});
  @override
  List<Object?> get props => [homeName, subnet, rooms, lights];
}

/// Writes the first home: only rooms that received a light, plus rooms the
/// user created by hand, are written (handoff spec).
class FinishOnboarding {
  final HomeRepository _homes;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final SettingsRepository _settings;
  final LiveStateStore _store;
  final IdGenerator _ids;
  final Clock _clock;

  FinishOnboarding({
    required HomeRepository homes,
    required RoomRepository rooms,
    required LightRepository lights,
    required SettingsRepository settings,
    required LiveStateStore store,
    required IdGenerator ids,
    required Clock clock,
  })  : _homes = homes, _rooms = rooms, _lights = lights, _settings = settings, _store = store, _ids = ids, _clock = clock;

  Future<Home> call(OnboardingResult result) async {
    var name = result.homeName.trim();
    if (name.isEmpty) throw const EmptyNameException();
    var now = _clock.now();
    var home = Home(id: _ids.next(), name: name, subnet: result.subnet, createdAt: now, sortIndex: (await _homes.getAll()).length);
    await _homes.insert(home);

    var used = result.lights.map((l) => l.roomTempId).toSet();
    var roomIds = <String, String>{};
    var index = 0;
    for (var r in result.rooms) {
      if (!r.custom && !used.contains(r.tempId)) continue;
      var room = Room(id: _ids.next(), homeId: home.id, name: r.name.trim(), glyph: r.glyph, sortIndex: index++);
      await _rooms.insert(room);
      roomIds[r.tempId] = room.id;
    }

    var lightIndex = 0;
    for (var l in result.lights) {
      var roomId = roomIds[l.roomTempId];
      if (roomId == null) continue;
      var light = Light(
        id: _ids.next(),
        homeId: home.id,
        roomId: roomId,
        name: l.alias.trim().isEmpty ? l.device.displayName : l.alias.trim(),
        ip: l.device.ip,
        mac: l.device.mac,
        moduleName: l.device.moduleName,
        bulbClass: l.device.bulbClass,
        fixture: l.fixture,
        fwVersion: l.device.fwVersion,
        sortIndex: lightIndex++,
        addedAt: now,
      );
      await _lights.insert(light);
      if (l.initial != null) _store.put(light.id, l.initial!);
    }

    await _settings.save((await _settings.get()).copyWith(activeHomeId: home.id));
    return home;
  }
}
```

Update the barrel `lib/domain/usecases/usecases.dart` to export every file in this task plus `usecase_exceptions.dart`. Add to `DiscoveredDevice`:

```dart
  DiscoveredDevice copyWithMac(String mac) => DiscoveredDevice(ip: ip, mac: mac, moduleName: moduleName, bulbClass: bulbClass, fwVersion: fwVersion, alreadySaved: alreadySaved);
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/domain && dart format lib test && flutter analyze --fatal-infos
git add lib/domain test/domain
git commit -m "feat(domain): home, room, light and onboarding use cases"
```

---
### Task 13: Drift database

**Files:**
- Create: `lib/data/db/app_database.dart` (+ generated `app_database.g.dart`)
- Test: `test/data/db/app_database_test.dart`

**Interfaces:**
- Produces: tables `Homes`, `Rooms`, `Lights`, `LightStates`, `Settings` with data classes `HomeRow`, `RoomRow`, `LightRow`, `LightStateRow`, `SettingRow` (spec §6); `class AppDatabase extends _$AppDatabase { AppDatabase(QueryExecutor e); factory AppDatabase.inMemory(); }`, schema version 1, foreign keys on, cascade from homes to rooms, lights and states, restrict on deleting a room that holds lights, unique `(homeId, mac)`.

- [ ] **Step 1: Write the failing test**

`test/data/db/app_database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  HomeRow home(String id) => HomeRow(id: id, name: 'Home $id', subnet: null, createdAt: 0, sortIndex: 0);
  RoomRow room(String id, String home) => RoomRow(id: id, homeId: home, name: 'Room', glyph: 'sofa', sortIndex: 0);
  LightRow light(String id, String home, String room, {String mac = 'mac'}) => LightRow(
      id: id, homeId: home, roomId: room, name: 'L', ip: '10.0.0.1', mac: mac, moduleName: null, bulbClass: 'rgb', fixture: 'bulb', fwVersion: null, sortIndex: 0, addedAt: 0);

  test('inserts and reads back', () async {
    await db.into(db.homes).insert(home('h'));
    await db.into(db.rooms).insert(room('r', 'h'));
    await db.into(db.lights).insert(light('l', 'h', 'r'));
    expect((await db.select(db.lights).get()).single.mac, 'mac');
  });

  test('a MAC is unique within a home', () async {
    await db.into(db.homes).insert(home('h'));
    await db.into(db.homes).insert(home('h2'));
    await db.into(db.rooms).insert(room('r', 'h'));
    await db.into(db.rooms).insert(room('r2', 'h2'));
    await db.into(db.lights).insert(light('a', 'h', 'r'));
    await db.into(db.lights).insert(light('b', 'h2', 'r2'));
    await expectLater(db.into(db.lights).insert(light('c', 'h', 'r')), throwsA(anything));
  });

  test('deleting a home cascades; deleting a room with lights is refused', () async {
    await db.into(db.homes).insert(home('h'));
    await db.into(db.rooms).insert(room('r', 'h'));
    await db.into(db.lights).insert(light('l', 'h', 'r'));
    await db.into(db.lightStates).insert(LightStateRow(lightId: 'l', isOn: true, brightness: 50, kelvin: 2700, r: 1, g: 2, b: 3, sceneId: 0, speed: 100, active: 'white', rssi: null, updatedAt: null));
    await expectLater((db.delete(db.rooms)..where((r) => r.id.equals('r'))).go(), throwsA(anything));
    await (db.delete(db.homes)..where((h) => h.id.equals('h'))).go();
    expect(await db.select(db.rooms).get(), isEmpty);
    expect(await db.select(db.lights).get(), isEmpty);
    expect(await db.select(db.lightStates).get(), isEmpty);
  });

  test('settings upsert', () async {
    await db.into(db.settings).insertOnConflictUpdate(const SettingRow(key: 'activeHomeId', value: 'h'));
    await db.into(db.settings).insertOnConflictUpdate(const SettingRow(key: 'activeHomeId', value: 'h2'));
    expect((await db.select(db.settings).get()).single.value, 'h2');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/data/db`
Expected: compile error.

- [ ] **Step 3: Implement the schema and generate**

`lib/data/db/app_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DataClassName('HomeRow')
class Homes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get subnet => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomRow')
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text().references(Homes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get glyph => text()();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LightRow')
class Lights extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text().references(Homes, #id, onDelete: KeyAction.cascade)();
  TextColumn get roomId => text().references(Rooms, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get ip => text()();
  TextColumn get mac => text()();
  TextColumn get moduleName => text().nullable()();
  TextColumn get bulbClass => text().nullable()();
  TextColumn get fixture => text()();
  TextColumn get fwVersion => text().nullable()();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {homeId, mac},
      ];
}

/// Last-known live state, so the app opens showing real values.
@DataClassName('LightStateRow')
class LightStates extends Table {
  TextColumn get lightId => text().references(Lights, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isOn => boolean()();
  IntColumn get brightness => integer()();
  IntColumn get kelvin => integer()();
  IntColumn get r => integer()();
  IntColumn get g => integer()();
  IntColumn get b => integer()();
  IntColumn get sceneId => integer()();
  IntColumn get speed => integer()();
  TextColumn get active => text()();
  IntColumn get rssi => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {lightId};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Homes, Rooms, Lights, LightStates, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // SQLite ignores foreign keys unless asked; cascade and restrict
          // depend on this.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`. Commit the generated `app_database.g.dart` (the analyzer excludes it).

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/data/db && dart format lib test && flutter analyze --fatal-infos
git add lib/data/db test/data/db
git commit -m "feat(data): drift schema"
```

---

### Task 14: Drift repositories, settings, live-state persistence

**Files:**
- Create: `lib/data/repositories/drift_home_repository.dart`, `drift_room_repository.dart`, `drift_light_repository.dart`, `drift_settings_repository.dart`, `drift_live_state_persistence.dart`, `live_state_persister.dart`, `lib/data/repositories/row_mappers.dart`, `lib/data/ids/uuid_ids.dart`
- Test: `test/data/repositories/drift_repositories_test.dart`, `test/data/repositories/live_state_persister_test.dart`

**Interfaces:**
- Produces: `DriftHomeRepository(AppDatabase)`, `DriftRoomRepository(AppDatabase)`, `DriftLightRepository(AppDatabase)`, `DriftSettingsRepository(AppDatabase)`, `DriftLiveStatePersistence(AppDatabase)` implementing the Task 5 interfaces; `class LiveStatePersister { LiveStatePersister({required LiveStateStore store, required LiveStatePersistence persistence, Duration debounce = 500 ms}); void start(); Future<void> dispose(); }`; `class UuidIds implements IdGenerator`; mappers `HomeRow.toDomain()`, `Home.toRow()` and the same for rooms, lights, states.

- [ ] **Step 1: Write the failing tests**

`test/data/repositories/drift_repositories_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/data/repositories/drift_home_repository.dart';
import 'package:wizctl_app/data/repositories/drift_light_repository.dart';
import 'package:wizctl_app/data/repositories/drift_live_state_persistence.dart';
import 'package:wizctl_app/data/repositories/drift_room_repository.dart';
import 'package:wizctl_app/data/repositories/drift_settings_repository.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  late AppDatabase db;
  late DriftHomeRepository homes;
  late DriftRoomRepository rooms;
  late DriftLightRepository lights;

  setUp(() {
    db = AppDatabase.inMemory();
    homes = DriftHomeRepository(db);
    rooms = DriftRoomRepository(db);
    lights = DriftLightRepository(db);
  });
  tearDown(() => db.close());

  final home = Home(id: 'h', name: 'Home', subnet: '192.168.1', createdAt: DateTime(2026, 9, 8), sortIndex: 0);
  const room = Room(id: 'r', homeId: 'h', name: 'Living Room', glyph: RoomGlyph.sofa);
  final light = Light(id: 'l', homeId: 'h', roomId: 'r', name: 'Dome', ip: '192.168.1.104', mac: 'aa', moduleName: 'ESP01_SHRGB1C_31', bulbClass: BulbClass.rgb, fixture: Fixture.dome, fwVersion: '1.25.0', addedAt: DateTime(2026, 9, 8));

  test('homes round-trip and stream', () async {
    var seen = <List<Home>>[];
    var sub = homes.watchAll().listen(seen.add);
    await homes.insert(home);
    await homes.update(home.copyWith(name: 'Renamed'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await homes.get('h'))!.name, 'Renamed');
    expect((await homes.get('h'))!.createdAt, DateTime(2026, 9, 8));
    expect(seen.last.single.name, 'Renamed');
    await sub.cancel();
    await homes.delete('h');
    expect(await homes.getAll(), isEmpty);
  });

  test('rooms and lights round-trip with enums and lookups', () async {
    await homes.insert(home);
    await rooms.insert(room);
    await lights.insert(light);
    expect((await rooms.getByHome('h')).single.glyph, RoomGlyph.sofa);
    var read = (await lights.get('l'))!;
    expect(read, light);
    expect(read.bulbClass, BulbClass.rgb);
    expect(read.fixture, Fixture.dome);
    expect((await lights.getByMac('h', 'aa'))!.id, 'l');
    expect(await lights.getByMac('h', 'zz'), isNull);
    expect((await lights.getByRoom('r')).single.id, 'l');
    var watched = await lights.watch('l').first;
    expect(watched!.name, 'Dome');
    await lights.update(light.copyWith(name: 'Lamp', bulbClass: null, clearBulbClass: true));
    expect((await lights.get('l'))!.className, 'Unknown');
    await lights.delete('l');
    expect(await lights.watchByHome('h').first, isEmpty);
  });

  test('settings persist and stream, with a clearable active home', () async {
    var settings = DriftSettingsRepository(db);
    expect(await settings.get(), AppSettings.defaults);
    await settings.save(const AppSettings(activeHomeId: 'h', feedbackEnabled: false, rescanOnLaunch: false));
    expect(await settings.get(), const AppSettings(activeHomeId: 'h', feedbackEnabled: false, rescanOnLaunch: false));
    expect((await settings.watch().first).activeHomeId, 'h');
    await settings.save(const AppSettings());
    expect((await settings.get()).activeHomeId, isNull);
  });

  test('live states persist for existing lights only', () async {
    await homes.insert(home);
    await rooms.insert(room);
    await lights.insert(light);
    var persistence = DriftLiveStatePersistence(db);
    await persistence.save({
      'l': LiveState.initial.copyWith(isOn: true, brightness: 80, active: ActiveChannel.scene, sceneId: 5, rssi: -40, updatedAt: DateTime(2026, 9, 8, 12)),
      'ghost': LiveState.initial,
    });
    var loaded = await persistence.load();
    expect(loaded.keys, ['l']);
    expect(loaded['l']!.sceneId, 5);
    expect(loaded['l']!.active, ActiveChannel.scene);
    expect(loaded['l']!.rssi, -40);
    expect(loaded['l']!.updatedAt, DateTime(2026, 9, 8, 12));
    expect(loaded['l']!.reachable, isFalse, reason: 'a loaded state is stale until refreshed');
  });
}
```

`test/data/repositories/live_state_persister_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/repositories/live_state_persister.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

import '../../support/fakes.dart';

void main() {
  test('coalesces bursts of changes into one save after the debounce', () {
    fakeAsync((async) {
      var store = LiveStateStore();
      var persistence = FakeLiveStatePersistence();
      var persister = LiveStatePersister(store: store, persistence: persistence, debounce: const Duration(milliseconds: 500));
      persister.start();
      async.flushMicrotasks();
      store.put('a', LiveState.initial.copyWith(isOn: true));
      store.put('a', LiveState.initial.copyWith(brightness: 30));
      store.put('b', LiveState.initial);
      async.elapse(const Duration(milliseconds: 499));
      expect(persistence.saves, 0);
      async.elapse(const Duration(milliseconds: 2));
      expect(persistence.saves, 1);
      expect(persistence.stored['a']!.brightness, 30);
      persister.dispose();
      store.dispose();
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/data/repositories`
Expected: compile errors.

- [ ] **Step 3: Implement mappers and repositories**

`lib/data/repositories/row_mappers.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../../domain/entities/entities.dart';
import '../db/app_database.dart';

extension HomeRowMapper on HomeRow {
  Home toDomain() => Home(id: id, name: name, subnet: subnet, createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt), sortIndex: sortIndex);
}

extension HomeMapper on Home {
  HomeRow toRow() => HomeRow(id: id, name: name, subnet: subnet, createdAt: createdAt.millisecondsSinceEpoch, sortIndex: sortIndex);
}

extension RoomRowMapper on RoomRow {
  Room toDomain() => Room(id: id, homeId: homeId, name: name, glyph: RoomGlyph.parse(glyph), sortIndex: sortIndex);
}

extension RoomMapper on Room {
  RoomRow toRow() => RoomRow(id: id, homeId: homeId, name: name, glyph: glyph.storageName, sortIndex: sortIndex);
}

extension LightRowMapper on LightRow {
  Light toDomain() => Light(
        id: id,
        homeId: homeId,
        roomId: roomId,
        name: name,
        ip: ip,
        mac: mac,
        moduleName: moduleName,
        bulbClass: bulbClass == null ? null : BulbClass.values.where((c) => c.name == bulbClass).firstOrNull,
        fixture: Fixture.parse(fixture),
        fwVersion: fwVersion,
        sortIndex: sortIndex,
        addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
      );
}

extension LightMapper on Light {
  LightRow toRow() => LightRow(
        id: id,
        homeId: homeId,
        roomId: roomId,
        name: name,
        ip: ip,
        mac: mac,
        moduleName: moduleName,
        bulbClass: bulbClass?.name,
        fixture: fixture.name,
        fwVersion: fwVersion,
        sortIndex: sortIndex,
        addedAt: addedAt.millisecondsSinceEpoch,
      );
}

extension LightStateRowMapper on LightStateRow {
  /// Loaded states are stale: [LiveState.reachable] stays false until a
  /// refresh proves the bulb is there.
  LiveState toDomain() => LiveState(
        isOn: isOn,
        brightness: brightness,
        kelvin: kelvin,
        rgb: Rgb(r, g, b),
        sceneId: sceneId,
        speed: speed,
        active: ActiveChannel.values.firstWhere((a) => a.name == active, orElse: () => ActiveChannel.white),
        reachable: false,
        rssi: rssi,
        updatedAt: updatedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(updatedAt!),
      );
}

extension LiveStateMapperRow on LiveState {
  LightStateRow toRow(String lightId) => LightStateRow(
        lightId: lightId,
        isOn: isOn,
        brightness: brightness,
        kelvin: kelvin,
        r: rgb.r,
        g: rgb.g,
        b: rgb.b,
        sceneId: sceneId,
        speed: speed,
        active: active.name,
        rssi: rssi,
        updatedAt: updatedAt?.millisecondsSinceEpoch,
      );
}
```

`lib/data/repositories/drift_home_repository.dart`:

```dart
import 'package:drift/drift.dart';

import '../../domain/entities/home.dart';
import '../../domain/repositories/home_repository.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftHomeRepository implements HomeRepository {
  final AppDatabase _db;

  DriftHomeRepository(this._db);

  SimpleSelectStatement<$HomesTable, HomeRow> get _ordered => _db.select(_db.homes)..orderBy([(h) => OrderingTerm.asc(h.sortIndex), (h) => OrderingTerm.asc(h.createdAt)]);

  @override
  Stream<List<Home>> watchAll() => _ordered.watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<Home>> getAll() async => (await _ordered.get()).map((r) => r.toDomain()).toList();

  @override
  Future<Home?> get(String id) async => (await (_db.select(_db.homes)..where((h) => h.id.equals(id))).getSingleOrNull())?.toDomain();

  @override
  Future<void> insert(Home home) => _db.into(_db.homes).insert(home.toRow());

  @override
  Future<void> update(Home home) => _db.update(_db.homes).replace(home.toRow());

  @override
  Future<void> delete(String id) => (_db.delete(_db.homes)..where((h) => h.id.equals(id))).go();
}
```

`lib/data/repositories/drift_room_repository.dart`:

```dart
import 'package:drift/drift.dart';

import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftRoomRepository implements RoomRepository {
  final AppDatabase _db;

  DriftRoomRepository(this._db);

  SimpleSelectStatement<$RoomsTable, RoomRow> _byHome(String homeId) =>
      _db.select(_db.rooms)..where((r) => r.homeId.equals(homeId))..orderBy([(r) => OrderingTerm.asc(r.sortIndex)]);

  @override
  Stream<List<Room>> watchByHome(String homeId) => _byHome(homeId).watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<Room>> getByHome(String homeId) async => (await _byHome(homeId).get()).map((r) => r.toDomain()).toList();

  @override
  Future<Room?> get(String id) async => (await (_db.select(_db.rooms)..where((r) => r.id.equals(id))).getSingleOrNull())?.toDomain();

  @override
  Future<void> insert(Room room) => _db.into(_db.rooms).insert(room.toRow());

  @override
  Future<void> update(Room room) => _db.update(_db.rooms).replace(room.toRow());

  @override
  Future<void> delete(String id) => (_db.delete(_db.rooms)..where((r) => r.id.equals(id))).go();
}
```

`lib/data/repositories/drift_light_repository.dart`:

```dart
import 'package:drift/drift.dart';

import '../../domain/entities/light.dart';
import '../../domain/repositories/light_repository.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftLightRepository implements LightRepository {
  final AppDatabase _db;

  DriftLightRepository(this._db);

  SimpleSelectStatement<$LightsTable, LightRow> _where(Expression<bool> Function($LightsTable l) filter) =>
      _db.select(_db.lights)..where(filter)..orderBy([(l) => OrderingTerm.asc(l.sortIndex), (l) => OrderingTerm.asc(l.addedAt)]);

  List<Light> _map(List<LightRow> rows) => rows.map((r) => r.toDomain()).toList();

  @override
  Stream<List<Light>> watchByHome(String homeId) => _where((l) => l.homeId.equals(homeId)).watch().map(_map);

  @override
  Stream<List<Light>> watchByRoom(String roomId) => _where((l) => l.roomId.equals(roomId)).watch().map(_map);

  @override
  Stream<Light?> watch(String id) => _where((l) => l.id.equals(id)).watchSingleOrNull().map((r) => r?.toDomain());

  @override
  Future<List<Light>> getByHome(String homeId) async => _map(await _where((l) => l.homeId.equals(homeId)).get());

  @override
  Future<List<Light>> getByRoom(String roomId) async => _map(await _where((l) => l.roomId.equals(roomId)).get());

  @override
  Future<Light?> get(String id) async => (await _where((l) => l.id.equals(id)).getSingleOrNull())?.toDomain();

  @override
  Future<Light?> getByMac(String homeId, String mac) async =>
      (await _where((l) => l.homeId.equals(homeId) & l.mac.equals(mac)).getSingleOrNull())?.toDomain();

  @override
  Future<void> insert(Light light) => _db.into(_db.lights).insert(light.toRow());

  @override
  Future<void> update(Light light) => _db.update(_db.lights).replace(light.toRow());

  @override
  Future<void> delete(String id) => (_db.delete(_db.lights)..where((l) => l.id.equals(id))).go();
}
```

`lib/data/repositories/drift_settings_repository.dart`:

```dart
import 'package:drift/drift.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../db/app_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase _db;

  DriftSettingsRepository(this._db);

  static const _activeHome = 'activeHomeId';
  static const _feedback = 'feedbackEnabled';
  static const _rescan = 'rescanOnLaunch';

  AppSettings _parse(List<SettingRow> rows) {
    var map = {for (var r in rows) r.key: r.value};
    return AppSettings(
      activeHomeId: map[_activeHome],
      feedbackEnabled: map[_feedback] != 'false',
      rescanOnLaunch: map[_rescan] != 'false',
    );
  }

  @override
  Stream<AppSettings> watch() => _db.select(_db.settings).watch().map(_parse);

  @override
  Future<AppSettings> get() async => _parse(await _db.select(_db.settings).get());

  @override
  Future<void> save(AppSettings settings) => _db.transaction(() async {
        if (settings.activeHomeId == null) {
          await (_db.delete(_db.settings)..where((s) => s.key.equals(_activeHome))).go();
        } else {
          await _db.into(_db.settings).insertOnConflictUpdate(SettingRow(key: _activeHome, value: settings.activeHomeId!));
        }
        await _db.into(_db.settings).insertOnConflictUpdate(SettingRow(key: _feedback, value: '${settings.feedbackEnabled}'));
        await _db.into(_db.settings).insertOnConflictUpdate(SettingRow(key: _rescan, value: '${settings.rescanOnLaunch}'));
      });
}
```

`lib/data/repositories/drift_live_state_persistence.dart`:

```dart
import 'package:drift/drift.dart';

import '../../domain/entities/live_state.dart';
import '../../domain/repositories/live_state_persistence.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftLiveStatePersistence implements LiveStatePersistence {
  final AppDatabase _db;

  DriftLiveStatePersistence(this._db);

  @override
  Future<Map<String, LiveState>> load() async {
    var rows = await _db.select(_db.lightStates).get();
    return {for (var r in rows) r.lightId: r.toDomain()};
  }

  @override
  Future<void> save(Map<String, LiveState> states) => _db.transaction(() async {
        var known = (await _db.select(_db.lights).get()).map((l) => l.id).toSet();
        await _db.batch((b) {
          for (var entry in states.entries) {
            if (!known.contains(entry.key)) continue;
            b.insert(_db.lightStates, entry.value.toRow(entry.key), mode: InsertMode.insertOrReplace);
          }
        });
      });
}
```

`lib/data/repositories/live_state_persister.dart`:

```dart
import 'dart:async';

import '../../domain/entities/live_state.dart';
import '../../domain/repositories/live_state_persistence.dart';
import '../../domain/services/live_state_store.dart';

/// Writes the store to the database, debounced so a dial drag costs one
/// write rather than a hundred.
class LiveStatePersister {
  final LiveStateStore _store;
  final LiveStatePersistence _persistence;
  final Duration debounce;
  StreamSubscription<Map<String, LiveState>>? _sub;
  Timer? _timer;
  Map<String, LiveState>? _latest;

  LiveStatePersister({required LiveStateStore store, required LiveStatePersistence persistence, this.debounce = const Duration(milliseconds: 500)})
      : _store = store,
        _persistence = persistence;

  void start() {
    _sub ??= _store.watchAll().skip(1).listen((states) {
      _latest = states;
      _timer?.cancel();
      _timer = Timer(debounce, _flush);
    });
  }

  void _flush() {
    var latest = _latest;
    if (latest == null) return;
    _latest = null;
    unawaited(_persistence.save(latest));
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _flush();
    await _sub?.cancel();
    _sub = null;
  }
}
```

`lib/data/ids/uuid_ids.dart`:

```dart
import 'package:uuid/uuid.dart';

import '../../domain/services/id_generator.dart';

class UuidIds implements IdGenerator {
  final Uuid _uuid = const Uuid();

  @override
  String next() => _uuid.v4();
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/data && dart format lib test && flutter analyze --fatal-infos
git add lib/data test/data
git commit -m "feat(data): drift repositories, settings, live-state persistence"
```

---

### Task 15: WizDeviceGateway and fault injection

**Files:**
- Create: `lib/data/device/gateway_tuning.dart`, `lib/data/device/wiz_device_gateway.dart`, `lib/data/device/fault_injecting_gateway.dart`, `lib/data/device/fault_injecting_network_info.dart`, `test/support/fake_bulb.dart` (copied from the wizctl worktree's `test/support/fake_bulb.dart`)
- Test: `test/data/device/wiz_device_gateway_test.dart`, `test/data/device/fault_injecting_gateway_test.dart`

**Interfaces:**
- Produces: `class GatewayTuning { Duration writeTimeout = 1 s; RetryConfig writeRetry = exponential(count 2, 250 ms, max 1 s); Duration readTimeout = 1500 ms; RetryConfig readRetry = fixed(count 1, 250 ms); Duration broadcastTimeout = 4 s; Duration sweepTimeout = 3 s; int port = wizPort; int localPort = wizPort; String broadcastAddress; }`; `class WizDeviceGateway implements DeviceGateway { WizDeviceGateway({GatewayTuning tuning = const GatewayTuning()}); static DeviceFailure mapError(Object error, String ip); }`; `class FaultInjectingGateway implements DeviceGateway { FaultInjectingGateway(DeviceGateway inner, {required DebugFlags Function() flags, required Clock clock}); }` (force timeout: every read and write waits 1.1 s then fails with `TimeoutFailure(ip, 3)`; find nothing: broadcast returns nothing and the sweep reports four progress steps then an empty done); `class FaultInjectingNetworkInfo implements NetworkInfo { FaultInjectingNetworkInfo(NetworkInfo inner, {required DebugFlags Function() flags}); }` (wrong network reports `10.0.0`).

- [ ] **Step 1: Copy the FakeBulb harness and write the failing tests**

Copy `test/support/fake_bulb.dart` from the wizctl worktree (Plan 1 Task 1) into the app's `test/support/fake_bulb.dart` unchanged.

`test/data/device/wiz_device_gateway_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/data/device/gateway_tuning.dart';
import 'package:wizctl_app/data/device/wiz_device_gateway.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fake_bulb.dart';

void main() {
  const bulbPort = 39441;
  const replyPort = 39442;
  const deadPort = 39443;

  test('reads state and config from a loopback bulb and sends a pilot', () async {
    var bulb = await FakeBulb.start(listenPort: bulbPort, replyMode: ReplyMode.sourcePort);
    addTearDown(bulb.close);
    var gateway = WizDeviceGateway(tuning: const GatewayTuning(port: bulbPort, localPort: replyPort));
    var state = await gateway.readState('127.0.0.1');
    expect(state.isOn, isTrue);
    expect(state.dimming, 70);
    var config = await gateway.readConfig('127.0.0.1');
    expect(config.moduleName, 'ESP01_SHRGB_03');
    await gateway.send('127.0.0.1', ControlSignal.on());
    expect(bulb.requestCount, 3);
  });

  test('a silent address fails with a device exception in bounded time', () async {
    var gateway = WizDeviceGateway(tuning: const GatewayTuning(port: deadPort, readTimeout: Duration(milliseconds: 200), readRetry: RetryConfig.none(), writeTimeout: Duration(milliseconds: 200), writeRetry: RetryConfig.none()));
    var watch = Stopwatch()..start();
    await expectLater(gateway.readState('127.0.0.1'), throwsA(isA<DeviceException>()));
    await expectLater(gateway.send('127.0.0.1', ControlSignal.on()), throwsA(isA<DeviceException>()));
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
  });

  test('probe streams scan events', () async {
    var bulb = await FakeBulb.start(listenPort: bulbPort, replyMode: ReplyMode.sourcePort);
    addTearDown(bulb.close);
    var gateway = WizDeviceGateway(tuning: const GatewayTuning(port: bulbPort, localPort: replyPort, readTimeout: Duration(seconds: 1)));
    var events = await gateway.probe(['127.0.0.1']).toList();
    expect(events.whereType<ScanFound>(), hasLength(1));
    expect(events.last, isA<ScanDone>());
  });

  test('maps library errors to failures', () {
    expect(WizDeviceGateway.mapError(WizTimeoutError(ip: '1.2.3.4', timeout: const Duration(seconds: 1), retryCount: 3), '1.2.3.4'), const TimeoutFailure('1.2.3.4', 3));
    expect(WizDeviceGateway.mapError(WizConnectionError('no route'), '1.2.3.4'), isA<UnreachableFailure>());
    expect(WizDeviceGateway.mapError(WizMethodNotFoundError(method: 'getModelConfig', ip: '1.2.3.4'), '1.2.3.4'), const UnsupportedFailure('1.2.3.4', 'getModelConfig'));
    expect(WizDeviceGateway.mapError(WizArgumentError(argumentName: 'x', invalidValue: 1, message: 'bad'), '1.2.3.4'), const InvalidArgumentFailure('bad'));
    expect(WizDeviceGateway.mapError(StateError('boom'), '1.2.3.4'), isA<UnreachableFailure>());
  });
}
```

`test/data/device/fault_injecting_gateway_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/data/device/fault_injecting_gateway.dart';
import 'package:wizctl_app/data/device/fault_injecting_network_info.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';

class _Net implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async => '192.168.1';
}

void main() {
  test('force timeout waits 1.1 s then fails every read and write', () async {
    var inner = FakeGateway()..states['1.1.1.1'] = const LightState(isOn: true);
    var flags = const DebugFlags(forceTimeout: true);
    var clock = FakeClock();
    var gateway = FaultInjectingGateway(inner, flags: () => flags, clock: clock);
    await expectLater(gateway.readState('1.1.1.1'), throwsA(isA<DeviceException>()));
    await expectLater(gateway.send('1.1.1.1', ControlSignal.on()), throwsA(isA<DeviceException>()));
    expect(clock.delays, [const Duration(milliseconds: 1100), const Duration(milliseconds: 1100)]);
    expect(inner.sends, isEmpty);
  });

  test('find nothing empties broadcast and the sweep; off network reports another subnet', () async {
    var inner = FakeGateway()..broadcastResult = [const DiscoveredLight(ip: '1', mac: 'm')];
    var gateway = FaultInjectingGateway(inner, flags: () => const DebugFlags(findNothing: true), clock: FakeClock());
    expect(await gateway.broadcast(), isEmpty);
    var events = await gateway.sweep().toList();
    expect(events.whereType<ScanProgress>(), hasLength(4));
    expect((events.last as ScanDone).lights, isEmpty);
    var passthrough = FaultInjectingGateway(inner, flags: () => DebugFlags.none, clock: FakeClock());
    expect(await passthrough.broadcast(), hasLength(1));
    var net = FaultInjectingNetworkInfo(_Net(), flags: () => const DebugFlags(offNetwork: true));
    expect(await net.currentSubnet(), '10.0.0');
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/data/device`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/data/device/gateway_tuning.dart`:

```dart
import 'package:wizctl/wizctl.dart';

/// Timeouts and retries for an interactive client (spec §3.3, §5.8): three
/// attempts of one second for writes so a dead bulb reports in a few
/// seconds; two attempts for reads so one lost packet is not "unreachable".
class GatewayTuning {
  final Duration writeTimeout;
  final RetryConfig writeRetry;
  final Duration readTimeout;
  final RetryConfig readRetry;
  final Duration broadcastTimeout;
  final Duration sweepTimeout;
  final int port;
  final int localPort;
  final String broadcastAddress;

  const GatewayTuning({
    this.writeTimeout = const Duration(seconds: 1),
    this.writeRetry = const RetryConfig.exponential(count: 2, initialInterval: Duration(milliseconds: 250), maxInterval: Duration(seconds: 1)),
    this.readTimeout = const Duration(milliseconds: 1500),
    this.readRetry = const RetryConfig.fixed(count: 1, interval: Duration(milliseconds: 250)),
    this.broadcastTimeout = const Duration(seconds: 4),
    this.sweepTimeout = const Duration(seconds: 3),
    this.port = wizPort,
    this.localPort = wizPort,
    this.broadcastAddress = defaultBroadcastAddress,
  });
}
```

`lib/data/device/wiz_device_gateway.dart`:

```dart
import 'dart:async';

import 'package:wizctl/wizctl.dart';

import '../../domain/entities/device_failure.dart';
import '../../domain/services/device_gateway.dart';
import 'gateway_tuning.dart';

/// The bulbs, through the wizctl package. One `WizLight` per address and
/// purpose, so reads and writes keep their own timeouts.
class WizDeviceGateway implements DeviceGateway {
  final GatewayTuning tuning;
  final Map<String, WizLight> _readers = {};
  final Map<String, WizLight> _writers = {};

  WizDeviceGateway({this.tuning = const GatewayTuning()});

  WizLight _reader(String ip) => _readers.putIfAbsent(ip, () => WizLight(ip, port: tuning.port, timeout: tuning.readTimeout, retry: tuning.readRetry));

  WizLight _writer(String ip) => _writers.putIfAbsent(ip, () => WizLight(ip, port: tuning.port, timeout: tuning.writeTimeout, retry: tuning.writeRetry));

  static DeviceFailure mapError(Object error, String ip) => switch (error) {
        WizTimeoutError e => TimeoutFailure(ip, e.retryCount),
        WizConnectionError e => UnreachableFailure(ip, e.message),
        WizMethodNotFoundError e => UnsupportedFailure(ip, e.method),
        WizArgumentError e => InvalidArgumentFailure(e.message),
        WizResponseError e => UnreachableFailure(ip, e.message),
        WizUnknownBulbError e => UnreachableFailure(ip, e.message),
        _ => UnreachableFailure(ip, '$error'),
      };

  Future<T> _guard<T>(String ip, Future<T> Function() op) async {
    try {
      return await op();
    } catch (e) {
      throw DeviceException(mapError(e, ip));
    }
  }

  @override
  Future<LightState> readState(String ip) => _guard(ip, () => _reader(ip).getState());

  @override
  Future<BulbConfig> readConfig(String ip) => _guard(ip, () => _reader(ip).getSystemConfig());

  @override
  Future<void> send(String ip, ControlSignal signal) => _guard(ip, () => _writer(ip).send(signal));

  @override
  Future<List<DiscoveredLight>> broadcast() => _guard(
        tuning.broadcastAddress,
        () => WizDiscovery.discover(
          broadcastAddress: tuning.broadcastAddress,
          timeout: tuning.broadcastTimeout,
          port: tuning.port,
          localPort: tuning.localPort,
        ),
      );

  Stream<ScanEvent> _mapErrors(Stream<ScanEvent> stream, String ip) =>
      stream.handleError((Object e) => throw DeviceException(mapError(e, ip)), test: (e) => e is! DeviceException);

  @override
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}) => _mapErrors(
        WizDiscovery.probeAddressesStream(addresses: ips, timeout: tuning.readTimeout, rounds: rounds, port: tuning.port, localPort: tuning.localPort),
        ips.join(','),
      );

  @override
  Stream<ScanEvent> sweep({String? subnet}) => _mapErrors(
        WizDiscovery.scanSubnetStream(subnet: subnet, timeout: tuning.sweepTimeout, port: tuning.port, localPort: tuning.localPort),
        subnet ?? 'subnet',
      );
}
```

`lib/data/device/fault_injecting_gateway.dart`:

```dart
import 'package:wizctl/wizctl.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/clock.dart';
import '../../domain/services/device_gateway.dart';

/// The prototype switches, for debug builds only (spec §18). Wraps the real
/// gateway so every failure state can be reviewed without touching the
/// network.
class FaultInjectingGateway implements DeviceGateway {
  final DeviceGateway _inner;
  final DebugFlags Function() _flags;
  final Clock _clock;

  static const Duration forcedTimeout = Duration(milliseconds: 1100);
  static const int forcedAttempts = 3;
  static const int fakeAddressCount = 254;
  static const int fakeSweepSteps = 4;
  static const Duration fakeSweepStep = Duration(milliseconds: 400);

  FaultInjectingGateway(this._inner, {required DebugFlags Function() flags, required Clock clock})
      : _flags = flags,
        _clock = clock;

  Future<T> _maybeTimeout<T>(String ip, Future<T> Function() op) async {
    if (!_flags().forceTimeout) return op();
    await _clock.delay(forcedTimeout);
    throw DeviceException(TimeoutFailure(ip, forcedAttempts));
  }

  @override
  Future<LightState> readState(String ip) => _maybeTimeout(ip, () => _inner.readState(ip));

  @override
  Future<BulbConfig> readConfig(String ip) => _maybeTimeout(ip, () => _inner.readConfig(ip));

  @override
  Future<void> send(String ip, ControlSignal signal) => _maybeTimeout(ip, () => _inner.send(ip, signal));

  @override
  Future<List<DiscoveredLight>> broadcast() async => _flags().findNothing ? const [] : _inner.broadcast();

  @override
  Stream<ScanEvent> probe(Iterable<String> ips, {int rounds = 1}) => _inner.probe(ips, rounds: rounds);

  @override
  Stream<ScanEvent> sweep({String? subnet}) {
    if (!_flags().findNothing) return _inner.sweep(subnet: subnet);
    return _emptySweep(subnet ?? '192.168.1');
  }

  Stream<ScanEvent> _emptySweep(String subnet) async* {
    for (var step = 1; step <= fakeSweepSteps; step++) {
      await _clock.delay(fakeSweepStep);
      var probed = (fakeAddressCount * step / fakeSweepSteps).round();
      yield ScanProgress(addressesProbed: probed, addressCount: fakeAddressCount, fraction: step / fakeSweepSteps, subnet: subnet);
    }
    yield const ScanDone([]);
  }
}
```

`lib/data/device/fault_injecting_network_info.dart`:

```dart
import '../../domain/entities/debug_flags.dart';
import '../../domain/services/network_monitor.dart';

/// "Wrong network" prototype switch: report a subnet no home uses.
class FaultInjectingNetworkInfo implements NetworkInfo {
  final NetworkInfo _inner;
  final DebugFlags Function() _flags;

  static const String elsewhere = '10.0.0';

  FaultInjectingNetworkInfo(this._inner, {required DebugFlags Function() flags}) : _flags = flags;

  @override
  Future<String?> currentSubnet() async => _flags().offNetwork ? elsewhere : _inner.currentSubnet();
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/data && dart format lib test && flutter analyze --fatal-infos
git add lib/data test/data test/support/fake_bulb.dart
git commit -m "feat(data): WizDeviceGateway with debug fault injection"
```

---

### Task 16: CLI config export (desktop)

**Files:**
- Create: `lib/data/cli/cli_config_exporter.dart`, `lib/data/cli/cli_export_listener.dart`
- Modify: `pubspec.yaml` (`flutter pub add path`)
- Test: `test/data/cli/cli_config_exporter_test.dart`, `test/data/cli/cli_export_listener_test.dart`

**Interfaces:**
- Produces: `class CliConfigExporter { CliConfigExporter({required Directory Function() homeDirectory}); static Directory defaultHomeDirectory(); File get file; static Map<String, dynamic> toJson({required List<Light> lights, required List<Room> rooms}); Future<void> export({required List<Light> lights, required List<Room> rooms}); }` writing `~/.config/wizctl/config.json` atomically (spec §16); `class CliExportListener { CliExportListener({required SettingsRepository settings, required RoomRepository rooms, required LightRepository lights, required CliConfigExporter exporter, Duration debounce = 500 ms}); void start(); Future<void> dispose(); }`.

- [ ] **Step 1: Write the failing tests**

`test/data/cli/cli_config_exporter_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/cli/cli_config_exporter.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  final rooms = [const Room(id: 'r1', homeId: 'h', name: 'Living Room', glyph: RoomGlyph.sofa), const Room(id: 'r2', homeId: 'h', name: 'Bedroom', glyph: RoomGlyph.bed)];
  final lights = [
    Light(id: 'a', homeId: 'h', roomId: 'r1', name: 'Ceiling dome light', ip: '192.168.1.104', mac: 'aa', fixture: Fixture.dome, addedAt: DateTime(2026)),
    Light(id: 'b', homeId: 'h', roomId: 'r1', name: 'Corner floor lamp', ip: '192.168.1.107', mac: 'bb', fixture: Fixture.desk, addedAt: DateTime(2026)),
    Light(id: 'c', homeId: 'h', roomId: 'r2', name: 'Bedside bulb', ip: '192.168.1.115', mac: 'cc', fixture: Fixture.bulb, addedAt: DateTime(2026)),
  ];

  test('json matches the CLI config shape', () {
    var json = CliConfigExporter.toJson(lights: lights, rooms: rooms);
    expect(json['lights'], {
      '192.168.1.104': {'alias': 'Ceiling dome light', 'mac': 'aa'},
      '192.168.1.107': {'alias': 'Corner floor lamp', 'mac': 'bb'},
      '192.168.1.115': {'alias': 'Bedside bulb', 'mac': 'cc'},
    });
    expect(json['groups'], {
      'Living Room': ['192.168.1.104', '192.168.1.107'],
      'Bedroom': ['192.168.1.115'],
    });
  });

  test('writes atomically into HOME/.config/wizctl/config.json', () async {
    var home = await Directory.systemTemp.createTemp('wizctl-home');
    addTearDown(() => home.delete(recursive: true));
    var exporter = CliConfigExporter(homeDirectory: () => home);
    await exporter.export(lights: lights, rooms: rooms);
    var file = File('${home.path}/.config/wizctl/config.json');
    expect(file.existsSync(), isTrue);
    var parsed = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect((parsed['groups'] as Map)['Bedroom'], ['192.168.1.115']);
    expect(Directory('${home.path}/.config/wizctl').listSync().where((f) => f.path.endsWith('.tmp')), isEmpty);
    expect(exporter.file.path, file.path);
  });
}
```

`test/data/cli/cli_export_listener_test.dart`:

```dart
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/cli/cli_config_exporter.dart';
import 'package:wizctl_app/data/cli/cli_export_listener.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fakes.dart';

class _CountingExporter extends CliConfigExporter {
  int exports = 0;
  List<Light> lastLights = [];
  _CountingExporter() : super(homeDirectory: () => Directory.systemTemp);
  @override
  Future<void> export({required List<Light> lights, required List<Room> rooms}) async {
    exports++;
    lastLights = lights;
  }
}

void main() {
  test('exports the active home after changes, debounced', () {
    fakeAsync((async) {
      var settings = FakeSettingsRepository();
      var rooms = FakeRoomRepository()..seed([const Room(id: 'r', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa)]);
      var lights = FakeLightRepository();
      var exporter = _CountingExporter();
      var listener = CliExportListener(settings: settings, rooms: rooms, lights: lights, exporter: exporter, debounce: const Duration(milliseconds: 500));
      listener.start();
      async.flushMicrotasks();
      expect(exporter.exports, 0, reason: 'no active home yet');
      settings.save(const AppSettings(activeHomeId: 'h'));
      async.flushMicrotasks();
      lights.insert(Light(id: '1', homeId: 'h', roomId: 'r', name: 'x', ip: '1', mac: 'm', fixture: Fixture.bulb, addedAt: DateTime(2026)));
      lights.insert(Light(id: '2', homeId: 'h', roomId: 'r', name: 'y', ip: '2', mac: 'n', fixture: Fixture.bulb, addedAt: DateTime(2026)));
      async.elapse(const Duration(milliseconds: 600));
      expect(exporter.exports, 1);
      expect(exporter.lastLights, hasLength(2));
      listener.dispose();
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter pub add path && flutter test test/data/cli`
Expected: compile errors.

- [ ] **Step 3: Implement**

`lib/data/cli/cli_config_exporter.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/light.dart';
import '../../domain/entities/room.dart';

/// Rewrites the CLI's config file from the active home so
/// `wizctl on -t "Living Room"` addresses the same lights (spec §16).
/// Desktop only; the file is overwritten and never read.
class CliConfigExporter {
  final Directory Function() homeDirectory;

  CliConfigExporter({required this.homeDirectory});

  static Directory defaultHomeDirectory() =>
      Directory(Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.');

  File get file => File(p.join(homeDirectory().path, '.config', 'wizctl', 'config.json'));

  static Map<String, dynamic> toJson({required List<Light> lights, required List<Room> rooms}) {
    var byRoom = <String, List<String>>{};
    for (var room in rooms) {
      byRoom[room.name] = [for (var l in lights) if (l.roomId == room.id) l.ip];
    }
    return {
      'lights': {for (var l in lights) l.ip: {'alias': l.name, 'mac': l.mac}},
      'groups': byRoom,
    };
  }

  Future<void> export({required List<Light> lights, required List<Room> rooms}) async {
    var target = file;
    await target.parent.create(recursive: true);
    var tmp = File('${target.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(toJson(lights: lights, rooms: rooms)));
    await tmp.rename(target.path);
  }
}
```

`lib/data/cli/cli_export_listener.dart`:

```dart
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
  final Duration debounce;

  StreamSubscription<AppSettings>? _settingsSub;
  StreamSubscription<List<Room>>? _roomsSub;
  StreamSubscription<List<Light>>? _lightsSub;
  String? _homeId;
  List<Room> _latestRooms = [];
  List<Light> _latestLights = [];
  Timer? _timer;

  CliExportListener({
    required SettingsRepository settings,
    required RoomRepository rooms,
    required LightRepository lights,
    required CliConfigExporter exporter,
    this.debounce = const Duration(milliseconds: 500),
  })  : _settings = settings,
        _rooms = rooms,
        _lights = lights,
        _exporter = exporter;

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
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_exporter.export(lights: _latestLights, rooms: _latestRooms)));
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _settingsSub?.cancel();
    await _roomsSub?.cancel();
    await _lightsSub?.cancel();
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/data && dart format lib test && flutter analyze --fatal-infos
git add pubspec.yaml pubspec.lock lib/data test/data
git commit -m "feat(data): CLI config export for desktop"
```

---

### Task 17: Composition root

**Files:**
- Create: `lib/app/dependencies.dart`, `lib/app/debug_flags_holder.dart`
- Test: `test/app/dependencies_test.dart`

**Interfaces:**
- Produces: `class DebugFlagsHolder extends ValueNotifier<DebugFlags>`; `class AppDependencies` exposing `database, homes, rooms, lights, settings, store, persister, gateway, networkInfo, network, resolver, pipeline, refreshStates, sync, runDiscovery, blinkLight, setPower, setBrightness, setKelvin, setSpeed, applyColour, applyWhite, applyScene, createHome, switchHome, renameHome, deleteHome, addRoom, renameRoom, deleteRoom, renameLight, moveLight, setFixture, forgetLight, saveDiscoveredLight, finishOnboarding, cliExport (nullable), debugFlags, clock, ids` and `static Future<AppDependencies> build({AppDatabase? database, DeviceGateway? gateway, NetworkInfo? networkInfo, bool exportCli = false, Directory Function()? homeDirectory, DebugFlagsHolder? debugFlags, Clock clock = const SystemClock(), IdGenerator? ids})`, `Future<void> dispose()`. Plan 4's blocs receive these through `RepositoryProvider`.

- [ ] **Step 1: Write the failing test**

`test/app/dependencies_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/dependencies.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../support/fakes.dart';

class _Net implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async => '192.168.1';
}

void main() {
  test('wires the whole logic layer end to end', () async {
    var gateway = FakeGateway();
    var deps = await AppDependencies.build(database: AppDatabase.inMemory(), gateway: gateway, networkInfo: _Net(), clock: FakeClock(), ids: SequenceIds());
    addTearDown(deps.dispose);

    var home = await deps.createHome('Kaverappa House', subnet: '192.168.1');
    var room = await deps.addRoom(home.id, 'Living Room', RoomGlyph.sofa);
    var light = await deps.saveDiscoveredLight(
      homeId: home.id,
      roomId: room.id,
      device: const DiscoveredDevice(ip: '192.168.1.104', mac: 'aa', bulbClass: BulbClass.rgb),
      alias: 'Ceiling dome light',
      fixture: Fixture.dome,
    );
    expect((await deps.settings.get()).activeHomeId, home.id);

    gateway.states['192.168.1.104'] = const LightState(isOn: true, dimming: 70, temperature: 2700);
    await deps.refreshStates.forHome(home.id);
    expect(deps.store.of(light.id).isOn, isTrue);
    expect(deps.store.of(light.id).reachable, isTrue);

    await deps.setBrightness(RoomTarget(room.id), 40);
    expect(gateway.sends.last.$2.dimming, 40);
    expect(deps.store.of(light.id).brightness, 40);

    var reports = <CommandReport>[];
    var sub = deps.pipeline.reports.listen(reports.add);
    await deps.setPower(LightTarget(light.id), false);
    await Future<void>.delayed(Duration.zero);
    expect(reports.last, isA<CommandSucceeded>());
    await sub.cancel();
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/app`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/app/debug_flags_holder.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../domain/entities/debug_flags.dart';

/// The prototype switches' state. Only debug builds ever change it.
class DebugFlagsHolder extends ValueNotifier<DebugFlags> {
  DebugFlagsHolder() : super(DebugFlags.none);
}
```

`lib/app/dependencies.dart`:

```dart
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

  static Future<AppDependencies> build({
    AppDatabase? database,
    DeviceGateway? gateway,
    NetworkInfo? networkInfo,
    bool exportCli = false,
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
    var persister = LiveStatePersister(store: store, persistence: persistence)..start();

    DeviceGateway device = gateway ?? WizDeviceGateway();
    NetworkInfo info = networkInfo ?? IoNetworkInfo();
    if (kDebugMode) {
      device = FaultInjectingGateway(device, flags: () => flags.value, clock: clock);
      info = FaultInjectingNetworkInfo(info, flags: () => flags.value);
    }
    var network = NetworkMonitor(info);

    Future<String?> homeSubnet() async {
      var id = (await settings.get()).activeHomeId;
      return id == null ? null : (await homes.get(id))?.subnet;
    }

    var resolver = TargetResolver(lights);
    var pipeline = DeviceCommandPipeline(gateway: device, store: store, network: network, homeSubnet: homeSubnet, clock: clock, ids: idGen);
    var refresh = RefreshStates(gateway: device, store: store, lights: lights, clock: clock);
    var sync = SyncCoordinator(refresh: refresh, lights: lights, settings: settings);

    CliExportListener? cli;
    if (exportCli) {
      cli = CliExportListener(
        settings: settings,
        rooms: rooms,
        lights: lights,
        exporter: CliConfigExporter(homeDirectory: homeDirectory ?? CliConfigExporter.defaultHomeDirectory),
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
      runDiscovery: RunDiscovery(gateway: device, lights: lights, store: store, network: info, clock: clock),
      blinkLight: BlinkLight(gateway: device, clock: clock),
      setPower: SetPower(resolver: resolver, store: store, pipeline: pipeline),
      setBrightness: SetBrightness(resolver: resolver, store: store, pipeline: pipeline),
      setKelvin: SetKelvin(resolver: resolver, store: store, pipeline: pipeline),
      setSpeed: SetSpeed(resolver: resolver, store: store, pipeline: pipeline),
      applyColour: ApplyColour(resolver: resolver, store: store, pipeline: pipeline),
      applyWhite: ApplyWhite(resolver: resolver, store: store, pipeline: pipeline),
      applyScene: ApplyScene(resolver: resolver, store: store, pipeline: pipeline),
      createHome: CreateHome(homes: homes, settings: settings, ids: idGen, clock: clock),
      switchHome: SwitchHome(settings: settings),
      renameHome: RenameHome(homes: homes),
      deleteHome: DeleteHome(homes: homes, settings: settings),
      addRoom: AddRoom(rooms: rooms, ids: idGen),
      renameRoom: RenameRoom(rooms: rooms),
      deleteRoom: DeleteRoom(rooms: rooms, lights: lights),
      renameLight: RenameLight(lights: lights),
      moveLight: MoveLight(lights: lights),
      setFixture: SetFixture(lights: lights),
      forgetLight: ForgetLight(lights: lights, store: store),
      saveDiscoveredLight: SaveDiscoveredLight(lights: lights, store: store, ids: idGen, clock: clock),
      finishOnboarding: FinishOnboarding(homes: homes, rooms: rooms, lights: lights, settings: settings, store: store, ids: idGen, clock: clock),
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
```

- [ ] **Step 4: Run everything, format, analyze, commit**

```bash
flutter test && dart format lib test && flutter analyze --fatal-infos
git add lib/app test/app
git commit -m "feat(app): composition root wiring domain, data and services"
```

Plan 3 is complete when `flutter test` is green across `test/domain`, `test/data` and `test/app`, the layering test passes, and `flutter analyze --fatal-infos` is clean. Plan 4 builds the screens on `AppDependencies`.
