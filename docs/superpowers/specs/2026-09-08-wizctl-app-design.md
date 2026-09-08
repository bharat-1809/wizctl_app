# WizCtl app — design spec

Date: 2026-09-08 · Status: design approved in brainstorm; this document is the source of truth for the implementation plan.

## 1. Goal

A Flutter client for Philips WiZ lights on the local network, built on the `wizctl` Dart package and matching the Claude Design project "Philips Wiz Light Controller App" (mobile prototype, desktop prototype, handoff spec, design system) at high fidelity. Platforms: iOS, Android, macOS, Windows, Linux. No web. No account, no cloud: the app talks UDP to bulbs on port 38899 only.

Non-negotiables from the brief: BLoC state management, clean architecture, a local database for homes/rooms/lights, no hard-coded sizes (tokens plus layout-driven sizing), minimal magic numbers, `flutter_lints`, and subtle, buttery, tactile animation with synthesized sound and haptics.

## 2. Repositories, branches, dependencies

| Item | Decision |
|---|---|
| Package | `/Users/bharat/Bharat/github/wizctl`, `main` untouched. Package changes on branch `sharma/app-support` in a git worktree; version 1.1.0; PR to `main`. |
| App | `/Users/bharat/Bharat/github/wizctl_app`, fresh git repo, Dart package `wizctl_app`, `flutter create --org com.dotstudios --platforms=ios,android,macos,windows,linux --project-name wizctl_app .` |
| Package dependency | `wizctl: {path: ../wizctl}`. Until the package PR merges, a git-ignored `pubspec_overrides.yaml` points `wizctl` at the worktree path. |
| Toolchain | Flutter 3.47.2 stable, Dart 3.13. |
| Runtime packages | `flutter_bloc`, `bloc`, `equatable`, `go_router`, `drift`, `drift_flutter`, `flutter_soloud`, `path_drawing`, `uuid`, `package_info_plus`, `wizctl`. |
| Dev packages | `flutter_lints`, `bloc_test`, `mocktail`, `drift_dev`, `build_runner`. |
| Lints | `include: package:flutter_lints/flutter.yaml`; `language: strict-casts, strict-inference, strict-raw-types`. |
| Verification commands | `flutter analyze --fatal-infos`, `dart format --output=none --set-exit-if-changed lib test`, `flutter test`, `dart run build_runner build --delete-conflicting-outputs`. |

Design reference files (prototypes, compiled component bundle, tokens) live in `design/reference/` for grepping exact values. They are reference, not code.

## 3. Package changes (wizctl 1.1.0, additive only)

### 3.1 Streaming discovery

```dart
sealed class ScanEvent {}
final class ScanProgress extends ScanEvent { probed, total, round, rounds, subnet }   // after each batch is sent
final class ScanFound    extends ScanEvent { DiscoveredLight light }                  // first reply from a MAC
final class ScanUpdated  extends ScanEvent { DiscoveredLight light }                  // richer reply for a known MAC (moduleName arrived)
final class ScanDone     extends ScanEvent { List<DiscoveredLight> lights }           // final deduplicated list

static Stream<ScanEvent> WizDiscovery.scanSubnetStream({String? subnet, Duration timeout, int port, int localPort, InternetAddress? bindAddress, int rounds});
static Stream<ScanEvent> WizDiscovery.probeAddressesStream({required Iterable<String> addresses, Duration timeout, int port, int localPort, InternetAddress? bindAddress, int rounds});
```

- `probed` counts addresses sent in the current round; `total` is the address count (254 minus own addresses); `round` runs 1..`rounds`.
- Cancelling the subscription stops probing and closes the socket.
- `scanSubnet` and `probeAddresses` are re-implemented as collectors over the streams; behaviour and existing tests unchanged.
- The stream also exposes `subnet` so the UI can print "Sweeping 192.168.1.0/24".

### 3.2 State restore

`factory ControlSignal.fromState(LightState state)` builds the pilot that restores a captured state: `state`, `dimming` (clamped 10–100), then exactly one channel in priority order: `sceneId > 0` (plus `speed`, clamped 10–200) → `temperature` (dropped if outside 1000–10000) → `r,g,b` (plus `coldWhite`/`warmWhite` if present) → `coldWhite`/`warmWhite`. Never throws for values a bulb reported.

### 3.3 Retry on `WizLight`

`WizLight(ip, {port, timeout, RetryConfig? retry})`, forwarded to `WizProtocol.send`. `null` keeps today's six-attempt default. The app uses `RetryConfig.exponential(count: 2, initialInterval: 250 ms, maxInterval: 1 s)` with `timeout: 1 s` for writes (three attempts, matching the design's "No response after 3 tries").

### 3.4 Housekeeping

`CHANGELOG.md` 1.1.0, README snippet for the stream, `cliVersion`/`pubspec` bump. Tests (offline, FakeBulb harness): progress totals per round, found/updated/done events, cancellation closes the socket, `fromState` round trips every channel, retry count honoured.

## 4. Domain model

The domain layer is pure Dart. It imports `package:wizctl` for its value types only (`BulbClass`, `WizScene`, `ControlSignal`, `LightState`, `DiscoveredLight`, `KelvinRange`, `RetryConfig`); the package's IO classes (`WizLight`, `WizDiscovery`) are used only in the data layer.

```dart
class Home  { String id; String name; String? subnet; DateTime createdAt; int sortIndex; }
enum RoomGlyph { sofa, bed, utensils, bath, lampDesk, trees }          // icon names: sofa, bed, utensils-crossed, bath, lamp-desk, trees
class Room  { String id; String homeId; String name; RoomGlyph glyph; int sortIndex; }
enum Fixture { bulb, dome, desk, strip, socket }                        // "Show it as": Bulb, Ceiling light, Lamp, Light strip, Plug
class Light { String id; String homeId; String roomId; String name; String ip; String mac; String? moduleName; BulbClass? bulbClass; Fixture fixture; String? fwVersion; int sortIndex; DateTime addedAt; }

enum ActiveChannel { white, colour, scene }
class Rgb { int r, g, b; }
class LiveState {
  bool isOn; int brightness /*10–100*/; int kelvin /*2200–6500, step 50*/; Rgb rgb; int sceneId; int speed /*10–200*/;
  ActiveChannel active; bool reachable; int? rssi; DateTime? updatedAt;
  static const initial = LiveState(isOn: false, brightness: 60, kelvin: 2700, rgb: Rgb(255,224,188), sceneId: 6, speed: 100, active: white, reachable: false);
}
class DiscoveredDevice { String ip; String mac; String? moduleName; BulbClass? bulbClass; String? fwVersion; String displayName; bool alreadySaved; }
sealed class ModeTarget { WholeHome(); RoomTarget(roomId); LightTarget(lightId); }
sealed class ModeArt { SceneArt(sceneId); SolidArt(Rgb); FlatArt(); }
class ModeSummary { String name; ModeArt art; bool isDynamicScene; bool isStaticScene; String slot; }
class DiscoveryProgress { DiscoveryPhase phase; int probed; int total; int round; int rounds; String subnet; }   // app-side; distinct from the package's ScanProgress
enum DiscoveryPhase { probingKnown, broadcasting, sweeping }
sealed class DeviceFailure { Timeout(ip, attempts); Unreachable(ip, cause); Unsupported(ip, method); OffNetwork(homeSubnet, currentSubnet); InvalidArgument(message); }
sealed class CommandReport { Pending(id, lightIds, description); Succeeded(id); Failed(id, lightId, lightName, ip, DeviceFailure); RetryFailed(id, lightName); }
class AppSettings { String? activeHomeId; bool feedbackEnabled = true; bool rescanOnLaunch = true; }
class DebugFlags { bool offNetwork; bool forceTimeout; bool findNothing; }   // debug builds only
```

