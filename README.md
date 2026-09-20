# wizctl_app

WizCtl is a Flutter app for Philips WiZ lights. No account, no cloud — lights
are reached over UDP on port 38899 on your own network, and everything the app
knows about them lives in a local database on the device. It finds lights by
broadcast and, when an access point filters that, by sweeping the subnet one
address at a time; it groups them into homes and rooms; and it drives power,
brightness, colour temperature, the colour wheel and the 36 scenes, for one
light, one room or the whole home at once. On desktop it also exports the
aliases and rooms it holds to `~/.config/wizctl/config.json`, so the `wizctl`
CLI names the same lights.

The protocol lives in the [`wizctl`](../wizctl) package, which this app depends
on by path (`wizctl: path: ../wizctl` in `pubspec.yaml`). Nothing in `lib/`
speaks UDP directly.

## Platforms

Five targets are configured — Android, iOS, macOS, Linux and Windows — and
there is no web target. Each one's local-network permissions, window minimum
and display name are described under "Platform notes" below.

macOS is the only target built and walked in this run. The iOS, Android, Linux
and Windows runners are configured and pinned by
`test/platform/platform_config_test.dart`, but no toolchain for them was
available, so their native code has not been compiled. The Linux and Windows
minimum-window hooks are the first two things to build where a toolchain
exists.

## Running

The Flutter version is pinned in `.fvmrc` (3.47.2), so prefix commands with
`fvm` if you use FVM and drop it if your `flutter` is already that version.

```bash
fvm flutter pub get
fvm flutter run -d macos
fvm flutter run -d iphone      # or a device id from `fvm flutter devices`
```

A debug build carries three extra things, all behind `kDebugMode` and absent
from release builds: the "PROTOTYPE SWITCHES" block below Settings' privacy
note (wrong network, forced command timeout, discovery finds nothing), the
`FaultInjectingGateway` those switches drive, and that block's last row,
**Widget gallery**, which opens `/gallery` — every kit widget, live, with a
reduced-motion switch of its own.

## Architecture

Five layers. `app` composes the others, `core` knows nothing of the domain,
`domain` knows nothing of Flutter or the database, `data` implements the
domain's interfaces, and `features` draw the screens.

- **`lib/app`** — bootstrap, the dependency graph, `go_router` and the two
  shells (a floating tab bar under 720 px, a rail above it), the app-level
  blocs (homes, settings, network, unreachable, blink, inspector) and the
  toast listener that turns command results into toasts.
- **`lib/core`** — everything with no domain knowledge: the theme tokens, the
  widget kit (see [`lib/core/widgets/README.md`](lib/core/widgets/README.md)),
  the icons, the layout and motion helpers, the feedback synthesiser, and all
  user-facing copy in one file, `lib/core/copy/strings.dart`.
- **`lib/domain`** — entities, repository interfaces, services and use cases.
  Every write goes through a use case, which is where throttling, capability
  rules and optimistic apply live.
- **`lib/data`** — the drift database, the repository implementations, the
  device gateway over `package:wizctl`, the CLI config exporter and the
  network-info reader.
- **`lib/features`** — one folder per screen area, each with `bloc/`, `view/`
  and `widgets/`. A bloc stays pure: no `flutter/widgets.dart`,
  `material.dart` or `cupertino.dart`, no `flutter_bloc`, no `go_router`, no
  `lib/data` and no widget kit, and, by convention, never another bloc.
- **Layering is a source scan.** `test/features/layering_test.dart` reads every
  import under `lib` — relative ones resolved to their real path — and fails on
  any of three: a bloc importing widgets, `flutter_bloc`, `go_router`,
  `lib/data` or the kit; anything in `lib/core` importing `lib/features` or
  `lib/app`; and anything in `lib/features` importing `lib/app/router*` or
  `lib/app/shell/`. A screen navigates through `AppRoutes` and
  `lib/app/navigation.dart`; the shells compose the features, never the other
  way round.
- **One-shot effects** are a `notice` field on a bloc's state, cleared by a
  `…NoticeCleared` event once the view has acted on it; blocs never call the
  toast controller or the router themselves.

The design this implements is
`docs/superpowers/specs/2026-09-08-wizctl-app-design.md`, whose last section
records where the shipped app departs from the sections above it.

## Fonts

The app bundles four faces.