IDs are UUID v4. `displayName` for a discovered device comes from class: RGB → "WiZ RGB", Tunable White → "WiZ Tunable White", Dimmable White → "WiZ Dimmable", Socket → "WiZ Smart Plug", Fan Dimmer → "WiZ Fan Dimmer", unknown → "WiZ device". Class display strings are the package's `BulbClass.displayName`; unknown class shows "Unknown".

## 5. Rules (pure functions, unit tested)

### 5.1 Capabilities (`CapabilityRules`)

| Capability | Classes |
|---|---|
| power | all |
| brightness | all except Socket (unknown class → yes) |
| colour temperature | RGB, Tunable White (unknown → yes) |
| colour | RGB (unknown → yes) |
| scenes | all except Socket |
| speed | only while the active scene is dynamic |

"Never a dead control": an unsupported control is absent, and one line says why (see copy in §15).

### 5.2 Live state from a `LightState`

`isOn = state.isOn`; `brightness = dimming ?? previous`, clamped 10–100; `rssi = state.rssi`; `reachable = true`; `updatedAt = now`.
Channel: `sceneId > 0` → `scene` (sceneId, `speed ?? previous`); else `temperature != null` → `white` (kelvin rounded to 50, clamped 2200–6500); else `r,g,b` present → `colour`; else `white` with previous kelvin. Fields of the other channels keep their previous values so the sheet can show the last colour or kelvin.

### 5.3 Mode summary (`ModeSummarizer`), port of the prototype

Input: the target's lights with live states. Empty → "Nothing set", flat art. If more than one light and any non-socket exists, drop sockets. If not all lights share (active, sceneId, rgb, kelvin) → "Mixed", flat. Then by the first light: scene → scene name, scene art, dynamic/static flags; colour → "Colour", solid rgb; all sockets → "Power on"/"Power off", flat; all Dimmable White → "Warm white", solid `rgb(255,201,141)`; else → "<kelvin>K white", solid kelvin colour.

Selection in the modes sheet: a colour swatch is selected when every target light is `colour` with that rgb; a white tile when every target light is `white` at that kelvin; a scene tile when every target light is `scene` with that id. The speed rail shows only on the Dynamic tab when the whole target is on one dynamic scene.

### 5.4 Room aggregates

`roomBrightness` = mean brightness of lights with the brightness capability, rounded; `roomKelvin` = mean kelvin of lights with the kelvin capability, rounded to 50; `roomCanKelvin` = any light with kelvin; kelvin note: if lights exist and none has kelvin → "No bulb in this room has a white channel to tune."; else if any light lacks kelvin → "Colour temp reaches <k> of <n> bulbs."; else none. Room power: any on → toggle checked.

### 5.5 Kelvin to colour

Linear interpolation between stops 2200 `(255,178,92)`, 2700 `(255,201,141)`, 3500 `(255,224,188)`, 4500 `(255,244,230)`, 5500 `(242,246,255)`, 6500 `(220,233,255)`.

### 5.6 Emission (fixture hero and cards)

Off or unreachable → transparent, bloom 0, filament opacity 0.06. On: colour = rgb when `colour` and class RGB; scene `from` colour when `scene`; kelvin colour otherwise. `alpha = 0.30 + brightness/100 × 0.62`; soft alpha = `alpha × 0.32`; bloom = `0.22 + brightness/100 × 0.58`; all transitions 420 ms.

### 5.7 Discovery sequence (`RunDiscovery`)

1. `probingKnown`: `probeAddressesStream` over the active home's light IPs (1 round, 1.5 s) to refresh reachability. Skipped in onboarding.
2. `broadcasting`: `WizDiscovery.discover(timeout: 4 s)` with an indeterminate filament bar.
3. Only on the user's action "Scan subnet": `sweeping` via `scanSubnetStream` (2 rounds), determinate bar "n of 254 addresses". Sweeps are never automatic (AGENTS.md: sweeps pollute the ARP table).
4. Every device found (any phase) is de-duplicated by MAC; devices lacking `moduleName` get one follow-up `getSystemConfig`; each gets one `getState` for initial live state. Devices whose MAC already belongs to the active home are marked `alreadySaved`.
5. The subnet reported by the sweep (or `NetworkInfo`) is stored on the home if the home has none.
6. Discovery pauses polling while it runs.

### 5.8 Refresh and reachability (`RefreshStates`, `SyncCoordinator`)

- `RefreshStates(lightIds)`: `getState` per light, 2 attempts, 1.5 s per attempt, at most 8 in parallel. Success → live state updated, miss counter reset, `reachable = true`. Failure → miss counter +1; two consecutive misses → `reachable = false`.
- `SyncCoordinator`: on cold start with an active home, refresh all lights if `rescanOnLaunch`; on resume and on desktop window focus, refresh all lights of the active home; screens register a poll scope (set of light ids) while visible; the union of scopes is polled every 10 s; polling pauses during discovery and while the app is backgrounded.

### 5.9 Off network (`NetworkMonitor`)

Current subnet = first RFC1918 IPv4 interface address (same preference as the package), re-read every 5 s while foregrounded and on resume. Off network when the home has a subnet and the current one is non-null and differs, or when there is no IPv4 address at all. No SSID reads, no location permission. While off network, every command fails fast with `OffNetwork` (toast "No route to the light"), reads are skipped, and the banner shows.

### 5.10 Blink to identify (`BlinkLight`)

Ignored while that ip is blinking. Sequence: `getState` (2 attempts) — on failure show the command-timeout toast and do not blink. Then write, wait 2000 ms, restore with `ControlSignal.fromState(captured)`.

| Class | Blink write |
|---|---|
| RGB | `state on, r 255 g 176 b 32, dimming 100` |
| Tunable White | `state on, temperature 2700, dimming 100` |
| Dimmable White, Fan Dimmer | captured on → `state off`; captured off → `state on, dimming 100` |
| Socket | `state = !captured.isOn` |
| Unknown class | as RGB |

While blinking, the key is amber with the strong glow and the row's icon well emits.

### 5.11 Command pipeline (`DeviceCommandPipeline`)

Input: a batch of `(light, ControlSignal, LiveState patch)` plus a description and an optional throttle key.

1. Off network → emit `Failed(OffNetwork)`; nothing sent, nothing patched.
2. Apply patches optimistically to `LiveStateStore`, remembering previous states.
3. Throttle: per key, send immediately if idle; otherwise keep only the latest batch and send it when the in-flight one completes or after 120 ms, whichever is later. Releasing a dial always sends the final value.
4. Send to each light in parallel through `DeviceGateway.send(ip, signal)` (3 attempts, 1 s each).
5. Per light: success → `reachable = true`, `updatedAt`; failure → revert that light's patch, `reachable = false`, emit `Failed`.
6. `Pending` is emitted at start; the toast layer shows the loading toast only if the batch is still pending after 600 ms, and resolves it in place.
7. `retry(reportId)` re-sends that light's signal once: success → patch re-applied, `reachable = true`; failure → `RetryFailed` ("Still no reply").

Debug builds wrap the gateway in a `FaultInjectingGateway` that honours `DebugFlags` (force timeout after 1.1 s, find nothing, off network).

### 5.12 Apply rules (`ApplyColour`, `ApplyWhite`, `ApplyScene`, `SetSpeed`)

| Use case | Eligible lights in target | Signal | Patch | If none eligible |
|---|---|---|---|---|
| ApplyColour(rgb) | class RGB (or unknown) | `state on, r g b` | `active colour, rgb, isOn` | toast error "No colour bulb here" / "Colour needs an RGB bulb." |
| ApplyWhite(kelvin) | RGB, TW | `state on, temperature` | `active white, kelvin, isOn` | toast error "No white channel here" / "These bulbs only dim." |
| ApplyScene(id, speed?) | all but Socket | `state on, sceneId, speed (dynamic only)` | `active scene, sceneId, isOn` | toast error "No scene channel here" / "A plug only switches power." |
| SetSpeed(speed) | lights on a dynamic scene | `speed` | `speed` | silently nothing |
| SetBrightness(v) | brightness capability | `state on, dimming` | `brightness, isOn` | nothing |
| SetKelvin(k) | kelvin capability | `temperature` | `kelvin, active white` | nothing |
| SetPower(on) | all | `state` | `isOn` | nothing |

Unreachable lights are still attempted (a failure refreshes their status). Scene apply toasts "<Scene> applied" with body "to the whole home" / "to <room>" / "to <light>".

## 6. Persistence (drift, SQLite via `drift_flutter`)

```
homes        (id TEXT PK, name TEXT, subnet TEXT NULL, created_at INT, sort_index INT)
rooms        (id TEXT PK, home_id → homes ON DELETE CASCADE, name TEXT, glyph TEXT, sort_index INT)
lights       (id TEXT PK, home_id → homes CASCADE, room_id → rooms RESTRICT, name TEXT, ip TEXT, mac TEXT, module_name TEXT NULL,
              bulb_class TEXT NULL, fixture TEXT, fw_version TEXT NULL, sort_index INT, added_at INT, UNIQUE(home_id, mac))
light_states (light_id TEXT PK → lights CASCADE, is_on BOOL, brightness INT, kelvin INT, r INT, g INT, b INT, scene_id INT, speed INT,
              active TEXT, rssi INT NULL, updated_at INT)
settings     (key TEXT PK, value TEXT)
```

Repositories expose `watch…()` streams (`HomeRepository.watchHomes/watchActive`, `RoomRepository.watchByHome`, `LightRepository.watchByHome/watchByRoom/watch`). `light_states` is written by a debounced (500 ms) listener on `LiveStateStore` and read once at startup to seed the store, so dials show real values immediately while the first refresh runs. Schema version 1; migrations via drift's `MigrationStrategy`. Deleting a room is refused while it has lights.

## 7. Architecture and layout

Feature-first clean architecture. Dependencies point inward: `features` → `domain` ← `data`; `core` is shared UI infrastructure with no domain knowledge; `app` is the composition root.

```
lib/
  main.dart                 bootstrap(): DB, settings, audio, composition root → runApp
  app/                      WizCtlApp, router, shells (compact/medium/expanded), global providers, command-report → toast listener
  core/
    theme/                  WizColors, WizType, WizSpace, WizElevation, WizMotion (ThemeExtensions), WizTheme.build()
    layout/                 WizBreakpoints, WidthClass, WizLayout.of(context), grid column helpers
    widgets/                the design-system kit (§11)
    icons/                  WizIcon + WizIconData (49 paths)
    motion/                 RiseIn (staggered load-in), FadeScreenTransition, breathe, reduced-motion helper
    feedback/               FeedbackKind, FeedbackService, WizSynth (PCM renderer), SoLoudPlayer, HapticMapper
    copy/                   Strings (all user-facing copy)
    util/                   kelvin/rgb/hsv maths, plural(), subnet helpers
  domain/
    entities/  repositories/  services/ (LiveStateStore, DeviceCommandPipeline, SyncCoordinator, NetworkMonitor, ModeSummarizer, CapabilityRules)  usecases/
  data/
    db/ (AppDatabase, tables, DAOs)  repositories/  device/ (WizDeviceGateway, FaultInjectingGateway)  network/ (NetworkInfo)  cli/ (CliConfigExporter)
  features/
    onboarding/  home/  rooms/  lights/  modes/  discovery/  settings/     each: bloc/  view/  widgets/
test/                      mirrors lib/
```

Streams in, use cases out: a bloc subscribes to repository/store streams and calls use cases; it never touches the gateway or another bloc. The composition root (`app/bootstrap.dart`) constructs the database, repositories, gateway, services and use cases once and provides them with `RepositoryProvider`; no service locator, no DI codegen.

## 8. Blocs

| Bloc | Scope | State (essentials) | Events / intents |
|---|---|---|---|
| `HomesBloc` | app | homes, activeHomeId, activeHome | subscribe, create(name), switchTo(id), rename(id, name), delete(id) |
| `SettingsCubit` | app | feedbackEnabled, rescanOnLaunch, debugFlags | toggles |
| `BlinkCubit` | app | blinking ip set | blink(ip) |
| `HomeScreenBloc` | route `/home` | rooms with counts/on, allLights summary (All on / k of n on / All off), unreachableCount, offNetwork | subscribe, allPower(on), roomPower(id, on), retryNetwork |
| `RoomsListBloc` | route `/rooms` | rooms with counts | add(name, glyph), rename, delete |
| `RoomBloc(roomId)` | route `/rooms/:id` | room, lights + live, brightness/kelvin aggregates, canKelvin, kelvinNote, modeSummary, offNetwork | brightnessChanged(v, final), kelvinChanged, lightPower(id, on), lightBrightness(id, v), roomPower |
| `LightBloc(lightId)` | route `/lights/:id` and desktop inspector | light, live, capabilities, facts, modeSummary, offNetwork | power, brightness, kelvin, speed, setFixture, rename, forget, retry |
| `LightModesBloc(target)` | sheet and `/modes` | target, tab, hasWheel, wheel hue/sat, swatch/white/scene selection, speed, note | setTarget, setTab, colour(rgb), white(k), scene(id), speed(v) |
| `DiscoveryBloc` | route `/discover`, onboarding step 2 | phase (idle/probingKnown/broadcasting/sweeping/found/empty/error), progress, found list, saving | start, sweep, cancel, keepToggle(ip), save(ip, alias, roomId, fixture) |
| `OnboardingBloc` | route `/setup` | step, draftName, setupRooms, kept ips, assignments (alias, roomId, fixture), namesComplete | nameChanged, createHome, back, keepToggle, toNaming, aliasChanged, roomPicked, fixturePicked, newRoom(name, glyph), finish |