- **Big Shoulders Display** (display: headings, titles, readouts), **Hanken
  Grotesk** (UI) and **JetBrains Mono** (numerals and addresses) are under the
  [SIL Open Font License 1.1](https://openfontlicense.org). The licence texts
  ship as assets (`assets/fonts/OFL-*.txt`) and are registered with
  `LicenseRegistry` at start, so they appear on the app's licence page. The
  Big Shoulders files are static instances of Google Fonts' variable font at
  weights 600–900.
- **Neumatic Compressed** (the 64 px hero only, ExtraBold) is a commercial
  face. **To confirm before any store build:** the project owner must check
  that the licence held for it covers embedding in a distributed application
  on all five targets — Android, iOS, macOS, Linux and Windows — and obtain
  an app-embedding licence if it does not. Nothing here asserts what that
  licence permits.

## Platform notes

The app talks to the lights over UDP on the local network, and each platform
asks for that in its own way (spec §17). `test/platform/platform_config_test.dart`
reads the runner files and fails if any of this drifts.

- **iOS** declares `NSLocalNetworkUsageDescription` — "WizCtl finds and
  controls WiZ lights on your local network." — so the system prompt explains
  itself the first time discovery runs. No background modes: the app only
  talks to lights while it is on screen. The feedback clicks run through an
  ambient audio session (`lib/core/feedback/audio_session_config.dart`), so
  they mix with whatever is playing and go quiet with the mute switch.
- **macOS** is sandboxed, so both `DebugProfile.entitlements` and
  `Release.entitlements` carry `com.apple.security.network.client` and
  `com.apple.security.network.server`. Without the server entitlement the
  sandbox drops the replies the lights send back, and discovery finds
  nothing. It also declares `NSLocalNetworkUsageDescription` — the same
  sentence iOS uses — because macOS 15 gates local-network traffic behind the
  same privacy control: without the key, a denied or never-requested
  permission fails every send with "No route to host" (errno 65) instead of a
  timeout.
- **Android** asks for `INTERNET`. Nothing else: the traffic is UDP, so
  `usesCleartextTraffic` does not apply. **Caveat:** Android may drop the
  broadcast replies discovery listens for unless the app holds a
  `WifiManager.MulticastLock`, which is a platform-channel addition this app
  does not yet make. If broadcast discovery comes back empty on Android while
  a subnet scan finds the lights, the missing lock is the first suspect.
- **Desktop** (macOS, Windows, Linux) refuses to shrink below **720×560**,
  the narrowest window the medium layout fits in.
  `lib/core/platform/window_limits.dart` owns the two numbers; the three
  runners repeat them in Swift, C++ and C, each with a comment naming that
  file.

## Testing

```bash
fvm flutter analyze --fatal-infos
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter test
```

**734 tests**, all offline: no test reaches a real light or the LAN. The one
that exercises the device gateway for real answers it with `FakeBulb`, a
loopback UDP socket in `test/support/fake_bulb.dart`; everything else stops at a
fake. Bloc tests drive real use cases over the fakes in `test/support`
(`FakeGateway`, the fake repositories, `FakeClock`, `SequenceIds`); screen tests
pump the screen inside `wizTestApp` with real blocs over the `SeedHome` fixture.
There are no golden tests — visuals are reviewed on a device.

Conventions the harness expects, learned the hard way:

- Pump **twice** after every `go` or `push`: once for the route's page, once for
  the lazily created bloc's first emission. `settle(tester)` in
  `test/support/router_harness.dart` is that pair, bounded at one screen fade
  with room for a load-in stagger; never `pumpAndSettle`, which with a
  breathing card or a poll timer never returns.
- Count navigations on `router.routeInformationProvider`, never on the
  delegate — the delegate coalesces two identical `go`s in one frame.
- Reset flutter_test's outbound mock handlers in a `tearDown`; 3.47.2 does not
  clear them for you.
- Build and dispose an `AppScope` or a route bloc **inside** the `testWidgets`
  body, and do not await `Bloc.close()`. A bloc built in `setUp` runs its
  handlers in the real zone and never sees the body's events.
- `pumpRouted(size:)` sets the surface itself, not just the `MediaQuery`. Phone
  screens are tested at 390×844; a taller surface at the same width is allowed
  when a lazy panel or an out-of-reach key would otherwise never be built.
- `currentLocation(router)` reports pushed and shell-branch routes, so it can be
  asserted after a `context.push`.
- Reduced-motion app tests wrap the router with `reducedMotion(...)` through
  `pumpAppRouter(wrap:)`: the switch is read below `MaterialApp`, so a wrapper
  above it would not be seen.
- Any test that builds `AppDependencies` sets
  `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true`.
- A test that measures **text width** — an overflow check, a fit — loads the
  real face first (`FontLoader` over the `assets/fonts` asset, as
  `settings_screen_test.dart` does). `flutter_test`'s fallback font draws every
  glyph as a square of the font size, so widths measured against it are roughly
  double and mean nothing.

One limit worth knowing: `reducedMotion(...)` overrides `MediaQuery` only, so a
widget test never sees the 5 % duration scaling the platform flag applies to
every non-repeating `AnimationController`. That half of the reduced-motion
policy can only be checked on a device.