`ToastController` (a `ChangeNotifier` in `app/`) holds at most three toasts, 3.2 s each, loading toasts until updated; it subscribes to `DeviceCommandPipeline.reports`. Route-scoped blocs are created in route builders and closed on pop; they register their poll scope with `SyncCoordinator` on subscribe and unregister on close.

## 9. Navigation and shells (go_router)

| Route | Screen |
|---|---|
| `/setup` | Onboarding (redirect target while the database has no home) |
| `/home` | Home (compact: room grid; expanded: "All lights" grid + inspector) |
| `/rooms` | Rooms list |
| `/rooms/:roomId` | Room |
| `/lights/:lightId` | Light detail (compact); on expanded renders the light's room with that light selected in the inspector |
| `/modes` | Light modes tab (Scenes) |
| `/settings` | Settings |
| `/discover` | Discovery |

Compact shell: `StatefulShellRoute.indexedStack` with branches Home, Rooms, Scenes, Settings; the floating tab bar shows on all routes except `/setup` and `/discover`. Expanded/medium shell: rail (rooms, All lights, Scenes, Discovery, Settings) + content + inspector (expanded) or inspector-as-sheet (medium). The shell is chosen by width class inside one `ShellRoute` builder, so the current route and its blocs survive a resize. Screen transitions are a 300 ms opacity fade; sheets are 260 ms rise-and-fade with a 72 % scrim and 6 px blur. Back always pops.

## 10. Screens

Copy is verbatim from the prototypes and handoff; control labels are uppercase with 0.10 em tracking.

### 10.1 First run (mandatory; compact stacked, expanded as a centred 560 column)

1. **Name this home.** Wordmark WIZCTL; hero "Name this home"; body "Rooms and lights are stored in this home's config file on this machine. You can keep several homes here."; field "HOME NAME" (56 tall, placeholder "Kaverappa House"); primary key "Create home" (radio icon) disabled until non-empty; "A home is required. You can add more homes later and switch between them."; privacy line. Content rises in with 90/160/230 ms stagger.
2. **Discovering.** Auto-runs the broadcast phase on entry; the sweep runs only from the "Scan subnet" key. Top bar "Discovering", subtitle "n of 254 addresses" while sweeping else "Local network", back to step 1. Scanning: the radar (150 well, two ping rings 2.2 s, 64 key with radio icon), filament bar "Sweeping subnet"/"Listening for lights", three skeleton rows. Empty: empty state "No response on the local network" / "Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time." / primary "Scan subnet". Found: success banner "<n> lights answered" body "Swept <subnet>/24 · 254 addresses" (after a sweep) or "Broadcast on <subnet>/24"; one row per device (icon well, name, mono "ip · class", 44 flash key, 26 check cap, checked by default; tapping the row toggles keep); primary "Save <n> lights"; ghost "Scan again".
3. **Name your lights.** Top bar "Name your lights" / "A name replaces the address", back to step 2; hint "Not sure which bulb is which? Tap the flash key on a card and that light blinks for two seconds, then goes back."; one card per kept light: mono meta + flash key, 56 alias field (placeholder "Ceiling dome light", "Plug by the TV" for a socket), ROOM chips (Living Room, Bedroom, Kitchen, any created) + "New room" chip (opens the New room sheet: ROOM NAME, GLYPH ×6, Cancel / Create room; empty name → reject), SHOW IT AS fixture keys (44 squares; socket defaults to Plug, others Bulb). Primary "Finish setup" disabled until every kept light has a name. Finish writes the home with the rooms that received a light plus custom rooms, stores the subnet, toasts "<Home> is set up" / "<n> lights in <m> rooms", and routes to `/home`.

### 10.2 Home (compact)

Top bar: home name, subtitle "<r> rooms · <l> lights", leading house key (Homes sheet), trailing radio key (`/discover`). Off-network banner (§15). Inset panel "ALL LIGHTS" with the display-size state and the master toggle. Red line with wifi icon "<n> light(s) not answering" when any light is unreachable. Room grid (min tile 150) of room cards, rising in with 40 + 55·i ms. No stat tiles, no section label, no add-room key.

Homes sheet: rows per home (house well, name, "<r> rooms · <l> lights", amber ring on the active one; tap switches), "NEW HOME" field (placeholder "Studio"), footer Close / Add home (empty → reject; success toasts "<name> created" / "Discover the lights on this network" and opens `/discover`).

### 10.3 Room (compact)

Top bar: room name, "<n> lights", back, trailing room toggle. Inset "WHOLE ROOM" panel: two dials (Brightness %, Colour temp. K, the second only if `roomCanKelvin`), kelvin note, Light mode row (48 art square, "LIGHT MODE", summary name, chevron well) opening the modes sheet for the room. Empty room: empty state "No lights in this room" / "Discover lights on the network, then place them here." / primary "Discover lights". Then one light card per light (name, meta = mode summary or ip when unreachable, fixture icon, toggle, brightness rail; a plug shows no rail), rising in with 30 + 60·i ms, tap opens the light. Tapping the toggle or rail never opens the light.

### 10.4 Light detail (compact)

Top bar: name, "<room> · <class>", back, trailing badge Live (online) / No reply (danger). Fixture hero (236 tall design box) drawn from the fixture kind with bloom and breathe. Power key (lg) centred. Unreachable banner "No reply from this light" / "It may be switched off at the wall, or the router changed its address." / Retry. Two stat tiles: A = thermometer "Colour temp" kelvin K (RGB/TW) else lightbulb "Class"; B = power "Power" On/Off (socket) else gauge "Intensity" brightness % (accent when on). Socket: inset note "A plug switches power only. It has no brightness, colour or scene channel." Otherwise: dials panel (Brightness; Colour temp. if capable; note "This bulb dims but has no white channel to tune." when not) and a modes panel (Light mode row → sheet; speed rail "Speed" when the scene is dynamic; "<Scene> is a static scene — the bulb ignores speed." when static). Device panel "DEVICE": Address "<ip>:38899", MAC, Class, Signal "<rssi> dBm" or "no reply"; keys "Show it as" (fixture sheet: "This only changes how the light is drawn here. It does not change what the bulb supports.", grid of the five fixtures, min tile 100), "Rename" (ghost), "Forget" (danger; confirm sheet "Forget <name>?" / "Its alias and room are removed. The bulb keeps working." Cancel / Forget → toast "<name> forgotten" / "Removed from this home's config file").

### 10.5 Light modes (sheet from a room or light; `/modes` tab)

Sheet title "Light mode · whole home" / "· <room>" / "· <light>"; tab route title "Light modes" / "Colour, 15 static and 21 dynamic scenes" with an "APPLY TO" well key (target name, chevron-down) opening the target sheet ("Apply scenes to": Whole home with "<n> lights", each room with its count, each light indented with its ip; amber ring on the selection). Segmented control Colour / Static / Dynamic. Colour: colour wheel (only if the target has an RGB bulb; 228 on the tab, 196 in the sheet, capped by width), "COLOURS" twelve hue swatches (52 / 44), "WHITES" six kelvin tiles (60×64 / 52×60) with mono labels. Static and Dynamic: speed rail "Speed — <scene>" when applicable, scene grid (tab: square tiles min 160, sheet: tiles min 100 at 82 tall), selection ring, cyan pip on dynamic tiles, note "Dynamic scenes cycle. Speed runs from 10 to 200." / "Static scenes hold one look. The bulb ignores speed." One tap applies.

### 10.6 Rooms (compact tab)

Top bar "Rooms" / "<r> rooms · <l> lights", trailing plus key. List rows (glyph well, name, "<n> lights · <k> on", chevron), rising in with 30 + 55·i. Ghost "Add room" (house-plus). Inset note "Rooms are stored in this home's config file on this machine. Nothing is uploaded." Add sheet "Add a room" (ROOM NAME, GLYPH, Cancel / Save room → toast "Room saved" / "<name> is empty — discover lights for it"; empty name → reject). Long-press a row: sheet with Rename room / Delete room (delete disabled with "Move its lights first" while it holds lights).

### 10.7 Settings

Top bar "Settings" / "This home lives on this device" ("machine" on desktop). Unreachable banner. Rows: house "<home>" meta "Home name" pencil (Rename home sheet); radio "Discovery" meta "Broadcast, then unicast sweep" (compact only; desktop uses the rail); desktop only: terminal "Config file" meta "~/.config/wizctl/config.json" subtitle "Aliases and rooms are exported here for the CLI"; desktop only: terminal "CLI parity" meta `wizctl on -t "<first light>"`, tap copies to the clipboard; refresh "Re-scan on launch" toggle; zap "Sound & haptics" meta "Clicks and vibration on every control" toggle; privacy note; caption "WizCtl <version> · wizctl <package version>". Debug builds only: "PROTOTYPE SWITCHES" rows wifi "Wrong network" / "Show the offline state", clock "Force command timeout" / "Every write fails after 1.1s", search "Discovery finds nothing" / "Scan returns zero lights".

### 10.8 Discovery (`/discover`)

Top bar "Discover lights" / "n of 254 addresses" or "Local network", back; desktop: "Discovery" with a ghost "Rescan" key. Idle: empty state "Nothing found yet" / "Lights answer on your local network. Make sure they are powered on, then scan the subnet." / primary "Discover lights" (starts probe + broadcast). Scanning: loading banner "Listening on <subnet>/24" / "Broadcast" or "Sweeping <subnet>/24" / "n of 254 addresses", filament bar "Discovering", three skeletons. Empty after broadcast: empty state "No response on the local network" / "Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time." / primary "Scan subnet", plus the inset note "The IP shown in the Philips app can be stale — it talks to the cloud. Your router's DHCP client list is the reliable source." Empty after a sweep: the same with body "Make sure the lights are powered on, then sweep the subnet one address at a time." Found: success banner "<n> lights answered" with a Live badge; rows (lightbulb well, device name, "ip · class", trailing blink key + primary sm "Save", or ghost "Saved" when already in the home); ghost "Scan again" (broadcast) and ghost "Sweep subnet". Save sheet "Name this light": mono meta, ALIAS (placeholder "Bedside bulb"), ROOM chips (existing rooms, or a New room chip when none), Cancel / Save light → toast loading "Saving <alias>" → success "<alias> saved" / "<ip> added to this home". Leaving the screen cancels a running scan.

### 10.9 Desktop (medium and expanded)

Window title "wizctl · setup" / "wizctl · <home>". Rail: WIZCTL wordmark (30, weight 900, +0.02 em), home-switcher pill (name + chevron-down → Homes dialog), sections ROOMS (each room, mono count) and HOUSE (All lights with count, Scenes "36", Discovery, Settings), footer inset panel "terminal · <k> on · udp 38899". A single raised cap travels between items. Grid view (All lights or a room): top bar with subtitle "<n> lights · <k> on" or "<n> lights", trailing ghost "Add room" and the room toggle; off-network banner; stat tiles "Lights on" (k / n, accent) and "Not answering"; unreachable banner; empty state "No lights in this room" / "Discover lights on the network, then save them into this room." / "Discover lights"; whole-room panel (dials 140, Light mode row, note) when a room has lights; "LIGHTS" label; light-card grid (meter variant, min tile 340, gap 14, rising in with 30 + 50·i) where clicking a card selects it (amber 1.5 ring). Inspector (352; 400 on very wide): name (display 26) and "ip · class", Live badge; hero well (132 tall, fixture at 0.6 scale); dials 140 when the class has modes; power key (md) beside stat tiles Class and Scene / Brightness / Power; Light mode row; socket note; flat device panel (MAC, "udp 38899 · fw <version>"); keys Rename (ghost sm, pencil) and Forget (danger sm, trash). No selection: empty state "No light selected" / "Pick a light on the left to control it." Dialogs are centred (520 wide; modes 680 with a 216 wheel and 4-column scene grid at 104 tall; Scenes tab grid 4 columns at 140). Toasts stack bottom-right, 340 wide. Medium width collapses the rail to icons with tooltips and shows the inspector as a dialog on selection.

## 11. Design-system port

### 11.1 Tokens (ThemeExtensions; reference names in code, never literals)

Colours (`WizColors`): char 1000 `#0C0C0E`, 950 `#101013`, 900 `#16161A`, 850 `#1D1D22`, 800 `#24242A`, 750 `#2C2C33`, 700 `#35353D`, 600 `#42424C`, 500 `#55555F`, 400 `#6E6C69`; ink 1000 `#F6F3ED`, 700 `#C6C2BA`, 500 `#95918A`, 400 `#6E6B65`, 300 `#4B4945`; amber 300 `#FFD98A`, 400 `#FFC24D`, 500 `#FFB020`, 600 `#E1930A`, 700 `#A96C05`; kelvin 2200 `#FFB25C`, 2700 `#FFC98D`, 3500 `#FFE0BC`, 4500 `#FFF4E6`, 5500 `#F2F6FF`, 6500 `#DCE9FF`; hues red `#FF4A3D`, orange `#FF8A2B`, yellow `#FFD52B`, lime `#B7F03C`, green `#38D06B`, teal `#25D8C0`, cyan `#2ECBFF`, blue `#2E7BFF`, indigo `#5B5BFF`, violet `#A45BFF`, magenta `#FF3FC0`, pink `#FF6FA5`; signal online `#38D06B`, offline `#55555F`, warn `#FFB020`, danger `#FF5A47`; surfaces app=char950, chassis=char900, panel=char850, raised=char800, key=char750, well=char1000, scrim `rgba(10,10,12,.72)`; text primary=ink1000, secondary=ink700, tertiary=ink500, disabled=ink400, onAccent `#1A1305`; accent soft `rgba(255,176,32,.14)`; edge hairline `rgba(255,255,255,.055)`, key `rgba(255,255,255,.10)`, groove `rgba(0,0,0,.55)`; focus ring `rgba(255,194,77,.55)`; danger key gradient `#E2543F → #A82B1C` on `#FFF1ED`.

Type (`WizType`): display face Neumatic Compressed, UI face Hanken Grotesk, mono JetBrains Mono. hero 64 / 0.92 / −0.005 em / 800; display 44 / 0.98 / 0.005 em / 700; title 30 / 1.06 / 0.015 em / 700; heading 23 / 1.16 / 0.025 em / 600; bodyLg 17 / 1.5; body 15 / 1.5; bodySm 13 / 1.45; caption 11 / 1.35 / 0.06 em; label 11 uppercase / 0.10 em; readout 34 / 1 / 700 tabular; readoutSm 18; code 12.5 / 1.55 mono. Letter-spacing in em converts to `size × em` logical pixels.

Space (`WizSpace`): space1 2, 2 4, 3 6, 4 8, 5 12, 6 16, 7 20, 8 24, 9 32, 10 40, 11 56, 12 72; radius1 6, 2 10, 3 14, 4 20, 5 28, 6 36, pill; control heights 36 / 48 / 56; hit minimum 44; knob sm 56, md 96, lg 168; track thickness 14; panel padding 16 / 20; gutter compact 20, desktop 32; rail 264 (288 wide), inspector 352 (400 wide), icon rail 72; tab bar height 72, float 18; hairline 1, key border 1.5.

Elevation (`WizElevation`): the shadow recipes from `elevation.css` as lists of outer `BoxShadow`s plus inset highlight/groove descriptors painted by `WizSurface`: panel, raised, key, knob, pressed, well, wellDeep, overlay, flat; glowAmber and glowAmberStrong (the softened values). Textures: grain = 0.5 radius dots at 3.5 % white on a 3 px tile; vignette = radial 115 %×85 % at (50 %, −8 %) from 5.5 % white to transparent at 58 %; knurl = repeating 1 px 7 % white, 2 px 34 % black stripes.

Motion (`WizMotion`): press 80, release 140, ui 180, panel 260, screenEnter 300, loadIn 360 (range 340–380), light 420, breathe 5500, toast 3200, ping 2200, filament 1350, sheen 1600, spin 900; curves tactile `Cubic(.2,.8,.2,1)`, press `Cubic(.4,0,1,1)`, settle `Cubic(.16,1.02,.3,1)`; press travel 1.5, press scale 0.985, small-key scale 0.94, card scale 0.975, stagger 55.

### 11.2 Widget kit (`core/widgets`), geometry from the bundle

- `WizPressable`: the one press recipe. Pointer down: translate 1.5 down, scale (0.94 small round keys, 0.97 keys, 0.975 cards, 0.985 large surfaces), shadow flips to pressed, fires a feedback kind. Release: settle curve 140 ms. Hover on desktop: brightness 1.08. Disabled: opacity 0.42, no press. Focus: 2 px amber ring.
- `WizSurface` / `WizPanel`: raised (surface-raised → panel gradient, panel shadow, grain), inset (char900 → char950, well shadow), flat (hairline), optional glow. Radius 20 default. Never raised directly inside raised.
- `WizButton`: primary (amber 400 → 600, onAccent ink, key shadow, fires `confirm`), secondary (key → raised), ghost (char800 → 850), danger (fires `reject`); sizes sm 36 / px 14 / 12, md 48 / 20 / 13.5, lg 56 / 26 / 15; uppercase 700 with label tracking; optional icon; fullWidth.
- `WizIconKey`: circle or squircle, sm 36 / md 44 / lg 56, active = amber.
- `WizToggle`: sm 46×27 cap 21, md 60×33 cap 27; on = amber gradient with inner warm shadow and 16 px glow, off = char1000 → 800; ivory radial cap slides 260 ms settle; press squash 0.93; supports drag and flick; fires `toggleOn`/`toggleOff`.
- `WizPowerKey`: md 96, lg 132; icon 0.34 × d; on = amber radial (300 → 500 → 700) with strong glow, off = key → char900 with knob shadow; press sinks 2 and scales 0.985; fires `power` on, `toggleOff` off.
- `WizDial`: 280° sweep starting at −140°; conic arc amber 600 → 400 (at 65 % of the filled sweep) → 500, charcoal for the rest, dead wedge at the bottom; knob inset 8.5 % with knurl, rotating with the value; index mark 3 wide, 12.5 % tall, amber 300 with glow; readout well inset 23.5 % with value at 24 % of the diameter (weight 800, tabular) and unit at 11 %; label below. Vertical drag: 160 px of travel = full range; arrow keys step ×5; detent every 1/40 of range fires `detent`; press fires `press` and scales 0.985; readout snaps (never tweened); the arc glow eases 180 ms. Size is given by the parent and clamped 56–168.
- `WizSlider`: track 14 pill with well shadow; fill inset 2 with gradients brightness (`#3A3A42 → amber 300`), kelvin (2200 → 3500 → 4500 → 6500), speed (`#3A3A42 → cyan`), colour (chosen rgb), neutral; ivory handle 26; detent every 1/20; label + display readout 20.
- `WizColorWheel`: conic hue ring (red, yellow, green, teal, cyan, indigo, violet, magenta, red from −90°), 8 px inset, radial white to transparent at 62 %, inner shadow; puck 34 with 4 px ivory ring and rgb glow; radius margin 18; drag anywhere; detent every 15° of hue; returns hue, saturation, rgb (HSV, V = 1).
- `WizSceneArt`: procedural painter from the scene's `from`/`to`: radial 72 %×58 % at (26 %, 14 %) `from` → transparent 68 %, radial 84 %×70 % at (82 %, 96 %) `to` → transparent 72 %, linear 158° `from → to`, top-left sheen, grain at 85 %. Keyed by scene id (`scene-<id>`) so real artwork can replace it later.
- `WizSceneTile` (grid variant): art, bottom gradient label in display face (20 tab / 14 sheet), cyan 5 px pip with glow for dynamic, 1.5 amber inset ring when selected, press scale 0.985.
- `WizSegmentedControl`: recessed pill track (char1000 → 900), 4 padding and gap, one raised cap that travels 260 ms settle; items uppercase 13 / 12 with 0.08 em; fires `tick` on change. Heights 44 / 36.
- `WizTabBar`: floating 72 tall, radius 28, key shadow; items 52 squares; one amber cap (radius 14) travels; selected icon onAccent and scale 1.06; fires `tick`.
- `WizRail`: 264 wide, char900 → 950, hairline right edge; brand slot, sections with caption titles, 42-tall items (icon amber when active, mono meta), one raised cap travels; footer slot; icon-only variant 72 wide with tooltips.
- `WizTopBar`: min height 56, leading slot, title (title type, ellipsis), subtitle (bodySm tertiary), trailing slot.
- `WizListRow`: 12/14 padding, radius 14, 40 icon well (amber when active), title 16 / 600, meta bodySm; press sinks; active state has a faint amber hairline.
- `WizBadge`: 22 tall pill, black 35 % well, caption uppercase; tones neutral / accent / online / danger; dot 6 with glow and a 2.2 s pulse for live tones only.
- `WizStatTile`: 14/16 padding, radius 14, caption with 14 icon, value 28 display 800 tabular (amber when accent), unit 13.
- `WizReadout`: display numeral with 0.44 em unit; sm 18, md 34, lg 48; mono option.
- `WizEmptyState`: 76 deep well with a 30 icon, heading title, body up to 320 wide, one action.
- `WizFilamentBar`: 6 tall well with 4 px ticks; determinate amber 700 → 300 fill with glow, width eases 420; indeterminate 38 % hot spot travelling −105 % → 205 % over 1.35 s with a heat pulse; optional caption label and mono percentage.
- `WizSkeleton`: well with a 1.6 s sheen; circle option.
- `WizSpinner`: needle sweep (conic 210° → 355°) in a recessed ring, 900 ms; sizes 16–22.
- `WizStatusBanner`: recessed band (char900 → 950), 30 icon well, tones loading (spinner, amber), success (check, online), error (x, danger), warn (wifi), info (terminal); title 14 / 600, body bodySm, trailing action.
- `WizToastLayer` + `ToastController`: raised card, 26 icon well, tones success (`confirm` sound), error (`reject`), loading (silent, spinner, stays), info (`tick`); max three; 3.2 s; 260 ms rise-in; dismiss key; placed above the tab bar on compact, bottom-right 340 wide on desktop.
- `WizSheet`: compact = bottom sheet (radius 28 top, grab handle 44×4, max height 86 %, drag to dismiss with proportional scrim); medium/expanded = centred dialog (radius 28, width capped 520 or 680); scrim 72 % with 6 px blur; 260 ms rise 14 + fade; Escape closes.
- `WizTextField`: recessed well, 48 or 56 tall, bodyLg, no border, amber focus ring.
- `WizChip`: pill, 36 or 40 tall, 13 / 600, amber when selected, raised shadow, press sinks.
- `LightCard`: radius 20, panel shadow plus amber glow when lit, opacity 0.55 when unreachable; 46 icon well (amber radial when lit); name 16.5 / 600; mono meta 11; toggle; second row: brightness rail (compact) or 6 px meter with amber 700 → 300 fill and an 18 display readout (desktop); unreachable line "No response on the local network" with wifi icon.
- `RoomCard`: radius 20, 42 glyph well (amber when on), sm toggle, name 19 / 600, "<n> lights · <k> on" or "· all off"; press scale 0.975; glow when on.
- `FixtureHero`: paints bulb (44×28 knurled cap, 58×18 neck, 122 globe with two 34-tall filaments and a loop, highlight), dome (216×78 with cord lines), desk (140×76 rounded top), strip (262×20), socket (104 square, radius 20) inside a 350×236 design box scaled uniformly to the available width; bloom above (blur 34, 1.55 × fixture width), floor glow (blur 14), emission per §5.6, 5.5 s breathe while on, all colour changes 420 ms. Desktop inspector variant is a 132-tall well at 0.6 scale.
- `ModeRow`: raised key (radius 14) with 48 art square, "LIGHT MODE" caption, heading name, chevron well; art cross-fades 260 ms on change.
- `WizGrid`: lays out children in as many columns as fit a minimum tile width, with a gap from tokens.

### 11.3 Icons

`WizIcon(WizIcons.<name>, size)` paints one of the 49 Phosphor Bold paths (256 grid, `currentColor`) inlined in `core/icons/wiz_icon_data.dart` from the bundle's `ICONS` map. Names: arrow-left, arrow-right, bath, bed, check, chevron-down, chevron-left, chevron-right, circle-dot, clock, coffee, droplet, ellipsis, flame, gauge, house, house-plus, lamp-ceiling, lamp-desk, layout-grid, lightbulb, minus, monitor, moon, palette, pause, pencil, play, plus, power, radio, refresh-cw, search, settings, sliders-horizontal, smartphone, sofa, sparkles, sun, terminal, thermometer, trash, trees, tv, utensils-crossed, waves-horizontal, wifi, x, zap. Sizes: 14–15 in captions, 20–24 in rows, 26–30 in empty-state wells, 0.34 × diameter in a power key.

### 11.4 Fonts and assets

Bundled in `assets/fonts/`: Neumatic Compressed Light 300, Regular 400, Medium 500, SemiBold 600, Bold 700, ExtraBold 800, Black 900 (OTF, fetched from the design project); Hanken Grotesk 400/600/700 and JetBrains Mono 400/500/700 (TTF from Google Fonts, OFL, licence files included). No images, no logo mark, no audio files.

## 12. Motion

From the handoff table: screen enter 300 opacity only; content load-in 340–380 rise 10–12 px + fade, 50–60 ms stagger per card, first build only; tab / segmented / rail cap 260 settle; key press 80 sink 1.5 with shadow flip; release 140 settle (large surfaces 0.985, small keys 0.94); sheet 260 rise 14 + fade; light fade 420 for emission colour and bloom; breathe 5.5 s 0.88 → 1 only while on; blink is a real 2000 ms write and restore. Nothing bounces, nothing spins except the spinner, nothing fades in on load, numeric readouts snap.

Additions (subtle, all durations from tokens, all skipped under reduced motion): toggle cap squash and flick-to-toggle; power key bloom flare ramping in over 420 on turn-on; card emission ring and meter easing; shared-element hero (name and fixture icon) from light card to light detail on compact; scene tile selection ring sweeping in over 150 with the mode row art cross-fading 260; radar ping rings during discovery and found rows sliding in; drag-to-dismiss sheets with proportional scrim; pull-to-refresh drawn as a filament bar; desktop hover brightening and cursor changes; badge dot pulse for live tones; dial arc glow easing with value.

## 13. Sound and haptics

`FeedbackService.play(FeedbackKind)`; kinds `press, release, toggleOn, toggleOff, tick, detent, power, confirm, reject`. On by default, one toggle in Settings, persisted. Every `WizPressable` fires on pointer down.

Synthesis (pure Dart, rendered once at startup into in-memory 16-bit mono WAV at 44.1 kHz, nothing longer than 150 ms): `noise(dur, cut, gain)` = white noise with a linear decay through a one-pole low-pass at `cut` Hz; `tone(f, f2, dur, gain, type, at)` = oscillator (sine, triangle, sawtooth) with an exponential frequency ramp `f → f2` over `dur`, gain envelope 0.0001 → gain in 4 ms → 0.0001 at `dur` (exponential), starting at `at`. Master gain 0.9.

| Kind | Haptic (web reference, ms; Flutter mapping below) | Recipe |
|---|---|---|
| press | 10 ms | noise 12 ms cut 2400 gain .05; sine 200→120 45 ms gain .05 |
| release | none | noise 8 ms cut 4200 gain .022 |
| toggleOn | 14 ms | noise 10 ms cut 3200 .05; sine 320→560 55 ms .05 |
| toggleOff | 10 ms | noise 10 ms cut 2600 .045; sine 300→170 55 ms .045 |
| tick | 8 ms | noise 9 ms cut 3600 .035; triangle 520 30 ms .03 |
| detent | 4 ms | noise 6 ms cut 5200 .02 |
| power | 18 ms | noise 14 ms cut 2200 .055; sine 150→90 90 ms .06 |
| confirm | 8, 26, 12 | triangle 660 50 ms .04; triangle 990 70 ms .035 at 55 ms |
| reject | 12, 40, 12 | sawtooth 210→140 120 ms .05 |

Playback: `flutter_soloud`, sources loaded from memory, polyphonic so rapid detents overlap. On iOS the audio session is set to the ambient category if the engine exposes it, so clicks mix with music and respect the mute switch; otherwise the engine default is kept. Verified on device during implementation. Haptics via Flutter's `HapticFeedback`: detent → selectionClick; press, tick → lightImpact; toggleOn, toggleOff → mediumImpact; power → heavyImpact; confirm → light then medium 30 ms apart; reject → heavy twice 40 ms apart; release → none; desktop platforms no-op. Widget tests inject a fake `FeedbackService`.

## 14. Responsive rules

- Width classes from tokens, evaluated by `LayoutBuilder`: compact < 720, medium 720–1100, expanded ≥ 1100, wide ≥ 1600 (rail 288, inspector 400). They re-evaluate on rotation, resize and folding; routes and blocs survive shell changes.
- Grids compute columns from a minimum tile width (rooms 150, light cards 340, scene tiles 100 sheet / 160 tab, fixture picker 100); never a fixed count.
- Controls size to their container: two dials split the panel width minus gap and clamp to 56–168 with readout and mark scaling with the diameter; the colour wheel is `min(available, 228)`; the fixture hero scales uniformly in a fitted box; the power key keeps its token size.
- Text honours system scaling up to 1.3; rows use minimum heights; names ellipsize; helper copy wraps.
- Safe areas: tab bar floats 18 above the bottom inset; top insets respected; fields scroll above the keyboard.
- Sheets: bottom on compact; centred and width-capped on medium and expanded; height ≤ 86 %.
- Desktop: native minimum window 720×560; every column scrolls, nothing overflows; hover and cursor feedback; keyboard: Escape closes sheets, arrows move dials and sliders.
- Touch targets never below 44 on any platform.

## 15. Failure states and copy

| When | Kind | Copy |
|---|---|---|
| First scan | skeleton | banner "Sweeping <subnet>/24" body "n of 254 addresses"; three skeleton rows |
| Nothing found | empty | "No response on the local network" / "Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time." + stale-IP note |
| Light unreachable | banner | "One light did not answer" or "<n> lights did not answer" / "<Name> may be switched off at the wall, or the router changed its address." action Rescan |
| Light detail unreachable | banner | "No reply from this light" / "It may be switched off at the wall, or the router changed its address." action Retry |
| Write in flight > 600 ms | toast loading | "Sending to <name>" body "<ip>:38899" |
| Write fails | toast error | "No response after 3 tries" / "<ip> did not answer on port 38899" action Retry |
| Retry fails | toast error | "Still no reply" / "Check the wall switch, then rescan the subnet." |
| Wrong network | banner | "Not on the home network" / "This device is on <current>/24. Lights answer only on <home>/24." action Retry; no network: body "This device has no local network." |
| Command while off network | toast error | "No route to the light" / "This device is not on <home>/24." |
| Retry network still off | toast error | "Still on <current>/24" / "Join the home network, then scan again." |
| Discovery port busy | empty | "Could not open the discovery port" / "Another app is using UDP 38899. Close it, then try again." action Try again |
| Save succeeds | toast loading → success | "Saving <alias>" → "<alias> saved" / "<ip> added to this home" |
| Empty room | empty | "No lights in this room" / "Discover lights on the network, then place them here." action Discover lights |
| Database error | banner error | "Could not read this home's config" / "<reason>" action Try again |

A banner is a condition, a toast is an event; never both for one thing; never toast what the UI already shows.

Copy that must not drift: "No account, no cloud. Lights are reached over UDP on port 38899 on your own network." · "Rooms are stored in this home's config file on this machine. Nothing is uploaded." · "Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time." · "The IP shown in the Philips app can be stale — it talks to the cloud. Your router's DHCP client list is the reliable source." · "A cyan pip marks a dynamic scene. Those accept a speed from 10 to 200." · "Not sure which bulb is which? Tap the flash key on a card and that light blinks for two seconds, then goes back." Voice: second person, sentence case, no "we", no emoji, no exclamation marks. Never show wattage.

## 16. Settings and CLI export

Settings persist in the `settings` table. On macOS, Windows and Linux only, `CliConfigExporter` rewrites `~/.config/wizctl/config.json` (HOME or USERPROFILE, same rule as the CLI) after any change to the active home's lights or rooms, debounced 500 ms, written atomically (temp file then rename): `lights` = ip → `{alias, mac}` for every light in the active home; `groups` = room name → its ips. The existing file is overwritten; it is never read. Mobile never touches the file and hides the CLI rows.

## 17. Platform configuration

- iOS: `NSLocalNetworkUsageDescription` "WizCtl finds and controls WiZ lights on your local network." Background modes none. Minimum iOS per Flutter default.
- macOS: sandbox entitlements `com.apple.security.network.client` and `com.apple.security.network.server` in both Debug and Release; minimum window size 720×560 set in `MainFlutterWindow`.
- Android: `INTERNET` permission; `usesCleartextTraffic` irrelevant (UDP). Minimum window handled by the OS.
- Windows / Linux: minimum window size in the runner; otherwise defaults.
- App display name "WizCtl" on every platform; bundle ids `com.dotstudios.wizctlApp` (Apple) and `com.dotstudios.wizctl_app` (Android).

## 18. Debug switches

Only compiled into debug builds (`kDebugMode`): the Settings block and `FaultInjectingGateway` (wrong network → `OffNetwork` failures and banner; force timeout → every write fails after 1.1 s with `Timeout`; discovery finds nothing → scans return empty). Release builds contain neither the rows nor the decorator.

## 19. Testing

TDD throughout (red, green, refactor). No golden tests; visuals are reviewed on device.

- Package: FakeBulb tests for the stream events, cancellation, `fromState`, retry.
- Domain: `CapabilityRules`, live-state derivation, `ModeSummarizer` (all branches), room aggregates, kelvin colour, emission, blink sequence with a fake gateway and fake clock, refresh/reachability counting, command pipeline (optimistic apply, throttle coalescing, revert, retry, off network), apply rules, discovery sequence ordering.
- Data: in-memory drift tests for every repository and the unique/cascade/restrict rules; `light_states` seeding; `CliConfigExporter` with a temp HOME; `NetworkInfo` subnet parsing.
- Blocs: `bloc_test` for every bloc in §8 with fake repositories and use cases.
- Core: `WizSynth` renders each kind to the expected length with samples in [−1, 1]; `WizBreakpoints` mapping; `WizGrid` column maths; kelvin/hsv maths.
- Widgets: dial drag maps distance to value and fires detents; slider tap and drag; segmented cap position moves on change; toggle drag/flick; toast queue caps at three and resolves loading in place; sheet is bottom on compact and dialog on expanded; shell picks tab bar or rail by width; light card hides the rail for a plug; text-scale 1.3 does not overflow the light card or room card.

## 20. Out of scope

Web, cloud, accounts, schedules/timers, the Rhythm music mode beyond selecting it, firmware updates, bulb reboot/reset, multi-device sync, photography or illustration, a logo mark, golden tests.
