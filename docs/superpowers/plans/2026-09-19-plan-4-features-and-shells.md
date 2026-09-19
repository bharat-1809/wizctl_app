# Plan 4: WizCtl Features and Shells Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the kit (Plan 2) and the logic layer (Plan 3) into the shipping app: one composition root, the blocs, every screen and sheet of the phone prototype, the desktop shell with its rail, grid and inspector, the go_router shells that survive a resize, the platform configuration, and the three items Plan 2's review left for this plan.

**Architecture:** Feature-first clean architecture (spec §7). `lib/app` is the composition root, the router, the shells and the app-scope blocs; `lib/features/<name>/{bloc,view,widgets}` holds each feature. Blocs subscribe to repository and store streams and call use cases; they never touch the gateway, another bloc or a widget. Screens compose kit widgets and read blocs; navigation is `go_router`; one-shot effects (toasts, navigation after a write) travel as a `notice` field on bloc state consumed by a `BlocListener`. Sizes come from tokens or the parent, colours from `context.wiz.colors`, copy from `Strings`.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13, `flutter_bloc` 9.1, `bloc` 9.2, `go_router` 18.0, `equatable`, `package_info_plus` 10.2, `audio_session` 0.2 (new, iOS only), `wizctl` 1.1.0. Tests with `flutter_test`, `bloc_test` 10, `fake_async`; hand-written fakes from `test/support`.

**Spec:** `/Users/bharat/Bharat/github/wizctl_app/docs/superpowers/specs/2026-09-08-wizctl-app-design.md` §7 to §10, §12 (additions), §14 to §19. The prototypes in `design/reference/` are the source for values the spec does not spell out; where the two prototypes disagree the spec's wording wins, and where the spec is silent the mobile prototype wins on compact widths and the desktop prototype on the others.

## Decisions taken with the user on 2026-09-19

- Plan 2's review leftovers are all in scope: `audio_session` for the iOS ambient category (Task 22), the accessibility batch and the kit README (Task 23).
- The debug gallery stays reachable through a "Widget gallery" row under PROTOTYPE SWITCHES in Settings, compiled out of release builds like the switches (Task 18), at `/gallery` (Task 19).
- The Xcode signing-team change is committed as the branch's first commit (done: `b652dcf`).
- One on-device review at the end of the plan; no mid-plan checkpoint.

## Global Constraints

- Project root `/Users/bharat/Bharat/github/wizctl_app`, branch `sharma/app-features` off the merged `main` (`ad2fb43`). Plans 2 and 3 have landed; every API named in this plan exists on `main` unless the task says it creates it.
- `flutter analyze --fatal-infos`, `dart format --output=none --set-exit-if-changed lib test` and `flutter test` must be clean after every task. `dart run build_runner build --delete-conflicting-outputs` after changing anything drift reads (no task here does).
- Lints as configured: `flutter_lints` plus `strict-casts`, `strict-inference`, `strict-raw-types`. `Color.withValues(alpha:)`, never `withOpacity`.
- No hard-coded sizes in widgets: every dimension comes from `context.wiz.space`, `context.wiz.typography`, a kit widget's own named constant, a widget parameter or the parent's constraints. Screen-specific geometry the prototype fixes (a dial size, a wheel size, a grid minimum) lives as a named `static const` at the top of that screen's file with a one-line comment naming its source. Colours only from `context.wiz.colors`; durations and curves only from `context.wiz.motion`; faces only through `context.wiz.typography`.
- Every user-facing string lives in `lib/core/copy/strings.dart` (`Strings`): constants for fixed lines, static methods for templated ones; sentence case, second person, no "we", no emoji, no exclamation marks. `strings.dart` is exempt from the 300-line guideline; every other file stays under roughly 300 lines and holds one widget or one class (a bloc's event and state files are their own classes).
- `lib/features/**/bloc/*.dart` and `lib/app/blocs/*.dart` import only `package:bloc`, `package:equatable`, `package:flutter/foundation.dart` (for `ValueListenable`), `package:wizctl`, `dart:async` and the domain; never `package:flutter/widgets.dart`, `material.dart`, `flutter_bloc`, `go_router`, the data layer or `lib/core/widgets`. A source-scan test enforces this (Task 3).
- Blocs never call `ToastController`, `GoRouter` or another bloc. One-shot effects are a `notice` field on the state, cleared by a `…NoticeCleared` event after the listener acts.
- The active home reaches a route bloc as `settings.watch().map((s) => s.activeHomeId).distinct()`; nothing holds a `HomesBloc` reference except the router's redirect and the shells.
- Streams are combined with `combineLatest2/3/4` from `lib/core/util/latest.dart` (Task 2); repository and store streams are subscribed fresh per bloc (`LiveStateStore.watchAll()` returns a new single-subscription stream per call; never re-listen a stored one).
- Every write goes through a use case; dials and rails call the use case on every `onChanged` (the use cases carry a throttle key) and again on `onChangeEnd` so the final value always lands. Colour from the wheel does the same once Task 12 gives `ApplyColour` its key.
- Every screen that shows lights registers a `PollScope` with `SyncCoordinator` while it is on show and disposes it in `close()`; `RunDiscovery` streams are bracketed by `sync.pauseForDiscovery()` and `sync.resumeAfterDiscovery()`.
- Copy in code matches the spec verbatim; the copy table in §10 and §15 is the authority, the prototype extraction is the tie-break.
- Tests: bloc tests use `blocTest` with the real use cases over `test/support` fakes (`FakeGateway`, the fake repositories, `FakeClock`, `SequenceIds`); view tests pump the screen inside `wizTestApp` with real blocs over the `SeedHome` fixture (Task 2) and, when navigation matters, inside `pumpRouted` (Task 2). No `mocktail` mocks of use cases: a use case over a fake gateway is cheaper to read than a mock of it.
- Commit after every task. No `Co-Authored-By`, `Claude-Session` or "Generated with" lines in any commit message or PR body.

---

## File structure

Created by this plan (`lib/`), by task:

```
 1  lib/app/bootstrap.dart (rewritten)         AppServices { feedback, toasts, deps, homes, settings }, bootstrap()
 2  lib/app/routes.dart                        AppRoutes path constants
    lib/core/util/latest.dart                  combineLatest2/3/4
    lib/app/command_toasts.dart                CommandToastListener: pipeline.reports → toasts
 3  lib/app/blocs/homes_bloc.dart, homes_event.dart, homes_state.dart, settings_cubit.dart, settings_state.dart
 4  lib/app/blocs/network_cubit.dart, network_state.dart, blink_cubit.dart, blink_state.dart, inspector_cubit.dart
    lib/app/widgets/off_network_banner.dart, blink_key.dart
 5  lib/features/home/bloc/home_screen_bloc.dart, home_screen_event.dart, home_screen_state.dart
 6  lib/app/widgets/screen_scroll.dart, field_label.dart;  lib/core/widgets/wiz_pull_to_refresh.dart
    lib/features/home/view/home_screen.dart
    lib/features/home/widgets/all_lights_panel.dart, unreachable_line.dart, homes_sheet.dart, homes_notice_listener.dart
 7  lib/features/rooms/bloc/rooms_list_bloc.dart, rooms_list_event.dart, rooms_list_state.dart
    lib/features/rooms/view/rooms_screen.dart
    lib/features/rooms/widgets/glyph_picker.dart, room_form.dart, add_room_sheet.dart, room_actions_sheet.dart, rooms_notice_listener.dart
 8  lib/features/modes/bloc/light_modes_bloc.dart, light_modes_event.dart, light_modes_state.dart
 9  lib/features/modes/widgets/modes_layout.dart, modes_body.dart, colour_tab.dart, scenes_tab.dart, swatch_row.dart, target_sheet.dart, modes_notice_listener.dart
    lib/features/modes/view/modes_sheet.dart, modes_screen.dart
10  lib/features/rooms/bloc/room_bloc.dart, room_event.dart, room_state.dart
11  lib/app/widgets/dual_dials.dart, mode_art.dart;  lib/features/modes/modes_bloc_factory.dart
    lib/features/rooms/view/room_screen.dart;  lib/features/rooms/widgets/whole_room_panel.dart
12  lib/features/lights/bloc/light_bloc.dart, light_event.dart, light_state.dart
13  lib/app/widgets/emission.dart, fixture_kind.dart
    lib/features/lights/view/light_screen.dart
    lib/features/lights/widgets/light_hero.dart, light_stat_tiles.dart, light_dials_panel.dart, light_modes_panel.dart,
        device_panel.dart, fixture_sheet.dart, rename_light_sheet.dart, forget_light_sheet.dart, light_notice_listener.dart
14  lib/features/discovery/bloc/discovery_bloc.dart, discovery_event.dart, discovery_state.dart
15  lib/features/discovery/view/discovery_screen.dart
    lib/features/discovery/widgets/skeleton_rows.dart, scanning_view.dart, discovery_empty.dart, found_row.dart,
        save_light_sheet.dart, discovery_notice_listener.dart
16  lib/features/onboarding/bloc/onboarding_bloc.dart, onboarding_event.dart, onboarding_state.dart
17  lib/features/onboarding/view/onboarding_screen.dart, name_home_step.dart, discovering_step.dart, name_lights_step.dart
    lib/features/onboarding/widgets/radar.dart, keep_row.dart, assign_card.dart, onboarding_notice_listener.dart
18  lib/app/blocs/unreachable_cubit.dart;  lib/app/widgets/unreachable_banner.dart
    lib/features/settings/view/settings_screen.dart
    lib/features/settings/widgets/settings_rows.dart, prototype_switches.dart, rename_home_sheet.dart, about_caption.dart
19  lib/app/shell/shell_branch.dart, app_shell.dart, compact_shell.dart;  lib/app/shell_deps.dart
    lib/app/router.dart, router_pages.dart, lifecycle.dart, gallery_page.dart;  lib/app/widgets/blink_notice_listener.dart
    lib/app/app.dart (rewritten)
20  lib/app/shell/desktop_shell.dart, desktop_rail.dart, rail_item.dart
    lib/features/home/view/home_page.dart;  lib/features/rooms/view/room_page.dart
    lib/features/desktop/view/grid_screen.dart;  lib/features/desktop/widgets/grid_stats.dart, light_grid.dart, grid_room_panel.dart
21  lib/features/desktop/view/inspector_panel.dart, inspector_dialog.dart
    lib/features/desktop/widgets/inspector_hero.dart, inspector_facts.dart;  lib/features/lights/view/light_page.dart
22  lib/core/platform/window_limits.dart;  lib/core/feedback/audio_session_config.dart
23  lib/core/widgets/README.md
```

Modified along the way: `lib/core/copy/strings.dart` (every task that adds copy), `lib/domain/usecases/apply_colour.dart` (Task 8: throttle key), `lib/domain/services/room_aggregates.dart` (Task 10: `Equatable`), `lib/domain/usecases/run_discovery.dart` (Task 14: optional `homeId`), `lib/features/home/bloc/*` (Task 20: a per-light power event), `lib/core/feedback/feedback_kind.dart` and `lib/core/motion/reduced_motion.dart` (Task 23: docs), `lib/core/feedback/soloud_player.dart`, `pubspec.yaml` and the five platform folders (Task 22), `lib/features/gallery/gallery_wordmark.dart`, the spec and `README.md` (Task 24). `lib/main.dart` does not change.

Test support added: `test/support/seed.dart` (the `SeedHome` fixture), `test/support/router_harness.dart` (`pumpRouted`, `currentLocation`), `test/support/bloc_helpers.dart`, `test/support/app_scope.dart` (the app-scope blocs and services over the fakes, extended by Tasks 9, 11, 15, 18 and 19). Tests mirror `lib/`.

## Shared conventions the tasks rely on

**Bloc shape.** `class XBloc extends Bloc<XEvent, XState>`; events are a `sealed class XEvent extends Equatable` with `final class` members and `const` constructors; the state is an `Equatable` with `copyWith` and a `status` where loading matters. Subscriptions are opened in the handler of a `…Subscribed` event with `emit.forEach` (one stream) or `emit.forEach` over a `combineLatest…` (several); `close()` disposes the poll scope. Cubits follow the same file split (`x_cubit.dart`, `x_state.dart`).

**Notices.** `XState.notice` is a nullable sealed value (`XNotice`), set by a handler after a use case returns and cleared by the `XNoticeCleared` event. The view's `BlocListener` has `listenWhen: (a, b) => b.notice != null && a.notice != b.notice`, acts (toast, navigate), then adds `XNoticeCleared()`.

**Active home in a route bloc.** `activeHomeId(SettingsRepository settings)` from `test/support/bloc_helpers.dart` is test-only; in `lib` every bloc writes the one-liner `settings.watch().map((s) => s.activeHomeId).distinct()` itself, then `switchMap`-style: the `…Subscribed` handler does

```dart
await emit.forEach(
  settings.watch().map((s) => s.activeHomeId).distinct().asyncExpand(_forHome),
  onData: (data) => data,
);
```

where `_forHome(String? id)` returns the combined stream for that home (or a single empty state when null). `asyncExpand` cancels nothing on its own, so `_forHome` streams end with the outer one; a home switch is rare and the previous inner stream ends when its repositories emit no more, which is acceptable for this app (spec §8 blocs are app- or route-scoped, not per home).

**Toasts from views.** Views push toasts through `context.read<ToastController>()` (provided at the root in Task 19, and by `wizTestApp`'s caller in tests) with copy from `Strings`.

**Navigation.** `context.go(AppRoutes.x)` to switch what is on show inside a branch; `context.push(AppRoutes.light(id))` from a room so Back pops to the room; `context.pop()` for Back when `context.canPop()`, otherwise `context.go` to the screen's natural parent.

**Sizes named per screen.** A screen file starts with its geometry block, e.g.

```dart
/// Room dials, `WizCtl_Mobile.dc.html` `roomDialSize=132`; the desktop
/// grid draws them at 140 (`dialSize=140`).
static const double dialSize = 132;
```

**Tests.** `wizTestApp(child, size:, feedback:)`; `setSurface(tester, size)` when the surface itself must be a width class; `SeedHome()` for data; `pumpRouted` when a tap navigates; `blocTest` for blocs with `wait:` only where a use case awaits a fake. `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true` in any test that builds `AppDependencies`.

---

### Task 1: One composition root

**Files:**
- Modify: `lib/app/bootstrap.dart`
- Modify: `test/app/bootstrap_test.dart`

**Interfaces:**
- Consumes: `AppDependencies.build({database, gateway, networkInfo, exportCli, homeDirectory, debugFlags, clock, ids})` and `dispose()` (lib/app/dependencies.dart); `SynthFeedbackService({player, haptics, enabled, onEnabledChanged})`; `SettingsRepository.get()`; `HomeRepository.getAll()`.
- Produces:

```dart
class AppServices {
  final FeedbackService feedback;
  final ToastController toasts;
  final AppDependencies deps;
  final List<Home> homes;        // snapshot at start, for the first-frame redirect
  final AppSettings settings;    // snapshot at start
}
Future<AppServices> bootstrap({AudioPlayerPort? player, HapticMapper? haptics, AppDependencies? dependencies});
```

- [ ] **Step 1: Write the failing test**

Append to `test/app/bootstrap_test.dart` (keep the two existing tests; add the imports `package:drift/drift.dart`, `package:wizctl_app/app/dependencies.dart`, `package:wizctl_app/data/db/app_database.dart`, `package:wizctl_app/domain/entities/entities.dart`, `../support/fakes.dart`, and a `setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);` at the top of `main`):

```dart
  testWidgets('bootstrap folds the dependency graph in and reads its settings', (
    tester,
  ) async {
    var deps = (await tester.runAsync(
      () => AppDependencies.build(
        database: AppDatabase.inMemory(),
        gateway: FakeGateway(),
        networkInfo: FakeNetworkInfo('192.168.1'),
        exportCli: false,
        clock: FakeClock(),
        ids: SequenceIds(),
      ),
    ))!;
    addTearDown(deps.dispose);
    await tester.runAsync(
      () => deps.settings.save(const AppSettings(feedbackEnabled: false)),
    );
    var home = (await tester.runAsync(
      () => deps.createHome('Kaverappa House', subnet: '192.168.1'),
    ))!;

    var player = _FakePlayer();
    var services = (await tester.runAsync(
      () => bootstrap(
        player: player,
        haptics: _recordingHaptics([]),
        dependencies: deps,
      ),
    ))!;
    addTearDown(services.toasts.dispose);

    expect(identical(services.deps, deps), isTrue,
        reason: 'an injected graph is used as is, never rebuilt');
    expect(services.feedback.enabled, isFalse,
        reason: 'the persisted toggle is honoured from the first click');
    expect(services.settings.feedbackEnabled, isFalse);
    expect(services.settings.activeHomeId, home.id);
    expect(services.homes.map((h) => h.id), [home.id]);
    // A disabled layer still renders its cues, so a later enable is instant.
    expect(player.loaded, FeedbackKind.values.map((k) => k.name));
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/app/bootstrap_test.dart`
Expected: FAIL, "No named parameter with the name 'dependencies'".

- [ ] **Step 3: Fold the graph into bootstrap**

Replace `lib/app/bootstrap.dart` with:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/feedback/audio_player_port.dart';
import '../core/feedback/feedback_service.dart';
import '../core/feedback/haptic_mapper.dart';
import '../core/feedback/soloud_player.dart';
import '../core/feedback/synth_feedback_service.dart';
import '../core/theme/wiz_textures.dart';
import '../core/widgets/toast_controller.dart';
import '../domain/entities/entities.dart';
import 'dependencies.dart';

/// Everything the widget tree needs that is built once at start: the
/// feedback layer and toast queue (Plan 2), the logic graph (Plan 3), and a
/// snapshot of the homes and settings so the first frame can route without
/// a round trip to the database (spec §9, the `/setup` redirect).
class AppServices {
  final FeedbackService feedback;
  final ToastController toasts;
  final AppDependencies deps;
  final List<Home> homes;
  final AppSettings settings;

  const AppServices({
    required this.feedback,
    required this.toasts,
    required this.deps,
    required this.homes,
    required this.settings,
  });
}

/// The open licences the app ships, by the family each covers. All three
/// faces are under the SIL Open Font License, whose terms require the
/// licence to travel with the software, so the text is bundled and handed to
/// the registry rather than merely linked.
///
/// The fourth face, Neumatic Compressed, is a commercial one and carries no
/// licence file here; see the README.
const Map<String, String> _fontLicences = {
  'Big Shoulders Display': 'assets/fonts/OFL-BigShouldersDisplay.txt',
  'Hanken Grotesk': 'assets/fonts/OFL-HankenGrotesk.txt',
  'JetBrains Mono': 'assets/fonts/OFL-JetBrainsMono.txt',
};

/// Adds the bundled font licences to the registry the standard
/// `LicensePage` reads, so they are listed beside the packages'.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (var entry in _fontLicences.entries) {
      yield LicenseEntryWithLineBreaks([
        entry.key,
      ], await rootBundle.loadString(entry.value));
    }
  });
}

/// The pixel ratio the grain tile is rendered at. Read from the implicit
/// view, which is the only one that exists before `runApp`; a headless
/// embedder has none, and 1 is then the honest answer.
double _devicePixelRatio() =>
    WidgetsBinding.instance.platformDispatcher.implicitView?.devicePixelRatio ??
    1;

/// Binding, textures at the real pixel ratio, the logic graph, then the
/// feedback layer with the persisted toggle already applied.
///
/// The graph comes before the feedback layer on purpose: `feedbackEnabled`
/// lives in the settings table, and a click played at the wrong setting on
/// the first screen is exactly the kind of thing the user notices.
///
/// The grain tile is awaited *before* `runApp`: `WizTextures.grainPaint`
/// returns null until it exists and the painters that read it simply paint
/// nothing, without ever asking again — a tile arriving a frame later would
/// leave the chassis flat until something else repainted it.
///
/// [player], [haptics] and [dependencies] default to the real ones; a test
/// injects fakes and an in-memory graph so that no audio engine is started
/// and no database file is written. The feedback defaults are constructed
/// *inside* the guard on purpose: [SynthFeedbackService.init] never throws
/// (it reports a dead engine and stays silent-but-haptic), so the only
/// failure this catch can still see is a synchronous one from construction —
/// a platform with the SoLoud plugin missing, an embedder with no audio
/// device at all. That is exactly the case where the app must run silently
/// rather than not at all.
Future<AppServices> bootstrap({
  AudioPlayerPort? player,
  HapticMapper? haptics,
  AppDependencies? dependencies,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();

  // Guarded on its own: a texture that will not render is a flat chassis,
  // not a dead app, and an unhandled throw here would take `main` down before
  // a single frame was drawn. `WizTextures.grainPaint` returns null until a
  // tile exists and every painter that reads it treats null as "paint no
  // grain", so carrying on is safe.
  //
  // Untested: `WizTextures.load` is a static with no injection point, so
  // there is no way to make it fail from a test without reaching into the
  // kit. The branch is one report-and-continue.
  try {
    await WizTextures.load(devicePixelRatio: _devicePixelRatio());
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'wizctl bootstrap',
        context: ErrorDescription('rendering the grain texture'),
      ),
    );
  }

  // Not guarded: a graph that cannot be built (a database that will not
  // open) is a dead app, and the error must reach the console rather than a
  // silent placeholder screen.
  var deps = dependencies ?? await AppDependencies.build();
  var settings = await deps.settings.get();
  var homes = await deps.homes.getAll();

  FeedbackService feedback;
  try {
    var synth = SynthFeedbackService(
      player: player ?? SoLoudPlayer(),
      haptics: haptics ?? HapticMapper(),
      enabled: settings.feedbackEnabled,
    );
    await synth.init();
    feedback = synth;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'wizctl bootstrap',
        context: ErrorDescription('starting the feedback layer'),
      ),
    );
    feedback = NoopFeedbackService();
  }
  return AppServices(
    feedback: feedback,
    toasts: ToastController(feedback: feedback),
    deps: deps,
    homes: homes,
    settings: settings,
  );
}
```

The two existing tests call `bootstrap(player:, haptics:)` without a graph and would now build a real `AppDependencies` against a file database. Change both to pass `dependencies:` built the same way as the new test (extract a `_inMemoryDeps(tester)` helper at the top of the file that builds it inside `tester.runAsync` and registers `deps.dispose` as a tear-down), and keep every existing assertion.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app/`
Expected: PASS (bootstrap: 3 tests; dependencies: 3 tests).

- [ ] **Step 5: Gates and commit**

Run: `flutter analyze --fatal-infos && dart format --output=none --set-exit-if-changed lib test && flutter test`
Expected: clean; the whole suite passes (402 before this task, 403 after).

```bash
git add lib/app/bootstrap.dart test/app/bootstrap_test.dart
git commit -m "feat(app): one composition root for the kit and the logic graph"
```

---

### Task 2: Shared plumbing: routes, combineLatest, command toasts, test fixtures

**Files:**
- Create: `lib/app/routes.dart`, `lib/core/util/latest.dart`, `lib/app/command_toasts.dart`
- Create: `test/core/util/latest_test.dart`, `test/app/command_toasts_test.dart`, `test/support/seed.dart`, `test/support/router_harness.dart`, `test/support/bloc_helpers.dart`
- Modify: `lib/core/copy/strings.dart`, `test/core/copy/strings_test.dart`

**Interfaces:**
- Consumes: `DeviceCommandPipeline.reports` / `retry(id)`; `CommandPending(id, lightIds, description)`, `CommandSucceeded(id)`, `CommandFailed(id, lightId, lightName, ip, failure)`, `CommandRetryFailed(id, lightId, lightName)`; `OffNetworkFailure(homeSubnet, currentSubnet)`; `ToastController.push/pushAfter/update/dismiss`; `LightRepository.get`; `wizPort` from `package:wizctl`.
- Produces:

```dart
// lib/app/routes.dart
class AppRoutes {
  static const String setup = '/setup', home = '/home', rooms = '/rooms', modes = '/modes',
      settings = '/settings', discover = '/discover', gallery = '/gallery';
  static String room(String roomId) => '/rooms/$roomId';
  static String light(String lightId) => '/lights/$lightId';
  static const String roomPattern = '/rooms/:roomId', lightPattern = '/lights/:lightId';
  static const String roomParam = 'roomId', lightParam = 'lightId';
}
// lib/core/util/latest.dart
Stream<(A, B)> combineLatest2<A, B>(Stream<A> a, Stream<B> b);
Stream<(A, B, C)> combineLatest3<A, B, C>(Stream<A> a, Stream<B> b, Stream<C> c);
Stream<(A, B, C, D)> combineLatest4<A, B, C, D>(Stream<A> a, Stream<B> b, Stream<C> c, Stream<D> d);
// lib/app/command_toasts.dart
class CommandToastListener {
  CommandToastListener({required ToastController toasts, required DeviceCommandPipeline pipeline,
      required LightRepository lights, required Duration delay});
  void start();
  Future<void> dispose();
}
// test/support/seed.dart
class SeedHome { homes, rooms, lights, settings, store; home, living, bedroom, kitchen; dome, floor, strip, bedside, hall, counter; }
// test/support/router_harness.dart
Future<GoRouter> pumpRouted(WidgetTester tester, Widget home, {List<String> targets, Size size, FeedbackService? feedback, Widget Function(Widget child)? wrap});
// Strings additions
noResponseAfterTries, stillNoReply, checkWallSwitch, noLocalNetwork; udpAddress(ip), didNotAnswer(ip), retrying(name), notOnHomeNetwork(subnet)
```

- [ ] **Step 1: Write the failing tests**

`test/core/util/latest_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/util/latest.dart';

void main() {
  test('emits once every source has a value, then on every change', () async {
    var a = StreamController<int>();
    var b = StreamController<String>();
    var seen = <(int, String)>[];
    var sub = combineLatest2(a.stream, b.stream).listen(seen.add);

    a.add(1);
    await pumpEventQueue();
    expect(seen, isEmpty, reason: 'b has no value yet');
    b.add('x');
    a.add(2);
    b.add('y');
    await pumpEventQueue();
    expect(seen, [(1, 'x'), (2, 'x'), (2, 'y')]);

    await sub.cancel();
    await a.close();
    await b.close();
  });

  test('three and four sources', () async {
    var a = Stream.value(1);
    var b = Stream.value('b');
    var c = Stream.value(true);
    var d = Stream.value(2.5);
    expect(await combineLatest3(a, b, c).first, (1, 'b', true));
    expect(await combineLatest4(a, b, c, d).first, (1, 'b', true, 2.5));
  });

  test('cancelling cancels every source and errors pass through', () async {
    var cancelled = 0;
    Stream<int> source() {
      late StreamController<int> controller;
      controller = StreamController<int>(
        onListen: () => controller.add(1),
        onCancel: () => cancelled++,
      );
      return controller.stream;
    }

    var sub = combineLatest2(source(), source()).listen((_) {});
    await pumpEventQueue();
    await sub.cancel();
    expect(cancelled, 2);

    var failing = StreamController<int>();
    var errors = <Object>[];
    var sub2 = combineLatest2(failing.stream, Stream.value(0)).listen(
      (_) {},
      onError: errors.add,
    );
    failing.addError(StateError('boom'));
    await pumpEventQueue();
    expect(errors.single, isA<StateError>());
    await sub2.cancel();
    await failing.close();
  });

  test('closes when every source is done', () async {
    var done = false;
    combineLatest2(Stream.value(1), Stream.value(2)).listen(
      (_) {},
      onDone: () => done = true,
    );
    await pumpEventQueue();
    expect(done, isTrue);
  });
}
```

`test/app/command_toasts_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/command_toasts.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../support/fakes.dart';

const _delay = Duration(milliseconds: 600);

Light _light(String id, String ip) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: 'Bedside bulb $id',
  ip: ip,
  mac: id,
  bulbClass: BulbClass.rgb,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

CommandItem _item(Light light) => CommandItem(
  light: light,
  signal: const ControlSignal(state: true),
  patch: (s) => s.copyWith(isOn: true),
);

/// A whole pipeline over the fakes, so the listener is tested against the
/// reports the real one emits rather than a hand-written sequence.
class _Rig {
  final gateway = FakeGateway();
  final store = LiveStateStore();
  final lights = FakeLightRepository();
  final toasts = ToastController();
  late final NetworkMonitor network;
  late final DeviceCommandPipeline pipeline;
  late final CommandToastListener listener;
  String? homeSubnet = '192.168.1';

  _Rig({String? current = '192.168.1'}) {
    network = NetworkMonitor(FakeNetworkInfo(current));
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: store,
      network: network,
      homeSubnet: () async => homeSubnet,
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    listener = CommandToastListener(
      toasts: toasts,
      pipeline: pipeline,
      lights: lights,
      delay: _delay,
    );
  }

  void dispose() {
    listener.dispose();
    pipeline.dispose();
    toasts.dispose();
    store.dispose();
  }
}

void main() {
  test('a write that finishes quickly never shows a toast', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      expect(rig.toasts.toasts, isEmpty);
      async.elapse(_delay * 2);
      expect(rig.toasts.toasts, isEmpty, reason: 'success dismissed the armed toast');
      rig.dispose();
    });
  });

  test('a slow single-light write shows the loading toast with its address', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.sendLatency = const Duration(seconds: 2);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.elapse(_delay - const Duration(milliseconds: 1));
      expect(rig.toasts.toasts, isEmpty);
      async.elapse(const Duration(milliseconds: 2));
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.loading);
      expect(toast.title, 'Sending to Bedside bulb a');
      expect(toast.body, '192.168.1.115:38899');
      async.elapse(const Duration(seconds: 2));
      expect(rig.toasts.toasts, isEmpty, reason: 'resolved in place: gone');
      rig.dispose();
    });
  });

  test('a failed write resolves the toast to the error with Retry', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.error);
      expect(toast.title, Strings.noResponseAfterTries);
      expect(toast.body, '192.168.1.115 did not answer on port 38899');
      expect(toast.actionLabel, Strings.retry);

      // Retry: the loading toast is pushed synchronously by the action, so
      // it is observable before the microtasks that finish the retry run.
      toast.onAction!();
      expect(rig.toasts.toasts.single.tone, WizToastTone.loading);
      expect(rig.toasts.toasts.single.title, 'Retrying Bedside bulb a');
      // Still failing → "Still no reply".
      async.flushMicrotasks();
      var again = rig.toasts.toasts.single;
      expect(again.tone, WizToastTone.error);
      expect(again.title, Strings.stillNoReply);
      expect(again.body, Strings.checkWallSwitch);
      expect(again.actionLabel, isNull);
      rig.dispose();
    });
  });

  test('a retry that succeeds takes the toast away', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      rig.gateway.failing.remove(a.ip);
      rig.toasts.toasts.single.onAction!();
      async.flushMicrotasks();
      async.flushMicrotasks();
      expect(rig.toasts.toasts, isEmpty);
      rig.dispose();
    });
  });

  test('every failed light of a batch gets its own error toast', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      var b = _light('b', '192.168.1.118');
      rig.lights.seed([a, b]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      rig.gateway.failing[b.ip] = const UnreachableFailure('192.168.1.118', 'x');
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a), _item(b)])));
      async.flushMicrotasks();
      expect(rig.toasts.toasts.map((t) => t.body), [
        '192.168.1.115 did not answer on port 38899',
        '192.168.1.118 did not answer on port 38899',
      ]);
      async.elapse(_delay * 2);
      expect(rig.toasts.toasts, hasLength(2), reason: 'no loading toast joins them');
      rig.dispose();
    });
  });

  test('off network is one error toast with no retry', () {
    fakeAsync((async) {
      var rig = _Rig(current: '10.0.0');
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.error);
      expect(toast.title, Strings.noRoute);
      expect(toast.body, 'This device is not on 192.168.1.0/24.');
      expect(toast.actionLabel, isNull);
      rig.dispose();
    });
  });
}
```

`test/core/copy/strings_test.dart` already asserts no exclamation marks over `Strings.all`; add:

```dart
  test('templated copy formats addresses and names', () {
    expect(Strings.udpAddress('192.168.1.115'), '192.168.1.115:38899');
    expect(Strings.didNotAnswer('192.168.1.115'), '192.168.1.115 did not answer on port 38899');
    expect(Strings.retrying('Hallway'), 'Retrying Hallway');
    expect(Strings.notOnHomeNetwork('192.168.1'), 'This device is not on 192.168.1.0/24.');
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/util/latest_test.dart test/app/command_toasts_test.dart test/core/copy/strings_test.dart`
Expected: FAIL to compile (missing files and members).

- [ ] **Step 3: Write the routes, the combinator, the copy and the listener**

`lib/app/routes.dart`:

```dart
/// The app's locations (spec §9). Screens navigate with these; only the
/// router knows the patterns.
class AppRoutes {
  AppRoutes._();

  static const String setup = '/setup';
  static const String home = '/home';
  static const String rooms = '/rooms';
  static const String modes = '/modes';
  static const String settings = '/settings';
  static const String discover = '/discover';

  /// Debug builds only (Task 19): the widget gallery behind the Settings row.
  static const String gallery = '/gallery';

  static const String roomParam = 'roomId';
  static const String lightParam = 'lightId';
  static const String roomPattern = '$rooms/:$roomParam';
  static const String lightPattern = '/lights/:$lightParam';

  static String room(String roomId) => '$rooms/$roomId';
  static String light(String lightId) => '/lights/$lightId';
}
```

`lib/core/util/latest.dart`:

```dart
import 'dart:async';

/// The latest value of each source, re-emitted whenever any of them changes,
/// starting once every source has produced one — the `combineLatest` every
/// stream library has. The app takes no such library for three arities.
///
/// Single-subscription. Cancelling cancels every source; an error from any
/// source is forwarded; the result closes when every source has closed.
Stream<(A, B)> combineLatest2<A, B>(Stream<A> a, Stream<B> b) =>
    _combine([a, b]).map((v) => (v[0] as A, v[1] as B));

Stream<(A, B, C)> combineLatest3<A, B, C>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
) => _combine([a, b, c]).map((v) => (v[0] as A, v[1] as B, v[2] as C));

Stream<(A, B, C, D)> combineLatest4<A, B, C, D>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
) => _combine([
  a,
  b,
  c,
  d,
]).map((v) => (v[0] as A, v[1] as B, v[2] as C, v[3] as D));

Stream<List<Object?>> _combine(List<Stream<Object?>> sources) {
  late StreamController<List<Object?>> controller;
  var subscriptions = <StreamSubscription<Object?>>[];
  var latest = List<Object?>.filled(sources.length, null);
  var seen = List<bool>.filled(sources.length, false);
  var done = 0;
  controller = StreamController<List<Object?>>(
    onListen: () {
      for (var i = 0; i < sources.length; i++) {
        subscriptions.add(
          sources[i].listen(
            (value) {
              latest[i] = value;
              seen[i] = true;
              if (seen.every((s) => s)) controller.add(List.of(latest));
            },
            onError: controller.addError,
            onDone: () {
              if (++done == sources.length) controller.close();
            },
          ),
        );
      }
    },
    onPause: () {
      for (var s in subscriptions) {
        s.pause();
      }
    },
    onResume: () {
      for (var s in subscriptions) {
        s.resume();
      }
    },
    onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
  );
  return controller.stream;
}
```

`lib/core/copy/strings.dart`: add these members (and the constants to `all`; methods are covered by the new test):

```dart
  // Command reports (spec §15).
  static const noResponseAfterTries = 'No response after 3 tries';
  static const stillNoReply = 'Still no reply';
  static const checkWallSwitch = 'Check the wall switch, then rescan the subnet.';
  static const noLocalNetwork = 'This device has no local network.';

  /// `<ip>:38899`, the address every device fact and toast body shows.
  static String udpAddress(String ip) => '$ip:$wizPort';
  static String didNotAnswer(String ip) => '$ip did not answer on port $wizPort';
  static String retrying(String name) => 'Retrying $name';
  static String notOnHomeNetwork(String subnet) => 'This device is not on $subnet.0/24.';
```

(`import 'package:wizctl/wizctl.dart' show wizPort;` at the top; the `all` list gains the four constants.)

`lib/app/command_toasts.dart`:

```dart
import 'dart:async';

import '../core/copy/strings.dart';
import '../core/widgets/toast_controller.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/services/device_command_pipeline.dart';

/// Turns the pipeline's reports into toasts (spec §5.11.6, §15).
///
/// A pending batch arms a loading toast that surfaces only if the batch is
/// still in flight after [delay]; success takes it away again (the control
/// already shows the new value, and a toast never says what the UI shows);
/// each failed light resolves it — or pushes its own — as the error with a
/// Retry key; a retry shows "Retrying <name>" until it succeeds or reports
/// "Still no reply". Off network is one error with nothing to retry.
class CommandToastListener {
  final ToastController toasts;
  final DeviceCommandPipeline pipeline;
  final LightRepository lights;

  /// `WizMotion.toastDelay`, handed in because this class has no context.
  final Duration delay;

  /// The toast standing for each report id, once one exists.
  final Map<String, String> _toastFor = {};

  /// Report ids that resolved before their loading toast could be armed
  /// (a fast send completes while the address is still being read).
  final Set<String> _settled = {};

  StreamSubscription<CommandReport>? _subscription;

  CommandToastListener({
    required this.toasts,
    required this.pipeline,
    required this.lights,
    required this.delay,
  });

  void start() {
    _subscription ??= pipeline.reports.listen(_onReport);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onReport(CommandReport report) async {
    switch (report) {
      case CommandPending p:
        await _pending(p);
      case CommandSucceeded s:
        _succeeded(s.id);
      case CommandFailed f:
        _failed(f);
      case CommandRetryFailed f:
        _retryFailed(f);
    }
  }

  Future<void> _pending(CommandPending report) async {
    String? body;
    if (report.lightIds.length == 1) {
      var light = await lights.get(report.lightIds.single);
      if (light != null) body = Strings.udpAddress(light.ip);
    }
    if (_settled.remove(report.id)) return;
    _toastFor[report.id] = toasts.pushAfter(
      delay,
      tone: WizToastTone.loading,
      title: report.description,
      body: body,
    );
  }

  void _succeeded(String id) {
    var toast = _toastFor.remove(id);
    if (toast == null) {
      _settled.add(id);
      return;
    }
    toasts.dismiss(toast);
  }

  void _failed(CommandFailed report) {
    if (report.failure case OffNetworkFailure(:var homeSubnet)) {
      _settled.add(report.id);
      toasts.push(
        tone: WizToastTone.error,
        title: Strings.noRoute,
        body: homeSubnet == null
            ? Strings.noLocalNetwork
            : Strings.notOnHomeNetwork(homeSubnet),
      );
      return;
    }
    var title = Strings.noResponseAfterTries;
    var body = Strings.didNotAnswer(report.ip);
    var pending = _toastFor.remove(report.id);
    void retry() => _retry(report);
    if (pending != null) {
      // Resolved in place: the loading toast becomes the error.
      toasts.update(
        pending,
        tone: WizToastTone.error,
        title: title,
        body: body,
        actionLabel: Strings.retry,
        onAction: retry,
      );
      return;
    }
    _settled.add(report.id);
    toasts.push(
      tone: WizToastTone.error,
      title: title,
      body: body,
      actionLabel: Strings.retry,
      onAction: retry,
    );
  }

  /// A fresh loading toast rather than an update: `copyWith` keeps a field
  /// its argument leaves null, so the Retry key could not be cleared in
  /// place.
  void _retry(CommandFailed report) {
    for (var entry in toasts.toasts) {
      if (entry.onAction != null && entry.title == Strings.noResponseAfterTries &&
          entry.body == Strings.didNotAnswer(report.ip)) {
        toasts.dismiss(entry.id);
      }
    }
    _toastFor[report.id] = toasts.push(
      tone: WizToastTone.loading,
      title: Strings.retrying(report.lightName),
    );
    unawaited(pipeline.retry(report.id));
  }

  void _retryFailed(CommandRetryFailed report) {
    var pending = _toastFor.remove(report.id);
    if (pending != null) {
      toasts.update(
        pending,
        tone: WizToastTone.error,
        title: Strings.stillNoReply,
        body: Strings.checkWallSwitch,
      );
      return;
    }
    toasts.push(
      tone: WizToastTone.error,
      title: Strings.stillNoReply,
      body: Strings.checkWallSwitch,
    );
  }
}
```

`_retry` matches the error toast by its copy rather than by id because `WizToastData` has no reference back to the report; the ids handed out by `push` are kept in `_toastFor` only while a report is unresolved. Dismissing by (title, body) is exact: the body carries the ip.

`test/support/seed.dart` — the prototype's seed home (`WizCtl_Mobile.dc.html` state block; the second home "Studio" too, so home switching has something to switch to). `Home` and `Light` carry a `DateTime`, so the fixture uses `late final` fields rather than `static const`:

```dart
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

import 'fakes.dart';

/// The prototype's home, as fakes: Kaverappa House with its three rooms and
/// six lights (one of them unreachable), plus the Studio to switch to.
/// Names, addresses, classes, fixtures and states are the mobile prototype's
/// seed data (`design/reference/WizCtl_Mobile.dc.html`, state block).
class SeedHome {
  final homes = FakeHomeRepository();
  final rooms = FakeRoomRepository();
  final lights = FakeLightRepository();
  final settings = FakeSettingsRepository();
  final store = LiveStateStore();

  final DateTime added = DateTime(2026, 9, 8, 12);

  late final Home home = Home(
    id: 'h1',
    name: 'Kaverappa House',
    subnet: '192.168.1',
    createdAt: added,
  );
  late final Home studio = Home(
    id: 'h2',
    name: 'Studio',
    createdAt: added,
    sortIndex: 1,
  );

  final Room living = const Room(
    id: 'living',
    homeId: 'h1',
    name: 'Living Room',
    glyph: RoomGlyph.sofa,
  );
  final Room bedroom = const Room(
    id: 'bedroom',
    homeId: 'h1',
    name: 'Bedroom',
    glyph: RoomGlyph.bed,
    sortIndex: 1,
  );
  final Room kitchen = const Room(
    id: 'kitchen',
    homeId: 'h1',
    name: 'Kitchen',
    glyph: RoomGlyph.utensils,
    sortIndex: 2,
  );
  final Room desk = const Room(
    id: 'desk',
    homeId: 'h2',
    name: 'Desk',
    glyph: RoomGlyph.lampDesk,
  );

  late final Light dome = _light('dome', 'living', 'Ceiling dome light',
      '192.168.1.104', 'a8bb50f1c204', BulbClass.rgb, Fixture.dome, 0);
  late final Light floor = _light('floor', 'living', 'Corner floor lamp',
      '192.168.1.107', 'a8bb50f1c8a1', BulbClass.rgb, Fixture.desk, 1);
  late final Light strip = _light('strip', 'living', 'Shelf strip',
      '192.168.1.111', 'a8bb50f2013e', BulbClass.tw, Fixture.strip, 2);
  late final Light bedside = _light('bedside', 'bedroom', 'Bedside bulb',
      '192.168.1.115', 'a8bb50f21177', BulbClass.rgb, Fixture.bulb, 3);
  late final Light hall = _light('hall', 'bedroom', 'Hallway',
      '192.168.1.118', 'a8bb50f22b03', BulbClass.dw, Fixture.dome, 4);
  late final Light counter = _light('counter', 'kitchen', 'Counter downlight',
      '192.168.1.121', 'a8bb50f23940', BulbClass.tw, Fixture.dome, 5);
  late final Light task = _light('task', 'desk', 'Task lamp', '10.0.0.42',
      'a8bb50f30011', BulbClass.tw, Fixture.desk, 0, homeId: 'h2');

  List<Light> get all => [dome, floor, strip, bedside, hall, counter, task];

  SeedHome({bool active = true}) {
    homes.seed([home, studio]);
    rooms.seed([living, bedroom, kitchen, desk]);
    lights.seed(all);
    if (active) {
      settings.save(const AppSettings(activeHomeId: 'h1'));
    }
    store.seed({
      'dome': const LiveState(isOn: true, brightness: 70, kelvin: 2450,
          rgb: Rgb.amber, sceneId: 6, speed: 150, active: ActiveChannel.scene,
          reachable: true, rssi: -52),
      'floor': const LiveState(isOn: true, brightness: 45, kelvin: 2700,
          rgb: Rgb(255, 120, 60), sceneId: 29, speed: 120,
          active: ActiveChannel.colour, reachable: true, rssi: -58),
      'strip': const LiveState(isOn: false, brightness: 60, kelvin: 4000,
          rgb: Rgb.warm, sceneId: 12, speed: 100, active: ActiveChannel.white,
          reachable: true, rssi: -61),
      'bedside': const LiveState(isOn: false, brightness: 30, kelvin: 2200,
          rgb: Rgb(255, 140, 40), sceneId: 10, speed: 90,
          active: ActiveChannel.white, reachable: true, rssi: -66),
      'hall': const LiveState(isOn: false, brightness: 50, kelvin: 2700,
          rgb: Rgb.warm, sceneId: 11, speed: 100, active: ActiveChannel.white,
          reachable: false),
      'counter': const LiveState(isOn: true, brightness: 90, kelvin: 5000,
          rgb: Rgb(242, 246, 255), sceneId: 15, speed: 100,
          active: ActiveChannel.white, reachable: true, rssi: -49),
      'task': const LiveState(isOn: true, brightness: 80, kelvin: 4500,
          rgb: Rgb(255, 244, 230), sceneId: 15, speed: 100,
          active: ActiveChannel.white, reachable: true, rssi: -40),
    });
  }

  Light _light(String id, String roomId, String name, String ip, String mac,
      BulbClass cls, Fixture fixture, int sortIndex, {String homeId = 'h1'}) =>
      Light(
        id: id,
        homeId: homeId,
        roomId: roomId,
        name: name,
        ip: ip,
        mac: mac,
        moduleName: null,
        bulbClass: cls,
        fixture: fixture,
        fwVersion: '1.25.0',
        sortIndex: sortIndex,
        addedAt: added,
      );

  /// A home with nothing in it, for the first run.
  static SeedHome empty() {
    var seed = SeedHome(active: false);
    for (var l in seed.all) {
      seed.lights.delete(l.id);
    }
    for (var r in [seed.living, seed.bedroom, seed.kitchen, seed.desk]) {
      seed.rooms.delete(r.id);
    }
    seed.homes.delete('h1');
    seed.homes.delete('h2');
    return seed;
  }
}
```

Run `dart format` on it; the long `_light(...)` calls above wrap onto several lines.

`test/support/bloc_helpers.dart`:

```dart
import 'package:wizctl_app/domain/repositories/settings_repository.dart';

/// The stream every route bloc derives its home from, for tests that drive
/// a home switch by hand.
Stream<String?> activeHomeId(SettingsRepository settings) =>
    settings.watch().map((s) => s.activeHomeId).distinct();
```

`test/support/router_harness.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';

/// Pumps [home] at `/` inside a `GoRouter` whose other locations are
/// [targets], each showing its own path as text, and returns the router so
/// a test can read where a tap went:
/// `router.routerDelegate.currentConfiguration.uri.toString()`.
///
/// [wrap] installs providers around the whole app (blocs, a toast
/// controller); [size] pins the MediaQuery like `wizTestApp` does.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget home, {
  List<String> targets = const [],
  Size size = const Size(390, 844),
  FeedbackService? feedback,
  Widget Function(Widget child)? wrap,
}) async {
  var router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      for (var t in targets)
        GoRoute(
          path: t,
          builder: (context, state) => Scaffold(
            body: Text(state.uri.toString(), key: const Key('routed-to')),
          ),
        ),
    ],
  );
  addTearDown(router.dispose);
  Widget app = FeedbackScope(
    service: feedback ?? RecordingFeedbackService(),
    child: MaterialApp.router(
      theme: buildWizThemeData(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: WizLayoutScope(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  if (wrap != null) app = wrap(app);
  await tester.pumpWidget(app);
  return router;
}

/// Where the router is now.
String currentLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/util/latest_test.dart test/app/command_toasts_test.dart test/core/copy/`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

Run the three gates. Then:

```bash
git add lib/app/routes.dart lib/core/util/latest.dart lib/app/command_toasts.dart lib/core/copy/strings.dart test/
git commit -m "feat(app): routes, combineLatest, command toasts and the seed fixture"
```

---

### Task 3: HomesBloc and SettingsCubit, and the bloc layering test

**Files:**
- Create: `lib/app/blocs/homes_bloc.dart`, `lib/app/blocs/homes_event.dart`, `lib/app/blocs/homes_state.dart`, `lib/app/blocs/settings_cubit.dart`, `lib/app/blocs/settings_state.dart`
- Test: `test/app/blocs/homes_bloc_test.dart`, `test/app/blocs/settings_cubit_test.dart`, `test/features/layering_test.dart`

**Interfaces:**
- Consumes: `HomeRepository.watchAll/getAll`, `RoomRepository.watchByHome/getByHome`, `LightRepository.watchByHome/getByHome`, `SettingsRepository.watch/get/save`, `CreateHome(name, {subnet})`, `SwitchHome(homeId)`, `RenameHome(id, name)`, `DeleteHome(id)`, `DomainException.message`, `FeedbackService.setEnabled`, `DebugFlagsHolder` (a `ValueNotifier<DebugFlags>`), `combineLatest3`.
- Produces:

```dart
// homes_event.dart
sealed class HomesEvent extends Equatable
final class HomesSubscribed, HomeCreated(String name), HomeSwitched(String homeId),
    HomeRenamed(String homeId, String name), HomeDeleted(String homeId), HomesNoticeCleared
// homes_state.dart
enum HomesStatus { loading, ready }
class HomeSummary extends Equatable { Home home; int roomCount; int lightCount; }
sealed class HomesNotice extends Equatable
final class HomeCreatedNotice(Home home), HomesError(String message)
class HomesState extends Equatable {
  HomesStatus status; List<HomeSummary> homes; String? activeHomeId; HomesNotice? notice;
  Home? get activeHome; bool get hasHome;
  factory HomesState.snapshot(List<Home> homes, AppSettings settings);   // status loading, counts 0
  HomesState copyWith({...; bool clearNotice = false});
}
class HomesBloc extends Bloc<HomesEvent, HomesState> {
  HomesBloc({required HomeRepository homes, required RoomRepository rooms, required LightRepository lights,
      required SettingsRepository settings, required CreateHome createHome, required SwitchHome switchHome,
      required RenameHome renameHome, required DeleteHome deleteHome, HomesState? initial});
}
// settings_state.dart
class SettingsState extends Equatable { bool feedbackEnabled; bool rescanOnLaunch; DebugFlags debugFlags; }
// settings_cubit.dart
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository settings, required FeedbackService feedback,
      required DebugFlagsHolder debugFlags, AppSettings? initial});
  void subscribe();
  Future<void> setFeedback(bool value);
  Future<void> setRescanOnLaunch(bool value);
  void setOffNetwork(bool value); void setForceTimeout(bool value); void setFindNothing(bool value);
}
```

- [ ] **Step 1: Write the failing tests**

`test/features/layering_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Blocs are pure: they may not import widgets, flutter_bloc, the router,
/// the data layer or the kit (plan Global Constraints). Their only Flutter
/// import is `foundation.dart`, for `ValueListenable`.
void main() {
  test('bloc files import no widgets, router, data or kit', () {
    var offenders = <String>[];
    var forbidden = [
      "package:flutter/material.dart",
      "package:flutter/widgets.dart",
      "package:flutter/cupertino.dart",
      "package:flutter_bloc/",
      "package:go_router/",
      "/data/",
      "/core/widgets/",
    ];
    var files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) =>
              f.path.contains('/bloc/') || f.path.contains('lib/app/blocs/'),
        );
    expect(files, isNotEmpty, reason: 'the scan found no bloc files');
    for (var file in files) {
      for (var line in file.readAsLinesSync()) {
        if (!line.startsWith('import ')) continue;
        for (var bad in forbidden) {
          if (line.contains(bad)) offenders.add('${file.path}: $line');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
```

`test/app/blocs/homes_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/homes_bloc.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/blocs/homes_state.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';

void main() {
  late SeedHome seed;

  HomesBloc build() => HomesBloc(
    homes: seed.homes,
    rooms: seed.rooms,
    lights: seed.lights,
    settings: seed.settings,
    createHome: CreateHome(
      homes: seed.homes,
      settings: seed.settings,
      ids: SequenceIds(),
      clock: FakeClock(),
    ),
    switchHome: SwitchHome(settings: seed.settings),
    renameHome: RenameHome(homes: seed.homes),
    deleteHome: DeleteHome(homes: seed.homes, settings: seed.settings),
  );

  setUp(() => seed = SeedHome());

  test('the snapshot state routes before anything is subscribed', () {
    var state = HomesState.snapshot([], AppSettings.defaults);
    expect(state.hasHome, isFalse);
    expect(state.status, HomesStatus.loading);
    var ready = HomesState.snapshot([seed.home], const AppSettings(activeHomeId: 'h1'));
    expect(ready.hasHome, isTrue);
    expect(ready.activeHome, seed.home);
  });

  blocTest<HomesBloc, HomesState>(
    'subscribing lists every home with its counts and the active one',
    build: build,
    act: (bloc) => bloc.add(const HomesSubscribed()),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, HomesStatus.ready);
      expect(s.activeHomeId, 'h1');
      expect(s.activeHome?.name, 'Kaverappa House');
      expect(s.homes.map((h) => h.home.id), ['h1', 'h2']);
      expect(s.homes.first.roomCount, 3);
      expect(s.homes.first.lightCount, 6);
      expect(s.homes.last.roomCount, 1);
      expect(s.homes.last.lightCount, 1);
    },
  );

  blocTest<HomesBloc, HomesState>(
    'the active home\'s counts follow its rooms and lights',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await seed.rooms.insert(const Room(
        id: 'garage', homeId: 'h1', name: 'Garage', glyph: RoomGlyph.trees, sortIndex: 3));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) => expect(bloc.state.homes.first.roomCount, 4),
  );

  blocTest<HomesBloc, HomesState>(
    'creating a home activates it and raises the created notice',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeCreated('Cabin'));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.homes.map((h) => h.home.name), contains('Cabin'));
      expect(s.activeHome?.name, 'Cabin');
      expect(s.notice, isA<HomeCreatedNotice>());
      expect((s.notice! as HomeCreatedNotice).home.name, 'Cabin');
    },
  );

  blocTest<HomesBloc, HomesState>(
    'an empty name is an error notice, not a home',
    build: build,
    act: (bloc) => bloc
      ..add(const HomesSubscribed())
      ..add(const HomeCreated('   ')),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.homes, hasLength(2));
      expect(bloc.state.notice, const HomesError('A name is required.'));
    },
  );

  blocTest<HomesBloc, HomesState>(
    'switching, renaming and clearing the notice',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeSwitched('h2'));
      bloc.add(const HomeRenamed('h2', 'Loft'));
      bloc.add(const HomeCreated(''));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomesNoticeCleared());
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.activeHomeId, 'h2');
      expect(bloc.state.activeHome?.name, 'Loft');
      expect(bloc.state.notice, isNull);
    },
  );

  blocTest<HomesBloc, HomesState>(
    'the last home cannot be deleted',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeDeleted('h2'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeDeleted('h1'));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.homes.map((h) => h.home.id), ['h1']);
      expect(bloc.state.notice, isA<HomesError>());
    },
  );
}
```

`test/app/blocs/settings_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/settings_cubit.dart';
import 'package:wizctl_app/app/blocs/settings_state.dart';
import 'package:wizctl_app/app/debug_flags_holder.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fakes.dart';

void main() {
  late FakeSettingsRepository settings;
  late RecordingFeedbackService feedback;
  late DebugFlagsHolder flags;

  SettingsCubit build() => SettingsCubit(
    settings: settings,
    feedback: feedback,
    debugFlags: flags,
  );

  setUp(() {
    settings = FakeSettingsRepository();
    feedback = RecordingFeedbackService();
    flags = DebugFlagsHolder();
  });

  test('the initial state comes from the snapshot when given', () {
    var cubit = SettingsCubit(
      settings: settings,
      feedback: feedback,
      debugFlags: flags,
      initial: const AppSettings(feedbackEnabled: false, rescanOnLaunch: false),
    );
    addTearDown(cubit.close);
    expect(cubit.state.feedbackEnabled, isFalse);
    expect(cubit.state.rescanOnLaunch, isFalse);
    expect(cubit.state.debugFlags, DebugFlags.none);
  });

  blocTest<SettingsCubit, SettingsState>(
    'toggling feedback reaches the service and the repository',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await cubit.setFeedback(false);
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) async {
      expect(cubit.state.feedbackEnabled, isFalse);
      expect(feedback.enabled, isFalse);
      expect((await settings.get()).feedbackEnabled, isFalse);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'rescan on launch persists',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await cubit.setRescanOnLaunch(false);
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) async {
      expect(cubit.state.rescanOnLaunch, isFalse);
      expect((await settings.get()).rescanOnLaunch, isFalse);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'the prototype switches write the holder and the state follows',
    build: build,
    act: (cubit) {
      cubit.subscribe();
      cubit.setOffNetwork(true);
      cubit.setForceTimeout(true);
      cubit.setFindNothing(true);
      cubit.setOffNetwork(false);
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(flags.value, const DebugFlags(forceTimeout: true, findNothing: true));
      expect(cubit.state.debugFlags, flags.value);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'a change written elsewhere shows up',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await settings.save(const AppSettings(activeHomeId: 'h1', feedbackEnabled: false));
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) => expect(cubit.state.feedbackEnabled, isFalse),
  );
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app/blocs test/features/layering_test.dart`
Expected: FAIL to compile (the layering test fails with "the scan found no bloc files").

- [ ] **Step 3: Write the events, state and bloc**

`lib/app/blocs/homes_event.dart`:

```dart
import 'package:equatable/equatable.dart';

sealed class HomesEvent extends Equatable {
  const HomesEvent();
  @override
  List<Object?> get props => const [];
}

final class HomesSubscribed extends HomesEvent {
  const HomesSubscribed();
}

final class HomeCreated extends HomesEvent {
  final String name;
  const HomeCreated(this.name);
  @override
  List<Object?> get props => [name];
}

final class HomeSwitched extends HomesEvent {
  final String homeId;
  const HomeSwitched(this.homeId);
  @override
  List<Object?> get props => [homeId];
}

final class HomeRenamed extends HomesEvent {
  final String homeId;
  final String name;
  const HomeRenamed(this.homeId, this.name);
  @override
  List<Object?> get props => [homeId, name];
}

final class HomeDeleted extends HomesEvent {
  final String homeId;
  const HomeDeleted(this.homeId);
  @override
  List<Object?> get props => [homeId];
}

final class HomesNoticeCleared extends HomesEvent {
  const HomesNoticeCleared();
}
```

`lib/app/blocs/homes_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

enum HomesStatus { loading, ready }

/// A home with what the Homes sheet says about it: "<r> rooms · <l> lights".
class HomeSummary extends Equatable {
  final Home home;
  final int roomCount;
  final int lightCount;
  const HomeSummary({
    required this.home,
    required this.roomCount,
    required this.lightCount,
  });
  @override
  List<Object?> get props => [home, roomCount, lightCount];
}

sealed class HomesNotice extends Equatable {
  const HomesNotice();
}

/// A home was just created and activated; the view toasts and goes to
/// discovery (spec §10.2).
final class HomeCreatedNotice extends HomesNotice {
  final Home home;
  const HomeCreatedNotice(this.home);
  @override
  List<Object?> get props => [home];
}

final class HomesError extends HomesNotice {
  final String message;
  const HomesError(this.message);
  @override
  List<Object?> get props => [message];
}

class HomesState extends Equatable {
  final HomesStatus status;
  final List<HomeSummary> homes;
  final String? activeHomeId;
  final HomesNotice? notice;

  const HomesState({
    required this.status,
    required this.homes,
    required this.activeHomeId,
    this.notice,
  });

  /// What bootstrap knows before anything is subscribed: enough for the
  /// router's redirect (spec §9), with counts still to come.
  factory HomesState.snapshot(List<Home> homes, AppSettings settings) =>
      HomesState(
        status: HomesStatus.loading,
        homes: [
          for (var h in homes)
            HomeSummary(home: h, roomCount: 0, lightCount: 0),
        ],
        activeHomeId: settings.activeHomeId,
      );

  Home? get activeHome {
    for (var h in homes) {
      if (h.home.id == activeHomeId) return h.home;
    }
    return null;
  }

  bool get hasHome => homes.isNotEmpty;

  HomesState copyWith({
    HomesStatus? status,
    List<HomeSummary>? homes,
    String? activeHomeId,
    bool clearActiveHome = false,
    HomesNotice? notice,
    bool clearNotice = false,
  }) => HomesState(
    status: status ?? this.status,
    homes: homes ?? this.homes,
    activeHomeId: clearActiveHome ? null : activeHomeId ?? this.activeHomeId,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, homes, activeHomeId, notice];
}
```

`lib/app/blocs/homes_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';

import '../../core/util/latest.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/light_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/usecases.dart';
import 'homes_event.dart';
import 'homes_state.dart';

/// Every home on this device and which one is active (spec §8).
///
/// The active home's counts are live (its rooms and lights are what the
/// user is editing); the others are read once per emission, since nothing
/// changes in a home that is not active.
class HomesBloc extends Bloc<HomesEvent, HomesState> {
  final HomeRepository _homes;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final SettingsRepository _settings;
  final CreateHome _createHome;
  final SwitchHome _switchHome;
  final RenameHome _renameHome;
  final DeleteHome _deleteHome;

  HomesBloc({
    required HomeRepository homes,
    required RoomRepository rooms,
    required LightRepository lights,
    required SettingsRepository settings,
    required CreateHome createHome,
    required SwitchHome switchHome,
    required RenameHome renameHome,
    required DeleteHome deleteHome,
    HomesState? initial,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _createHome = createHome, // ignore: prefer_initializing_formals
       _switchHome = switchHome, // ignore: prefer_initializing_formals
       _renameHome = renameHome, // ignore: prefer_initializing_formals
       _deleteHome = deleteHome, // ignore: prefer_initializing_formals
       super(
         initial ??
             const HomesState(
               status: HomesStatus.loading,
               homes: [],
               activeHomeId: null,
             ),
       ) {
    on<HomesSubscribed>(_onSubscribed);
    on<HomeCreated>(_onCreated);
    on<HomeSwitched>(_onSwitched);
    on<HomeRenamed>(_onRenamed);
    on<HomeDeleted>(_onDeleted);
    on<HomesNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  Future<void> _onSubscribed(
    HomesSubscribed event,
    Emitter<HomesState> emit,
  ) async {
    var active = _settings.watch().map((s) => s.activeHomeId).distinct();
    await emit.forEach(
      active.asyncExpand(_forActive),
      onData: (next) => state.copyWith(
        status: HomesStatus.ready,
        homes: next.homes,
        activeHomeId: next.activeHomeId,
        clearActiveHome: next.activeHomeId == null,
      ),
    );
  }

  /// Homes with counts, the active one's counts following its rooms and
  /// lights.
  Stream<({List<HomeSummary> homes, String? activeHomeId})> _forActive(
    String? activeId,
  ) {
    var rooms = activeId == null
        ? Stream.value(const <Room>[])
        : _rooms.watchByHome(activeId);
    var lights = activeId == null
        ? Stream.value(const <Light>[])
        : _lights.watchByHome(activeId);
    return combineLatest3(_homes.watchAll(), rooms, lights).asyncMap((
      tuple,
    ) async {
      var (all, activeRooms, activeLights) = tuple;
      var summaries = <HomeSummary>[];
      for (var home in all) {
        if (home.id == activeId) {
          summaries.add(
            HomeSummary(
              home: home,
              roomCount: activeRooms.length,
              lightCount: activeLights.length,
            ),
          );
        } else {
          summaries.add(
            HomeSummary(
              home: home,
              roomCount: (await _rooms.getByHome(home.id)).length,
              lightCount: (await _lights.getByHome(home.id)).length,
            ),
          );
        }
      }
      return (homes: summaries, activeHomeId: activeId);
    });
  }

  Future<void> _onCreated(HomeCreated event, Emitter<HomesState> emit) async {
    try {
      var home = await _createHome(event.name);
      emit(state.copyWith(notice: HomeCreatedNotice(home)));
    } on DomainException catch (e) {
      emit(state.copyWith(notice: HomesError(e.message)));
    }
  }

  Future<void> _onSwitched(HomeSwitched event, Emitter<HomesState> emit) =>
      _switchHome(event.homeId);

  Future<void> _onRenamed(HomeRenamed event, Emitter<HomesState> emit) async {
    try {
      await _renameHome(event.homeId, event.name);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: HomesError(e.message)));
    }
  }

  Future<void> _onDeleted(HomeDeleted event, Emitter<HomesState> emit) async {
    try {
      await _deleteHome(event.homeId);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: HomesError(e.message)));
    }
  }
}
```

`lib/app/blocs/settings_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// The two persisted toggles (spec §10.7) and the prototype switches
/// (spec §18), which only debug builds ever change.
class SettingsState extends Equatable {
  final bool feedbackEnabled;
  final bool rescanOnLaunch;
  final DebugFlags debugFlags;

  const SettingsState({
    required this.feedbackEnabled,
    required this.rescanOnLaunch,
    required this.debugFlags,
  });

  factory SettingsState.from(AppSettings settings, DebugFlags flags) =>
      SettingsState(
        feedbackEnabled: settings.feedbackEnabled,
        rescanOnLaunch: settings.rescanOnLaunch,
        debugFlags: flags,
      );

  SettingsState copyWith({
    bool? feedbackEnabled,
    bool? rescanOnLaunch,
    DebugFlags? debugFlags,
  }) => SettingsState(
    feedbackEnabled: feedbackEnabled ?? this.feedbackEnabled,
    rescanOnLaunch: rescanOnLaunch ?? this.rescanOnLaunch,
    debugFlags: debugFlags ?? this.debugFlags,
  );

  @override
  List<Object?> get props => [feedbackEnabled, rescanOnLaunch, debugFlags];
}
```

`lib/app/blocs/settings_cubit.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/feedback/feedback_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/settings_repository.dart';
import '../debug_flags_holder.dart';
import 'settings_state.dart';

/// The Settings screen's toggles. The feedback toggle reaches the service at
/// once and the repository right after, so a click is silent from the very
/// next press rather than from the next launch.
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settings;
  final FeedbackService _feedback;
  final DebugFlagsHolder _flags;
  StreamSubscription<AppSettings>? _subscription;

  SettingsCubit({
    required SettingsRepository settings,
    required FeedbackService feedback,
    required DebugFlagsHolder debugFlags,
    AppSettings? initial,
  }) : _settings = settings, // ignore: prefer_initializing_formals
       _feedback = feedback, // ignore: prefer_initializing_formals
       _flags = debugFlags, // ignore: prefer_initializing_formals
       super(
         SettingsState.from(initial ?? AppSettings.defaults, debugFlags.value),
       );

  void subscribe() {
    _subscription ??= _settings.watch().listen(
      (s) => emit(
        state.copyWith(
          feedbackEnabled: s.feedbackEnabled,
          rescanOnLaunch: s.rescanOnLaunch,
        ),
      ),
    );
    _flags.addListener(_onFlags);
  }

  void _onFlags() => emit(state.copyWith(debugFlags: _flags.value));

  Future<void> setFeedback(bool value) async {
    await _feedback.setEnabled(value);
    await _settings.save(
      (await _settings.get()).copyWith(feedbackEnabled: value),
    );
  }

  Future<void> setRescanOnLaunch(bool value) async {
    await _settings.save(
      (await _settings.get()).copyWith(rescanOnLaunch: value),
    );
  }

  void setOffNetwork(bool value) =>
      _flags.value = _flags.value.copyWith(offNetwork: value);

  void setForceTimeout(bool value) =>
      _flags.value = _flags.value.copyWith(forceTimeout: value);

  void setFindNothing(bool value) =>
      _flags.value = _flags.value.copyWith(findNothing: value);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _flags.removeListener(_onFlags);
    return super.close();
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app/blocs test/features/layering_test.dart`
Expected: PASS. If the `HomesBloc` "empty name" test sees the notice cleared by a later repository emission, note that `_onSubscribed` copies `state` at emission time and keeps the notice; `copyWith` only clears it on `clearNotice`. The test passes as written.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app/blocs test/app/blocs test/features/layering_test.dart
git commit -m "feat(app): HomesBloc, SettingsCubit and the bloc layering test"
```

---

### Task 4: NetworkCubit, BlinkCubit, InspectorCubit, the off-network banner and the blink key

**Files:**
- Create: `lib/app/blocs/network_cubit.dart`, `lib/app/blocs/network_state.dart`, `lib/app/blocs/blink_cubit.dart`, `lib/app/blocs/blink_state.dart`, `lib/app/blocs/inspector_cubit.dart`, `lib/app/widgets/off_network_banner.dart`, `lib/app/widgets/blink_key.dart`
- Modify: `lib/core/copy/strings.dart`
- Test: `test/app/blocs/network_cubit_test.dart`, `test/app/blocs/blink_cubit_test.dart`, `test/app/widgets/off_network_banner_test.dart`, `test/app/widgets/blink_key_test.dart`

**Interfaces:**
- Consumes: `NetworkMonitor.watchSubnet/isOffNetwork/current/refresh`, `HomeRepository.watchAll`, `SettingsRepository.watch`, `BlinkLight.call(ip, {bulbClass})` (throws `DeviceException`), `WizStatusBanner`, `WizButton`, `WizIconKey`, `combineLatest2`.
- Produces:

```dart
// network_state.dart
sealed class NetworkNotice extends Equatable
final class StillOffNotice(String? currentSubnet)
class NetworkState extends Equatable {
  bool offNetwork; String? currentSubnet; String? homeSubnet; NetworkNotice? notice;
  static const NetworkState initial;
}
// network_cubit.dart
class NetworkCubit extends Cubit<NetworkState> {
  NetworkCubit({required NetworkMonitor network, required SettingsRepository settings, required HomeRepository homes});
  void subscribe(); Future<void> retry(); void clearNotice();
}
// blink_state.dart
class BlinkFailure extends Equatable { String ip; DeviceFailure failure; }
class BlinkState extends Equatable { Set<String> blinking; BlinkFailure? failure; bool isBlinking(String ip); }
// blink_cubit.dart
class BlinkCubit extends Cubit<BlinkState> {
  BlinkCubit({required BlinkLight blink});
  Future<void> blink(String ip, {BulbClass? bulbClass}); void clearFailure();
}
// inspector_cubit.dart
class InspectorCubit extends Cubit<String?> { void select(String lightId); void clear(); }
// widgets
class OffNetworkBanner extends StatelessWidget { const OffNetworkBanner({super.key}); }   // shrinks to nothing when on network
class BlinkKey extends StatelessWidget { BlinkKey({required String ip, BulbClass? bulbClass, WizKeySize size = WizKeySize.md}); }
// Strings
notOnHomeNetworkTitle, joinHomeNetwork, blinkLight; deviceOn(current, home), stillOn(current)
```

- [ ] **Step 1: Write the failing tests**

`test/app/blocs/network_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/network_cubit.dart';
import 'package:wizctl_app/app/blocs/network_state.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeNetworkInfo info;
  late NetworkMonitor monitor;

  NetworkCubit build() =>
      NetworkCubit(network: monitor, settings: seed.settings, homes: seed.homes);

  setUp(() {
    seed = SeedHome();
    info = FakeNetworkInfo('192.168.1');
    monitor = NetworkMonitor(info);
  });

  tearDown(() => monitor.dispose());

  blocTest<NetworkCubit, NetworkState>(
    'on the home subnet nothing is wrong',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      await monitor.refresh();
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.offNetwork, isFalse);
      expect(cubit.state.homeSubnet, '192.168.1');
      expect(cubit.state.currentSubnet, '192.168.1');
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'a different subnet is off network, and retry says so while it lasts',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = '10.0.0';
      await monitor.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cubit.retry();
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.offNetwork, isTrue);
      expect(cubit.state.currentSubnet, '10.0.0');
      expect(cubit.state.notice, const StillOffNotice('10.0.0'));
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'no address at all is off network too',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = null;
      await monitor.refresh();
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.offNetwork, isTrue);
      expect(cubit.state.currentSubnet, isNull);
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'a home without a subnet is never off network, and learning one flips it',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = '10.0.0';
      await monitor.refresh();
      await seed.homes.update(seed.home.copyWith(subnet: '10.0.0'));
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.homeSubnet, '10.0.0');
      expect(cubit.state.offNetwork, isFalse);
    },
  );

  blocTest<NetworkCubit, NetworkState>(
    'switching home re-reads the subnet it compares against',
    build: build,
    act: (cubit) async {
      cubit.subscribe();
      info.subnet = '10.0.0';
      await monitor.refresh();
      await cubit.retry();
      cubit.clearNotice();
      await seed.settings.save(
        (await seed.settings.get()).copyWith(activeHomeId: 'h2'),
      );
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) {
      expect(cubit.state.homeSubnet, isNull, reason: 'the Studio has none');
      expect(cubit.state.offNetwork, isFalse);
      expect(cubit.state.notice, isNull);
    },
  );
}
```

`test/app/blocs/blink_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/blocs/blink_state.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';

void main() {
  late FakeGateway gateway;
  late FakeClock clock;

  BlinkCubit build() =>
      BlinkCubit(blink: BlinkLight(gateway: gateway, clock: clock));

  setUp(() {
    gateway = FakeGateway();
    clock = FakeClock();
    gateway.states['192.168.1.115'] = const LightState(isOn: false);
  });

  blocTest<BlinkCubit, BlinkState>(
    'a blink is on the set while it runs and gone after',
    build: build,
    act: (cubit) => cubit.blink('192.168.1.115', bulbClass: BulbClass.rgb),
    expect: () => [
      const BlinkState(blinking: {'192.168.1.115'}),
      const BlinkState(blinking: {}),
    ],
    verify: (_) {
      expect(gateway.sends, hasLength(2), reason: 'the write and the restore');
      expect(clock.delays, [const Duration(seconds: 2)]);
    },
  );

  blocTest<BlinkCubit, BlinkState>(
    'a second tap while blinking is ignored',
    build: build,
    act: (cubit) async {
      var first = cubit.blink('192.168.1.115');
      await cubit.blink('192.168.1.115');
      await first;
    },
    verify: (_) => expect(gateway.sends, hasLength(2)),
  );

  blocTest<BlinkCubit, BlinkState>(
    'a bulb that does not answer raises the failure and never blinks',
    build: build,
    setUp: () => gateway.failing['192.168.1.115'] =
        const TimeoutFailure('192.168.1.115', 2),
    act: (cubit) async {
      await cubit.blink('192.168.1.115');
      cubit.clearFailure();
    },
    expect: () => [
      const BlinkState(blinking: {'192.168.1.115'}),
      const BlinkState(
        blinking: {},
        failure: BlinkFailure(
          '192.168.1.115',
          TimeoutFailure('192.168.1.115', 2),
        ),
      ),
      const BlinkState(blinking: {}),
    ],
    verify: (_) => expect(gateway.sends, isEmpty),
  );
}
```

`test/app/widgets/off_network_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/network_cubit.dart';
import 'package:wizctl_app/app/widgets/off_network_banner.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';
import '../../support/wiz_test_app.dart';

void main() {
  late SeedHome seed;
  late FakeNetworkInfo info;
  late NetworkMonitor monitor;
  late NetworkCubit cubit;
  late ToastController toasts;

  setUp(() {
    seed = SeedHome();
    info = FakeNetworkInfo('10.0.0');
    monitor = NetworkMonitor(info);
    cubit = NetworkCubit(network: monitor, settings: seed.settings, homes: seed.homes)
      ..subscribe();
    toasts = ToastController();
  });

  tearDown(() async {
    await cubit.close();
    monitor.dispose();
    toasts.dispose();
  });

  Widget subject() => BlocProvider.value(
    value: cubit,
    child: RepositoryProvider.value(
      value: toasts,
      child: const OffNetworkBanner(),
    ),
  );

  testWidgets('nothing is shown on the home network', (tester) async {
    info.subnet = '192.168.1';
    await monitor.refresh();
    await tester.pumpWidget(wizTestApp(subject()));
    await tester.pump();
    expect(find.byType(WizStatusBanner), findsNothing);
  });

  testWidgets('off network shows the banner with both subnets', (tester) async {
    await monitor.refresh();
    await tester.pumpWidget(wizTestApp(subject()));
    await tester.pump();
    expect(find.text(Strings.notOnHomeNetworkTitle), findsOneWidget);
    expect(
      find.text('This device is on 10.0.0.0/24. Lights answer only on 192.168.1.0/24.'),
      findsOneWidget,
    );
    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('no address at all says so', (tester) async {
    info.subnet = null;
    await monitor.refresh();
    await tester.pumpWidget(wizTestApp(subject()));
    await tester.pump();
    expect(find.text(Strings.noLocalNetwork), findsOneWidget);
  });

  testWidgets('retry while still off pushes the still-on toast', (tester) async {
    await monitor.refresh();
    await tester.pumpWidget(wizTestApp(subject()));
    await tester.pump();
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await tester.pump();
    expect(toasts.toasts.single.title, 'Still on 10.0.0.0/24');
    expect(toasts.toasts.single.body, Strings.joinHomeNetwork);
    expect(cubit.state.notice, isNull, reason: 'consumed by the listener');
  });
}
```

`flutter_bloc` 9.1 re-exports only `ReadContext`, `SelectContext` and `WatchContext` from `provider`, so plain objects such as the toast controller travel in a `RepositoryProvider` and blocs in a `BlocProvider`; `context.read<ToastController>()` resolves either way. Every later task provides the toast controller the same way.

`test/app/widgets/blink_key_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/widgets/blink_key.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';
import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('tapping blinks and the key is active while it does', (tester) async {
    var gateway = FakeGateway()
      ..states['192.168.1.115'] = const LightState(isOn: true)
      ..sendLatency = const Duration(milliseconds: 100);
    var cubit = BlinkCubit(blink: BlinkLight(gateway: gateway, clock: FakeClock()));
    addTearDown(cubit.close);
    await tester.pumpWidget(
      wizTestApp(
        BlocProvider.value(
          value: cubit,
          child: const BlinkKey(ip: '192.168.1.115', bulbClass: BulbClass.rgb),
        ),
      ),
    );
    expect(tester.widget<WizIconKey>(find.byType(WizIconKey)).active, isFalse);
    await tester.tap(find.bySemanticsLabel(Strings.blinkLight));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<WizIconKey>(find.byType(WizIconKey)).active, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(tester.widget<WizIconKey>(find.byType(WizIconKey)).active, isFalse);
    expect(gateway.sends, hasLength(2));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app/`
Expected: FAIL to compile.

- [ ] **Step 3: Write the cubits, the widgets and the copy**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Wrong network (spec §15).
  static const notOnHomeNetworkTitle = 'Not on the home network';
  static const joinHomeNetwork = 'Join the home network, then scan again.';
  static String deviceOn(String current, String home) =>
      'This device is on $current.0/24. Lights answer only on $home.0/24.';
  static String stillOn(String current) => 'Still on $current.0/24';

  // Semantics.
  static const blinkLight = 'Blink this light';
```

`lib/app/blocs/network_state.dart`:

```dart
import 'package:equatable/equatable.dart';

sealed class NetworkNotice extends Equatable {
  const NetworkNotice();
}

/// A retry found the device still elsewhere; the view toasts "Still on …".
final class StillOffNotice extends NetworkNotice {
  final String? currentSubnet;
  const StillOffNotice(this.currentSubnet);
  @override
  List<Object?> get props => [currentSubnet];
}

/// Off network = the active home has a subnet and this device is not on it,
/// or has no IPv4 address at all (spec §5.9).
class NetworkState extends Equatable {
  final bool offNetwork;
  final String? currentSubnet;
  final String? homeSubnet;
  final NetworkNotice? notice;

  const NetworkState({
    required this.offNetwork,
    required this.currentSubnet,
    required this.homeSubnet,
    this.notice,
  });

  static const NetworkState initial = NetworkState(
    offNetwork: false,
    currentSubnet: null,
    homeSubnet: null,
  );

  NetworkState copyWith({
    bool? offNetwork,
    String? currentSubnet,
    bool clearCurrent = false,
    String? homeSubnet,
    bool clearHome = false,
    NetworkNotice? notice,
    bool clearNotice = false,
  }) => NetworkState(
    offNetwork: offNetwork ?? this.offNetwork,
    currentSubnet: clearCurrent ? null : currentSubnet ?? this.currentSubnet,
    homeSubnet: clearHome ? null : homeSubnet ?? this.homeSubnet,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [offNetwork, currentSubnet, homeSubnet, notice];
}
```

`lib/app/blocs/network_cubit.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/util/latest.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/network_monitor.dart';
import 'network_state.dart';

/// The wrong-network banner's state (spec §5.9, §15). Re-subscribes the
/// monitor whenever the active home or its subnet changes, because
/// `watchOffNetwork` captures the subnet it compares against at subscribe
/// time.
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
    var homeSubnet = _settings
        .watch()
        .map((s) => s.activeHomeId)
        .distinct()
        .asyncExpand(
          (id) => id == null
              ? Stream.value(null)
              : _homes.watchAll().map((all) {
                  for (var h in all) {
                    if (h.id == id) return h.subnet;
                  }
                  return null;
                }).distinct(),
        );
    _subscription ??= combineLatest2(homeSubnet, _network.watchSubnet()).listen(
      (pair) {
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
      },
    );
  }

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
```

`lib/app/blocs/blink_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// A blink that did not happen: the bulb answered neither the read nor the
/// restore (spec §5.10); the view shows the command-timeout toast.
class BlinkFailure extends Equatable {
  final String ip;
  final DeviceFailure failure;
  const BlinkFailure(this.ip, this.failure);
  @override
  List<Object?> get props => [ip, failure];
}

class BlinkState extends Equatable {
  final Set<String> blinking;
  final BlinkFailure? failure;
  const BlinkState({required this.blinking, this.failure});

  bool isBlinking(String ip) => blinking.contains(ip);

  @override
  List<Object?> get props => [blinking, failure];
}
```

`lib/app/blocs/blink_cubit.dart`:

```dart
import 'package:bloc/bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';
import 'blink_state.dart';

/// Which addresses are blinking right now (spec §5.10, §8). A tap while an
/// address is blinking is ignored; the key and the row's well read the set.
class BlinkCubit extends Cubit<BlinkState> {
  final BlinkLight _blink;

  BlinkCubit({required BlinkLight blink})
    : _blink = blink, // ignore: prefer_initializing_formals
      super(const BlinkState(blinking: {}));

  Future<void> blink(String ip, {BulbClass? bulbClass}) async {
    if (state.isBlinking(ip)) return;
    emit(BlinkState(blinking: {...state.blinking, ip}, failure: state.failure));
    try {
      await _blink(ip, bulbClass: bulbClass);
      emit(BlinkState(blinking: {...state.blinking}..remove(ip), failure: state.failure));
    } on DeviceException catch (e) {
      emit(
        BlinkState(
          blinking: {...state.blinking}..remove(ip),
          failure: BlinkFailure(ip, e.failure),
        ),
      );
    }
  }

  void clearFailure() => emit(BlinkState(blinking: state.blinking));
}
```

`lib/app/blocs/inspector_cubit.dart`:

```dart
import 'package:bloc/bloc.dart';

/// The light the desktop inspector shows (spec §10.9), or null for the
/// "No light selected" state. Cleared when the home changes (Task 20).
class InspectorCubit extends Cubit<String?> {
  InspectorCubit() : super(null);
  void select(String lightId) => emit(lightId);
  void clear() => emit(null);
}
```

`lib/app/widgets/off_network_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/copy/strings.dart';
import '../../core/widgets/toast_controller.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_status_banner.dart';
import '../blocs/network_cubit.dart';
import '../blocs/network_state.dart';

/// The wrong-network condition (spec §15): a banner while it lasts, and the
/// "Still on …" toast when a retry changes nothing. Nothing at all on the
/// home network, so screens can place it unconditionally.
class OffNetworkBanner extends StatelessWidget {
  const OffNetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        if (state.notice case StillOffNotice(:var currentSubnet)) {
          context.read<ToastController>().push(
            tone: WizToastTone.error,
            title: currentSubnet == null
                ? Strings.noLocalNetwork
                : Strings.stillOn(currentSubnet),
            body: Strings.joinHomeNetwork,
          );
        }
        context.read<NetworkCubit>().clearNotice();
      },
      child: BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          if (!state.offNetwork) return const SizedBox.shrink();
          var current = state.currentSubnet;
          var home = state.homeSubnet;
          return WizStatusBanner(
            status: WizStatus.warn,
            title: Strings.notOnHomeNetworkTitle,
            body: current == null || home == null
                ? Strings.noLocalNetwork
                : Strings.deviceOn(current, home),
            action: WizButton(
              label: Strings.retry,
              variant: WizButtonVariant.ghost,
              size: WizButtonSize.sm,
              onPressed: () => context.read<NetworkCubit>().retry(),
            ),
          );
        },
      ),
    );
  }
}
```

Ruling recorded for the reviewer: the banner uses the `warn` tone (wifi glyph, spec §11.2 pairs wifi with warn) although the prototype's `StatusBanner` used `error`; §15 names no tone and the wifi glyph is what the copy is about.

`lib/app/widgets/blink_key.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/widgets/wiz_icon_key.dart';
import '../blocs/blink_cubit.dart';
import '../blocs/blink_state.dart';

/// The flash key beside a discovered or saved light: amber while that
/// address is blinking (spec §5.10, §10.1).
class BlinkKey extends StatelessWidget {
  final String ip;
  final BulbClass? bulbClass;
  final WizKeySize size;

  const BlinkKey({
    super.key,
    required this.ip,
    this.bulbClass,
    this.size = WizKeySize.md,
  });

  @override
  Widget build(BuildContext context) {
    var blinking = context.select<BlinkCubit, bool>(
      (c) => c.state.isBlinking(ip),
    );
    return WizIconKey(
      icon: WizIcons.lightbulb,
      size: size,
      active: blinking,
      semanticsLabel: Strings.blinkLight,
      onPressed: () =>
          context.read<BlinkCubit>().blink(ip, bulbClass: bulbClass),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app/`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app lib/core/copy/strings.dart test/app
git commit -m "feat(app): network, blink and inspector cubits with the banner and flash key"
```

---

### Task 5: HomeScreenBloc

**Files:**
- Create: `lib/features/home/bloc/home_screen_bloc.dart`, `lib/features/home/bloc/home_screen_event.dart`, `lib/features/home/bloc/home_screen_state.dart`
- Test: `test/features/home/bloc/home_screen_bloc_test.dart`

**Interfaces:**
- Consumes: `HomeRepository.watchAll`, `RoomRepository.watchByHome`, `LightRepository.watchByHome`, `LiveStateStore.watchAll`, `SettingsRepository.watch`, `SetPower.call(target, on)`, `SyncCoordinator.registerScope/refreshAll`, `PollScope.update/dispose`, `LiveLight` (`domain/services/mode_summarizer.dart`), `combineLatest4`.
- Produces:

```dart
sealed class HomeScreenEvent; final class HomeScreenSubscribed, AllPowerToggled(bool on),
    RoomPowerToggled(String roomId, bool on), HomeRefreshRequested
enum HomeScreenStatus { loading, ready, noHome }
class RoomTile extends Equatable { Room room; int lightCount; int onCount; bool get anyOn; }
class HomeScreenState extends Equatable {
  HomeScreenStatus status; Home? home; List<RoomTile> rooms; List<LiveLight> lights;
  int get lightCount; int get onCount; int get unreachableCount; bool get anyOn;
  static const HomeScreenState initial;
}
class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  HomeScreenBloc({required HomeRepository homes, required RoomRepository rooms, required LightRepository lights,
      required LiveStateStore store, required SettingsRepository settings, required SetPower setPower,
      required SyncCoordinator sync});
}
```

- [ ] **Step 1: Write the failing test**

`test/features/home/bloc/home_screen_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late SyncCoordinator sync;

  HomeScreenBloc build() => HomeScreenBloc(
    homes: seed.homes,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    settings: seed.settings,
    setPower: SetPower(
      resolver: TargetResolver(seed.lights),
      store: seed.store,
      pipeline: pipeline,
    ),
    sync: sync,
  );

  setUp(() async {
    seed = SeedHome();
    gateway = FakeGateway();
    for (var l in seed.all) {
      gateway.states[l.ip] = LightState(isOn: seed.store.of(l.id).isOn);
    }
    monitor = NetworkMonitor(FakeNetworkInfo('192.168.1'));
    await monitor.refresh();
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    sync = SyncCoordinator(
      refresh: RefreshStates(
        gateway: gateway,
        store: seed.store,
        lights: seed.lights,
        clock: FakeClock(),
      ),
      lights: seed.lights,
      settings: seed.settings,
      pollInterval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() {
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<HomeScreenBloc, HomeScreenState>(
    'subscribing projects the active home: rooms, counts, the unreachable',
    build: build,
    act: (bloc) => bloc.add(const HomeScreenSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, HomeScreenStatus.ready);
      expect(s.home?.name, 'Kaverappa House');
      expect(s.rooms.map((r) => r.room.name), ['Living Room', 'Bedroom', 'Kitchen']);
      expect(s.rooms.map((r) => r.lightCount), [3, 2, 1]);
      expect(s.rooms.map((r) => r.onCount), [2, 0, 1]);
      expect(s.lightCount, 6);
      expect(s.onCount, 3);
      expect(s.unreachableCount, 1);
      expect(s.anyOn, isTrue);
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'no active home is its own status',
    build: () {
      seed = SeedHome(active: false);
      return build();
    },
    act: (bloc) => bloc.add(const HomeScreenSubscribed()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.status, HomeScreenStatus.noHome),
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'all power off reaches every light of the home',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const AllPowerToggled(false));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, hasLength(6));
      expect(gateway.sends.every((s) => s.$2.state == false), isTrue);
      expect(bloc.state.onCount, 0);
      expect(gateway.sends.map((s) => s.$1), isNot(contains('10.0.0.42')),
          reason: 'the Studio is another home');
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'room power reaches that room only',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomPowerToggled('bedroom', true));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends.map((s) => s.$1), ['192.168.1.115', '192.168.1.118']);
      expect(bloc.state.rooms[1].onCount, 2);
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'a refresh request reads every light now',
    build: build,
    act: (bloc) async {
      sync.activateHome('h1');
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const HomeRefreshRequested());
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.reads.toSet(), seed.all.where((l) => l.homeId == 'h1').map((l) => l.ip).toSet());
      expect(bloc.state.unreachableCount, 0, reason: 'the Hallway answered this time');
    },
  );

  test('the home\'s lights are polled while subscribed and not after', () async {
    sync.activateHome('h1');
    var bloc = build()..add(const HomeScreenSubscribed());
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(gateway.reads, containsAll(['192.168.1.104', '192.168.1.118', '192.168.1.121']));
    await bloc.close();
    gateway.reads.clear();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(gateway.reads, isEmpty, reason: 'the scope went with the bloc');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/home`
Expected: FAIL to compile.

- [ ] **Step 3: Write the event, state and bloc**

`lib/features/home/bloc/home_screen_event.dart`:

```dart
import 'package:equatable/equatable.dart';

sealed class HomeScreenEvent extends Equatable {
  const HomeScreenEvent();
  @override
  List<Object?> get props => const [];
}

final class HomeScreenSubscribed extends HomeScreenEvent {
  const HomeScreenSubscribed();
}

/// The master toggle (spec §10.2).
final class AllPowerToggled extends HomeScreenEvent {
  final bool on;
  const AllPowerToggled(this.on);
  @override
  List<Object?> get props => [on];
}

/// A room card's switch.
final class RoomPowerToggled extends HomeScreenEvent {
  final String roomId;
  final bool on;
  const RoomPowerToggled(this.roomId, this.on);
  @override
  List<Object?> get props => [roomId, on];
}

/// Pull to refresh.
final class HomeRefreshRequested extends HomeScreenEvent {
  const HomeRefreshRequested();
}
```

`lib/features/home/bloc/home_screen_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/mode_summarizer.dart';

enum HomeScreenStatus { loading, ready, noHome }

/// One room card: "<n> lights · <k> on" and its switch.
class RoomTile extends Equatable {
  final Room room;
  final int lightCount;
  final int onCount;
  const RoomTile({
    required this.room,
    required this.lightCount,
    required this.onCount,
  });
  bool get anyOn => onCount > 0;
  @override
  List<Object?> get props => [room, lightCount, onCount];
}

class HomeScreenState extends Equatable {
  final HomeScreenStatus status;
  final Home? home;
  final List<RoomTile> rooms;

  /// Every light of the home with its live state, in repository order; the
  /// desktop "All lights" grid draws these (spec §10.9).
  final List<LiveLight> lights;

  const HomeScreenState({
    required this.status,
    required this.home,
    required this.rooms,
    required this.lights,
  });

  static const HomeScreenState initial = HomeScreenState(
    status: HomeScreenStatus.loading,
    home: null,
    rooms: [],
    lights: [],
  );

  int get lightCount => lights.length;
  int get onCount => lights.where((l) => l.state.isOn).length;
  int get unreachableCount => lights.where((l) => !l.state.reachable).length;
  bool get anyOn => onCount > 0;

  @override
  List<Object?> get props => [status, home, rooms, lights];
}
```

`lib/features/home/bloc/home_screen_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/home_repository.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'home_screen_event.dart';
import 'home_screen_state.dart';

/// The home overview (spec §8, §10.2): rooms with their counts, the whole
/// home's on/off summary, how many lights are not answering. Registers the
/// whole home as its poll scope while it is on show.
class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  final HomeRepository _homes;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final SettingsRepository _settings;
  final SetPower _setPower;
  final SyncCoordinator _sync;
  PollScope? _scope;

  HomeScreenBloc({
    required HomeRepository homes,
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required SettingsRepository settings,
    required SetPower setPower,
    required SyncCoordinator sync,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _setPower = setPower, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(HomeScreenState.initial) {
    on<HomeScreenSubscribed>(_onSubscribed);
    on<AllPowerToggled>(_onAllPower);
    on<RoomPowerToggled>(_onRoomPower);
    on<HomeRefreshRequested>((_, _) => _sync.refreshAll());
  }

  Future<void> _onSubscribed(
    HomeScreenSubscribed event,
    Emitter<HomeScreenState> emit,
  ) async {
    var active = _settings.watch().map((s) => s.activeHomeId).distinct();
    await emit.forEach(active.asyncExpand(_forHome), onData: (s) => s);
  }

  Stream<HomeScreenState> _forHome(String? homeId) {
    if (homeId == null) {
      _scope?.update(const {});
      return Stream.value(
        const HomeScreenState(
          status: HomeScreenStatus.noHome,
          home: null,
          rooms: [],
          lights: [],
        ),
      );
    }
    var home = _homes.watchAll().map((all) {
      for (var h in all) {
        if (h.id == homeId) return h;
      }
      return null;
    });
    return combineLatest4(
      home,
      _rooms.watchByHome(homeId),
      _lights.watchByHome(homeId),
      _store.watchAll(),
    ).map((tuple) {
      var (home, rooms, lights, states) = tuple;
      if (home == null) {
        return const HomeScreenState(
          status: HomeScreenStatus.noHome,
          home: null,
          rooms: [],
          lights: [],
        );
      }
      var live = [
        for (var l in lights) (light: l, state: states[l.id] ?? LiveState.initial),
      ];
      (_scope ??= _sync.registerScope({})).update({for (var l in lights) l.id});
      return HomeScreenState(
        status: HomeScreenStatus.ready,
        home: home,
        rooms: [
          for (var room in rooms)
            RoomTile(
              room: room,
              lightCount: live.where((l) => l.light.roomId == room.id).length,
              onCount: live
                  .where((l) => l.light.roomId == room.id && l.state.isOn)
                  .length,
            ),
        ],
        lights: live,
      );
    });
  }

  Future<void> _onAllPower(
    AllPowerToggled event,
    Emitter<HomeScreenState> emit,
  ) async {
    var home = state.home;
    if (home == null) return;
    await _setPower(WholeHomeTarget(home.id), event.on);
  }

  Future<void> _onRoomPower(
    RoomPowerToggled event,
    Emitter<HomeScreenState> emit,
  ) => _setPower(RoomTarget(event.roomId), event.on);

  @override
  Future<void> close() {
    _scope?.dispose();
    return super.close();
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/home`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/home/bloc test/features/home
git commit -m "feat(home): HomeScreenBloc"
```

---

### Task 6: The Home screen, its sheet, and the scroll body every compact screen shares

**Files:**
- Create: `lib/app/widgets/screen_scroll.dart`, `lib/app/widgets/field_label.dart`, `lib/core/widgets/wiz_pull_to_refresh.dart`, `lib/features/home/view/home_screen.dart`, `lib/features/home/widgets/all_lights_panel.dart`, `lib/features/home/widgets/unreachable_line.dart`, `lib/features/home/widgets/homes_sheet.dart`, `lib/features/home/widgets/homes_notice_listener.dart`
- Create: `test/support/app_scope.dart`
- Modify: `lib/core/copy/strings.dart`
- Test: `test/core/widgets/wiz_pull_to_refresh_test.dart`, `test/app/widgets/screen_scroll_test.dart`, `test/features/home/view/home_screen_test.dart`, `test/features/home/widgets/homes_sheet_test.dart`

**Interfaces:**
- Consumes: `HomeScreenBloc` (Task 5), `HomesBloc` (Task 3), `NetworkCubit` and `OffNetworkBanner` (Task 4), `WizTopBar`, `WizIconKey`, `WizPanel`, `WizToggle`, `WizGrid`, `RoomCard`, `RiseIn`, `WizListRow`, `WizTextField`, `WizButton`, `showWizSheet`, `WizFilamentBar`, `WizIcon`, `plural`, `RefreshIndicator.noSpinner` (Flutter).
- Produces:

```dart
class ScreenScroll extends StatelessWidget {  // the compact scroll body
  const ScreenScroll({required List<Widget> children, double? gap, Future<void> Function()? onRefresh, ScrollController? controller});
}
class FieldLabel extends StatelessWidget { const FieldLabel(String text); }   // "ROOM NAME" style caps label
class WizPullToRefresh extends StatefulWidget { const WizPullToRefresh({required Future<void> Function() onRefresh, required Widget child}); }
class HomeScreen extends StatelessWidget { static const double roomTileMin = 150; }
class AllLightsPanel extends StatelessWidget { AllLightsPanel({required int onCount, required int total, ValueChanged<bool>? onToggle}); static String stateLabel(int on, int total); }
class UnreachableLine extends StatelessWidget { UnreachableLine({required int count}); }
Future<void> showHomesSheet(BuildContext context);
class HomesNoticeListener extends StatelessWidget { HomesNoticeListener({required Widget child}); }
// test/support/app_scope.dart
class AppScope { AppScope(SeedHome seed, {String? subnet}); Future<void> start(); Widget wrap(Widget child); Future<void> dispose();
  gateway, clock, ids, monitor, pipeline, refresh, sync, resolver, homes, network, blink, settingsCubit, inspector, toasts, flags, feedback;
  SetPower get setPower; SetBrightness get setBrightness; SetKelvin get setKelvin; SetSpeed get setSpeed; ApplyColour get applyColour; ApplyWhite get applyWhite; ApplyScene get applyScene; }
// Strings
allLights, allOn, allOff, homes, newHome, newHomePlaceholder, addHome, discoverOnNetwork; someOn(on, total), notAnswering(n), roomsAndLights(r, l), homeCreated(name)
```

- [ ] **Step 1: Write the failing tests**

`test/support/app_scope.dart` (support, not a test):

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/blocs/homes_bloc.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/blocs/inspector_cubit.dart';
import 'package:wizctl_app/app/blocs/network_cubit.dart';
import 'package:wizctl_app/app/blocs/settings_cubit.dart';
import 'package:wizctl_app/app/debug_flags_holder.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import 'fakes.dart';
import 'seed.dart';

/// Everything a screen test needs around a screen: the logic services over
/// the fakes, and the app-scope blocs provided the way the shell provides
/// them (Task 19). Route blocs are built by each test from the use-case
/// getters below.
class AppScope {
  final SeedHome seed;
  final gateway = FakeGateway();
  final clock = FakeClock();
  final ids = SequenceIds();
  final toasts = ToastController();
  final flags = DebugFlagsHolder();
  final feedback = RecordingFeedbackService();
  late final NetworkMonitor monitor;
  late final DeviceCommandPipeline pipeline;
  late final RefreshStates refresh;
  late final SyncCoordinator sync;
  late final TargetResolver resolver;
  late final HomesBloc homes;
  late final NetworkCubit network;
  late final BlinkCubit blink;
  late final SettingsCubit settingsCubit;
  late final InspectorCubit inspector;

  AppScope(this.seed, {String? subnet = '192.168.1'}) {
    for (var l in seed.all) {
      var s = seed.store.of(l.id);
      gateway.states[l.ip] = LightState(
        isOn: s.isOn,
        dimming: s.brightness,
        temperature: s.active == ActiveChannel.white ? s.kelvin : null,
        sceneId: s.active == ActiveChannel.scene ? s.sceneId : null,
        r: s.active == ActiveChannel.colour ? s.rgb.r : null,
        g: s.active == ActiveChannel.colour ? s.rgb.g : null,
        b: s.active == ActiveChannel.colour ? s.rgb.b : null,
        rssi: s.rssi,
      );
    }
    monitor = NetworkMonitor(FakeNetworkInfo(subnet));
    resolver = TargetResolver(seed.lights);
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async {
        var id = (await seed.settings.get()).activeHomeId;
        return id == null ? null : (await seed.homes.get(id))?.subnet;
      },
      clock: clock,
      ids: ids,
    );
    refresh = RefreshStates(
      gateway: gateway,
      store: seed.store,
      lights: seed.lights,
      clock: clock,
    );
    sync = SyncCoordinator(
      refresh: refresh,
      lights: seed.lights,
      settings: seed.settings,
    );
    homes = HomesBloc(
      homes: seed.homes,
      rooms: seed.rooms,
      lights: seed.lights,
      settings: seed.settings,
      createHome: CreateHome(
        homes: seed.homes,
        settings: seed.settings,
        ids: ids,
        clock: clock,
      ),
      switchHome: SwitchHome(settings: seed.settings),
      renameHome: RenameHome(homes: seed.homes),
      deleteHome: DeleteHome(homes: seed.homes, settings: seed.settings),
    );
    network = NetworkCubit(
      network: monitor,
      settings: seed.settings,
      homes: seed.homes,
    );
    blink = BlinkCubit(blink: BlinkLight(gateway: gateway, clock: clock));
    settingsCubit = SettingsCubit(
      settings: seed.settings,
      feedback: feedback,
      debugFlags: flags,
    );
    inspector = InspectorCubit();
  }

  SetPower get setPower =>
      SetPower(resolver: resolver, store: seed.store, pipeline: pipeline);
  SetBrightness get setBrightness =>
      SetBrightness(resolver: resolver, store: seed.store, pipeline: pipeline);
  SetKelvin get setKelvin =>
      SetKelvin(resolver: resolver, store: seed.store, pipeline: pipeline);
  SetSpeed get setSpeed =>
      SetSpeed(resolver: resolver, store: seed.store, pipeline: pipeline);
  ApplyColour get applyColour =>
      ApplyColour(resolver: resolver, store: seed.store, pipeline: pipeline);
  ApplyWhite get applyWhite =>
      ApplyWhite(resolver: resolver, store: seed.store, pipeline: pipeline);
  ApplyScene get applyScene =>
      ApplyScene(resolver: resolver, store: seed.store, pipeline: pipeline);

  /// Subscribes the app-scope blocs and activates the seed's home, as the
  /// lifecycle driver does at start.
  Future<void> start() async {
    await monitor.refresh();
    homes.add(const HomesSubscribed());
    network.subscribe();
    settingsCubit.subscribe();
    sync.activateHome((await seed.settings.get()).activeHomeId);
  }

  Widget wrap(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<HomesBloc>.value(value: homes),
      BlocProvider<NetworkCubit>.value(value: network),
      BlocProvider<BlinkCubit>.value(value: blink),
      BlocProvider<SettingsCubit>.value(value: settingsCubit),
      BlocProvider<InspectorCubit>.value(value: inspector),
    ],
    child: RepositoryProvider<ToastController>.value(
      value: toasts,
      child: child,
    ),
  );

  Future<void> dispose() async {
    await homes.close();
    await network.close();
    await blink.close();
    await settingsCubit.close();
    await inspector.close();
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
    toasts.dispose();
    seed.store.dispose();
  }
}
```

`test/core/widgets/wiz_pull_to_refresh_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_pull_to_refresh.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a pull shows the filament until the refresh completes', (
    tester,
  ) async {
    var completer = Completer<void>();
    var pulls = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          height: 400,
          child: WizPullToRefresh(
            onRefresh: () {
              pulls++;
              return completer.future;
            },
            child: ListView(
              children: const [SizedBox(height: 100, child: Text('row'))],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(WizFilamentBar), findsNothing);
    await tester.fling(find.text('row'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(pulls, 1);
    expect(find.byType(WizFilamentBar), findsOneWidget);
    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(WizFilamentBar), findsNothing);
  });
}
```

`test/app/widgets/screen_scroll_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/screen_scroll.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('gutters, a gap between children, and the bottom inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: 124),
          ),
          child: const WizLayoutScope(
            child: ScreenScroll(
              children: [
                SizedBox(key: Key('a'), height: 40),
                SizedBox(key: Key('b'), height: 40),
              ],
            ),
          ),
        ),
        size: const Size(390, 844),
      ),
    );
    var a = tester.getRect(find.byKey(const Key('a')));
    var b = tester.getRect(find.byKey(const Key('b')));
    expect(a.left, 20, reason: 'the compact gutter');
    expect(a.width, 350);
    expect(a.top, 47 + 8, reason: 'top inset plus the prototype\'s 8');
    expect(b.top - a.bottom, 16, reason: 'space.s6 between children');
    var list = tester.widget<ListView>(find.byType(ListView));
    expect((list.padding! as EdgeInsets).bottom, 124 + 24,
        reason: 'the reported bottom inset plus s8');
  });
}
```

`test/features/home/view/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;
  late HomeScreenBloc bloc;

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
    bloc = HomeScreenBloc(
      homes: scope.seed.homes,
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      settings: scope.seed.settings,
      setPower: scope.setPower,
      sync: scope.sync,
    )..add(const HomeScreenSubscribed());
  });

  tearDown(() async {
    await bloc.close();
    await scope.dispose();
  });

  Widget screen() => scope.wrap(
    BlocProvider.value(value: bloc, child: const HomeScreen()),
  );

  testWidgets('shows the home, its summary, its rooms and the unreachable line', (
    tester,
  ) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('Kaverappa House'), findsOneWidget);
    expect(find.text('3 rooms · 6 lights'), findsOneWidget);
    expect(find.text('ALL LIGHTS'), findsOneWidget);
    expect(find.text('3 of 6 on'), findsOneWidget);
    expect(find.text('1 light not answering'), findsOneWidget);
    expect(find.byType(RoomCard), findsNWidgets(3));
    expect(find.byType(WizStatusBanner), findsNothing);
  });

  testWidgets('taps navigate: a room card, the discover key', (tester) async {
    var router = await pumpRouted(
      tester,
      screen(),
      targets: [AppRoutes.roomPattern, AppRoutes.discover],
    );
    await tester.pump();
    await tester.tap(find.text('Living Room'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/rooms/living');
    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Discover lights'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.discover);
  });

  testWidgets('the master toggle writes power to every light', (tester) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('All lights'));
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends, hasLength(6));
    expect(scope.gateway.sends.every((s) => s.$2.state == false), isTrue);
    await tester.pump();
    expect(find.text('All off'), findsOneWidget);
  });

  testWidgets('a room card\'s toggle writes that room only', (tester) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    var bedroomToggle = find.descendant(
      of: find.widgetWithText(RoomCard, 'Bedroom'),
      matching: find.byType(WizToggle),
    );
    await tester.tap(bedroomToggle);
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends.map((s) => s.$1), ['192.168.1.115', '192.168.1.118']);
  });

  testWidgets('off network shows the banner above the panel', (tester) async {
    scope.monitor.dispose();
    var offScope = AppScope(SeedHome(), subnet: '10.0.0');
    addTearDown(offScope.dispose);
    await offScope.start();
    var offBloc = HomeScreenBloc(
      homes: offScope.seed.homes,
      rooms: offScope.seed.rooms,
      lights: offScope.seed.lights,
      store: offScope.seed.store,
      settings: offScope.seed.settings,
      setPower: offScope.setPower,
      sync: offScope.sync,
    )..add(const HomeScreenSubscribed());
    addTearDown(offBloc.close);
    await pumpRouted(
      tester,
      offScope.wrap(BlocProvider.value(value: offBloc, child: const HomeScreen())),
    );
    await tester.pump();
    expect(find.byType(WizStatusBanner), findsOneWidget);
    expect(find.text('Not on the home network'), findsOneWidget);
  });
}
```

`test/features/home/widgets/homes_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/features/home/widgets/homes_notice_listener.dart';
import 'package:wizctl_app/features/home/widgets/homes_sheet.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
  });

  tearDown(() => scope.dispose());

  Widget opener() => scope.wrap(
    HomesNoticeListener(
      child: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showHomesSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('lists every home with its counts, the active one marked', (
    tester,
  ) async {
    await pumpRouted(tester, opener());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Homes'), findsOneWidget);
    expect(find.text('3 rooms · 6 lights'), findsOneWidget);
    expect(find.text('1 room · 1 light'), findsOneWidget);
    var active = tester.widget<WizListRow>(find.widgetWithText(WizListRow, 'Kaverappa House'));
    expect(active.active, isTrue);
    expect(tester.widget<WizListRow>(find.widgetWithText(WizListRow, 'Studio')).active, isFalse);
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'ADD HOME')).enabled, isFalse);
  });

  testWidgets('tapping a home switches to it and closes', (tester) async {
    var router = await pumpRouted(tester, opener(), targets: [AppRoutes.home]);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studio'));
    await tester.pumpAndSettle();
    expect((await scope.seed.settings.get()).activeHomeId, 'h2');
    expect(find.text('Homes'), findsNothing);
    expect(currentLocation(router), AppRoutes.home);
  });

  testWidgets('adding a home activates it, toasts and goes to discovery', (
    tester,
  ) async {
    var router = await pumpRouted(tester, opener(), targets: [AppRoutes.discover]);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(WizTextField), 'Cabin');
    await tester.pump();
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'ADD HOME')).enabled, isTrue);
    await tester.tap(find.text('ADD HOME'));
    await tester.pumpAndSettle();
    expect(scope.homes.state.activeHome?.name, 'Cabin');
    expect(scope.toasts.toasts.single.title, 'Cabin created');
    expect(scope.toasts.toasts.single.body, 'Discover the lights on this network');
    expect(currentLocation(router), AppRoutes.discover);
    expect(scope.homes.state.notice, isNull);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/widgets/wiz_pull_to_refresh_test.dart test/app/widgets/screen_scroll_test.dart test/features/home`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the shared widgets and the screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Home (spec §10.2).
  static const allLights = 'All lights';
  static const allOn = 'All on';
  static const allOff = 'All off';
  static const homes = 'Homes';
  static const newHome = 'New home';
  static const newHomePlaceholder = 'Studio';
  static const addHome = 'Add home';
  static const discoverOnNetwork = 'Discover the lights on this network';
  static String someOn(int on, int total) => '$on of $total on';
  static String notAnswering(int n) => '${plural(n, 'light')} not answering';
  static String roomsAndLights(int rooms, int lights) =>
      '${plural(rooms, 'room')} · ${plural(lights, 'light')}';
  static String homeCreated(String name) => '$name created';
```

(`import '../util/plural.dart';` at the top.)

`lib/app/widgets/field_label.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';

/// The caps label above a field or a group: "ROOM NAME", "GLYPH", "COLOURS"
/// (spec §10, "control labels are uppercase with 0.10 em tracking").
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Text(
      text.toUpperCase(),
      style: wiz.typography.label.copyWith(color: wiz.colors.textTertiary),
    );
  }
}
```

`lib/app/widgets/screen_scroll.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/layout/wiz_layout.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_pull_to_refresh.dart';

/// The scrolling body every compact screen shares (`WizCtl_Mobile.dc.html`
/// line 171: `padding: 8px 40px 116px 20px; gap: 16px`): the gutter on both
/// sides, the top inset plus a little air, the bottom inset the shell
/// reports (safe area plus the floating tab bar, Task 19) plus a gap, and a
/// fixed gap between children. Pull to refresh when [onRefresh] is given.
class ScreenScroll extends StatelessWidget {
  final List<Widget> children;
  final double? gap;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  const ScreenScroll({
    super.key,
    required this.children,
    this.gap,
    this.onRefresh,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var gutter = context.layout.gutter;
    var inset = MediaQuery.paddingOf(context);
    var list = ListView.separated(
      controller: controller,
      // Always scrollable, or a short screen could not be pulled.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        gutter,
        inset.top + space.s4,
        gutter,
        inset.bottom + space.s8,
      ),
      itemCount: children.length,
      itemBuilder: (context, i) => children[i],
      separatorBuilder: (context, i) => SizedBox(height: gap ?? space.s6),
    );
    // The insets are spent here; nothing below should add them again.
    var body = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: list,
    );
    var refresh = onRefresh;
    return refresh == null
        ? body
        : WizPullToRefresh(onRefresh: refresh, child: body);
  }
}
```

`lib/core/widgets/wiz_pull_to_refresh.dart`:

```dart
import 'package:flutter/material.dart';

import '../layout/wiz_layout.dart';
import '../theme/wiz_theme.dart';
import 'wiz_filament_bar.dart';

/// Pull to refresh drawn as a filament bar (spec §12, "pull-to-refresh
/// drawn as a filament bar"): Material's gesture and thresholds, the house
/// loader instead of its spinner. The bar sits under the top inset for as
/// long as the pull is armed or the refresh runs; no opacity layer, so it
/// simply is or is not there.
class WizPullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const WizPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<WizPullToRefresh> createState() => _WizPullToRefreshState();
}

class _WizPullToRefreshState extends State<WizPullToRefresh> {
  RefreshIndicatorStatus? _status;

  bool get _showing => switch (_status) {
    RefreshIndicatorStatus.armed ||
    RefreshIndicatorStatus.snap ||
    RefreshIndicatorStatus.refresh => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) => setState(() => _status = status),
          child: widget.child,
        ),
        if (_showing)
          Positioned(
            top: MediaQuery.paddingOf(context).top + space.s4,
            left: context.layout.gutter,
            right: context.layout.gutter,
            child: const IgnorePointer(child: WizFilamentBar()),
          ),
      ],
    );
  }
}
```

`lib/features/home/widgets/all_lights_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_toggle.dart';

/// "ALL LIGHTS" with the home's state in display type and the master switch
/// (spec §10.2). The prototype pads it 18; the kit's large panel padding
/// (20) is the token nearest to that.
class AllLightsPanel extends StatelessWidget {
  final int onCount;
  final int total;
  final ValueChanged<bool>? onToggle;

  const AllLightsPanel({
    super.key,
    required this.onCount,
    required this.total,
    this.onToggle,
  });

  /// "All off" / "All on" / "<k> of <n> on".
  static String stateLabel(int on, int total) {
    if (total == 0 || on == 0) return Strings.allOff;
    if (on == total) return Strings.allOn;
    return Strings.someOn(on, total);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPanel(
      variant: WizPanelVariant.inset,
      padding: EdgeInsets.all(wiz.space.panelPadLg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(Strings.allLights),
                SizedBox(height: wiz.space.s2),
                Text(
                  stateLabel(onCount, total),
                  style: wiz.typography.title.copyWith(
                    color: wiz.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          WizToggle(
            value: onCount > 0,
            onChanged: onToggle,
            semanticsLabel: Strings.allLights,
          ),
        ],
      ),
    );
  }
}
```

`lib/features/home/widgets/unreachable_line.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';

/// "<n> lights not answering" in the danger colour under the All lights
/// panel (spec §10.2).
class UnreachableLine extends StatelessWidget {
  final int count;
  const UnreachableLine({super.key, required this.count});

  /// The prototype's `icSm` glyph.
  static const double glyph = 15;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Row(
      children: [
        WizIcon(WizIcons.wifi, size: glyph, color: wiz.colors.signalDanger),
        SizedBox(width: wiz.space.s3),
        Text(
          Strings.notAnswering(count),
          style: wiz.typography.bodySm.copyWith(color: wiz.colors.signalDanger),
        ),
      ],
    );
  }
}
```

`lib/features/home/widgets/homes_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/homes_event.dart';
import '../../../app/blocs/homes_state.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';

/// The Homes sheet (spec §10.2): one row per home, the active one marked,
/// a field for a new one. Tapping a row switches and closes; Add home is
/// enabled once the field has a name (the sheet disables the key rather
/// than playing reject on press, because the primary key already plays
/// confirm on pointer down).
Future<void> showHomesSheet(BuildContext context) {
  var bloc = context.read<HomesBloc>();
  var router = GoRouter.of(context);
  var navigator = Navigator.of(context, rootNavigator: true);
  var controller = TextEditingController();
  return showWizSheet<void>(
    context,
    title: Strings.homes,
    builder: (context) => BlocProvider.value(
      value: bloc,
      child: _HomesSheetBody(
        controller: controller,
        onPick: (id) {
          bloc.add(HomeSwitched(id));
          navigator.pop();
          router.go(AppRoutes.home);
        },
      ),
    ),
    footer: [
      WizButton(
        label: Strings.close,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => WizButton(
          label: Strings.addHome,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: value.text.trim().isNotEmpty,
          onPressed: () {
            bloc.add(HomeCreated(controller.text));
            navigator.pop();
          },
        ),
      ),
    ],
  ).whenComplete(controller.dispose);
}

class _HomesSheetBody extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onPick;
  const _HomesSheetBody({required this.controller, required this.onPick});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return BlocBuilder<HomesBloc, HomesState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var h in state.homes) ...[
            WizListRow(
              icon: WizIcons.house,
              title: h.home.name,
              meta: Strings.roomsAndLights(h.roomCount, h.lightCount),
              active: h.home.id == state.activeHomeId,
              onTap: () => onPick(h.home.id),
            ),
            SizedBox(height: space.s3),
          ],
          SizedBox(height: space.s4),
          const FieldLabel(Strings.newHome),
          SizedBox(height: space.s3),
          WizTextField(
            controller: controller,
            placeholder: Strings.newHomePlaceholder,
          ),
        ],
      ),
    );
  }
}
```

`lib/features/home/widgets/homes_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/homes_event.dart';
import '../../../app/blocs/homes_state.dart';
import '../../../app/routes.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';

/// Acts on HomesBloc notices wherever the Homes sheet can be opened: a new
/// home toasts and goes to discovery (spec §10.2); an error toasts.
class HomesNoticeListener extends StatelessWidget {
  final Widget child;
  const HomesNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomesBloc, HomesState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        switch (state.notice!) {
          case HomeCreatedNotice(:var home):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.homeCreated(home.name),
              body: Strings.discoverOnNetwork,
            );
            context.go(AppRoutes.discover);
          case HomesError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
        context.read<HomesBloc>().add(const HomesNoticeCleared());
      },
      child: child,
    );
  }
}
```

`lib/features/home/view/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/room_card.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/home_screen_bloc.dart';
import '../bloc/home_screen_event.dart';
import '../bloc/home_screen_state.dart';
import '../widgets/all_lights_panel.dart';
import '../widgets/homes_sheet.dart';
import '../widgets/unreachable_line.dart';

/// Home on a phone (spec §10.2): the home's name and counts, the wrong-
/// network banner when it applies, the All lights panel, the not-answering
/// line, and the room grid rising in.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Two room cards across a phone (spec §10.2, "min tile 150").
  static const double roomTileMin = 150;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return BlocBuilder<HomeScreenBloc, HomeScreenState>(
      builder: (context, state) {
        var home = state.home;
        var bloc = context.read<HomeScreenBloc>();
        if (state.status != HomeScreenStatus.ready || home == null) {
          return const ScreenScroll(children: []);
        }
        return ScreenScroll(
          onRefresh: () async => bloc.add(const HomeRefreshRequested()),
          children: [
            WizTopBar(
              title: home.name,
              subtitle: Strings.roomsAndLights(
                state.rooms.length,
                state.lightCount,
              ),
              leading: WizIconKey(
                icon: WizIcons.house,
                semanticsLabel: Strings.homes,
                onPressed: () => showHomesSheet(context),
              ),
              trailing: WizIconKey(
                icon: WizIcons.radio,
                semanticsLabel: Strings.discoverLights,
                onPressed: () => context.go(AppRoutes.discover),
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            AllLightsPanel(
              onCount: state.onCount,
              total: state.lightCount,
              onToggle: (on) => bloc.add(AllPowerToggled(on)),
            ),
            if (state.unreachableCount > 0)
              UnreachableLine(count: state.unreachableCount),
            WizGrid(
              minTile: roomTileMin,
              gap: space.s6,
              children: [
                for (var (i, tile) in state.rooms.indexed)
                  RiseIn(
                    index: i,
                    child: RoomCard(
                      name: tile.room.name,
                      icon: WizIcons.byName(tile.room.glyph.iconName)!,
                      lightCount: tile.lightCount,
                      onCount: tile.onCount,
                      on: tile.anyOn,
                      onToggle: (on) =>
                          bloc.add(RoomPowerToggled(tile.room.id, on)),
                      onTap: () => context.go(AppRoutes.room(tile.room.id)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

`WizIcons.byName` never returns null for a `RoomGlyph.iconName`; the `!` is documented by the glyph enum's contract (Plan 3 Task 1).

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/widgets/wiz_pull_to_refresh_test.dart test/app/widgets test/features/home`
Expected: PASS. If the pull test never reaches `armed`, the fling distance is short of `RefreshIndicator`'s default 100-pixel displacement: increase the offset to `Offset(0, 400)`.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app/widgets lib/core/widgets/wiz_pull_to_refresh.dart lib/core/copy/strings.dart lib/features/home test/
git commit -m "feat(home): the Home screen, the Homes sheet and the shared scroll body"
```

---

### Task 7: The Rooms tab: RoomsListBloc, the list, the add sheet and the long-press sheet

**Files:**
- Create: `lib/features/rooms/bloc/rooms_list_bloc.dart`, `lib/features/rooms/bloc/rooms_list_event.dart`, `lib/features/rooms/bloc/rooms_list_state.dart`, `lib/features/rooms/view/rooms_screen.dart`, `lib/features/rooms/widgets/glyph_picker.dart`, `lib/features/rooms/widgets/room_form.dart`, `lib/features/rooms/widgets/add_room_sheet.dart`, `lib/features/rooms/widgets/room_actions_sheet.dart`, `lib/features/rooms/widgets/rooms_notice_listener.dart`
- Modify: `lib/core/copy/strings.dart`
- Test: `test/features/rooms/bloc/rooms_list_bloc_test.dart`, `test/features/rooms/view/rooms_screen_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.watchByHome`, `LightRepository.watchByHome`, `LiveStateStore.watchAll`, `SettingsRepository.watch`, `AddRoom(homeId, name, glyph)`, `RenameRoom(id, name)`, `DeleteRoom(id)` (throws `RoomNotEmptyException`), `RoomGlyph.values/iconName`, `WizListRow`, `WizIconKey`, `WizButton`, `WizPanel`, `WizTextField`, `showWizSheet`, `ScreenScroll`, `FieldLabel`, `RiseIn`, `plural`.
- Produces:

```dart
sealed class RoomsListEvent; final class RoomsListSubscribed, RoomAdded(String name, RoomGlyph glyph),
    RoomRenamed(String roomId, String name), RoomDeleted(String roomId), RoomsNoticeCleared
class RoomRow extends Equatable { Room room; int lightCount; int onCount; }
sealed class RoomsNotice; final class RoomSavedNotice(String name), RoomsError(String message)
class RoomsListState extends Equatable { RoomsListStatus status; String? homeId; List<RoomRow> rooms; int lightCount; RoomsNotice? notice; }
class RoomsListBloc extends Bloc<RoomsListEvent, RoomsListState> {
  RoomsListBloc({required RoomRepository rooms, required LightRepository lights, required LiveStateStore store,
      required SettingsRepository settings, required AddRoom addRoom, required RenameRoom renameRoom, required DeleteRoom deleteRoom});
}
class RoomsScreen extends StatelessWidget {}
class GlyphPicker extends StatelessWidget { GlyphPicker({required RoomGlyph value, required ValueChanged<RoomGlyph> onChanged}); }
class RoomForm extends StatelessWidget { RoomForm({required TextEditingController controller, RoomGlyph? glyph, ValueChanged<RoomGlyph>? onGlyph, String placeholder}); }  // glyph row shown when glyph != null
Future<({String name, RoomGlyph glyph})?> showRoomSheet(BuildContext context, {required String title, required String primaryLabel, String initialName = '', RoomGlyph? initialGlyph, bool showNote = false});
Future<void> showRoomActionsSheet(BuildContext context, {required RoomRow row});
class RoomsNoticeListener extends StatelessWidget { RoomsNoticeListener({required Widget child}); }
// Strings
rooms, addRoom, addARoom, roomName, roomNamePlaceholder, glyph, saveRoom, roomSaved, renameRoom, deleteRoom, moveLightsFirst, newRoom, createRoom;
lightsOn(n, k), roomIsEmpty(name)
```

- [ ] **Step 1: Write the failing tests**

`test/features/rooms/bloc/rooms_list_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_event.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;

  RoomsListBloc build() => RoomsListBloc(
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    settings: seed.settings,
    addRoom: AddRoom(rooms: seed.rooms, ids: SequenceIds()),
    renameRoom: RenameRoom(rooms: seed.rooms),
    deleteRoom: DeleteRoom(rooms: seed.rooms, lights: seed.lights),
  );

  setUp(() => seed = SeedHome());

  const wait = Duration(milliseconds: 10);

  blocTest<RoomsListBloc, RoomsListState>(
    'lists the active home\'s rooms with their counts',
    build: build,
    act: (bloc) => bloc.add(const RoomsListSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, RoomsListStatus.ready);
      expect(s.homeId, 'h1');
      expect(s.rooms.map((r) => r.room.name), ['Living Room', 'Bedroom', 'Kitchen']);
      expect(s.rooms.map((r) => r.lightCount), [3, 2, 1]);
      expect(s.rooms.map((r) => r.onCount), [2, 0, 1]);
      expect(s.lightCount, 6);
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'adding a room appends it and raises the saved notice',
    build: build,
    act: (bloc) async {
      bloc.add(const RoomsListSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomAdded('Study', RoomGlyph.lampDesk));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.rooms.last.room.name, 'Study');
      expect(bloc.state.rooms.last.room.glyph, RoomGlyph.lampDesk);
      expect(bloc.state.rooms.last.room.sortIndex, 3);
      expect(bloc.state.notice, const RoomSavedNotice('Study'));
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'renaming keeps the glyph and the order',
    build: build,
    act: (bloc) async {
      bloc.add(const RoomsListSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomRenamed('bedroom', 'Master bedroom'));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.rooms[1].room.name, 'Master bedroom');
      expect(bloc.state.rooms[1].room.glyph, RoomGlyph.bed);
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'a room with lights refuses to go; an empty one goes',
    build: build,
    act: (bloc) async {
      bloc.add(const RoomsListSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomDeleted('living'));
      await Future<void>.delayed(wait);
      bloc.add(const RoomAdded('Garage', RoomGlyph.trees));
      await Future<void>.delayed(wait);
      bloc.add(const RoomsNoticeCleared());
      bloc.add(RoomDeleted(bloc.state.rooms.last.room.id));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.rooms.map((r) => r.room.name), ['Living Room', 'Bedroom', 'Kitchen']);
      expect(bloc.state.notice, isNull);
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'the refusal is an error notice with the spec\'s line',
    build: build,
    act: (bloc) => bloc
      ..add(const RoomsListSubscribed())
      ..add(const RoomDeleted('living')),
    wait: wait,
    verify: (bloc) =>
        expect(bloc.state.notice, const RoomsError('Move its lights first.')),
  );
}
```

`test/features/rooms/view/rooms_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_event.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';
import 'package:wizctl_app/features/rooms/widgets/rooms_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;
  late RoomsListBloc bloc;

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
    bloc = RoomsListBloc(
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      settings: scope.seed.settings,
      addRoom: AddRoom(rooms: scope.seed.rooms, ids: scope.ids),
      renameRoom: RenameRoom(rooms: scope.seed.rooms),
      deleteRoom: DeleteRoom(rooms: scope.seed.rooms, lights: scope.seed.lights),
    )..add(const RoomsListSubscribed());
  });

  tearDown(() async {
    await bloc.close();
    await scope.dispose();
  });

  Widget screen() => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const RoomsNoticeListener(child: RoomsScreen()),
    ),
  );

  testWidgets('lists the rooms with counts and the stored note', (tester) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('3 rooms · 6 lights'), findsOneWidget);
    expect(find.text('3 lights · 2 on'), findsOneWidget);
    expect(find.text('2 lights · 0 on'), findsOneWidget);
    expect(find.text('1 light · 1 on'), findsOneWidget);
    expect(find.text('ADD ROOM'), findsOneWidget);
    expect(
      find.text("Rooms are stored in this home's config file on this machine. Nothing is uploaded."),
      findsOneWidget,
    );
  });

  testWidgets('tapping a row opens the room', (tester) async {
    var router = await pumpRouted(tester, screen(), targets: [AppRoutes.roomPattern]);
    await tester.pump();
    await tester.tap(find.text('Kitchen'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/rooms/kitchen');
  });

  testWidgets('the add sheet saves a room and toasts', (tester) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.tap(find.byType(WizIconKey).first);
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'SAVE ROOM')).enabled, isFalse);
    await tester.enterText(find.byType(WizTextField), 'Study');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Lamp'));
    await tester.tap(find.text('SAVE ROOM'));
    await tester.pumpAndSettle();
    expect(find.text('Study'), findsOneWidget);
    expect(scope.toasts.toasts.single.title, 'Room saved');
    expect(scope.toasts.toasts.single.body, 'Study is empty — discover lights for it');
    expect(scope.seed.rooms.getByHome('h1'), completion(hasLength(4)));
  });

  testWidgets('long-pressing a room with lights offers rename but not delete', (
    tester,
  ) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.longPress(find.text('Living Room'));
    await tester.pumpAndSettle();
    expect(find.text('Rename room'), findsOneWidget);
    var delete = tester.widget<WizListRow>(find.widgetWithText(WizListRow, 'Delete room'));
    expect(delete.onTap, isNull);
    expect(find.text('Move its lights first'), findsOneWidget);
    await tester.tap(find.text('Rename room'));
    await tester.pumpAndSettle();
    expect(find.text('Rename room'), findsOneWidget, reason: 'the sheet title');
    await tester.enterText(find.byType(WizTextField), 'Lounge');
    await tester.tap(find.text('SAVE ROOM'));
    await tester.pumpAndSettle();
    expect(find.text('Lounge'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/rooms`
Expected: FAIL to compile.

- [ ] **Step 3: Write the bloc, the widgets and the screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Rooms (spec §10.6).
  static const rooms = 'Rooms';
  static const addRoom = 'Add room';
  static const addARoom = 'Add a room';
  static const roomName = 'Room name';
  static const roomNamePlaceholder = 'Study';
  static const glyph = 'Glyph';
  static const saveRoom = 'Save room';
  static const roomSaved = 'Room saved';
  static const renameRoom = 'Rename room';
  static const deleteRoom = 'Delete room';
  static const moveLightsFirst = 'Move its lights first';
  static const newRoom = 'New room';
  static const createRoom = 'Create room';
  static String lightsOn(int lights, int on) => '${plural(lights, 'light')} · $on on';
  static String roomIsEmpty(String name) => '$name is empty — discover lights for it';
```

`lib/features/rooms/bloc/rooms_list_event.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

sealed class RoomsListEvent extends Equatable {
  const RoomsListEvent();
  @override
  List<Object?> get props => const [];
}

final class RoomsListSubscribed extends RoomsListEvent {
  const RoomsListSubscribed();
}

final class RoomAdded extends RoomsListEvent {
  final String name;
  final RoomGlyph glyph;
  const RoomAdded(this.name, this.glyph);
  @override
  List<Object?> get props => [name, glyph];
}

final class RoomRenamed extends RoomsListEvent {
  final String roomId;
  final String name;
  const RoomRenamed(this.roomId, this.name);
  @override
  List<Object?> get props => [roomId, name];
}

final class RoomDeleted extends RoomsListEvent {
  final String roomId;
  const RoomDeleted(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

final class RoomsNoticeCleared extends RoomsListEvent {
  const RoomsNoticeCleared();
}
```

`lib/features/rooms/bloc/rooms_list_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

enum RoomsListStatus { loading, ready, noHome }

/// One list row: "<n> lights · <k> on".
class RoomRow extends Equatable {
  final Room room;
  final int lightCount;
  final int onCount;
  const RoomRow({
    required this.room,
    required this.lightCount,
    required this.onCount,
  });
  @override
  List<Object?> get props => [room, lightCount, onCount];
}

sealed class RoomsNotice extends Equatable {
  const RoomsNotice();
}

/// "Room saved" / "<name> is empty — discover lights for it" (spec §10.6).
final class RoomSavedNotice extends RoomsNotice {
  final String name;
  const RoomSavedNotice(this.name);
  @override
  List<Object?> get props => [name];
}

final class RoomsError extends RoomsNotice {
  final String message;
  const RoomsError(this.message);
  @override
  List<Object?> get props => [message];
}

class RoomsListState extends Equatable {
  final RoomsListStatus status;
  final String? homeId;
  final List<RoomRow> rooms;
  final int lightCount;
  final RoomsNotice? notice;

  const RoomsListState({
    required this.status,
    required this.homeId,
    required this.rooms,
    required this.lightCount,
    this.notice,
  });

  static const RoomsListState initial = RoomsListState(
    status: RoomsListStatus.loading,
    homeId: null,
    rooms: [],
    lightCount: 0,
  );

  RoomsListState copyWith({
    RoomsListStatus? status,
    String? homeId,
    List<RoomRow>? rooms,
    int? lightCount,
    RoomsNotice? notice,
    bool clearNotice = false,
  }) => RoomsListState(
    status: status ?? this.status,
    homeId: homeId ?? this.homeId,
    rooms: rooms ?? this.rooms,
    lightCount: lightCount ?? this.lightCount,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, homeId, rooms, lightCount, notice];
}
```

`lib/features/rooms/bloc/rooms_list_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/usecases/usecases.dart';
import 'rooms_list_event.dart';
import 'rooms_list_state.dart';

/// The Rooms tab (spec §8, §10.6): the active home's rooms with their
/// counts; add, rename and delete.
class RoomsListBloc extends Bloc<RoomsListEvent, RoomsListState> {
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final SettingsRepository _settings;
  final AddRoom _addRoom;
  final RenameRoom _renameRoom;
  final DeleteRoom _deleteRoom;

  RoomsListBloc({
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required SettingsRepository settings,
    required AddRoom addRoom,
    required RenameRoom renameRoom,
    required DeleteRoom deleteRoom,
  }) : _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _addRoom = addRoom, // ignore: prefer_initializing_formals
       _renameRoom = renameRoom, // ignore: prefer_initializing_formals
       _deleteRoom = deleteRoom, // ignore: prefer_initializing_formals
       super(RoomsListState.initial) {
    on<RoomsListSubscribed>(_onSubscribed);
    on<RoomAdded>(_onAdded);
    on<RoomRenamed>(_onRenamed);
    on<RoomDeleted>(_onDeleted);
    on<RoomsNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  Future<void> _onSubscribed(
    RoomsListSubscribed event,
    Emitter<RoomsListState> emit,
  ) async {
    var active = _settings.watch().map((s) => s.activeHomeId).distinct();
    await emit.forEach(
      active.asyncExpand(_forHome),
      onData: (next) => state.copyWith(
        status: next.status,
        homeId: next.homeId,
        rooms: next.rooms,
        lightCount: next.lightCount,
      ),
    );
  }

  Stream<RoomsListState> _forHome(String? homeId) {
    if (homeId == null) {
      return Stream.value(
        RoomsListState.initial.copyWith(status: RoomsListStatus.noHome),
      );
    }
    return combineLatest3(
      _rooms.watchByHome(homeId),
      _lights.watchByHome(homeId),
      _store.watchAll(),
    ).map((tuple) {
      var (rooms, lights, states) = tuple;
      bool isOn(Light l) => (states[l.id] ?? LiveState.initial).isOn;
      return RoomsListState(
        status: RoomsListStatus.ready,
        homeId: homeId,
        rooms: [
          for (var room in rooms)
            RoomRow(
              room: room,
              lightCount: lights.where((l) => l.roomId == room.id).length,
              onCount: lights
                  .where((l) => l.roomId == room.id && isOn(l))
                  .length,
            ),
        ],
        lightCount: lights.length,
      );
    });
  }

  Future<void> _onAdded(RoomAdded event, Emitter<RoomsListState> emit) async {
    var homeId = state.homeId;
    if (homeId == null) return;
    try {
      var room = await _addRoom(homeId, event.name, event.glyph);
      emit(state.copyWith(notice: RoomSavedNotice(room.name)));
    } on DomainException catch (e) {
      emit(state.copyWith(notice: RoomsError(e.message)));
    }
  }

  Future<void> _onRenamed(
    RoomRenamed event,
    Emitter<RoomsListState> emit,
  ) async {
    try {
      await _renameRoom(event.roomId, event.name);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: RoomsError(e.message)));
    }
  }

  Future<void> _onDeleted(
    RoomDeleted event,
    Emitter<RoomsListState> emit,
  ) async {
    try {
      await _deleteRoom(event.roomId);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: RoomsError(e.message)));
    }
  }
}
```

`lib/features/rooms/widgets/glyph_picker.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../domain/entities/entities.dart';

/// The six room glyphs as squircle keys, the chosen one amber (spec
/// §10.1, "GLYPH ×6"). The prototype's 48 squares are the kit's md key.
class GlyphPicker extends StatelessWidget {
  final RoomGlyph value;
  final ValueChanged<RoomGlyph> onChanged;

  const GlyphPicker({super.key, required this.value, required this.onChanged});

  /// What the screen reader calls each glyph.
  static String labelFor(RoomGlyph glyph) => switch (glyph) {
    RoomGlyph.sofa => 'Sofa',
    RoomGlyph.bed => 'Bed',
    RoomGlyph.utensils => 'Kitchen',
    RoomGlyph.bath => 'Bath',
    RoomGlyph.lampDesk => 'Lamp',
    RoomGlyph.trees => 'Trees',
  };

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Wrap(
      spacing: space.s4,
      runSpacing: space.s4,
      children: [
        for (var glyph in RoomGlyph.values)
          WizIconKey(
            icon: WizIcons.byName(glyph.iconName)!,
            shape: WizKeyShape.squircle,
            active: glyph == value,
            semanticsLabel: labelFor(glyph),
            onPressed: () => onChanged(glyph),
          ),
      ],
    );
  }
}
```

`lib/features/rooms/widgets/room_form.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../../../domain/entities/entities.dart';
import 'glyph_picker.dart';

/// ROOM NAME and, when a glyph is given, GLYPH: the body of the add, new
/// and rename room sheets (spec §10.1, §10.6).
class RoomForm extends StatelessWidget {
  final TextEditingController controller;
  final RoomGlyph? glyph;
  final ValueChanged<RoomGlyph>? onGlyph;
  final String placeholder;

  const RoomForm({
    super.key,
    required this.controller,
    this.glyph,
    this.onGlyph,
    this.placeholder = Strings.roomNamePlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var glyph = this.glyph;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel(Strings.roomName),
        SizedBox(height: space.s3),
        WizTextField(
          controller: controller,
          placeholder: placeholder,
          autofocus: true,
        ),
        if (glyph != null) ...[
          SizedBox(height: space.s6),
          const FieldLabel(Strings.glyph),
          SizedBox(height: space.s3),
          GlyphPicker(value: glyph, onChanged: onGlyph ?? (_) {}),
        ],
      ],
    );
  }
}
```

`lib/features/rooms/widgets/add_room_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/entities/entities.dart';
import 'room_form.dart';

/// A room sheet: "Add a room" (spec §10.6), "New room" (spec §10.1) and
/// "Rename room" are the same form with different titles, keys and
/// starting values. Resolves to the name and glyph, or null on Cancel.
/// The primary key is disabled until the name is non-blank.
Future<({String name, RoomGlyph glyph})?> showRoomSheet(
  BuildContext context, {
  required String title,
  required String primaryLabel,
  String initialName = '',
  RoomGlyph? initialGlyph = RoomGlyph.sofa,
  bool showNote = false,
}) {
  var navigator = Navigator.of(context, rootNavigator: true);
  var controller = TextEditingController(text: initialName);
  var glyph = ValueNotifier<RoomGlyph>(initialGlyph ?? RoomGlyph.sofa);
  return showWizSheet<({String name, RoomGlyph glyph})>(
    context,
    title: title,
    builder: (context) => ValueListenableBuilder(
      valueListenable: glyph,
      builder: (context, value, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RoomForm(
            controller: controller,
            glyph: initialGlyph == null ? null : value,
            onGlyph: (g) => glyph.value = g,
          ),
          if (showNote) ...[
            SizedBox(height: context.wiz.space.s6),
            WizPanel(
              variant: WizPanelVariant.inset,
              child: Text(
                Strings.roomsStored,
                style: context.wiz.typography.bodySm.copyWith(
                  color: context.wiz.colors.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, text, _) => WizButton(
          label: primaryLabel,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: text.text.trim().isNotEmpty,
          onPressed: () => navigator.pop(
            (name: controller.text.trim(), glyph: glyph.value),
          ),
        ),
      ),
    ],
  ).whenComplete(() {
    controller.dispose();
    glyph.dispose();
  });
}
```

`lib/features/rooms/widgets/room_actions_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../bloc/rooms_list_bloc.dart';
import '../bloc/rooms_list_event.dart';
import '../bloc/rooms_list_state.dart';
import 'add_room_sheet.dart';

/// Long-press on a room row (spec §10.6): Rename room, and Delete room,
/// which is inert with "Move its lights first" while the room holds any.
Future<void> showRoomActionsSheet(
  BuildContext context, {
  required RoomRow row,
}) {
  var bloc = context.read<RoomsListBloc>();
  var navigator = Navigator.of(context, rootNavigator: true);
  var hasLights = row.lightCount > 0;
  return showWizSheet<void>(
    context,
    title: row.room.name,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WizListRow(
          icon: WizIcons.pencil,
          title: Strings.renameRoom,
          onTap: () async {
            navigator.pop();
            var result = await showRoomSheet(
              context,
              title: Strings.renameRoom,
              primaryLabel: Strings.saveRoom,
              initialName: row.room.name,
              initialGlyph: null,
            );
            if (result != null) {
              bloc.add(RoomRenamed(row.room.id, result.name));
            }
          },
        ),
        SizedBox(height: context.wiz.space.s3),
        WizListRow(
          icon: WizIcons.trash,
          title: Strings.deleteRoom,
          meta: hasLights ? Strings.moveLightsFirst : null,
          onTap: hasLights
              ? null
              : () {
                  bloc.add(RoomDeleted(row.room.id));
                  navigator.pop();
                },
        ),
      ],
    ),
  );
}
```

The rename row pops the actions sheet and then opens the rename sheet with the *screen's* context (the one `showRoomActionsSheet` received), which is still mounted; `showRoomSheet` reads the root navigator from it.

`lib/features/rooms/widgets/rooms_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/rooms_list_bloc.dart';
import '../bloc/rooms_list_event.dart';
import '../bloc/rooms_list_state.dart';

/// "Room saved" and the odd error, as toasts.
class RoomsNoticeListener extends StatelessWidget {
  final Widget child;
  const RoomsNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomsListBloc, RoomsListState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        switch (state.notice!) {
          case RoomSavedNotice(:var name):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.roomSaved,
              body: Strings.roomIsEmpty(name),
            );
          case RoomsError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
        context.read<RoomsListBloc>().add(const RoomsNoticeCleared());
      },
      child: child,
    );
  }
}
```

`lib/features/rooms/view/rooms_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/rooms_list_bloc.dart';
import '../bloc/rooms_list_event.dart';
import '../bloc/rooms_list_state.dart';
import '../widgets/add_room_sheet.dart';
import '../widgets/room_actions_sheet.dart';

/// The Rooms tab (spec §10.6).
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  /// The chevron at the end of a row (`WizCtl_Mobile.dc.html` line 416).
  static const double chevron = 18;

  Future<void> _add(BuildContext context) async {
    var bloc = context.read<RoomsListBloc>();
    var result = await showRoomSheet(
      context,
      title: Strings.addARoom,
      primaryLabel: Strings.saveRoom,
      showNote: true,
    );
    if (result != null) bloc.add(RoomAdded(result.name, result.glyph));
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<RoomsListBloc, RoomsListState>(
      builder: (context, state) => ScreenScroll(
        gap: wiz.space.s5,
        children: [
          WizTopBar(
            title: Strings.rooms,
            subtitle: Strings.roomsAndLights(state.rooms.length, state.lightCount),
            trailing: WizIconKey(
              icon: WizIcons.plus,
              semanticsLabel: Strings.addRoom,
              onPressed: () => _add(context),
            ),
          ),
          for (var (i, row) in state.rooms.indexed)
            RiseIn(
              index: i,
              child: WizListRow(
                icon: WizIcons.byName(row.room.glyph.iconName)!,
                title: row.room.name,
                meta: Strings.lightsOn(row.lightCount, row.onCount),
                trailing: WizIcon(
                  WizIcons.chevronRight,
                  size: chevron,
                  color: wiz.colors.textTertiary,
                ),
                onTap: () => context.go(AppRoutes.room(row.room.id)),
                onLongPress: () => showRoomActionsSheet(context, row: row),
              ),
            ),
          WizButton(
            label: Strings.addRoom,
            variant: WizButtonVariant.ghost,
            icon: WizIcons.housePlus,
            fullWidth: true,
            onPressed: () => _add(context),
          ),
          WizPanel(
            variant: WizPanelVariant.inset,
            child: Text(
              Strings.roomsStored,
              style: wiz.typography.bodySm.copyWith(
                color: wiz.colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/rooms`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/rooms lib/core/copy/strings.dart test/features/rooms
git commit -m "feat(rooms): the Rooms tab with its bloc, add sheet and long-press actions"
```

---

### Task 8: LightModesBloc, and a throttle key for colour

**Files:**
- Modify: `lib/domain/usecases/apply_colour.dart`, `test/domain/usecases/control_usecases_test.dart`
- Create: `lib/features/modes/bloc/light_modes_bloc.dart`, `lib/features/modes/bloc/light_modes_event.dart`, `lib/features/modes/bloc/light_modes_state.dart`
- Test: `test/features/modes/bloc/light_modes_bloc_test.dart`

**Interfaces:**
- Consumes: `ModeTarget` (`WholeHomeTarget(homeId)`, `RoomTarget(roomId)`, `LightTarget(lightId)`), `LightRepository.watchByHome/watchByRoom/watch`, `RoomRepository.get`, `LiveStateStore.watchAll`, `ApplyColour(target, rgb)`, `ApplyWhite(target, kelvin)`, `ApplyScene(target, id, {speed})` (each returns the count written), `SetSpeed(target, speed)`, `ModeSummarizer.sceneName/allOnOneDynamicScene`, `CapabilityRules.colour/isDynamicScene`, `LiveLight`, `combineLatest2`.
- Produces:

```dart
enum ModesTab { colour, staticScenes, dynamicScenes }
sealed class LightModesEvent; final class ModesSubscribed, ModesTargetChanged(ModeTarget target), ModesTabChanged(ModesTab tab),
    ColourPicked(Rgb rgb), WhitePicked(int kelvin), ScenePicked(int sceneId), SpeedChanged(int speed), ModesNoticeCleared
sealed class ModesNotice; final class SceneAppliedNotice(String sceneName, ModeTarget target, String? targetName),
    NoColourNotice, NoWhiteNotice, NoSceneNotice
class LightModesState extends Equatable {
  ModesStatus status; ModeTarget target; String? targetName; ModesTab tab; List<LiveLight> lights; ModesNotice? notice;
  bool get hasWheel; Rgb get wheelRgb; bool get speedVisible; int get speed; int? get currentScene; bool get isEmpty;
}
class LightModesBloc extends Bloc<LightModesEvent, LightModesState> {
  LightModesBloc({required ModeTarget target, required RoomRepository rooms, required LightRepository lights,
      required LiveStateStore store, required ApplyColour applyColour, required ApplyWhite applyWhite,
      required ApplyScene applyScene, required SetSpeed setSpeed});
}
```

- [ ] **Step 1: Write the failing tests**

Append to `test/domain/usecases/control_usecases_test.dart`:

```dart
  test('colour writes coalesce while one is in flight, like a dial drag', () async {
    gateway.sendLatency = const Duration(milliseconds: 20);
    var apply = ApplyColour(resolver: resolver, store: store, pipeline: pipeline);
    var target = const LightTarget('1');
    var writes = [
      apply(target, const Rgb(255, 0, 0)),
      apply(target, const Rgb(0, 255, 0)),
      apply(target, const Rgb(0, 0, 255)),
    ];
    await Future.wait(writes);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(gateway.sends.map((s) => s.$2.b), [0, 255],
        reason: 'the first goes at once; only the latest of the rest follows');
    expect(store.of('1').rgb, const Rgb(0, 0, 255));
  });
```

`test/features/modes/bloc/light_modes_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_bloc.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_event.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late TargetResolver resolver;

  LightModesBloc build(ModeTarget target) => LightModesBloc(
    target: target,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    applyColour: ApplyColour(resolver: resolver, store: seed.store, pipeline: pipeline),
    applyWhite: ApplyWhite(resolver: resolver, store: seed.store, pipeline: pipeline),
    applyScene: ApplyScene(resolver: resolver, store: seed.store, pipeline: pipeline),
    setSpeed: SetSpeed(resolver: resolver, store: seed.store, pipeline: pipeline),
  );

  setUp(() async {
    seed = SeedHome();
    gateway = FakeGateway();
    monitor = NetworkMonitor(FakeNetworkInfo('192.168.1'));
    await monitor.refresh();
    resolver = TargetResolver(seed.lights);
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: FakeClock(),
      ids: SequenceIds(),
    );
  });

  tearDown(() {
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<LightModesBloc, LightModesState>(
    'a room target lists its lights, has a wheel when one is RGB, and reads the first RGB colour',
    build: () => build(const RoomTarget('living')),
    act: (bloc) => bloc.add(const ModesSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, ModesStatus.ready);
      expect(s.targetName, 'Living Room');
      expect(s.lights.map((l) => l.light.id), ['dome', 'floor', 'strip']);
      expect(s.hasWheel, isTrue);
      expect(s.wheelRgb, Rgb.amber, reason: 'the dome is the first RGB light');
      expect(s.tab, ModesTab.colour);
      expect(s.speedVisible, isFalse, reason: 'not all on one dynamic scene');
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'the whole home has no name of its own; a light target has its name and no wheel when it dims only',
    build: () => build(const LightTarget('hall')),
    act: (bloc) => bloc.add(const ModesSubscribed()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.targetName, 'Hallway');
      expect(bloc.state.hasWheel, isFalse);
      expect(bloc.state.lights, hasLength(1));
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'changing the target re-subscribes',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ModesTargetChanged(WholeHomeTarget('h1')));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.target, const WholeHomeTarget('h1'));
      expect(bloc.state.targetName, isNull);
      expect(bloc.state.lights, hasLength(6));
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'a colour reaches the RGB lights of the target; a white the RGB and tunable ones',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ColourPicked(Rgb(255, 0, 0)));
      await Future<void>.delayed(wait);
      bloc.add(const WhitePicked(4000));
    },
    wait: wait,
    verify: (bloc) {
      var colour = gateway.sends.where((s) => s.$2.r == 255).map((s) => s.$1);
      expect(colour, ['192.168.1.104', '192.168.1.107']);
      var white = gateway.sends.where((s) => s.$2.temperature == 4000).map((s) => s.$1);
      expect(white, ['192.168.1.104', '192.168.1.107', '192.168.1.111']);
      expect(bloc.state.notice, isNull);
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'nothing eligible is a notice, not a write',
    build: () => build(const LightTarget('hall')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ColourPicked(Rgb(255, 0, 0)));
      await Future<void>.delayed(wait);
      expect(bloc.state.notice, const NoColourNotice());
      bloc.add(const ModesNoticeCleared());
      bloc.add(const WhitePicked(4000));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, isEmpty);
      expect(bloc.state.notice, const NoWhiteNotice());
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'a scene applies with the speed on dynamic ones and reports where it went',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ModesTabChanged(ModesTab.dynamicScenes));
      bloc.add(const ScenePicked(1));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, hasLength(3), reason: 'no plug in the living room');
      expect(gateway.sends.every((s) => s.$2.sceneId == 1 && s.$2.speed != null), isTrue);
      expect(
        bloc.state.notice,
        const SceneAppliedNotice('Ocean', RoomTarget('living'), 'Living Room'),
      );
      expect(bloc.state.speedVisible, isTrue, reason: 'now all on one dynamic scene');
      expect(bloc.state.currentScene, 1);
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'speed reaches the lights on a dynamic scene',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ScenePicked(1));
      await Future<void>.delayed(wait);
      gateway.sends.clear();
      bloc.add(const SpeedChanged(180));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, hasLength(3));
      expect(gateway.sends.first.$2.speed, 180);
      expect(bloc.state.speed, 180);
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'a plug alone has no scene channel',
    build: () {
      seed.lights.seed([
        Light(
          id: 'plug', homeId: 'h1', roomId: 'kitchen', name: 'Plug by the TV',
          ip: '192.168.1.140', mac: 'plug', bulbClass: BulbClass.socket,
          fixture: Fixture.socket, sortIndex: 9, addedAt: DateTime(2026),
        ),
      ]);
      return build(const LightTarget('plug'));
    },
    act: (bloc) => bloc
      ..add(const ModesSubscribed())
      ..add(const ScenePicked(6)),
    wait: wait,
    verify: (bloc) => expect(bloc.state.notice, const NoSceneNotice()),
  );
}
```

(`import 'package:wizctl/wizctl.dart';` for `BulbClass` in the last test.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/usecases/control_usecases_test.dart test/features/modes`
Expected: the coalescing test fails with three sends; the bloc tests fail to compile.

- [ ] **Step 3: Give colour its key, then write the bloc**

In `lib/domain/usecases/apply_colour.dart`, pass `throttleKey: 'colour:${target.key}'` to `dispatch` (the same shape `SetBrightness` uses), and extend the class doc: "Coalesces like a dial drag, so the wheel can write on every move."

`lib/features/modes/bloc/light_modes_event.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import 'light_modes_state.dart';

sealed class LightModesEvent extends Equatable {
  const LightModesEvent();
  @override
  List<Object?> get props => const [];
}

final class ModesSubscribed extends LightModesEvent {
  const ModesSubscribed();
}

final class ModesTargetChanged extends LightModesEvent {
  final ModeTarget target;
  const ModesTargetChanged(this.target);
  @override
  List<Object?> get props => [target];
}

final class ModesTabChanged extends LightModesEvent {
  final ModesTab tab;
  const ModesTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

/// A swatch, or a wheel position the view has already turned into a colour.
final class ColourPicked extends LightModesEvent {
  final Rgb rgb;
  const ColourPicked(this.rgb);
  @override
  List<Object?> get props => [rgb];
}

final class WhitePicked extends LightModesEvent {
  final int kelvin;
  const WhitePicked(this.kelvin);
  @override
  List<Object?> get props => [kelvin];
}

final class ScenePicked extends LightModesEvent {
  final int sceneId;
  const ScenePicked(this.sceneId);
  @override
  List<Object?> get props => [sceneId];
}

final class SpeedChanged extends LightModesEvent {
  final int speed;
  const SpeedChanged(this.speed);
  @override
  List<Object?> get props => [speed];
}

final class ModesNoticeCleared extends LightModesEvent {
  const ModesNoticeCleared();
}
```

`lib/features/modes/bloc/light_modes_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/capability_rules.dart';
import '../../../domain/services/mode_summarizer.dart';

enum ModesStatus { loading, ready }

/// The segmented control (spec §10.5).
enum ModesTab { colour, staticScenes, dynamicScenes }

sealed class ModesNotice extends Equatable {
  const ModesNotice();
  @override
  List<Object?> get props => const [];
}

/// "<Scene> applied" / "to the whole home" · "to <room>" · "to <light>".
final class SceneAppliedNotice extends ModesNotice {
  final String sceneName;
  final ModeTarget target;
  final String? targetName;
  const SceneAppliedNotice(this.sceneName, this.target, this.targetName);
  @override
  List<Object?> get props => [sceneName, target, targetName];
}

final class NoColourNotice extends ModesNotice {
  const NoColourNotice();
}

final class NoWhiteNotice extends ModesNotice {
  const NoWhiteNotice();
}

final class NoSceneNotice extends ModesNotice {
  const NoSceneNotice();
}

class LightModesState extends Equatable {
  final ModesStatus status;
  final ModeTarget target;

  /// The room's or light's name; null for the whole home, which the view
  /// names itself.
  final String? targetName;
  final ModesTab tab;
  final List<LiveLight> lights;
  final ModesNotice? notice;

  const LightModesState({
    required this.status,
    required this.target,
    required this.targetName,
    required this.tab,
    required this.lights,
    this.notice,
  });

  /// The wheel shows only when the target holds a colour bulb (spec §10.5).
  bool get hasWheel =>
      lights.any((l) => CapabilityRules.colour(l.light.bulbClass));

  /// Where the puck sits: the first colour bulb's last colour.
  Rgb get wheelRgb {
    for (var l in lights) {
      if (CapabilityRules.colour(l.light.bulbClass)) return l.state.rgb;
    }
    return Rgb.warm;
  }

  /// The speed rail shows only when the whole target is on one dynamic
  /// scene (spec §5.3).
  bool get speedVisible => ModeSummarizer.allOnOneDynamicScene(lights);

  int get speed => lights.isEmpty ? defaultSpeedFallback : lights.first.state.speed;

  /// The scene every target light is on, or null.
  int? get currentScene {
    if (lights.isEmpty) return null;
    var first = lights.first.state;
    if (first.active != ActiveChannel.scene) return null;
    return ModeSummarizer.sceneSelected(lights, first.sceneId)
        ? first.sceneId
        : null;
  }

  bool get isEmpty => lights.isEmpty;

  /// What the rail reads before any light is known; the library's default.
  static const int defaultSpeedFallback = 100;

  LightModesState copyWith({
    ModesStatus? status,
    ModeTarget? target,
    String? targetName,
    bool clearTargetName = false,
    ModesTab? tab,
    List<LiveLight>? lights,
    ModesNotice? notice,
    bool clearNotice = false,
  }) => LightModesState(
    status: status ?? this.status,
    target: target ?? this.target,
    targetName: clearTargetName ? null : targetName ?? this.targetName,
    tab: tab ?? this.tab,
    lights: lights ?? this.lights,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, target, targetName, tab, lights, notice];
}
```

Use `defaultSpeed` from `package:wizctl` for the fallback instead of a literal if the import is acceptable to the layering test (it is: `package:wizctl` is allowed). Replace `defaultSpeedFallback` with `defaultSpeed` and delete the constant.

`lib/features/modes/bloc/light_modes_bloc.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/services/capability_rules.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/usecases/usecases.dart';
import 'light_modes_event.dart';
import 'light_modes_state.dart';

/// The modes sheet and the Scenes tab (spec §8, §10.5): the target's lights
/// live, what is selected, and the four writes. One tap applies.
class LightModesBloc extends Bloc<LightModesEvent, LightModesState> {
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final ApplyColour _applyColour;
  final ApplyWhite _applyWhite;
  final ApplyScene _applyScene;
  final SetSpeed _setSpeed;
  final StreamController<ModeTarget> _targets = StreamController();

  LightModesBloc({
    required ModeTarget target,
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required ApplyColour applyColour,
    required ApplyWhite applyWhite,
    required ApplyScene applyScene,
    required SetSpeed setSpeed,
  }) : _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _applyColour = applyColour, // ignore: prefer_initializing_formals
       _applyWhite = applyWhite, // ignore: prefer_initializing_formals
       _applyScene = applyScene, // ignore: prefer_initializing_formals
       _setSpeed = setSpeed, // ignore: prefer_initializing_formals
       super(
         LightModesState(
           status: ModesStatus.loading,
           target: target,
           targetName: null,
           tab: ModesTab.colour,
           lights: const [],
         ),
       ) {
    on<ModesSubscribed>(_onSubscribed);
    on<ModesTargetChanged>((event, emit) {
      emit(state.copyWith(target: event.target, status: ModesStatus.loading));
      _targets.add(event.target);
    });
    on<ModesTabChanged>((event, emit) => emit(state.copyWith(tab: event.tab)));
    on<ColourPicked>(_onColour);
    on<WhitePicked>(_onWhite);
    on<ScenePicked>(_onScene);
    on<SpeedChanged>(_onSpeed);
    on<ModesNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  Future<void> _onSubscribed(
    ModesSubscribed event,
    Emitter<LightModesState> emit,
  ) async {
    var targets = Stream.value(state.target).followedBy(_targets.stream);
    await emit.forEach(
      targets.asyncExpand(_forTarget),
      onData: (next) => state.copyWith(
        status: ModesStatus.ready,
        target: next.target,
        targetName: next.name,
        clearTargetName: next.name == null,
        lights: next.lights,
      ),
    );
  }

  Stream<({ModeTarget target, String? name, List<LiveLight> lights})>
  _forTarget(ModeTarget target) {
    Stream<List<Light>> lights;
    Future<String?> name;
    switch (target) {
      case WholeHomeTarget(:var homeId):
        lights = _lights.watchByHome(homeId);
        name = Future.value(null);
      case RoomTarget(:var roomId):
        lights = _lights.watchByRoom(roomId);
        name = _rooms.get(roomId).then((r) => r?.name);
      case LightTarget(:var lightId):
        lights = _lights.watch(lightId).map((l) => [?l]);
        name = _lights.get(lightId).then((l) => l?.name);
    }
    return Stream.fromFuture(name).asyncExpand(
      (name) => combineLatest2(lights, _store.watchAll()).map((tuple) {
        var (list, states) = tuple;
        return (
          target: target,
          name: name,
          lights: [
            for (var l in list)
              (light: l, state: states[l.id] ?? LiveState.initial),
          ],
        );
      }),
    );
  }

  Future<void> _onColour(
    ColourPicked event,
    Emitter<LightModesState> emit,
  ) async {
    var written = await _applyColour(state.target, event.rgb);
    if (written == 0) emit(state.copyWith(notice: const NoColourNotice()));
  }

  Future<void> _onWhite(
    WhitePicked event,
    Emitter<LightModesState> emit,
  ) async {
    var written = await _applyWhite(state.target, event.kelvin);
    if (written == 0) emit(state.copyWith(notice: const NoWhiteNotice()));
  }

  Future<void> _onScene(
    ScenePicked event,
    Emitter<LightModesState> emit,
  ) async {
    var speed = CapabilityRules.isDynamicScene(event.sceneId)
        ? state.speed
        : null;
    var written = await _applyScene(state.target, event.sceneId, speed: speed);
    if (written == 0) {
      emit(state.copyWith(notice: const NoSceneNotice()));
      return;
    }
    emit(
      state.copyWith(
        notice: SceneAppliedNotice(
          ModeSummarizer.sceneName(event.sceneId),
          state.target,
          state.targetName,
        ),
      ),
    );
  }

  Future<void> _onSpeed(SpeedChanged event, Emitter<LightModesState> emit) =>
      _setSpeed(state.target, event.speed);

  @override
  Future<void> close() async {
    await _targets.close();
    return super.close();
  }
}
```

`Stream.value(x).followedBy(...)` is not a `Stream` method; write the target stream as an `async*` generator instead:

```dart
  Stream<ModeTarget> _targetStream() async* {
    yield state.target;
    yield* _targets.stream;
  }
```

and use `_targetStream().asyncExpand(_forTarget)` in `_onSubscribed`. (`[?l]` is the null-aware element of Dart 3.8+, already used by `TargetResolver`.)

- [ ] **Step 4: Run the tests**

Run: `flutter test test/domain/usecases/control_usecases_test.dart test/features/modes test/features/layering_test.dart`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/domain/usecases/apply_colour.dart test/domain/usecases/control_usecases_test.dart lib/features/modes/bloc test/features/modes
git commit -m "feat(modes): LightModesBloc, and colour writes coalesce like a drag"
```

---

### Task 9: The modes body, the sheet, the Scenes tab and the target sheet

**Files:**
- Create: `lib/features/modes/widgets/modes_layout.dart`, `lib/features/modes/widgets/modes_body.dart`, `lib/features/modes/widgets/colour_tab.dart`, `lib/features/modes/widgets/scenes_tab.dart`, `lib/features/modes/widgets/swatch_row.dart`, `lib/features/modes/widgets/target_sheet.dart`, `lib/features/modes/widgets/modes_notice_listener.dart`, `lib/features/modes/view/modes_sheet.dart`, `lib/features/modes/view/modes_screen.dart`
- Modify: `lib/core/copy/strings.dart`
- Test: `test/features/modes/view/modes_sheet_test.dart`, `test/features/modes/view/modes_screen_test.dart`

**Interfaces:**
- Consumes: `LightModesBloc` (Task 8), `WizSegmentedControl`/`WizSegment`, `WizColorWheel`/`WizHsv`, `WizSlider`/`WizSliderFill.speed`, `WizSceneTile`/`WizSceneTileVariant`, `WizGrid`, `WizPressable`, `WizSurface`, `WizListRow`, `WizTopBar`, `WizPanel`, `showWizSheet`, `ScreenScroll`, `FieldLabel`, `sceneGradients`/`staticScenes`/`dynamicScenes`, `hsvToColor`/`colorToHs`, `ModeSummarizer.colourSelected/whiteSelected/sceneSelected/sceneName`, `WizColors.hues/kelvinStops`, `AppDependencies`-free construction through the use-case getters the caller passes.
- Produces:

```dart
enum ModesLayout { compactTab, desktopTab, sheet, dialog }   // with a const geometry table
class ModesBody extends StatelessWidget { ModesBody({required ModesLayout layout}); }
class ColourTab, ScenesTab, SwatchRow (internal to the body)
Future<ModeTarget?> showTargetSheet(BuildContext context, {required String homeId, required ModeTarget current});
Future<void> showModesSheet(BuildContext context, {required ModeTarget target, required LightModesBloc Function(ModeTarget) blocFor});
class ModesNoticeListener extends StatelessWidget { ModesNoticeListener({required Widget child}); }
class ModesScreen extends StatelessWidget { ModesScreen({required String homeId}); }   // the /modes tab; expects a LightModesBloc above it
// Strings
lightModes, applyTo, applyScenesTo, colours, whites, staticTab ('Static'), dynamicTab ('Dynamic'), dynamicNote, staticNote,
noColourBulb, colourNeedsRgb, noWhiteChannel, bulbsOnlyDim, noSceneChannel, plugOnlySwitches, toWholeHome, speed;
modesSubtitle(staticCount, dynamicCount), lightModeFor(name), lightModeWholeHome, sceneApplied(name), toTarget(name), speedFor(scene), kelvinLabel(k)
```

- [ ] **Step 1: Write the failing tests**

`test/features/modes/view/modes_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_bloc.dart';
import 'package:wizctl_app/features/modes/view/modes_sheet.dart';
import 'package:wizctl_app/features/modes/widgets/swatch_row.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
  });

  tearDown(() => scope.dispose());

  LightModesBloc blocFor(ModeTarget target) => LightModesBloc(
    target: target,
    rooms: scope.seed.rooms,
    lights: scope.seed.lights,
    store: scope.seed.store,
    applyColour: scope.applyColour,
    applyWhite: scope.applyWhite,
    applyScene: scope.applyScene,
    setSpeed: scope.setSpeed,
  );

  Widget opener(ModeTarget target) => scope.wrap(
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showModesSheet(context, target: target, blocFor: blocFor),
          child: const Text('open'),
        ),
      ),
    ),
  );

  testWidgets('a room sheet: title, three tabs, the wheel and both swatch rows', (
    tester,
  ) async {
    await pumpRouted(tester, opener(const RoomTarget('living')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Light mode · Living Room'), findsOneWidget);
    expect(find.text('COLOUR'), findsOneWidget);
    expect(find.text('STATIC'), findsOneWidget);
    expect(find.text('DYNAMIC'), findsOneWidget);
    expect(find.byType(WizColorWheel), findsOneWidget);
    expect(find.byType(Swatch), findsNWidgets(12));
    expect(find.byType(WhiteTile), findsNWidgets(6));
    expect(find.text('2700K'), findsOneWidget);
  });

  testWidgets('a swatch writes the colour to the RGB lights', (tester) async {
    await pumpRouted(tester, opener(const RoomTarget('living')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Red'));
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends.map((s) => s.$1), ['192.168.1.104', '192.168.1.107']);
    expect(scope.gateway.sends.first.$2.r, 255);
  });

  testWidgets('a dim-only light gets no wheel and colour is refused with a toast', (
    tester,
  ) async {
    await pumpRouted(tester, opener(const LightTarget('hall')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(WizColorWheel), findsNothing);
    await tester.tap(find.bySemanticsLabel('Red'));
    await tester.pumpAndSettle();
    expect(scope.toasts.toasts.single.title, 'No colour bulb here');
    expect(scope.toasts.toasts.single.body, 'Colour needs an RGB bulb.');
  });

  testWidgets('the static tab lists the static scenes; a tap applies and toasts', (
    tester,
  ) async {
    await pumpRouted(tester, opener(const RoomTarget('living')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STATIC'));
    await tester.pumpAndSettle();
    expect(find.byType(WizSceneTile), findsNWidgets(staticScenes.length));
    expect(find.text('Static scenes hold one look. The bulb ignores speed.'), findsOneWidget);
    await tester.tap(find.text('Cozy'));
    await tester.pumpAndSettle();
    expect(scope.gateway.sends, hasLength(3));
    expect(scope.toasts.toasts.single.title, 'Cozy applied');
    expect(scope.toasts.toasts.single.body, 'to Living Room');
  });

  testWidgets('the dynamic tab shows the speed rail once all lights share a dynamic scene', (
    tester,
  ) async {
    await pumpRouted(tester, opener(const RoomTarget('living')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DYNAMIC'));
    await tester.pumpAndSettle();
    expect(find.byType(WizSlider), findsNothing);
    expect(find.byType(WizSceneTile), findsNWidgets(dynamicScenes.length));
    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    expect(find.byType(WizSlider), findsOneWidget);
    expect(find.text('Speed — Ocean'), findsOneWidget);
    expect(find.text('Dynamic scenes cycle. Speed runs from 10 to 200.'), findsOneWidget);
  });

  testWidgets('on a wide surface the sheet is a dialog with the desktop wheel', (
    tester,
  ) async {
    await setSurface(tester, const Size(1200, 800));
    await pumpRouted(tester, opener(const WholeHomeTarget('h1')), size: const Size(1200, 800));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Light mode · whole home'), findsOneWidget);
    expect(tester.widget<WizColorWheel>(find.byType(WizColorWheel)).size, 216);
  });
}
```

(`setSurface` comes from `../../../support/wiz_test_app.dart`; add the import.)

`test/features/modes/view/modes_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_bloc.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_event.dart';
import 'package:wizctl_app/features/modes/view/modes_screen.dart';
import 'package:wizctl_app/features/modes/widgets/modes_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;
  late LightModesBloc bloc;

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
    bloc = LightModesBloc(
      target: const WholeHomeTarget('h1'),
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      applyColour: scope.applyColour,
      applyWhite: scope.applyWhite,
      applyScene: scope.applyScene,
      setSpeed: scope.setSpeed,
    )..add(const ModesSubscribed());
  });

  tearDown(() async {
    await bloc.close();
    await scope.dispose();
  });

  Widget screen() => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const ModesNoticeListener(child: ModesScreen(homeId: 'h1')),
    ),
  );

  testWidgets('the tab names the target and counts the scenes truthfully', (
    tester,
  ) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('Light modes'), findsOneWidget);
    expect(
      find.text('Colour, ${staticScenes.length} static and ${dynamicScenes.length} dynamic scenes'),
      findsOneWidget,
    );
    expect(find.text('APPLY TO'), findsOneWidget);
    expect(find.text('Whole home'), findsOneWidget);
  });

  testWidgets('the target sheet lists home, rooms and lights and re-targets', (
    tester,
  ) async {
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.tap(find.text('Whole home'));
    await tester.pumpAndSettle();
    expect(find.text('Apply scenes to'), findsOneWidget);
    expect(find.widgetWithText(WizListRow, 'Whole home'), findsOneWidget);
    expect(find.text('6 lights'), findsOneWidget);
    expect(find.text('Bedside bulb'), findsOneWidget);
    expect(find.text('192.168.1.115'), findsOneWidget);
    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    expect(bloc.state.target, const RoomTarget('bedroom'));
    expect(find.text('Bedroom'), findsOneWidget, reason: 'the well key now names it');
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/modes/view`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the layout table, the tabs, the sheets and the tab screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Light modes (spec §10.5, §5.12).
  static const lightModes = 'Light modes';
  static const applyScenesTo = 'Apply scenes to';
  static const colours = 'Colours';
  static const whites = 'Whites';
  static const staticTab = 'Static';
  static const dynamicTab = 'Dynamic';
  static const dynamicNote = 'Dynamic scenes cycle. Speed runs from 10 to 200.';
  static const staticNote = 'Static scenes hold one look. The bulb ignores speed.';
  static const noColourBulb = 'No colour bulb here';
  static const colourNeedsRgb = 'Colour needs an RGB bulb.';
  static const noWhiteChannel = 'No white channel here';
  static const bulbsOnlyDim = 'These bulbs only dim.';
  static const noSceneChannel = 'No scene channel here';
  static const plugOnlySwitches = 'A plug only switches power.';
  static const toWholeHome = 'to the whole home';
  static const lightModeWholeHome = 'Light mode · whole home';
  static const speed = 'Speed';
  static String modesSubtitle(int staticCount, int dynamicCount) =>
      'Colour, $staticCount static and $dynamicCount dynamic scenes';
  static String lightModeFor(String name) => 'Light mode · $name';
  static String sceneApplied(String name) => '$name applied';
  static String toTarget(String name) => 'to $name';
  static String speedFor(String scene) => 'Speed — $scene';
  static String kelvinLabel(int kelvin) => '${kelvin}K';
```

(`Strings.applyTo`, `wholeHome`, `lightMode` already exist.)

Ruling recorded: the tab's subtitle counts the scenes from the kit's table rather than repeating the prototype's "15 static and 21 dynamic", because the table holds 13 and 23 and the line must be true; cost if wrong: one string.

`lib/features/modes/widgets/modes_layout.dart`:

```dart
import '../../../core/widgets/wiz_scene_tile.dart';

/// Where the modes body is being shown; the prototypes size the wheel, the
/// swatches and the scene grid differently in each (spec §10.5, §10.9).
enum ModesLayout {
  /// The Scenes tab on a phone (`WizCtl_Mobile.dc.html` lines 346–408).
  compactTab(
    wheel: 228,
    swatch: 52,
    whiteWidth: 60,
    whiteHeight: 64,
    sceneMinTile: 160,
    sceneHeight: null,
    tileVariant: WizSceneTileVariant.tab,
    labelSize: WizSceneTile.labelSizeTab,
  ),

  /// The Scenes view on a desktop (`WizCtl_Desktop.dc.html` lines 223–284).
  desktopTab(
    wheel: 216,
    swatch: 48,
    whiteWidth: 58,
    whiteHeight: 60,
    sceneMinTile: 130,
    sceneHeight: 140,
    tileVariant: WizSceneTileVariant.tab,
    labelSize: 18,
  ),

  /// The bottom sheet on a phone (`WizCtl_Mobile.dc.html` lines 519–574).
  sheet(
    wheel: 196,
    swatch: 44,
    whiteWidth: 52,
    whiteHeight: 60,
    sceneMinTile: 100,
    sceneHeight: 82,
    tileVariant: WizSceneTileVariant.sheet,
    labelSize: WizSceneTile.labelSizeSheet,
  ),

  /// The centred dialog on a desktop (`WizCtl_Desktop.dc.html` lines
  /// 423–476): 640 wide inside, four columns of 104.
  dialog(
    wheel: 216,
    swatch: 48,
    whiteWidth: 58,
    whiteHeight: 60,
    sceneMinTile: 140,
    sceneHeight: 104,
    tileVariant: WizSceneTileVariant.sheet,
    labelSize: WizSceneTile.labelSizeSheet,
  );

  final double wheel;
  final double swatch;
  final double whiteWidth;
  final double whiteHeight;
  final double sceneMinTile;

  /// Null means square tiles.
  final double? sceneHeight;
  final WizSceneTileVariant tileVariant;
  final double labelSize;

  const ModesLayout({
    required this.wheel,
    required this.swatch,
    required this.whiteWidth,
    required this.whiteHeight,
    required this.sceneMinTile,
    required this.sceneHeight,
    required this.tileVariant,
    required this.labelSize,
  });

  /// The dialog is 680 wide (spec §10.9); the sheet keeps the kit's 520.
  double? get maxWidth => this == dialog ? dialogWidth : null;

  static const double dialogWidth = 680;
}
```

`lib/features/modes/widgets/swatch_row.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../domain/entities/entities.dart';
import 'modes_layout.dart';

/// The twelve hue circles (spec §10.5, "COLOURS twelve hue swatches").
class SwatchRow extends StatelessWidget {
  final ModesLayout layout;
  final bool Function(Rgb rgb) isSelected;
  final ValueChanged<Rgb> onPick;

  const SwatchRow({
    super.key,
    required this.layout,
    required this.isSelected,
    required this.onPick,
  });

  /// The design system's names, in `WizColors.hues` order.
  static const List<String> hueNames = [
    'Red', 'Orange', 'Yellow', 'Lime', 'Green', 'Teal',
    'Cyan', 'Blue', 'Indigo', 'Violet', 'Magenta', 'Pink',
  ];

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(Strings.colours),
        SizedBox(height: wiz.space.s3),
        Wrap(
          spacing: wiz.space.s3,
          runSpacing: wiz.space.s3,
          children: [
            for (var (i, color) in wiz.colors.hues.indexed)
              Swatch(
                color: color,
                size: layout.swatch,
                label: hueNames[i],
                selected: isSelected(_rgb(color)),
                onTap: () => onPick(_rgb(color)),
              ),
          ],
        ),
      ],
    );
  }

  static Rgb _rgb(Color c) => Rgb(
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
  );
}

/// One hue circle: a raised key filled with the colour, ringed when
/// selected.
class Swatch extends StatelessWidget {
  final Color color;
  final double size;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const Swatch({
    super.key,
    required this.color,
    required this.size,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: label,
      toggled: selected,
      scale: wiz.motion.smallKeyScale,
      hitPadding: EdgeInsets.all((wiz.space.hitMin - size).clamp(0, wiz.space.hitMin) / 2),
      focusRadius: BorderRadius.circular(size / 2),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(size / 2),
        color: color,
        width: size,
        height: size,
        child: selected
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: wiz.colors.amber500,
                    width: wiz.space.keyBorder,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// One white tile: the kelvin colour with its mono label (spec §10.5,
/// "WHITES six kelvin tiles with mono labels").
class WhiteTile extends StatelessWidget {
  final int kelvin;
  final Color color;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  const WhiteTile({
    super.key,
    required this.kelvin,
    required this.color,
    required this.width,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: Strings.kelvinLabel(kelvin),
      toggled: selected,
      scale: wiz.motion.smallKeyScale,
      focusRadius: BorderRadius.circular(wiz.space.r2),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(wiz.space.r2),
        color: color,
        width: width,
        height: height,
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.only(bottom: wiz.space.s2),
        child: DecoratedBox(
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(wiz.space.r2),
                  border: Border.all(
                    color: wiz.colors.amber500,
                    width: wiz.space.keyBorder,
                  ),
                )
              : const BoxDecoration(),
          child: Text(
            Strings.kelvinLabel(kelvin),
            style: wiz.typography.mono.copyWith(color: wiz.colors.textOnAccent),
          ),
        ),
      ),
    );
  }
}
```

`WizPressable.hitPadding` is `EdgeInsets?`; the swatch pads itself out to the 44 minimum when smaller (spec §14). The `DecoratedBox` ring for the white tile wraps only the label; if that reads wrong on device, wrap the whole `WizSurface` in a `Stack` with a `Positioned.fill` ring instead (same approach as `WizSceneTile`'s selection ring).

`lib/features/modes/widgets/colour_tab.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/util/color_maths.dart';
import '../../../core/widgets/wiz_color_wheel.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import 'modes_layout.dart';
import 'swatch_row.dart';

/// The Colour tab: the wheel when the target has a colour bulb, then the
/// hue swatches and the white tiles (spec §10.5).
class ColourTab extends StatelessWidget {
  final ModesLayout layout;
  const ColourTab({super.key, required this.layout});

  static Rgb _rgb(Color c) => Rgb(
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
  );

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightModesBloc>();
    return BlocBuilder<LightModesBloc, LightModesState>(
      builder: (context, state) {
        var wheelRgb = state.wheelRgb;
        var hs = colorToHs(Color.fromARGB(255, wheelRgb.r, wheelRgb.g, wheelRgb.b));
        var whites = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(Strings.whites),
            SizedBox(height: wiz.space.s3),
            Wrap(
              spacing: wiz.space.s3,
              runSpacing: wiz.space.s3,
              children: [
                for (var entry in wiz.colors.kelvinStops.entries)
                  WhiteTile(
                    kelvin: entry.key,
                    color: entry.value,
                    width: layout.whiteWidth,
                    height: layout.whiteHeight,
                    selected: ModeSummarizer.whiteSelected(state.lights, entry.key),
                    onTap: () => bloc.add(WhitePicked(entry.key)),
                  ),
              ],
            ),
          ],
        );
        var swatches = SwatchRow(
          layout: layout,
          isSelected: (rgb) => ModeSummarizer.colourSelected(state.lights, rgb),
          onPick: (rgb) => bloc.add(ColourPicked(rgb)),
        );
        var wheel = state.hasWheel
            ? LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: WizColorWheel(
                    hue: hs.hue,
                    saturation: hs.saturation,
                    size: math.min(layout.wheel, constraints.maxWidth),
                    onChanged: (hsv) =>
                        bloc.add(ColourPicked(_rgb(hsvToColor(hsv.hue, hsv.saturation)))),
                    onChangeEnd: (hsv) =>
                        bloc.add(ColourPicked(_rgb(hsvToColor(hsv.hue, hsv.saturation)))),
                  ),
                ),
              )
            : null;
        if (layout == ModesLayout.desktopTab && wheel != null) {
          // Two columns on a desktop: the wheel left, the swatches right.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: layout.wheel, child: wheel),
              SizedBox(width: wiz.space.s9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [swatches, SizedBox(height: wiz.space.s6), whites],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wheel != null) ...[wheel, SizedBox(height: wiz.space.s6)],
            swatches,
            SizedBox(height: wiz.space.s6),
            whites,
          ],
        );
      },
    );
  }
}
```

`lib/features/modes/widgets/scenes_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../../core/copy/strings.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/scene_gradients.dart';
import '../../../core/widgets/wiz_scene_tile.dart';
import '../../../core/widgets/wiz_slider.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import 'modes_layout.dart';

/// The Static and Dynamic tabs: the speed rail when the whole target is on
/// one dynamic scene, the scene grid, the note (spec §10.5).
class ScenesTab extends StatelessWidget {
  final ModesLayout layout;
  final bool dynamic;
  const ScenesTab({super.key, required this.layout, required this.dynamic});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightModesBloc>();
    var scenes = dynamic ? dynamicScenes : staticScenes;
    return BlocBuilder<LightModesBloc, LightModesState>(
      builder: (context, state) {
        var current = state.currentScene;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dynamic && state.speedVisible && current != null) ...[
              WizSlider(
                value: state.speed.toDouble(),
                min: minSpeed.toDouble(),
                max: maxSpeed.toDouble(),
                fill: WizSliderFill.speed,
                label: Strings.speedFor(ModeSummarizer.sceneName(current)),
                readout: '${state.speed}',
                onChanged: (v) => bloc.add(SpeedChanged(v.round())),
                onChangeEnd: (v) => bloc.add(SpeedChanged(v.round())),
              ),
              SizedBox(height: wiz.space.s6),
            ],
            WizGrid(
              minTile: layout.sceneMinTile,
              gap: wiz.space.s5,
              mainAxisExtent: layout.sceneHeight,
              childAspectRatio: layout.sceneHeight == null ? 1 : null,
              children: [
                for (var scene in scenes)
                  WizSceneTile(
                    sceneId: scene.id,
                    selected: ModeSummarizer.sceneSelected(state.lights, scene.id),
                    variant: layout.tileVariant,
                    labelSize: layout.labelSize,
                    height: layout.sceneHeight,
                    onTap: () => bloc.add(ScenePicked(scene.id)),
                  ),
              ],
            ),
            SizedBox(height: wiz.space.s5),
            Text(
              dynamic ? Strings.dynamicNote : Strings.staticNote,
              style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
            ),
          ],
        );
      },
    );
  }
}
```

`lib/features/modes/widgets/modes_body.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_segmented_control.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import 'colour_tab.dart';
import 'modes_layout.dart';
import 'scenes_tab.dart';

/// Segmented control Colour / Static / Dynamic over the matching tab; the
/// same body inside the sheet, the dialog and the Scenes tab (spec §10.5).
class ModesBody extends StatelessWidget {
  final ModesLayout layout;
  const ModesBody({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightModesBloc>();
    var tab = context.select<LightModesBloc, ModesTab>((b) => b.state.tab);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WizSegmentedControl<ModesTab>(
          segments: const [
            WizSegment(value: ModesTab.colour, label: Strings.colour),
            WizSegment(value: ModesTab.staticScenes, label: Strings.staticTab),
            WizSegment(value: ModesTab.dynamicScenes, label: Strings.dynamicTab),
          ],
          value: tab,
          onChanged: (t) => bloc.add(ModesTabChanged(t)),
        ),
        SizedBox(height: wiz.space.s6),
        switch (tab) {
          ModesTab.colour => ColourTab(layout: layout),
          ModesTab.staticScenes => ScenesTab(layout: layout, dynamic: false),
          ModesTab.dynamicScenes => ScenesTab(layout: layout, dynamic: true),
        },
      ],
    );
  }
}
```

`lib/features/modes/widgets/modes_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';

/// The modes toasts (spec §5.12): "<Scene> applied", and the three
/// nothing-eligible errors.
class ModesNoticeListener extends StatelessWidget {
  final Widget child;
  const ModesNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LightModesBloc, LightModesState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        switch (state.notice!) {
          case SceneAppliedNotice(:var sceneName, :var target, :var targetName):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.sceneApplied(sceneName),
              body: target is WholeHomeTarget || targetName == null
                  ? Strings.toWholeHome
                  : Strings.toTarget(targetName),
            );
          case NoColourNotice():
            toasts.push(
              tone: WizToastTone.error,
              title: Strings.noColourBulb,
              body: Strings.colourNeedsRgb,
            );
          case NoWhiteNotice():
            toasts.push(
              tone: WizToastTone.error,
              title: Strings.noWhiteChannel,
              body: Strings.bulbsOnlyDim,
            );
          case NoSceneNotice():
            toasts.push(
              tone: WizToastTone.error,
              title: Strings.noSceneChannel,
              body: Strings.plugOnlySwitches,
            );
        }
        context.read<LightModesBloc>().add(const ModesNoticeCleared());
      },
      child: child,
    );
  }
}
```

`lib/features/modes/widgets/target_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/util/plural.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';

/// "Apply scenes to": the whole home, each room with its count, each light
/// indented with its address; the selection ringed (spec §10.5).
Future<ModeTarget?> showTargetSheet(
  BuildContext context, {
  required String homeId,
  required ModeTarget current,
}) async {
  var rooms = await context.read<RoomRepository>().getByHome(homeId);
  var lights = await context.read<LightRepository>().getByHome(homeId);
  if (!context.mounted) return null;
  var navigator = Navigator.of(context, rootNavigator: true);
  var space = context.wiz.space;
  return showWizSheet<ModeTarget>(
    context,
    title: Strings.applyScenesTo,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WizListRow(
          icon: WizIcons.house,
          title: Strings.wholeHome,
          meta: plural(lights.length, 'light'),
          active: current is WholeHomeTarget,
          onTap: () => navigator.pop(WholeHomeTarget(homeId)),
        ),
        for (var room in rooms) ...[
          SizedBox(height: space.s3),
          WizListRow(
            icon: WizIcons.byName(room.glyph.iconName)!,
            title: room.name,
            meta: plural(lights.where((l) => l.roomId == room.id).length, 'light'),
            active: current == RoomTarget(room.id),
            onTap: () => navigator.pop(RoomTarget(room.id)),
          ),
          for (var light in lights.where((l) => l.roomId == room.id)) ...[
            SizedBox(height: space.s3),
            Padding(
              padding: EdgeInsets.only(left: space.s7),
              child: WizListRow(
                icon: WizIcons.byName(light.fixture.iconName)!,
                title: light.name,
                meta: light.ip,
                active: current == LightTarget(light.id),
                onTap: () => navigator.pop(LightTarget(light.id)),
              ),
            ),
          ],
        ],
      ],
    ),
  );
}
```

The target sheet reads the repositories from `RepositoryProvider`s the shell installs (Task 19: `AppDependencies`' repositories are provided by type). The test wraps the screen in those providers through `AppScope.wrap` — extend `AppScope.wrap` in this task to also provide `RepositoryProvider<RoomRepository>.value(value: seed.rooms)` and `RepositoryProvider<LightRepository>.value(value: seed.lights)` (and `HomeRepository`, `SettingsRepository`, `LiveStateStore` for later tasks).

`lib/features/modes/view/modes_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../widgets/modes_body.dart';
import '../widgets/modes_layout.dart';
import '../widgets/modes_notice_listener.dart';

/// The modes sheet for a room or a light (spec §10.3, §10.4, §10.5): a
/// bottom sheet on a phone, a 680 dialog elsewhere. Owns its bloc for as
/// long as it is up. [blocFor] builds one for the target; the caller has
/// the use cases.
///
/// The title names the target ("Light mode · <room>"), which the bloc reads
/// from the repositories; the sheet waits for the bloc's first ready state
/// (a few microtasks) so the title is right from the first frame.
Future<void> showModesSheet(
  BuildContext context, {
  required ModeTarget target,
  required LightModesBloc Function(ModeTarget target) blocFor,
}) async {
  var bloc = blocFor(target)..add(const ModesSubscribed());
  if (bloc.state.status != ModesStatus.ready) {
    await bloc.stream.firstWhere((s) => s.status == ModesStatus.ready);
  }
  if (!context.mounted) {
    await bloc.close();
    return;
  }
  var layout = context.layout.widthClass.isCompact
      ? ModesLayout.sheet
      : ModesLayout.dialog;
  await showWizSheet<void>(
    context,
    title: _title(bloc.state),
    maxWidth: layout.maxWidth,
    builder: (context) => BlocProvider.value(
      value: bloc,
      child: ModesNoticeListener(child: ModesBody(layout: layout)),
    ),
  ).whenComplete(bloc.close);
}

/// "Light mode · whole home" / "· <room>" / "· <light>".
String _title(LightModesState state) {
  if (state.target is WholeHomeTarget) return Strings.lightModeWholeHome;
  var name = state.targetName;
  return name == null ? Strings.lightMode : Strings.lightModeFor(name);
}
```

(`import '../bloc/light_modes_state.dart';` for `ModesStatus` and `LightModesState`.)

`lib/features/modes/view/modes_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/scene_gradients.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import '../widgets/modes_body.dart';
import '../widgets/modes_layout.dart';
import '../widgets/target_sheet.dart';

/// The Scenes tab (`/modes`, spec §10.5): the APPLY TO well key, then the
/// modes body at the tab's sizes.
class ModesScreen extends StatelessWidget {
  final String homeId;
  const ModesScreen({super.key, required this.homeId});

  /// The chevron in the well key (`WizCtl_Mobile.dc.html` line 351).
  static const double chevron = 18;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var layout = context.layout.widthClass.isCompact
        ? ModesLayout.compactTab
        : ModesLayout.desktopTab;
    return BlocBuilder<LightModesBloc, LightModesState>(
      builder: (context, state) => ScreenScroll(
        children: [
          WizTopBar(
            title: Strings.lightModes,
            subtitle: Strings.modesSubtitle(staticScenes.length, dynamicScenes.length),
          ),
          _ApplyToKey(
            name: state.target is WholeHomeTarget
                ? Strings.wholeHome
                : state.targetName ?? Strings.wholeHome,
            onTap: () async {
              var bloc = context.read<LightModesBloc>();
              var picked = await showTargetSheet(
                context,
                homeId: homeId,
                current: state.target,
              );
              if (picked != null) bloc.add(ModesTargetChanged(picked));
            },
          ),
          ModesBody(layout: layout),
        ],
      ),
    );
  }
}

/// "APPLY TO" over the target's name with a chevron, as a raised key.
class _ApplyToKey extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _ApplyToKey({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: Strings.applyTo,
      scale: wiz.motion.keyScale,
      focusRadius: BorderRadius.circular(wiz.space.r3),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(wiz.colors.surfaceRaised, wiz.colors.surfacePanel),
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.s6,
          vertical: wiz.space.s5,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel(Strings.applyTo),
                  SizedBox(height: wiz.space.s1),
                  Text(
                    name,
                    style: wiz.typography.heading.copyWith(
                      color: wiz.colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            WizIcon(
              WizIcons.chevronDown,
              size: ModesScreen.chevron,
              color: wiz.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
```

(`wizVertical` is in `core/theme/wiz_textures.dart`; import it.)

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/modes`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/modes lib/core/copy/strings.dart test/features/modes test/support/app_scope.dart
git commit -m "feat(modes): the modes body, the sheet, the Scenes tab and the target sheet"
```

---

### Task 10: RoomBloc

**Files:**
- Create: `lib/features/rooms/bloc/room_bloc.dart`, `lib/features/rooms/bloc/room_event.dart`, `lib/features/rooms/bloc/room_state.dart`
- Test: `test/features/rooms/bloc/room_bloc_test.dart`

**Interfaces:**
- Consumes: `RoomRepository.get/watchByHome`, `LightRepository.watchByRoom`, `LiveStateStore.watchAll`, `RoomAggregates.of(List<LiveLight>)` (brightness, kelvin, canKelvin, kelvinNote, anyOn, onCount, unreachableCount), `ModeSummarizer.summarize`, `SetPower`, `SetBrightness`, `SetKelvin`, `SyncCoordinator.registerScope/refreshAll`, `combineLatest3`.
- Produces:

```dart
sealed class RoomEvent; final class RoomSubscribed, RoomBrightnessChanged(int value), RoomKelvinChanged(int kelvin),
    RoomPowerToggled(bool on), LightPowerToggled(String lightId, bool on), LightBrightnessChanged(String lightId, int value), RoomRefreshRequested
enum RoomStatus { loading, ready, gone }
class RoomState extends Equatable {
  RoomStatus status; Room? room; List<LiveLight> lights; RoomAggregates? aggregates; ModeSummary summary;
  bool get anyOn; bool get canKelvin; String? get kelvinNote; int get brightness; int get kelvin; bool get isEmpty;
}
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc({required String roomId, required RoomRepository rooms, required LightRepository lights, required LiveStateStore store,
      required SetPower setPower, required SetBrightness setBrightness, required SetKelvin setKelvin, required SyncCoordinator sync});
}
```

- [ ] **Step 1: Write the failing test**

`test/features/rooms/bloc/room_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/room_event.dart';
import 'package:wizctl_app/features/rooms/bloc/room_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late SyncCoordinator sync;
  late TargetResolver resolver;

  RoomBloc build(String roomId) => RoomBloc(
    roomId: roomId,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    setPower: SetPower(resolver: resolver, store: seed.store, pipeline: pipeline),
    setBrightness: SetBrightness(resolver: resolver, store: seed.store, pipeline: pipeline),
    setKelvin: SetKelvin(resolver: resolver, store: seed.store, pipeline: pipeline),
    sync: sync,
  );

  setUp(() async {
    seed = SeedHome();
    gateway = FakeGateway();
    for (var l in seed.all) {
      gateway.states[l.ip] = LightState(isOn: seed.store.of(l.id).isOn);
    }
    monitor = NetworkMonitor(FakeNetworkInfo('192.168.1'));
    await monitor.refresh();
    resolver = TargetResolver(seed.lights);
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    sync = SyncCoordinator(
      refresh: RefreshStates(gateway: gateway, store: seed.store, lights: seed.lights, clock: FakeClock()),
      lights: seed.lights,
      settings: seed.settings,
      pollInterval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() {
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<RoomBloc, RoomState>(
    'the living room: aggregates, capability, summary',
    build: () => build('living'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, RoomStatus.ready);
      expect(s.room?.name, 'Living Room');
      expect(s.lights.map((l) => l.light.id), ['dome', 'floor', 'strip']);
      expect(s.brightness, 58, reason: 'mean of 70, 45, 60');
      expect(s.kelvin, 3050, reason: 'mean of 2450, 2700, 4000 to the nearest 50');
      expect(s.canKelvin, isTrue);
      expect(s.kelvinNote, isNull);
      expect(s.summary, ModeSummary.mixed);
      expect(s.anyOn, isTrue);
    },
  );

  blocTest<RoomBloc, RoomState>(
    'the bedroom: a dimmer beside an RGB bulb gets the reach note',
    build: () => build('bedroom'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.kelvinNote, 'Colour temp reaches 1 of 2 bulbs.');
      expect(bloc.state.canKelvin, isTrue);
      expect(bloc.state.anyOn, isFalse);
    },
  );

  blocTest<RoomBloc, RoomState>(
    'the kitchen: one white light is its own summary',
    build: () => build('kitchen'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.summary.name, '5000K white'),
  );

  blocTest<RoomBloc, RoomState>(
    'a room that is not there is gone',
    build: () => build('nope'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.status, RoomStatus.gone),
  );

  blocTest<RoomBloc, RoomState>(
    'the whole-room dials write to every eligible light',
    build: () => build('living'),
    act: (bloc) async {
      bloc.add(const RoomSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomBrightnessChanged(40));
      await Future<void>.delayed(wait);
      bloc.add(const RoomKelvinChanged(3000));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends.where((s) => s.$2.dimming == 40), hasLength(3));
      expect(gateway.sends.where((s) => s.$2.temperature == 3000), hasLength(3));
      expect(bloc.state.brightness, 40);
      expect(bloc.state.kelvin, 3000);
    },
  );

  blocTest<RoomBloc, RoomState>(
    'the room switch, a light switch and a light rail',
    build: () => build('living'),
    act: (bloc) async {
      bloc.add(const RoomSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomPowerToggled(false));
      await Future<void>.delayed(wait);
      bloc.add(const LightPowerToggled('strip', true));
      await Future<void>.delayed(wait);
      bloc.add(const LightBrightnessChanged('floor', 80));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends.take(3).every((s) => s.$2.state == false), isTrue);
      expect(gateway.sends[3].$1, '192.168.1.111');
      expect(gateway.sends[3].$2.state, isTrue);
      expect(gateway.sends[4].$1, '192.168.1.107');
      expect(gateway.sends[4].$2.dimming, 80);
      expect(bloc.state.lights[1].state.brightness, 80);
    },
  );

  test('the room\'s lights are polled while subscribed and not after', () async {
    sync.activateHome('h1');
    var bloc = build('bedroom')..add(const RoomSubscribed());
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(gateway.reads.toSet(), {'192.168.1.115', '192.168.1.118'});
    await bloc.close();
    gateway.reads.clear();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(gateway.reads, isEmpty);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/rooms/bloc/room_bloc_test.dart`
Expected: FAIL to compile.

- [ ] **Step 3: Write the event, state and bloc**

`lib/features/rooms/bloc/room_event.dart`:

```dart
import 'package:equatable/equatable.dart';

sealed class RoomEvent extends Equatable {
  const RoomEvent();
  @override
  List<Object?> get props => const [];
}

final class RoomSubscribed extends RoomEvent {
  const RoomSubscribed();
}

/// The whole-room brightness dial, on every move and on release.
final class RoomBrightnessChanged extends RoomEvent {
  final int value;
  const RoomBrightnessChanged(this.value);
  @override
  List<Object?> get props => [value];
}

final class RoomKelvinChanged extends RoomEvent {
  final int kelvin;
  const RoomKelvinChanged(this.kelvin);
  @override
  List<Object?> get props => [kelvin];
}

final class RoomPowerToggled extends RoomEvent {
  final bool on;
  const RoomPowerToggled(this.on);
  @override
  List<Object?> get props => [on];
}

final class LightPowerToggled extends RoomEvent {
  final String lightId;
  final bool on;
  const LightPowerToggled(this.lightId, this.on);
  @override
  List<Object?> get props => [lightId, on];
}

final class LightBrightnessChanged extends RoomEvent {
  final String lightId;
  final int value;
  const LightBrightnessChanged(this.lightId, this.value);
  @override
  List<Object?> get props => [lightId, value];
}

final class RoomRefreshRequested extends RoomEvent {
  const RoomRefreshRequested();
}
```

`lib/features/rooms/bloc/room_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/room_aggregates.dart';

enum RoomStatus { loading, ready, gone }

class RoomState extends Equatable {
  final RoomStatus status;
  final Room? room;
  final List<LiveLight> lights;
  final RoomAggregates? aggregates;
  final ModeSummary summary;

  const RoomState({
    required this.status,
    required this.room,
    required this.lights,
    required this.aggregates,
    required this.summary,
  });

  static const RoomState initial = RoomState(
    status: RoomStatus.loading,
    room: null,
    lights: [],
    aggregates: null,
    summary: ModeSummary.nothingSet,
  );

  bool get anyOn => aggregates?.anyOn ?? false;
  bool get canKelvin => aggregates?.canKelvin ?? false;
  String? get kelvinNote => aggregates?.kelvinNote;
  int get brightness => aggregates?.brightness ?? LiveState.initial.brightness;
  int get kelvin => aggregates?.kelvin ?? LiveState.initial.kelvin;
  bool get isEmpty => lights.isEmpty;

  @override
  List<Object?> get props => [status, room, lights, aggregates, summary];
}
```

`RoomAggregates` is a plain class without `Equatable`; give it value equality in this task (add `extends Equatable` and `props` over its seven fields in `lib/domain/services/room_aggregates.dart`) so `RoomState` compares by value. Its tests keep passing; the domain layering test allows `equatable`.

`lib/features/rooms/bloc/room_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/room_aggregates.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'room_event.dart';
import 'room_state.dart';

/// One room (spec §8, §10.3): its lights live, the whole-room numbers and
/// note, the mode summary; the whole-room and per-light writes. Registers
/// the room as its poll scope while on show.
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final String roomId;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final SetPower _setPower;
  final SetBrightness _setBrightness;
  final SetKelvin _setKelvin;
  final SyncCoordinator _sync;
  PollScope? _scope;

  RoomBloc({
    required this.roomId,
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required SetPower setPower,
    required SetBrightness setBrightness,
    required SetKelvin setKelvin,
    required SyncCoordinator sync,
  }) : _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _setPower = setPower, // ignore: prefer_initializing_formals
       _setBrightness = setBrightness, // ignore: prefer_initializing_formals
       _setKelvin = setKelvin, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(RoomState.initial) {
    on<RoomSubscribed>(_onSubscribed);
    on<RoomBrightnessChanged>(
      (e, _) => _setBrightness(RoomTarget(roomId), e.value),
    );
    on<RoomKelvinChanged>((e, _) => _setKelvin(RoomTarget(roomId), e.kelvin));
    on<RoomPowerToggled>((e, _) => _setPower(RoomTarget(roomId), e.on));
    on<LightPowerToggled>((e, _) => _setPower(LightTarget(e.lightId), e.on));
    on<LightBrightnessChanged>(
      (e, _) => _setBrightness(LightTarget(e.lightId), e.value),
    );
    on<RoomRefreshRequested>((_, _) => _sync.refreshAll());
  }

  Future<void> _onSubscribed(
    RoomSubscribed event,
    Emitter<RoomState> emit,
  ) async {
    // The repository has no per-room stream, so the room is found once and
    // then followed through its home's list (a rename lands that way).
    var room = Stream.fromFuture(_rooms.get(roomId)).asyncExpand(
      (found) => found == null
          ? Stream.value(null)
          : _rooms.watchByHome(found.homeId).map((all) {
              for (var r in all) {
                if (r.id == roomId) return r;
              }
              return null;
            }),
    );
    await emit.forEach(
      combineLatest3(room, _lights.watchByRoom(roomId), _store.watchAll()),
      onData: (tuple) {
        var (room, lights, states) = tuple;
        if (room == null) {
          return const RoomState(
            status: RoomStatus.gone,
            room: null,
            lights: [],
            aggregates: null,
            summary: ModeSummary.nothingSet,
          );
        }
        var live = [
          for (var l in lights)
            (light: l, state: states[l.id] ?? LiveState.initial),
        ];
        (_scope ??= _sync.registerScope({})).update({for (var l in lights) l.id});
        return RoomState(
          status: RoomStatus.ready,
          room: room,
          lights: live,
          aggregates: RoomAggregates.of(live),
          summary: ModeSummarizer.summarize(live),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _scope?.dispose();
    return super.close();
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/rooms test/domain/services`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/rooms/bloc lib/domain/services/room_aggregates.dart test/features/rooms
git commit -m "feat(rooms): RoomBloc"
```

---

### Task 11: The Room screen, the two-dial panel and the mode-art mapping

**Files:**
- Create: `lib/app/widgets/dual_dials.dart`, `lib/app/widgets/mode_art.dart`, `lib/features/modes/modes_bloc_factory.dart`, `lib/features/rooms/view/room_screen.dart`, `lib/features/rooms/widgets/whole_room_panel.dart`
- Modify: `lib/core/copy/strings.dart`, `test/support/app_scope.dart`
- Test: `test/app/widgets/dual_dials_test.dart`, `test/features/rooms/view/room_screen_test.dart`

**Interfaces:**
- Consumes: `RoomBloc` (Task 10), `showModesSheet` (Task 9), `WizDial` (`minSize` 56, `maxSize` 168), `ModeRow`/`WizModeArt`, `LightCard`/`WizBrightnessControl`, `WizEmptyState`, `WizToggle`, `WizTopBar`, `WizIconKey`, `WizPanel`, `ScreenScroll`, `FieldLabel`, `OffNetworkBanner`, `RiseIn`, `ModeSummarizer.summarize`, `LiveStateMapper.kelvinStep`, `minBrightness`/`maxBrightness`/`typicalMinTemperature`/`typicalMaxTemperature` (wizctl), `plural`.
- Produces:

```dart
typedef ModesBlocFactory = LightModesBloc Function(ModeTarget target);   // provided by the shell (Task 19) and AppScope
class DualDials extends StatelessWidget {
  DualDials({required int brightness, int? kelvin, required ValueChanged<int> onBrightness, ValueChanged<int>? onKelvin,
      required double preferredSize, String? note});
  static double sizeFor({required double width, required int count, required double gap, required double preferred});
}
WizModeArt modeArtOf(ModeArt art);
class RoomScreen extends StatelessWidget { RoomScreen(); static const double dialSize = 132; }
class WholeRoomPanel extends StatelessWidget {}
// Strings
brightness, colourTemp, wholeRoom, noLightsInRoom, discoverThenPlace, discoverThenSave, back; roomPower(name)
```

- [ ] **Step 1: Write the failing tests**

`test/app/widgets/dual_dials_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/dual_dials.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('two dials split the width minus the gap, clamped to the kit range', () {
    expect(DualDials.sizeFor(width: 350, count: 2, gap: 12, preferred: 132), 132);
    expect(DualDials.sizeFor(width: 200, count: 2, gap: 12, preferred: 132), 94);
    expect(DualDials.sizeFor(width: 100, count: 2, gap: 12, preferred: 132), WizDial.minSize);
    expect(DualDials.sizeFor(width: 800, count: 1, gap: 12, preferred: 400), WizDial.maxSize);
  });

  testWidgets('one dial without kelvin, two with, and the note below', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: DualDials(
            brightness: 58,
            onBrightness: (_) {},
            preferredSize: 132,
            note: 'This bulb dims but has no white channel to tune.',
          ),
        ),
      ),
    );
    expect(find.byType(WizDial), findsOneWidget);
    expect(find.text('This bulb dims but has no white channel to tune.'), findsOneWidget);
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          width: 350,
          child: DualDials(
            brightness: 58,
            kelvin: 3050,
            onBrightness: (_) {},
            onKelvin: (_) {},
            preferredSize: 132,
          ),
        ),
      ),
    );
    expect(find.byType(WizDial), findsNWidgets(2));
    expect(tester.getSize(find.byType(WizDial).first).width, 132);
    expect(find.text('BRIGHTNESS'), findsOneWidget);
    expect(find.text('COLOUR TEMP.'), findsOneWidget);
  });
}
```

(The dial's label is uppercased by `WizDial` itself; if it is not, assert on `'Brightness'` and `'Colour temp.'` instead, and keep whichever the kit renders.)

`test/features/rooms/view/room_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/room_event.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;
  late RoomBloc bloc;

  Future<void> open(String roomId) async {
    scope = AppScope(SeedHome());
    await scope.start();
    bloc = RoomBloc(
      roomId: roomId,
      rooms: scope.seed.rooms,
      lights: scope.seed.lights,
      store: scope.seed.store,
      setPower: scope.setPower,
      setBrightness: scope.setBrightness,
      setKelvin: scope.setKelvin,
      sync: scope.sync,
    )..add(const RoomSubscribed());
  }

  tearDown(() async {
    await bloc.close();
    await scope.dispose();
  });

  Widget screen() =>
      scope.wrap(BlocProvider.value(value: bloc, child: const RoomScreen()));

  testWidgets('the living room: bar, dials, mode row, three cards', (tester) async {
    await open('living');
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text('3 lights'), findsOneWidget);
    expect(find.text('WHOLE ROOM'), findsOneWidget);
    expect(find.byType(WizDial), findsNWidgets(2));
    expect(find.text('58'), findsOneWidget);
    expect(find.text('3050'), findsOneWidget);
    expect(find.widgetWithText(ModeRow, 'Mixed'), findsOneWidget);
    expect(find.byType(LightCard), findsNWidgets(3));
    expect(find.text('Cozy'), findsOneWidget, reason: 'the dome is on the Cozy scene');
    expect(find.text('Colour'), findsOneWidget, reason: 'the floor lamp shows a colour');
    expect(find.text('4000K white'), findsOneWidget);
  });

  testWidgets('a plug has no rail and an unreachable light shows its address', (
    tester,
  ) async {
    await open('bedroom');
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('Colour temp reaches 1 of 2 bulbs.'), findsOneWidget);
    var hall = tester.widget<LightCard>(find.widgetWithText(LightCard, 'Hallway'));
    expect(hall.unreachable, isTrue);
    expect(hall.meta, '192.168.1.118');
  });

  testWidgets('tapping a card pushes the light; its switch does not', (tester) async {
    await open('living');
    var router = await pumpRouted(tester, screen(), targets: [AppRoutes.lightPattern]);
    await tester.pump();
    var stripToggle = find.descendant(
      of: find.widgetWithText(LightCard, 'Shelf strip'),
      matching: find.byType(WizToggle),
    );
    await tester.tap(stripToggle);
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends.single.$1, '192.168.1.111');
    expect(currentLocation(router), '/');
    await tester.tap(find.text('Shelf strip'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/lights/strip');
  });

  testWidgets('the room switch writes the whole room', (tester) async {
    await open('living');
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Living Room power'));
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends, hasLength(3));
  });

  testWidgets('an empty room shows the empty state that leads to discovery', (
    tester,
  ) async {
    await open('kitchen');
    await scope.seed.lights.delete('counter');
    var router = await pumpRouted(tester, screen(), targets: [AppRoutes.discover]);
    await tester.pump();
    expect(find.byType(WizEmptyState), findsOneWidget);
    expect(find.text('No lights in this room'), findsOneWidget);
    expect(find.byType(WizDial), findsNothing);
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.discover);
  });

  testWidgets('the mode row opens the room\'s modes sheet', (tester) async {
    await open('living');
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.tap(find.byType(ModeRow));
    await tester.pumpAndSettle();
    expect(find.text('Light mode · Living Room'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app/widgets/dual_dials_test.dart test/features/rooms/view/room_screen_test.dart`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the shared widgets and the screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Room (spec §10.3).
  static const brightness = 'Brightness';
  static const colourTemp = 'Colour temp.';
  static const wholeRoom = 'Whole room';
  static const noLightsInRoom = 'No lights in this room';
  static const discoverThenPlace = 'Discover lights on the network, then place them here.';
  static const discoverThenSave = 'Discover lights on the network, then save them into this room.';
  static const back = 'Back';
  static String roomPower(String name) => '$name power';
```

`lib/features/modes/modes_bloc_factory.dart`:

```dart
import '../../domain/entities/entities.dart';
import 'bloc/light_modes_bloc.dart';

/// Builds a modes bloc for a target. The shell provides one over the real
/// use cases (Task 19); screens read it with `context.read` and hand it to
/// `showModesSheet`, so no screen holds a use case.
typedef ModesBlocFactory = LightModesBloc Function(ModeTarget target);
```

`lib/app/widgets/mode_art.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/widgets/mode_row.dart';
import '../../domain/entities/entities.dart';

/// The domain's mode art in the kit's terms: a scene keeps its id, a solid
/// becomes a colour, flat stays flat.
WizModeArt modeArtOf(ModeArt art) => switch (art) {
  SceneArt(:var sceneId) => SceneModeArt(sceneId),
  SolidArt(:var rgb) => SolidModeArt(Color.fromARGB(255, rgb.r, rgb.g, rgb.b)),
  FlatArt() => const FlatModeArt(),
};
```

`lib/app/widgets/dual_dials.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wizctl/wizctl.dart';

import '../../core/copy/strings.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_dial.dart';
import '../../domain/services/live_state_mapper.dart';

/// Brightness and, when the target has a white channel, colour temperature,
/// side by side: the whole-room panel, the light's dials panel and the
/// desktop inspector all draw this (spec §10.3, §10.4, §10.9). The dials
/// split the width minus the gap and clamp to the kit's range (spec §14);
/// the note, when given, sits centred beneath.
class DualDials extends StatelessWidget {
  final int brightness;
  final int? kelvin;
  final ValueChanged<int> onBrightness;
  final ValueChanged<int>? onKelvin;
  final double preferredSize;
  final String? note;

  const DualDials({
    super.key,
    required this.brightness,
    this.kelvin,
    required this.onBrightness,
    this.onKelvin,
    required this.preferredSize,
    this.note,
  });

  static double sizeFor({
    required double width,
    required int count,
    required double gap,
    required double preferred,
  }) {
    var available = (width - gap * (count - 1)) / count;
    return math.min(preferred, available).clamp(WizDial.minSize, WizDial.maxSize);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var gap = wiz.space.s5;
    var kelvin = this.kelvin;
    var note = this.note;
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = sizeFor(
          width: constraints.maxWidth,
          count: kelvin == null ? 1 : 2,
          gap: gap,
          preferred: preferredSize,
        );
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WizDial(
                  value: brightness.toDouble(),
                  min: minBrightness.toDouble(),
                  max: maxBrightness.toDouble(),
                  unit: '%',
                  label: Strings.brightness,
                  size: size,
                  onChanged: (v) => onBrightness(v.round()),
                  onChangeEnd: (v) => onBrightness(v.round()),
                ),
                if (kelvin != null) ...[
                  SizedBox(width: gap),
                  WizDial(
                    value: kelvin.toDouble(),
                    min: typicalMinTemperature.toDouble(),
                    max: typicalMaxTemperature.toDouble(),
                    step: LiveStateMapper.kelvinStep.toDouble(),
                    unit: 'K',
                    label: Strings.colourTemp,
                    size: size,
                    onChanged: (v) => onKelvin?.call(v.round()),
                    onChangeEnd: (v) => onKelvin?.call(v.round()),
                  ),
                ],
              ],
            ),
            if (note != null) ...[
              SizedBox(height: wiz.space.s4),
              Text(
                note,
                textAlign: TextAlign.center,
                style: wiz.typography.bodySm.copyWith(
                  color: wiz.colors.textTertiary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
```

`lib/features/rooms/widgets/whole_room_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/dual_dials.dart';
import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../domain/entities/entities.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';

/// "WHOLE ROOM": the two dials, the kelvin note and the Light mode row
/// (spec §10.3).
class WholeRoomPanel extends StatelessWidget {
  final double dialSize;
  const WholeRoomPanel({super.key, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<RoomBloc>();
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) => WizPanel(
        variant: WizPanelVariant.inset,
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.panelPad,
          vertical: wiz.space.panelPadLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(Strings.wholeRoom),
            SizedBox(height: wiz.space.s5),
            DualDials(
              brightness: state.brightness,
              kelvin: state.canKelvin ? state.kelvin : null,
              onBrightness: (v) => bloc.add(RoomBrightnessChanged(v)),
              onKelvin: (k) => bloc.add(RoomKelvinChanged(k)),
              preferredSize: dialSize,
              note: state.kelvinNote,
            ),
            SizedBox(height: wiz.space.s5),
            ModeRow(
              art: modeArtOf(state.summary.art),
              name: state.summary.name,
              onTap: () => showModesSheet(
                context,
                target: RoomTarget(bloc.roomId),
                blocFor: context.read<ModesBlocFactory>(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/rooms/view/room_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl/wizctl.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/util/plural.dart';
import '../../../core/widgets/light_card.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_toggle.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../widgets/whole_room_panel.dart';

/// A room on a phone (spec §10.3).
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  /// `WizCtl_Mobile.dc.html` `roomDialSize=132`.
  static const double dialSize = 132;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.rooms);
    }
  }

  @override
  Widget build(BuildContext context) {
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        var bloc = context.read<RoomBloc>();
        var room = state.room;
        if (state.status != RoomStatus.ready || room == null) {
          return const ScreenScroll(children: []);
        }
        return ScreenScroll(
          onRefresh: () async => bloc.add(const RoomRefreshRequested()),
          children: [
            WizTopBar(
              title: room.name,
              subtitle: plural(state.lights.length, 'light'),
              leading: WizIconKey(
                icon: WizIcons.chevronLeft,
                semanticsLabel: Strings.back,
                onPressed: () => _back(context),
              ),
              trailing: WizToggle(
                value: state.anyOn,
                onChanged: (on) => bloc.add(RoomPowerToggled(on)),
                semanticsLabel: Strings.roomPower(room.name),
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            if (state.isEmpty)
              WizEmptyState(
                icon: WizIcons.lightbulb,
                title: Strings.noLightsInRoom,
                body: Strings.discoverThenPlace,
                action: WizButton(
                  label: Strings.discoverLights,
                  variant: WizButtonVariant.primary,
                  onPressed: () => context.go(AppRoutes.discover),
                ),
              )
            else
              const WholeRoomPanel(dialSize: dialSize),
            for (var (i, live) in state.lights.indexed)
              RiseIn(
                index: i,
                child: LightCard(
                  name: live.light.name,
                  meta: live.state.reachable
                      ? ModeSummarizer.summarize([live]).name
                      : live.light.ip,
                  icon: WizIcons.byName(live.light.fixture.iconName)!,
                  on: live.state.isOn,
                  unreachable: !live.state.reachable,
                  brightness: live.state.brightness.toDouble(),
                  control: live.light.bulbClass == BulbClass.socket
                      ? WizBrightnessControl.none
                      : WizBrightnessControl.rail,
                  onToggle: (on) => bloc.add(LightPowerToggled(live.light.id, on)),
                  onBrightness: (v) =>
                      bloc.add(LightBrightnessChanged(live.light.id, v.round())),
                  onBrightnessEnd: (v) =>
                      bloc.add(LightBrightnessChanged(live.light.id, v.round())),
                  onTap: () => context.push(AppRoutes.light(live.light.id)),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

Spec §10.3 says a plug "shows no rail", and `LightCard` documents that `WizBrightnessControl.none` draws neither rail nor meter.

`test/support/app_scope.dart`: add to `wrap` the repositories and the modes factory:

```dart
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ToastController>.value(value: toasts),
          RepositoryProvider<HomeRepository>.value(value: seed.homes),
          RepositoryProvider<RoomRepository>.value(value: seed.rooms),
          RepositoryProvider<LightRepository>.value(value: seed.lights),
          RepositoryProvider<SettingsRepository>.value(value: seed.settings),
          RepositoryProvider<LiveStateStore>.value(value: seed.store),
          RepositoryProvider<ModesBlocFactory>.value(value: modesBlocFor),
        ],
        child: child,
      ),
```

with

```dart
  LightModesBloc modesBlocFor(ModeTarget target) => LightModesBloc(
    target: target,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    applyColour: applyColour,
    applyWhite: applyWhite,
    applyScene: applyScene,
    setSpeed: setSpeed,
  );
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app/widgets test/features/rooms test/features/modes`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app/widgets lib/features/modes/modes_bloc_factory.dart lib/features/rooms lib/core/copy/strings.dart test/
git commit -m "feat(rooms): the Room screen with the two-dial panel and the mode row"
```

---

### Task 12: LightBloc

**Files:**
- Create: `lib/features/lights/bloc/light_bloc.dart`, `lib/features/lights/bloc/light_event.dart`, `lib/features/lights/bloc/light_state.dart`
- Test: `test/features/lights/bloc/light_bloc_test.dart`

**Interfaces:**
- Consumes: `LightRepository.watch(id)`, `RoomRepository.get`, `LiveStateStore.watch(id)`, `CapabilityRules.brightness/kelvin/colour/scenes/speed/isDynamicScene`, `ModeSummarizer.summarize/sceneName`, `SetPower/SetBrightness/SetKelvin/SetSpeed`, `SetFixture(id, fixture)`, `RenameLight(id, name)`, `ForgetLight(id)`, `SyncCoordinator.registerScope/refreshLight`, `combineLatest2`.
- Produces:

```dart
sealed class LightEvent; final class LightSubscribed, LightPowerChanged(bool on), LightBrightnessChanged(int value),
    LightKelvinChanged(int kelvin), LightSpeedChanged(int speed), LightFixtureChanged(Fixture fixture), LightRenamed(String name),
    LightForgotten, LightRetryRequested, LightNoticeCleared
enum LightStatus { loading, ready, gone }
sealed class LightNotice; final class LightForgottenNotice(String name), LightError(String message)
class LightState extends Equatable {
  LightStatus status; Light? light; Room? room; LiveState live; ModeSummary summary; LightNotice? notice;
  bool get canBrightness; bool get canKelvin; bool get canColour; bool get canScenes; bool get isSocket;
  bool get speedVisible; bool get isStaticScene; String? get sceneName;
}
class LightBloc extends Bloc<LightEvent, LightState> {
  LightBloc({required String lightId, required LightRepository lights, required RoomRepository rooms, required LiveStateStore store,
      required SetPower setPower, required SetBrightness setBrightness, required SetKelvin setKelvin, required SetSpeed setSpeed,
      required SetFixture setFixture, required RenameLight renameLight, required ForgetLight forgetLight, required SyncCoordinator sync});
}
```

- [ ] **Step 1: Write the failing test**

`test/features/lights/bloc/light_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/lights/bloc/light_bloc.dart';
import 'package:wizctl_app/features/lights/bloc/light_event.dart';
import 'package:wizctl_app/features/lights/bloc/light_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late SyncCoordinator sync;
  late TargetResolver resolver;

  LightBloc build(String id) => LightBloc(
    lightId: id,
    lights: seed.lights,
    rooms: seed.rooms,
    store: seed.store,
    setPower: SetPower(resolver: resolver, store: seed.store, pipeline: pipeline),
    setBrightness: SetBrightness(resolver: resolver, store: seed.store, pipeline: pipeline),
    setKelvin: SetKelvin(resolver: resolver, store: seed.store, pipeline: pipeline),
    setSpeed: SetSpeed(resolver: resolver, store: seed.store, pipeline: pipeline),
    setFixture: SetFixture(lights: seed.lights),
    renameLight: RenameLight(lights: seed.lights),
    forgetLight: ForgetLight(lights: seed.lights, store: seed.store),
    sync: sync,
  );

  setUp(() async {
    seed = SeedHome();
    gateway = FakeGateway();
    for (var l in seed.all) {
      gateway.states[l.ip] = LightState(isOn: seed.store.of(l.id).isOn, rssi: -50);
    }
    monitor = NetworkMonitor(FakeNetworkInfo('192.168.1'));
    await monitor.refresh();
    resolver = TargetResolver(seed.lights);
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    sync = SyncCoordinator(
      refresh: RefreshStates(gateway: gateway, store: seed.store, lights: seed.lights, clock: FakeClock()),
      lights: seed.lights,
      settings: seed.settings,
    );
    sync.activateHome('h1');
  });

  tearDown(() {
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<LightBloc, LightState>(
    'the dome: name, room, class, capabilities, a static scene, and one read on open',
    build: () => build('dome'),
    act: (bloc) => bloc.add(const LightSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, LightStatus.ready);
      expect(s.light?.name, 'Ceiling dome light');
      expect(s.room?.name, 'Living Room');
      expect(s.light?.className, 'RGB');
      expect(s.live.isOn, isTrue);
      expect(s.canBrightness, isTrue);
      expect(s.canKelvin, isTrue);
      expect(s.canColour, isTrue);
      expect(s.canScenes, isTrue);
      expect(s.isSocket, isFalse);
      expect(s.summary.name, 'Cozy');
      expect(s.isStaticScene, isTrue);
      expect(s.sceneName, 'Cozy');
      expect(s.speedVisible, isFalse);
      expect(gateway.reads, ['192.168.1.104'], reason: 'refreshed when the screen opens');
      expect(s.live.rssi, -50, reason: 'and the read landed');
    },
  );

  blocTest<LightBloc, LightState>(
    'the hallway dims only; a plug switches only',
    build: () {
      seed.lights.seed([
        Light(
          id: 'plug', homeId: 'h1', roomId: 'kitchen', name: 'Plug by the TV',
          ip: '192.168.1.140', mac: 'plug', bulbClass: BulbClass.socket,
          fixture: Fixture.socket, sortIndex: 9, addedAt: DateTime(2026),
        ),
      ]);
      gateway.states['192.168.1.140'] = const LightState(isOn: false);
      return build('hall');
    },
    act: (bloc) => bloc.add(const LightSubscribed()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.canKelvin, isFalse);
      expect(bloc.state.canColour, isFalse);
      expect(bloc.state.canScenes, isTrue);
      expect(bloc.state.canBrightness, isTrue);
      var plug = build('plug');
      addTearDown(plug.close);
      plug.add(const LightSubscribed());
      return Future<void>.delayed(wait).then((_) {
        expect(plug.state.isSocket, isTrue);
        expect(plug.state.canScenes, isFalse);
        expect(plug.state.canBrightness, isFalse);
      });
    },
  );

  blocTest<LightBloc, LightState>(
    'power, brightness, kelvin reach the bulb; speed only on a dynamic scene',
    build: () => build('dome'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightPowerChanged(false));
      await Future<void>.delayed(wait);
      bloc.add(const LightBrightnessChanged(35));
      await Future<void>.delayed(wait);
      bloc.add(const LightKelvinChanged(3500));
      await Future<void>.delayed(wait);
      bloc.add(const LightSpeedChanged(150));
      await Future<void>.delayed(wait);
      seed.store.update('dome', (s) => s.copyWith(active: ActiveChannel.scene, sceneId: 1));
      await Future<void>.delayed(wait);
      bloc.add(const LightSpeedChanged(160));
    },
    wait: wait,
    verify: (bloc) {
      var sends = gateway.sends.map((s) => s.$2).toList();
      expect(sends[0].state, isFalse);
      expect(sends[1].dimming, 35);
      expect(sends[2].temperature, 3500);
      expect(sends, hasLength(4), reason: 'the first speed went nowhere: Cozy is static');
      expect(sends[3].speed, 160);
      expect(bloc.state.speedVisible, isTrue);
      expect(bloc.state.sceneName, 'Ocean');
      expect(bloc.state.isStaticScene, isFalse);
    },
  );

  blocTest<LightBloc, LightState>(
    'fixture and alias changes land in the repository and the state',
    build: () => build('dome'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightFixtureChanged(Fixture.strip));
      await Future<void>.delayed(wait);
      bloc.add(const LightRenamed('Big dome'));
    },
    wait: wait,
    verify: (bloc) async {
      expect(bloc.state.light?.fixture, Fixture.strip);
      expect(bloc.state.light?.name, 'Big dome');
      expect((await seed.lights.get('dome'))?.name, 'Big dome');
    },
  );

  blocTest<LightBloc, LightState>(
    'an empty alias is an error notice',
    build: () => build('dome'),
    act: (bloc) => bloc
      ..add(const LightSubscribed())
      ..add(const LightRenamed('  ')),
    wait: wait,
    verify: (bloc) => expect(bloc.state.notice, const LightError('A name is required.')),
  );

  blocTest<LightBloc, LightState>(
    'forgetting raises the notice, then the light is gone',
    build: () => build('strip'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightForgotten());
    },
    wait: wait,
    verify: (bloc) async {
      expect(bloc.state.notice, const LightForgottenNotice('Shelf strip'));
      expect(bloc.state.status, LightStatus.gone);
      expect(await seed.lights.get('strip'), isNull);
      expect(seed.store.snapshot.containsKey('strip'), isFalse);
    },
  );

  blocTest<LightBloc, LightState>(
    'retry reads the bulb again',
    build: () => build('hall'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      gateway.reads.clear();
      bloc.add(const LightRetryRequested());
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.reads, ['192.168.1.118']);
      expect(bloc.state.live.reachable, isTrue);
    },
  );
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/lights`
Expected: FAIL to compile.

- [ ] **Step 3: Write the event, state and bloc**

`lib/features/lights/bloc/light_event.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

sealed class LightEvent extends Equatable {
  const LightEvent();
  @override
  List<Object?> get props => const [];
}

final class LightSubscribed extends LightEvent {
  const LightSubscribed();
}

final class LightPowerChanged extends LightEvent {
  final bool on;
  const LightPowerChanged(this.on);
  @override
  List<Object?> get props => [on];
}

final class LightBrightnessChanged extends LightEvent {
  final int value;
  const LightBrightnessChanged(this.value);
  @override
  List<Object?> get props => [value];
}

final class LightKelvinChanged extends LightEvent {
  final int kelvin;
  const LightKelvinChanged(this.kelvin);
  @override
  List<Object?> get props => [kelvin];
}

final class LightSpeedChanged extends LightEvent {
  final int speed;
  const LightSpeedChanged(this.speed);
  @override
  List<Object?> get props => [speed];
}

/// "Show it as" (spec §10.4).
final class LightFixtureChanged extends LightEvent {
  final Fixture fixture;
  const LightFixtureChanged(this.fixture);
  @override
  List<Object?> get props => [fixture];
}

final class LightRenamed extends LightEvent {
  final String name;
  const LightRenamed(this.name);
  @override
  List<Object?> get props => [name];
}

final class LightForgotten extends LightEvent {
  const LightForgotten();
}

/// The unreachable banner's Retry: read the bulb once more.
final class LightRetryRequested extends LightEvent {
  const LightRetryRequested();
}

final class LightNoticeCleared extends LightEvent {
  const LightNoticeCleared();
}
```

`lib/features/lights/bloc/light_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/capability_rules.dart';
import '../../../domain/services/mode_summarizer.dart';

enum LightStatus { loading, ready, gone }

sealed class LightNotice extends Equatable {
  const LightNotice();
}

/// "<name> forgotten" / "Removed from this home's config file"; the view
/// leaves the screen.
final class LightForgottenNotice extends LightNotice {
  final String name;
  const LightForgottenNotice(this.name);
  @override
  List<Object?> get props => [name];
}

final class LightError extends LightNotice {
  final String message;
  const LightError(this.message);
  @override
  List<Object?> get props => [message];
}

class LightState extends Equatable {
  final LightStatus status;
  final Light? light;
  final Room? room;
  final LiveState live;
  final ModeSummary summary;
  final LightNotice? notice;

  const LightState({
    required this.status,
    required this.light,
    required this.room,
    required this.live,
    required this.summary,
    this.notice,
  });

  static const LightState initial = LightState(
    status: LightStatus.loading,
    light: null,
    room: null,
    live: LiveState.initial,
    summary: ModeSummary.nothingSet,
  );

  BulbClass? get _cls => light?.bulbClass;
  bool get canBrightness => CapabilityRules.brightness(_cls);
  bool get canKelvin => CapabilityRules.kelvin(_cls);
  bool get canColour => CapabilityRules.colour(_cls);
  bool get canScenes => CapabilityRules.scenes(_cls);
  bool get isSocket => _cls == BulbClass.socket;

  /// The speed rail: only while on a dynamic scene (spec §5.1).
  bool get speedVisible => CapabilityRules.speed(live);

  bool get isStaticScene =>
      live.active == ActiveChannel.scene &&
      !CapabilityRules.isDynamicScene(live.sceneId);

  String? get sceneName => live.active == ActiveChannel.scene
      ? ModeSummarizer.sceneName(live.sceneId)
      : null;

  LightState copyWith({
    LightStatus? status,
    Light? light,
    Room? room,
    LiveState? live,
    ModeSummary? summary,
    LightNotice? notice,
    bool clearNotice = false,
  }) => LightState(
    status: status ?? this.status,
    light: light ?? this.light,
    room: room ?? this.room,
    live: live ?? this.live,
    summary: summary ?? this.summary,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, light, room, live, summary, notice];
}
```

`lib/features/lights/bloc/light_bloc.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'light_event.dart';
import 'light_state.dart';

/// One light (spec §8, §10.4, §10.9): the detail screen on a phone and the
/// inspector on a desktop. Reads the bulb once when it opens (spec §5.8),
/// keeps it polled while on show, and owns its writes and edits.
class LightBloc extends Bloc<LightEvent, LightState> {
  final String lightId;
  final LightRepository _lights;
  final RoomRepository _rooms;
  final LiveStateStore _store;
  final SetPower _setPower;
  final SetBrightness _setBrightness;
  final SetKelvin _setKelvin;
  final SetSpeed _setSpeed;
  final SetFixture _setFixture;
  final RenameLight _renameLight;
  final ForgetLight _forgetLight;
  final SyncCoordinator _sync;
  PollScope? _scope;

  LightBloc({
    required this.lightId,
    required LightRepository lights,
    required RoomRepository rooms,
    required LiveStateStore store,
    required SetPower setPower,
    required SetBrightness setBrightness,
    required SetKelvin setKelvin,
    required SetSpeed setSpeed,
    required SetFixture setFixture,
    required RenameLight renameLight,
    required ForgetLight forgetLight,
    required SyncCoordinator sync,
  }) : _lights = lights, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _setPower = setPower, // ignore: prefer_initializing_formals
       _setBrightness = setBrightness, // ignore: prefer_initializing_formals
       _setKelvin = setKelvin, // ignore: prefer_initializing_formals
       _setSpeed = setSpeed, // ignore: prefer_initializing_formals
       _setFixture = setFixture, // ignore: prefer_initializing_formals
       _renameLight = renameLight, // ignore: prefer_initializing_formals
       _forgetLight = forgetLight, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(LightState.initial) {
    on<LightSubscribed>(_onSubscribed);
    on<LightPowerChanged>((e, _) => _setPower(LightTarget(lightId), e.on));
    on<LightBrightnessChanged>(
      (e, _) => _setBrightness(LightTarget(lightId), e.value),
    );
    on<LightKelvinChanged>((e, _) => _setKelvin(LightTarget(lightId), e.kelvin));
    on<LightSpeedChanged>((e, _) => _setSpeed(LightTarget(lightId), e.speed));
    on<LightFixtureChanged>((e, _) => _setFixture(lightId, e.fixture));
    on<LightRenamed>(_onRenamed);
    on<LightForgotten>(_onForgotten);
    on<LightRetryRequested>((_, _) => _sync.refreshLight(lightId));
    on<LightNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  Future<void> _onSubscribed(
    LightSubscribed event,
    Emitter<LightState> emit,
  ) async {
    _scope ??= _sync.registerScope({lightId});
    unawaited(_sync.refreshLight(lightId));
    Room? room;
    await emit.forEach(
      combineLatest2(_lights.watch(lightId), _store.watch(lightId)).asyncMap((
        tuple,
      ) async {
        var (light, live) = tuple;
        if (light != null && room?.id != light.roomId) {
          room = await _rooms.get(light.roomId);
        }
        return (light: light, live: live, room: room);
      }),
      onData: (next) {
        var light = next.light;
        if (light == null) {
          return state.copyWith(status: LightStatus.gone);
        }
        return state.copyWith(
          status: LightStatus.ready,
          light: light,
          room: next.room,
          live: next.live,
          summary: ModeSummarizer.summarize([(light: light, state: next.live)]),
        );
      },
    );
  }

  Future<void> _onRenamed(LightRenamed event, Emitter<LightState> emit) async {
    try {
      await _renameLight(lightId, event.name);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: LightError(e.message)));
    }
  }

  Future<void> _onForgotten(
    LightForgotten event,
    Emitter<LightState> emit,
  ) async {
    var name = state.light?.name;
    if (name == null) return;
    await _forgetLight(lightId);
    emit(state.copyWith(notice: LightForgottenNotice(name)));
  }

  @override
  Future<void> close() {
    _scope?.dispose();
    return super.close();
  }
}
```

`copyWith(status: gone)` keeps the last `light` so the forgotten notice can still name it; the view treats `gone` as "leave".

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/lights`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/lights/bloc test/features/lights
git commit -m "feat(lights): LightBloc"
```

---

### Task 13: The Light detail screen and its sheets

**Files:**
- Create: `lib/app/widgets/emission.dart`, `lib/app/widgets/fixture_kind.dart`, `lib/features/lights/view/light_screen.dart`, `lib/features/lights/widgets/light_hero.dart`, `lib/features/lights/widgets/light_stat_tiles.dart`, `lib/features/lights/widgets/light_dials_panel.dart`, `lib/features/lights/widgets/light_modes_panel.dart`, `lib/features/lights/widgets/device_panel.dart`, `lib/features/lights/widgets/fixture_sheet.dart`, `lib/features/lights/widgets/rename_light_sheet.dart`, `lib/features/lights/widgets/forget_light_sheet.dart`, `lib/features/lights/widgets/light_notice_listener.dart`
- Modify: `lib/core/copy/strings.dart`
- Test: `test/app/widgets/emission_test.dart`, `test/features/lights/view/light_screen_test.dart`

**Interfaces:**
- Consumes: `LightBloc` (Task 12), `FixtureHero`/`WizFixture`/`WizEmission.lit/off`, `kelvinToColor`, `sceneGradients`, `WizPowerKey`, `WizStatTile`, `WizBadge`, `WizStatusBanner`, `WizSlider`/`WizSliderFill.speed`, `WizPanel`, `WizGrid`, `WizIconKey`, `WizButton`, `WizTextField`, `showWizSheet`, `ModeRow`, `DualDials`, `modeArtOf`, `showModesSheet`/`ModesBlocFactory`, `ScreenScroll`, `FieldLabel`, `OffNetworkBanner`, `Fixture.values/label/iconName`, `minSpeed`/`maxSpeed` (wizctl).
- Produces:

```dart
WizEmission emissionOf(LiveState live, BulbClass? bulbClass);   // spec §5.6
WizFixture fixtureOf(Fixture fixture);
class LightScreen extends StatelessWidget { static const double dialSize = 132; static const double fixtureTileMin = 100; }
class LightHero, LightStatTiles, LightDialsPanel, LightModesPanel, DevicePanel (widgets)
Future<Fixture?> showFixtureSheet(BuildContext context, {required Fixture current});
Future<String?> showRenameLightSheet(BuildContext context, {required String name});
Future<bool> showForgetLightSheet(BuildContext context, {required String name});
class LightNoticeListener extends StatelessWidget { LightNoticeListener({required Widget child}); }
// Strings
live, noReply, noReplyFromLight, mayBeOffAtWall, colourTempTile, classTile, power, intensity, on, off, plugOnlyNote, dimsNoWhite,
device, address, mac, signal, noReplyLower, showItAs, showItAsNote, rename, renameLight, forget, alias, aliasPlaceholder, saveAlias,
forgetBody, removedFromConfig; staticSceneNote(name), dbm(rssi), forgetTitle(name), forgotten(name), roomAndClass(room, cls)
```

- [ ] **Step 1: Write the failing tests**

`test/app/widgets/emission_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/widgets/emission.dart';
import 'package:wizctl_app/app/widgets/fixture_kind.dart';
import 'package:wizctl_app/core/util/color_maths.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  const base = LiveState.initial;

  test('off or unreachable is the off emission', () {
    expect(emissionOf(base, BulbClass.rgb), WizEmission.off);
    expect(
      emissionOf(base.copyWith(isOn: true, reachable: false), BulbClass.rgb),
      WizEmission.off,
    );
  });

  test('colour on an RGB bulb emits the colour; on another class the kelvin', () {
    var on = base.copyWith(isOn: true, reachable: true, active: ActiveChannel.colour, rgb: const Rgb(255, 0, 0), brightness: 100);
    expect(emissionOf(on, BulbClass.rgb).color, const Color(0xFFFF0000));
    expect(emissionOf(on, BulbClass.tw).color, kelvinToColor(on.kelvin));
  });

  test('a scene emits its from colour; white the kelvin colour', () {
    var scene = base.copyWith(isOn: true, reachable: true, active: ActiveChannel.scene, sceneId: 1);
    expect(emissionOf(scene, BulbClass.rgb).color, sceneGradients[1]!.from);
    var white = base.copyWith(isOn: true, reachable: true, active: ActiveChannel.white, kelvin: 4500);
    expect(emissionOf(white, BulbClass.tw).color, kelvinToColor(4500));
    expect(emissionOf(white, BulbClass.tw).alpha, closeTo(0.30 + 0.60 * 0.62, 0.001));
  });

  test('every fixture kind maps to the hero\'s', () {
    for (var f in Fixture.values) {
      expect(fixtureOf(f).name, f.name);
    }
  });
}
```

`test/features/lights/view/light_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/lights/bloc/light_bloc.dart';
import 'package:wizctl_app/features/lights/bloc/light_event.dart';
import 'package:wizctl_app/features/lights/view/light_screen.dart';
import 'package:wizctl_app/features/lights/widgets/light_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

void main() {
  late AppScope scope;
  late LightBloc bloc;

  Future<void> open(String id) async {
    scope = AppScope(SeedHome());
    await scope.start();
    bloc = LightBloc(
      lightId: id,
      lights: scope.seed.lights,
      rooms: scope.seed.rooms,
      store: scope.seed.store,
      setPower: scope.setPower,
      setBrightness: scope.setBrightness,
      setKelvin: scope.setKelvin,
      setSpeed: scope.setSpeed,
      setFixture: SetFixture(lights: scope.seed.lights),
      renameLight: RenameLight(lights: scope.seed.lights),
      forgetLight: ForgetLight(lights: scope.seed.lights, store: scope.seed.store),
      sync: scope.sync,
    )..add(const LightSubscribed());
  }

  tearDown(() async {
    await bloc.close();
    await scope.dispose();
  });

  Widget screen() => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const LightNoticeListener(child: LightScreen()),
    ),
  );

  testWidgets('the dome: bar, live badge, hero, power key, tiles, dials, mode row, device facts', (
    tester,
  ) async {
    await open('dome');
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('Ceiling dome light'), findsOneWidget);
    expect(find.text('Living Room · RGB'), findsOneWidget);
    expect(tester.widget<WizBadge>(find.byType(WizBadge)).label, 'Live');
    expect(tester.widget<FixtureHero>(find.byType(FixtureHero)).fixture, WizFixture.dome);
    expect(tester.widget<WizPowerKey>(find.byType(WizPowerKey)).on, isTrue);
    expect(find.byType(WizStatusBanner), findsNothing);
    expect(find.widgetWithText(WizStatTile, 'COLOUR TEMP'), findsOneWidget);
    expect(find.widgetWithText(WizStatTile, 'INTENSITY'), findsOneWidget);
    expect(find.byType(WizDial), findsNWidgets(2));
    expect(find.widgetWithText(ModeRow, 'Cozy'), findsOneWidget);
    expect(find.text('Cozy is a static scene — the bulb ignores speed.'), findsOneWidget);
    expect(find.byType(WizSlider), findsNothing);
    expect(find.text('192.168.1.104:38899'), findsOneWidget);
    expect(find.text('a8bb50f1c204'), findsOneWidget);
    expect(find.text('-52 dBm'), findsOneWidget);
  });

  testWidgets('a dynamic scene shows the speed rail', (tester) async {
    await open('dome');
    scope.seed.store.update('dome', (s) => s.copyWith(active: ActiveChannel.scene, sceneId: 1));
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.byType(WizSlider), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);
  });

  testWidgets('the hallway: no reply banner, class tile, one dial and the dims note', (
    tester,
  ) async {
    await open('hall');
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(tester.widget<WizBadge>(find.byType(WizBadge)).label, 'No reply');
    expect(find.text('No reply from this light'), findsOneWidget);
    expect(find.widgetWithText(WizStatTile, 'CLASS'), findsOneWidget);
    expect(find.byType(WizDial), findsOneWidget);
    expect(find.text('This bulb dims but has no white channel to tune.'), findsOneWidget);
    expect(find.text('no reply'), findsOneWidget, reason: 'the signal fact');
    await tester.tap(find.text('RETRY'));
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.reads, contains('192.168.1.118'));
  });

  testWidgets('a plug: the note, the power tile, no dials and no mode row', (tester) async {
    await open('dome');
    scope.seed.lights.seed([
      Light(
        id: 'plug', homeId: 'h1', roomId: 'kitchen', name: 'Plug by the TV',
        ip: '192.168.1.140', mac: 'plug', bulbClass: BulbClass.socket,
        fixture: Fixture.socket, sortIndex: 9, addedAt: DateTime(2026),
      ),
    ]);
    scope.gateway.states['192.168.1.140'] = const LightState(isOn: false);
    await bloc.close();
    bloc = LightBloc(
      lightId: 'plug', lights: scope.seed.lights, rooms: scope.seed.rooms, store: scope.seed.store,
      setPower: scope.setPower, setBrightness: scope.setBrightness, setKelvin: scope.setKelvin,
      setSpeed: scope.setSpeed, setFixture: SetFixture(lights: scope.seed.lights),
      renameLight: RenameLight(lights: scope.seed.lights),
      forgetLight: ForgetLight(lights: scope.seed.lights, store: scope.seed.store), sync: scope.sync,
    )..add(const LightSubscribed());
    await pumpRouted(tester, screen());
    await tester.pump();
    expect(find.text('A plug switches power only. It has no brightness, colour or scene channel.'), findsOneWidget);
    expect(find.widgetWithText(WizStatTile, 'POWER'), findsOneWidget);
    expect(find.byType(WizDial), findsNothing);
    expect(find.byType(ModeRow), findsNothing);
  });

  testWidgets('the power key and the dials write', (tester) async {
    await open('dome');
    await pumpRouted(tester, screen());
    await tester.pump();
    await tester.tap(find.byType(WizPowerKey));
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends.last.$2.state, isFalse);
  });

  testWidgets('show it as, rename and forget through their sheets', (tester) async {
    await open('strip');
    var router = await pumpRouted(tester, screen(), targets: ['/rooms/living']);
    await tester.pump();
    await tester.tap(find.text('SHOW IT AS'));
    await tester.pumpAndSettle();
    expect(find.text('This only changes how the light is drawn here. It does not change what the bulb supports.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Lamp'));
    await tester.pumpAndSettle();
    expect(tester.widget<FixtureHero>(find.byType(FixtureHero)).fixture, WizFixture.desk);

    await tester.tap(find.text('RENAME'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(WizTextField), 'Bookshelf strip');
    await tester.tap(find.text('SAVE ALIAS'));
    await tester.pumpAndSettle();
    expect(find.text('Bookshelf strip'), findsOneWidget);

    await tester.tap(find.text('FORGET'));
    await tester.pumpAndSettle();
    expect(find.text('Forget Bookshelf strip?'), findsOneWidget);
    await tester.tap(find.text('FORGET').last);
    await tester.pumpAndSettle();
    expect(scope.toasts.toasts.single.title, 'Bookshelf strip forgotten');
    expect(scope.toasts.toasts.single.body, "Removed from this home's config file");
    expect(currentLocation(router), '/', reason: 'left the detail: pop, or the room when nothing to pop');
  });
}
```

The last assertion: `pumpRouted` mounts the screen at `/` with nothing beneath, so `context.canPop()` is false and the listener falls back to `context.go(AppRoutes.room(roomId))` — expect `'/rooms/living'` there instead of `'/'`. Write the expectation as `'/rooms/living'`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app/widgets/emission_test.dart test/features/lights/view`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the mappings, the widgets, the sheets and the screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Light detail (spec §10.4, §15).
  static const live = 'Live';
  static const noReply = 'No reply';
  static const noReplyFromLight = 'No reply from this light';
  static const mayBeOffAtWall = 'It may be switched off at the wall, or the router changed its address.';
  static const colourTempTile = 'Colour temp';
  static const classTile = 'Class';
  static const power = 'Power';
  static const intensity = 'Intensity';
  static const on = 'On';
  static const off = 'Off';
  static const plugOnlyNote = 'A plug switches power only. It has no brightness, colour or scene channel.';
  static const dimsNoWhite = 'This bulb dims but has no white channel to tune.';
  static const device = 'Device';
  static const address = 'Address';
  static const mac = 'MAC';
  static const signal = 'Signal';
  static const noReplyLower = 'no reply';
  static const showItAs = 'Show it as';
  static const showItAsNote = 'This only changes how the light is drawn here. It does not change what the bulb supports.';
  static const rename = 'Rename';
  static const renameLight = 'Rename light';
  static const forget = 'Forget';
  static const alias = 'Alias';
  static const aliasPlaceholder = 'Bedside bulb';
  static const saveAlias = 'Save alias';
  static const forgetBody = 'Its alias and room are removed. The bulb keeps working.';
  static const removedFromConfig = "Removed from this home's config file";
  static String staticSceneNote(String name) => '$name is a static scene — the bulb ignores speed.';
  static String dbm(int rssi) => '$rssi dBm';
  static String forgetTitle(String name) => 'Forget $name?';
  static String forgotten(String name) => '$name forgotten';
  static String roomAndClass(String room, String cls) => '$room · $cls';
```

`lib/app/widgets/emission.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:wizctl/wizctl.dart';

import '../../core/util/color_maths.dart';
import '../../core/widgets/fixture_hero.dart';
import '../../core/widgets/scene_gradients.dart';
import '../../domain/entities/entities.dart';

/// What a light emits (spec §5.6): nothing when off or unreachable; its
/// colour on an RGB bulb showing a colour, the scene's `from` colour on a
/// scene, the kelvin colour otherwise, all scaled by brightness.
WizEmission emissionOf(LiveState live, BulbClass? bulbClass) {
  if (!live.isOn || !live.reachable) return WizEmission.off;
  var color = switch (live.active) {
    ActiveChannel.colour when bulbClass == BulbClass.rgb || bulbClass == null =>
      Color.fromARGB(255, live.rgb.r, live.rgb.g, live.rgb.b),
    ActiveChannel.scene =>
      sceneGradients[live.sceneId]?.from ?? kelvinToColor(live.kelvin),
    _ => kelvinToColor(live.kelvin),
  };
  return WizEmission.lit(color: color, brightness: live.brightness);
}
```

`lib/app/widgets/fixture_kind.dart`:

```dart
import '../../core/widgets/fixture_hero.dart';
import '../../domain/entities/entities.dart';

/// The domain's "show it as" in the hero's terms; the two enums share
/// their names by design (Plan 2 Task 20, Plan 3 Task 1).
WizFixture fixtureOf(Fixture fixture) => WizFixture.values.byName(fixture.name);
```

`lib/features/lights/widgets/light_hero.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/emission.dart';
import '../../../app/widgets/fixture_kind.dart';
import '../../../core/widgets/fixture_hero.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_state.dart';

/// The fixture drawn from "show it as", lit from the live state
/// (spec §10.4).
class LightHero extends StatelessWidget {
  const LightHero({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        return FixtureHero(
          fixture: fixtureOf(light.fixture),
          emission: emissionOf(state.live, light.bulbClass),
        );
      },
    );
  }
}
```

`lib/features/lights/widgets/light_stat_tiles.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_stat_tile.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_state.dart';

/// Two tiles (spec §10.4): colour temp or class on the left, intensity or
/// power on the right.
class LightStatTiles extends StatelessWidget {
  const LightStatTiles({super.key});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var a = state.canKelvin
            ? WizStatTile(
                icon: WizIcons.thermometer,
                label: Strings.colourTempTile,
                value: '${state.live.kelvin}',
                unit: 'K',
              )
            : WizStatTile(
                icon: WizIcons.lightbulb,
                label: Strings.classTile,
                value: light.className,
              );
        var b = state.isSocket
            ? WizStatTile(
                icon: WizIcons.power,
                label: Strings.power,
                value: state.live.isOn ? Strings.on : Strings.off,
              )
            : WizStatTile(
                icon: WizIcons.gauge,
                label: Strings.intensity,
                value: '${state.live.brightness}',
                unit: '%',
                accent: state.live.isOn,
              );
        return Row(
          children: [
            Expanded(child: a),
            SizedBox(width: space.s5),
            Expanded(child: b),
          ],
        );
      },
    );
  }
}
```

`lib/features/lights/widgets/light_dials_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/dual_dials.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';

/// Brightness and, when the bulb has a white channel, colour temp; the
/// "dims but has no white channel" note when it does not (spec §10.4).
class LightDialsPanel extends StatelessWidget {
  final double dialSize;
  const LightDialsPanel({super.key, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) => WizPanel(
        variant: WizPanelVariant.inset,
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.panelPad,
          vertical: wiz.space.panelPadLg,
        ),
        child: DualDials(
          brightness: state.live.brightness,
          kelvin: state.canKelvin ? state.live.kelvin : null,
          onBrightness: (v) => bloc.add(LightBrightnessChanged(v)),
          onKelvin: (k) => bloc.add(LightKelvinChanged(k)),
          preferredSize: dialSize,
          note: state.canKelvin ? null : Strings.dimsNoWhite,
        ),
      ),
    );
  }
}
```

`lib/features/lights/widgets/light_modes_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_slider.dart';
import '../../../domain/entities/entities.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';

/// The Light mode row, the speed rail on a dynamic scene, the note on a
/// static one (spec §10.4).
class LightModesPanel extends StatelessWidget {
  const LightModesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var sceneName = state.sceneName;
        return WizPanel(
          variant: WizPanelVariant.inset,
          padding: EdgeInsets.symmetric(
            horizontal: wiz.space.panelPad,
            vertical: wiz.space.panelPadLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModeRow(
                art: modeArtOf(state.summary.art),
                name: state.summary.name,
                onTap: () => showModesSheet(
                  context,
                  target: LightTarget(bloc.lightId),
                  blocFor: context.read<ModesBlocFactory>(),
                ),
              ),
              if (state.speedVisible) ...[
                SizedBox(height: wiz.space.s5),
                WizSlider(
                  value: state.live.speed.toDouble(),
                  min: minSpeed.toDouble(),
                  max: maxSpeed.toDouble(),
                  fill: WizSliderFill.speed,
                  label: Strings.speed,
                  readout: '${state.live.speed}',
                  onChanged: (v) => bloc.add(LightSpeedChanged(v.round())),
                  onChangeEnd: (v) => bloc.add(LightSpeedChanged(v.round())),
                ),
              ] else if (state.isStaticScene && sceneName != null) ...[
                SizedBox(height: wiz.space.s4),
                Text(
                  Strings.staticSceneNote(sceneName),
                  textAlign: TextAlign.center,
                  style: wiz.typography.bodySm.copyWith(
                    color: wiz.colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
```

`lib/features/lights/widgets/device_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';
import 'fixture_sheet.dart';
import 'forget_light_sheet.dart';
import 'rename_light_sheet.dart';

/// "DEVICE": address, MAC, class, signal; then Show it as, Rename and
/// Forget (spec §10.4).
class DevicePanel extends StatelessWidget {
  const DevicePanel({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var rssi = state.live.rssi;
        var facts = <(String, String)>[
          (Strings.address, Strings.udpAddress(light.ip)),
          (Strings.mac, light.mac),
          (Strings.classTile, light.className),
          (
            Strings.signal,
            state.live.reachable && rssi != null
                ? Strings.dbm(rssi)
                : Strings.noReplyLower,
          ),
        ];
        return WizPanel(
          variant: WizPanelVariant.flat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(Strings.device),
              SizedBox(height: wiz.space.s4),
              for (var (label, value) in facts)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: wiz.space.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: wiz.typography.bodySm.copyWith(
                            color: wiz.colors.textTertiary,
                          ),
                        ),
                      ),
                      Text(
                        value,
                        style: wiz.typography.mono.copyWith(
                          color: wiz.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: wiz.space.s5),
              WizButton(
                label: Strings.showItAs,
                fullWidth: true,
                onPressed: () async {
                  var picked = await showFixtureSheet(
                    context,
                    current: light.fixture,
                  );
                  if (picked != null) bloc.add(LightFixtureChanged(picked));
                },
              ),
              SizedBox(height: wiz.space.s4),
              Row(
                children: [
                  Expanded(
                    child: WizButton(
                      label: Strings.rename,
                      variant: WizButtonVariant.ghost,
                      icon: WizIcons.pencil,
                      fullWidth: true,
                      onPressed: () async {
                        var name = await showRenameLightSheet(
                          context,
                          name: light.name,
                        );
                        if (name != null) bloc.add(LightRenamed(name));
                      },
                    ),
                  ),
                  SizedBox(width: wiz.space.s4),
                  Expanded(
                    child: WizButton(
                      label: Strings.forget,
                      variant: WizButtonVariant.danger,
                      icon: WizIcons.trash,
                      fullWidth: true,
                      onPressed: () async {
                        var sure = await showForgetLightSheet(
                          context,
                          name: light.name,
                        );
                        if (sure) bloc.add(const LightForgotten());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

`lib/features/lights/widgets/fixture_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../domain/entities/entities.dart';

/// "Show it as" (spec §10.4): the five fixtures, min tile 100, the current
/// one amber. Resolves to the pick, or null.
Future<Fixture?> showFixtureSheet(
  BuildContext context, {
  required Fixture current,
}) {
  var navigator = Navigator.of(context, rootNavigator: true);
  return showWizSheet<Fixture>(
    context,
    title: Strings.showItAs,
    builder: (context) {
      var wiz = context.wiz;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Strings.showItAsNote,
            style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
          ),
          SizedBox(height: wiz.space.s6),
          WizGrid(
            minTile: fixtureTileMin,
            gap: wiz.space.s4,
            children: [
              for (var f in Fixture.values)
                _FixtureTile(
                  fixture: f,
                  selected: f == current,
                  onTap: () => navigator.pop(f),
                ),
            ],
          ),
        ],
      );
    },
  );
}

/// Spec §10.4, "grid of the five fixtures, min tile 100".
const double fixtureTileMin = 100;

class _FixtureTile extends StatelessWidget {
  final Fixture fixture;
  final bool selected;
  final VoidCallback onTap;
  const _FixtureTile({required this.fixture, required this.selected, required this.onTap});

  /// `WizCtl_Mobile.dc.html` line 655: `icXl` in the fixture option.
  static const double glyph = 26;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: fixture.label,
      toggled: selected,
      scale: wiz.motion.keyScale,
      focusRadius: BorderRadius.circular(wiz.space.r3),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: selected
            ? wizVertical(wiz.colors.amber400, wiz.colors.amber600)
            : wizVertical(wiz.colors.surfaceKey, wiz.colors.surfaceRaised),
        padding: EdgeInsets.symmetric(vertical: wiz.space.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WizIcon(
              WizIcons.byName(fixture.iconName)!,
              size: glyph,
              color: selected ? wiz.colors.textOnAccent : wiz.colors.textSecondary,
            ),
            SizedBox(height: wiz.space.s3),
            Text(
              fixture.label,
              style: wiz.typography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? wiz.colors.textOnAccent : wiz.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

(`wizVertical` from `core/theme/wiz_textures.dart`.)

`lib/features/lights/widgets/rename_light_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';

/// "Rename light": ALIAS, Cancel / Save alias (spec §10.4, §10.9).
/// Resolves to the trimmed alias, or null.
Future<String?> showRenameLightSheet(
  BuildContext context, {
  required String name,
}) {
  var navigator = Navigator.of(context, rootNavigator: true);
  var controller = TextEditingController(text: name);
  return showWizSheet<String>(
    context,
    title: Strings.renameLight,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel(Strings.alias),
        SizedBox(height: context.wiz.space.s3),
        WizTextField(
          controller: controller,
          placeholder: Strings.aliasPlaceholder,
          autofocus: true,
        ),
      ],
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => WizButton(
          label: Strings.saveAlias,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: value.text.trim().isNotEmpty,
          onPressed: () => navigator.pop(controller.text.trim()),
        ),
      ),
    ],
  ).whenComplete(controller.dispose);
}
```

`lib/features/lights/widgets/forget_light_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_sheet.dart';

/// "Forget <name>?" (spec §10.4). Resolves to true only on Forget.
Future<bool> showForgetLightSheet(
  BuildContext context, {
  required String name,
}) async {
  var navigator = Navigator.of(context, rootNavigator: true);
  var sure = await showWizSheet<bool>(
    context,
    title: Strings.forgetTitle(name),
    builder: (context) => Text(
      Strings.forgetBody,
      style: context.wiz.typography.body.copyWith(
        color: context.wiz.colors.textSecondary,
      ),
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      WizButton(
        label: Strings.forget,
        variant: WizButtonVariant.danger,
        fullWidth: true,
        onPressed: () => navigator.pop(true),
      ),
    ],
  );
  return sure ?? false;
}
```

`lib/features/lights/widgets/light_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';

/// A forgotten light toasts and leaves the screen; an error toasts.
class LightNoticeListener extends StatelessWidget {
  final Widget child;
  const LightNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LightBloc, LightState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        switch (state.notice!) {
          case LightForgottenNotice(:var name):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.forgotten(name),
              body: Strings.removedFromConfig,
            );
            var roomId = state.light?.roomId;
            if (context.canPop()) {
              context.pop();
            } else if (roomId != null) {
              context.go(AppRoutes.room(roomId));
            } else {
              context.go(AppRoutes.home);
            }
          case LightError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
        context.read<LightBloc>().add(const LightNoticeCleared());
      },
      child: child,
    );
  }
}
```

`lib/features/lights/view/light_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_power_key.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';
import '../widgets/device_panel.dart';
import '../widgets/light_dials_panel.dart';
import '../widgets/light_hero.dart';
import '../widgets/light_modes_panel.dart';
import '../widgets/light_stat_tiles.dart';

/// A light on a phone (spec §10.4).
class LightScreen extends StatelessWidget {
  const LightScreen({super.key});

  /// Same dials as the room (`WizCtl_Mobile.dc.html` line 302).
  static const double dialSize = 132;

  void _back(BuildContext context, String? roomId) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(roomId == null ? AppRoutes.home : AppRoutes.room(roomId));
    }
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var bloc = context.read<LightBloc>();
        var light = state.light;
        if (state.status != LightStatus.ready || light == null) {
          return const ScreenScroll(children: []);
        }
        var reachable = state.live.reachable;
        return ScreenScroll(
          children: [
            WizTopBar(
              title: light.name,
              subtitle: Strings.roomAndClass(
                state.room?.name ?? '',
                light.className,
              ),
              leading: WizIconKey(
                icon: WizIcons.chevronLeft,
                semanticsLabel: Strings.back,
                onPressed: () => _back(context, light.roomId),
              ),
              trailing: WizBadge(
                label: reachable ? Strings.live : Strings.noReply,
                tone: reachable ? WizBadgeTone.online : WizBadgeTone.danger,
                dot: true,
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            const LightHero(),
            Center(
              child: WizPowerKey(
                on: state.live.isOn,
                onChanged: (on) => bloc.add(LightPowerChanged(on)),
              ),
            ),
            if (!reachable)
              WizStatusBanner(
                status: WizStatus.error,
                title: Strings.noReplyFromLight,
                body: Strings.mayBeOffAtWall,
                action: WizButton(
                  label: Strings.retry,
                  variant: WizButtonVariant.ghost,
                  size: WizButtonSize.sm,
                  onPressed: () => bloc.add(const LightRetryRequested()),
                ),
              ),
            const LightStatTiles(),
            if (state.isSocket)
              WizPanel(
                variant: WizPanelVariant.inset,
                child: Text(
                  Strings.plugOnlyNote,
                  style: wiz.typography.bodySm.copyWith(
                    color: wiz.colors.textTertiary,
                  ),
                ),
              )
            else ...[
              const LightDialsPanel(dialSize: dialSize),
              const LightModesPanel(),
            ],
            const DevicePanel(),
          ],
        );
      },
    );
  }
}
```

Ruling recorded for the reviewer and the hand-over: spec §12's "shared-element hero (name and fixture icon) from light card to light detail" is not in this plan. The kit's `LightCard` and `WizTopBar` each render their own text, so a `Hero` needs a kit change in both and a flight that has to be judged on device; it goes on the polish list with whatever the end-of-plan review finds. The 300 ms fade (spec §9) covers the push. Cost if wrong: one small task later.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app test/features/lights`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app/widgets lib/features/lights lib/core/copy/strings.dart test/
git commit -m "feat(lights): the light detail screen with its hero, panels and sheets"
```

---

### Task 14: DiscoveryBloc, and discovery without a home

**Files:**
- Modify: `lib/domain/usecases/run_discovery.dart`, `test/domain/usecases/run_discovery_test.dart`
- Create: `lib/features/discovery/bloc/discovery_bloc.dart`, `lib/features/discovery/bloc/discovery_event.dart`, `lib/features/discovery/bloc/discovery_state.dart`
- Test: `test/features/discovery/bloc/discovery_bloc_test.dart`

**Interfaces:**
- Consumes: `RunDiscovery.call({homeId, mode, probeKnown})` yielding `PhaseChanged(progress)`, `DeviceFound(device, initial)`, `DeviceUpdated(device)`, `DiscoveryFinished(devices, subnet, {failedRanges})`, `DiscoveryFailed(failure)`; `DiscoveryMode.quick/sweep`; `DiscoveryProgress(phase, probed, total, fraction, subnet)`; `SaveDiscoveredLight({homeId, roomId, device, alias, fixture, initial})` (throws `AlreadySavedException`); `LearnHomeSubnet(homeId, subnet)`; `SyncCoordinator.pauseForDiscovery/resumeAfterDiscovery`; `DiscoveredDevice.copyWith(alreadySaved:)`.
- Produces:

```dart
// run_discovery.dart: homeId becomes optional
Stream<DiscoveryUpdate> call({String? homeId, required DiscoveryMode mode, bool probeKnown = true});
// discovery_event.dart
sealed class DiscoveryEvent; final class DiscoveryStarted, DiscoverySweepRequested, DiscoveryCancelled, DiscoveryKeepToggled(String ip),
    DiscoverySaveRequested({required String ip, required String alias, required String roomId, required Fixture fixture}),
    DiscoveryNoticeCleared, DiscoveryUpdateReceived(DiscoveryUpdate update), DiscoveryRunEnded   // the last two are fed by the bloc itself
// discovery_state.dart
enum DiscoveryView { idle, probingKnown, broadcasting, sweeping, found, empty, error }
class FoundDevice extends Equatable { DiscoveredDevice device; LiveState? initial; bool kept; }
sealed class DiscoveryNotice; final class LightSavedNotice(String alias, String ip), SaveFailedNotice(String message)
class DiscoveryState extends Equatable {
  DiscoveryView view; DiscoveryProgress? progress; List<FoundDevice> found; Map<String, String> saving /* ip → alias */; String? subnet;
  DeviceFailure? failure; bool sweptOnce; List<String> failedRanges; DiscoveryNotice? notice;
  bool get isScanning; int get keptCount; List<FoundDevice> get kept;
}
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc({String? homeId, required RunDiscovery runDiscovery, required SaveDiscoveredLight saveDiscoveredLight,
      required LearnHomeSubnet learnHomeSubnet, required SyncCoordinator sync, bool onboarding = false});
}
```

- [ ] **Step 1: Write the failing tests**

Append to `test/domain/usecases/run_discovery_test.dart` (inside `main`, using its `gateway`, `lights`, `store`, `clock` fixtures):

```dart
  test('with no home there is nothing to probe and nothing already saved', () async {
    gateway.broadcastResult = [
      const DiscoveredLight(ip: '192.168.1.126', mac: 'a8bb50f1c204', moduleName: 'ESP01_SHRGB1C_31'),
    ];
    gateway.states['192.168.1.126'] = const LightState(isOn: true, dimming: 40);
    var updates = await RunDiscovery(
      gateway: gateway,
      lights: lights,
      store: store,
      network: FakeNetworkInfo('192.168.1'),
      clock: clock,
    )(mode: DiscoveryMode.quick).toList();
    expect(gateway.probeCalls, isEmpty);
    expect(updates.first, const PhaseChanged(DiscoveryProgress(phase: DiscoveryPhase.broadcasting)));
    var found = updates.whereType<DeviceFound>().single;
    expect(found.device.alreadySaved, isFalse, reason: 'a known MAC, but no home to know it');
    expect(found.initial?.brightness, 40);
    expect(updates.last, isA<DiscoveryFinished>());
  });
```

(`lights` in that file is seeded with a light carrying MAC `knownmac` on home `h`; the assertion above only needs no home to be passed.)

`test/features/discovery/bloc/discovery_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_event.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

/// Writes down when discovery pauses and resumes polling.
class _RecordingSync extends SyncCoordinator {
  final List<String> calls = [];
  _RecordingSync({required super.refresh, required super.lights, required super.settings});
  @override
  void pauseForDiscovery() {
    calls.add('pause');
    super.pauseForDiscovery();
  }

  @override
  void resumeAfterDiscovery() {
    calls.add('resume');
    super.resumeAfterDiscovery();
  }
}

const _rgb = DiscoveredLight(ip: '192.168.1.126', mac: 'newrgb', moduleName: 'ESP01_SHRGB1C_31');
const _dw = DiscoveredLight(ip: '192.168.1.131', mac: 'newdw', moduleName: 'ESP01_SHDW1C_31');
const _known = DiscoveredLight(ip: '192.168.1.104', mac: 'a8bb50f1c204', moduleName: 'ESP01_SHRGB1C_31');

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late _RecordingSync sync;
  late FakeClock clock;

  DiscoveryBloc build({String? homeId = 'h1', bool onboarding = false}) => DiscoveryBloc(
    homeId: homeId,
    onboarding: onboarding,
    runDiscovery: RunDiscovery(
      gateway: gateway,
      lights: seed.lights,
      store: seed.store,
      network: FakeNetworkInfo('192.168.1'),
      clock: clock,
    ),
    saveDiscoveredLight: SaveDiscoveredLight(
      lights: seed.lights,
      store: seed.store,
      ids: SequenceIds(),
      clock: clock,
    ),
    learnHomeSubnet: LearnHomeSubnet(homes: seed.homes),
    sync: sync,
  );

  setUp(() {
    seed = SeedHome();
    gateway = FakeGateway();
    clock = FakeClock();
    sync = _RecordingSync(
      refresh: RefreshStates(gateway: gateway, store: seed.store, lights: seed.lights, clock: clock),
      lights: seed.lights,
      settings: seed.settings,
    );
    gateway.probeEvents = [const ScanDone([])];
    gateway.broadcastResult = [_rgb, _dw, _known];
    gateway.states['192.168.1.126'] = const LightState(isOn: true, dimming: 40, temperature: 3000);
    gateway.states['192.168.1.131'] = const LightState(isOn: false, dimming: 60);
    gateway.states['192.168.1.104'] = const LightState(isOn: true, dimming: 70);
  });

  tearDown(() => sync.dispose());

  const wait = Duration(milliseconds: 20);

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a quick run probes the known addresses, broadcasts, and ends found',
    build: build,
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    expect: () => [
      isA<DiscoveryState>().having((s) => s.view, 'view', DiscoveryView.probingKnown),
      isA<DiscoveryState>().having((s) => s.view, 'view', DiscoveryView.broadcasting),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(1)),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(2)),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(3)),
      isA<DiscoveryState>().having((s) => s.view, 'view', DiscoveryView.found),
    ],
    verify: (bloc) {
      var s = bloc.state;
      expect(gateway.probeCalls.single, containsAll(['192.168.1.104', '192.168.1.118']));
      expect(s.found.map((f) => f.device.displayName), ['WiZ RGB', 'WiZ Dimmable', 'WiZ RGB']);
      expect(s.found.first.initial?.brightness, 40);
      expect(s.found.first.kept, isTrue);
      expect(s.found.last.device.alreadySaved, isTrue, reason: 'the dome is already in the home');
      expect(s.subnet, '192.168.1');
      expect(s.sweptOnce, isFalse);
      expect(sync.calls, ['pause', 'resume']);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'onboarding has no home: no probe, nothing already saved',
    build: () => build(homeId: null, onboarding: true),
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) {
      expect(gateway.probeCalls, isEmpty);
      expect(bloc.state.view, DiscoveryView.found);
      expect(bloc.state.found.every((f) => !f.device.alreadySaved), isTrue);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a sweep reports its progress and remembers it swept',
    build: build,
    setUp: () {
      gateway.sweepEvents = [
        const ScanProgress(addressesProbed: 34, addressCount: 254, fraction: 34 / 254, subnet: '192.168.1'),
        const ScanFound(_rgb),
        const ScanProgress(addressesProbed: 254, addressCount: 254, fraction: 1, subnet: '192.168.1'),
        const ScanDone([_rgb]),
      ];
    },
    act: (bloc) => bloc.add(const DiscoverySweepRequested()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.view, DiscoveryView.found);
      expect(bloc.state.sweptOnce, isTrue);
      expect(bloc.state.found, hasLength(1));
      expect(bloc.state.progress?.total, 254);
      expect(bloc.state.progress?.probed, 254);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'nothing answering is the empty view',
    build: build,
    setUp: () => gateway.broadcastResult = [],
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.view, DiscoveryView.empty),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a port that will not open is the error view, and polling resumes',
    build: build,
    setUp: () => gateway.failing['broadcast'] = const UnreachableFailure('broadcast', 'port busy'),
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.view, DiscoveryView.error);
      expect(bloc.state.failure, isA<UnreachableFailure>());
      expect(sync.calls.last, 'resume');
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'keep toggles, and saving marks the row and raises the notice',
    build: build,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      bloc.add(const DiscoveryKeepToggled('192.168.1.126'));
      bloc.add(const DiscoverySaveRequested(
        ip: '192.168.1.131', alias: 'Hall plug', roomId: 'bedroom', fixture: Fixture.bulb,
      ));
    },
    wait: wait,
    verify: (bloc) async {
      expect(bloc.state.found.first.kept, isFalse);
      expect(bloc.state.keptCount, 2);
      expect(bloc.state.found[1].device.alreadySaved, isTrue);
      expect(bloc.state.saving, isEmpty);
      expect(bloc.state.notice, const LightSavedNotice('Hall plug', '192.168.1.131'));
      var saved = await seed.lights.getByMac('h1', 'newdw');
      expect(saved?.name, 'Hall plug');
      expect(saved?.roomId, 'bedroom');
      expect(seed.store.of(saved!.id).brightness, 60, reason: 'the initial read seeded the store');
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'saving the same bulb twice is refused with the use case\'s line',
    build: build,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      bloc.add(const DiscoverySaveRequested(
        ip: '192.168.1.104', alias: 'Dome again', roomId: 'living', fixture: Fixture.dome,
      ));
    },
    wait: wait,
    verify: (bloc) => expect(
      bloc.state.notice,
      const SaveFailedNotice('This light is already in this home.'),
    ),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a home without a subnet learns it from the run',
    build: () => build(homeId: 'h2'),
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) async => expect((await seed.homes.get('h2'))?.subnet, '192.168.1'),
  );

  test('closing cancels the run and resumes polling', () async {
    var bloc = build()..add(const DiscoveryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await bloc.close();
    expect(sync.calls.last, 'resume');
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/usecases/run_discovery_test.dart test/features/discovery`
Expected: the new domain test fails to compile (`homeId` is required); the bloc tests fail to compile.

- [ ] **Step 3: Make `homeId` optional, then write the bloc**

In `lib/domain/usecases/run_discovery.dart` change the signature to `String? homeId` and the first line of the body to

```dart
    var known = homeId == null
        ? const <Light>[]
        : await _lights.getByHome(homeId);
```

and add to the class doc: "Without a [homeId] (the first run) nothing is probed and nothing is already saved." Check `lib/app/dependencies.dart` and Plan 3's tests still compile (they pass `homeId:` by name).

`lib/features/discovery/bloc/discovery_event.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';

sealed class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();
  @override
  List<Object?> get props => const [];
}

/// Probe the known addresses (when there is a home), then broadcast.
final class DiscoveryStarted extends DiscoveryEvent {
  const DiscoveryStarted();
}

/// The unicast sweep, only ever on the user's key (spec §5.7).
final class DiscoverySweepRequested extends DiscoveryEvent {
  const DiscoverySweepRequested();
}

final class DiscoveryCancelled extends DiscoveryEvent {
  const DiscoveryCancelled();
}

/// Onboarding's keep/drop check on a found row.
final class DiscoveryKeepToggled extends DiscoveryEvent {
  final String ip;
  const DiscoveryKeepToggled(this.ip);
  @override
  List<Object?> get props => [ip];
}

final class DiscoverySaveRequested extends DiscoveryEvent {
  final String ip;
  final String alias;
  final String roomId;
  final Fixture fixture;
  const DiscoverySaveRequested({
    required this.ip,
    required this.alias,
    required this.roomId,
    required this.fixture,
  });
  @override
  List<Object?> get props => [ip, alias, roomId, fixture];
}

final class DiscoveryNoticeCleared extends DiscoveryEvent {
  const DiscoveryNoticeCleared();
}

/// Fed by the bloc itself from the running stream; not for views.
final class DiscoveryUpdateReceived extends DiscoveryEvent {
  final DiscoveryUpdate update;
  const DiscoveryUpdateReceived(this.update);
  @override
  List<Object?> get props => [update];
}

/// Fed by the bloc itself when the stream closes; not for views.
final class DiscoveryRunEnded extends DiscoveryEvent {
  const DiscoveryRunEnded();
}
```

`lib/features/discovery/bloc/discovery_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

/// What the screen shows (spec §8 "phase (idle/probingKnown/broadcasting/
/// sweeping/found/empty/error)").
enum DiscoveryView { idle, probingKnown, broadcasting, sweeping, found, empty, error }

/// A device that answered, its first read, and whether onboarding keeps it.
class FoundDevice extends Equatable {
  final DiscoveredDevice device;
  final LiveState? initial;
  final bool kept;
  const FoundDevice({required this.device, this.initial, this.kept = true});

  FoundDevice copyWith({DiscoveredDevice? device, LiveState? initial, bool? kept}) =>
      FoundDevice(
        device: device ?? this.device,
        initial: initial ?? this.initial,
        kept: kept ?? this.kept,
      );

  @override
  List<Object?> get props => [device, initial, kept];
}

sealed class DiscoveryNotice extends Equatable {
  const DiscoveryNotice();
}

/// "<alias> saved" / "<ip> added to this home".
final class LightSavedNotice extends DiscoveryNotice {
  final String alias;
  final String ip;
  const LightSavedNotice(this.alias, this.ip);
  @override
  List<Object?> get props => [alias, ip];
}

final class SaveFailedNotice extends DiscoveryNotice {
  final String message;
  const SaveFailedNotice(this.message);
  @override
  List<Object?> get props => [message];
}

class DiscoveryState extends Equatable {
  final DiscoveryView view;
  final DiscoveryProgress? progress;
  final List<FoundDevice> found;

  /// Saves in flight, by address, with the alias each is being given; the
  /// view names its loading toast from this.
  final Map<String, String> saving;
  final String? subnet;
  final DeviceFailure? failure;

  /// Whether a sweep has run in this screen's life: the empty state's copy
  /// and the found banner's body change after one (spec §10.8).
  final bool sweptOnce;
  final List<String> failedRanges;
  final DiscoveryNotice? notice;

  const DiscoveryState({
    required this.view,
    this.progress,
    required this.found,
    required this.saving,
    this.subnet,
    this.failure,
    this.sweptOnce = false,
    this.failedRanges = const [],
    this.notice,
  });

  static const DiscoveryState initial = DiscoveryState(
    view: DiscoveryView.idle,
    found: [],
    saving: {},
  );

  bool get isScanning =>
      view == DiscoveryView.probingKnown ||
      view == DiscoveryView.broadcasting ||
      view == DiscoveryView.sweeping;

  List<FoundDevice> get kept => found.where((f) => f.kept).toList();
  int get keptCount => kept.length;

  DiscoveryState copyWith({
    DiscoveryView? view,
    DiscoveryProgress? progress,
    bool clearProgress = false,
    List<FoundDevice>? found,
    Map<String, String>? saving,
    String? subnet,
    DeviceFailure? failure,
    bool clearFailure = false,
    bool? sweptOnce,
    List<String>? failedRanges,
    DiscoveryNotice? notice,
    bool clearNotice = false,
  }) => DiscoveryState(
    view: view ?? this.view,
    progress: clearProgress ? null : progress ?? this.progress,
    found: found ?? this.found,
    saving: saving ?? this.saving,
    subnet: subnet ?? this.subnet,
    failure: clearFailure ? null : failure ?? this.failure,
    sweptOnce: sweptOnce ?? this.sweptOnce,
    failedRanges: failedRanges ?? this.failedRanges,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    view, progress, found, saving, subnet, failure, sweptOnce, failedRanges, notice,
  ];
}
```

`lib/features/discovery/bloc/discovery_bloc.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// The discovery run (spec §5.7, §8, §10.8): drives `RunDiscovery`,
/// pauses polling while it runs, keeps what answered, saves rows into the
/// home, and teaches the home its subnet the first time.
///
/// With no [homeId] (onboarding) nothing is probed, nothing is already
/// saved and saving is not offered; the kept rows are handed to
/// `OnboardingBloc` instead.
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final String? homeId;
  final bool onboarding;
  final RunDiscovery _run;
  final SaveDiscoveredLight _save;
  final LearnHomeSubnet _learn;
  final SyncCoordinator _sync;
  StreamSubscription<DiscoveryUpdate>? _subscription;
  DiscoveryMode? _mode;

  DiscoveryBloc({
    this.homeId,
    this.onboarding = false,
    required RunDiscovery runDiscovery,
    required SaveDiscoveredLight saveDiscoveredLight,
    required LearnHomeSubnet learnHomeSubnet,
    required SyncCoordinator sync,
  }) : _run = runDiscovery, // ignore: prefer_initializing_formals
       _save = saveDiscoveredLight, // ignore: prefer_initializing_formals
       _learn = learnHomeSubnet, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(DiscoveryState.initial) {
    on<DiscoveryStarted>((_, emit) => _start(DiscoveryMode.quick, emit));
    on<DiscoverySweepRequested>((_, emit) => _start(DiscoveryMode.sweep, emit));
    on<DiscoveryCancelled>(_onCancelled);
    on<DiscoveryUpdateReceived>(_onUpdate);
    on<DiscoveryRunEnded>(_onEnded);
    on<DiscoveryKeepToggled>(_onKeep);
    on<DiscoverySaveRequested>(_onSave);
    on<DiscoveryNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  void _start(DiscoveryMode mode, Emitter<DiscoveryState> emit) {
    unawaited(_subscription?.cancel());
    _mode = mode;
    _sync.pauseForDiscovery();
    var probes = homeId != null && !onboarding;
    emit(
      state.copyWith(
        view: switch (mode) {
          DiscoveryMode.sweep => DiscoveryView.sweeping,
          DiscoveryMode.quick when probes => DiscoveryView.probingKnown,
          DiscoveryMode.quick => DiscoveryView.broadcasting,
        },
        found: const [],
        clearProgress: true,
        clearFailure: true,
        failedRanges: const [],
      ),
    );
    _subscription = _run(homeId: homeId, mode: mode, probeKnown: probes).listen(
      (update) => add(DiscoveryUpdateReceived(update)),
      onError: (Object error) =>
          add(DiscoveryUpdateReceived(DiscoveryFailed(UnreachableFailure('', '$error')))),
      onDone: () => add(const DiscoveryRunEnded()),
    );
  }

  Future<void> _onCancelled(
    DiscoveryCancelled event,
    Emitter<DiscoveryState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    _sync.resumeAfterDiscovery();
    if (state.isScanning) {
      emit(state.copyWith(view: state.found.isEmpty ? DiscoveryView.idle : DiscoveryView.found));
    }
  }

  void _onUpdate(DiscoveryUpdateReceived event, Emitter<DiscoveryState> emit) {
    switch (event.update) {
      case PhaseChanged(:var progress):
        emit(
          state.copyWith(
            view: switch (progress.phase) {
              DiscoveryPhase.probingKnown => DiscoveryView.probingKnown,
              DiscoveryPhase.broadcasting => DiscoveryView.broadcasting,
              DiscoveryPhase.sweeping => DiscoveryView.sweeping,
            },
            progress: progress,
            subnet: progress.subnet,
          ),
        );
      case DeviceFound(:var device, :var initial):
        emit(
          state.copyWith(
            found: [...state.found, FoundDevice(device: device, initial: initial)],
          ),
        );
      case DeviceUpdated(:var device):
        emit(
          state.copyWith(
            found: [
              for (var f in state.found)
                f.device.mac == device.mac ? f.copyWith(device: device) : f,
            ],
          ),
        );
      case DiscoveryFinished(:var devices, :var subnet, :var failedRanges):
        var byMac = {for (var f in state.found) f.device.mac: f};
        var found = [
          for (var d in devices)
            byMac[d.mac]?.copyWith(device: d) ?? FoundDevice(device: d),
        ];
        emit(
          state.copyWith(
            view: found.isEmpty ? DiscoveryView.empty : DiscoveryView.found,
            found: found,
            subnet: subnet,
            sweptOnce: state.sweptOnce || _mode == DiscoveryMode.sweep,
            failedRanges: failedRanges,
          ),
        );
        var home = homeId;
        if (home != null && subnet != null) unawaited(_learn(home, subnet));
      case DiscoveryFailed(:var failure):
        emit(state.copyWith(view: DiscoveryView.error, failure: failure));
    }
  }

  void _onEnded(DiscoveryRunEnded event, Emitter<DiscoveryState> emit) {
    _subscription = null;
    _sync.resumeAfterDiscovery();
    if (state.isScanning) {
      // The stream closed without a Finished: treat what arrived as final.
      emit(state.copyWith(view: state.found.isEmpty ? DiscoveryView.empty : DiscoveryView.found));
    }
  }

  void _onKeep(DiscoveryKeepToggled event, Emitter<DiscoveryState> emit) {
    emit(
      state.copyWith(
        found: [
          for (var f in state.found)
            f.device.ip == event.ip ? f.copyWith(kept: !f.kept) : f,
        ],
      ),
    );
  }

  Future<void> _onSave(
    DiscoverySaveRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    var home = homeId;
    FoundDevice? row;
    for (var f in state.found) {
      if (f.device.ip == event.ip) row = f;
    }
    if (home == null || row == null) return;
    emit(state.copyWith(saving: {...state.saving, event.ip: event.alias}));
    try {
      await _save(
        homeId: home,
        roomId: event.roomId,
        device: row.device,
        alias: event.alias,
        fixture: event.fixture,
        initial: row.initial,
      );
      emit(
        state.copyWith(
          found: [
            for (var f in state.found)
              f.device.ip == event.ip
                  ? f.copyWith(device: f.device.copyWith(alreadySaved: true))
                  : f,
          ],
          saving: {...state.saving}..remove(event.ip),
          notice: LightSavedNotice(event.alias, event.ip),
        ),
      );
    } on DomainException catch (e) {
      emit(
        state.copyWith(
          saving: {...state.saving}..remove(event.ip),
          notice: SaveFailedNotice(e.message),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _sync.resumeAfterDiscovery();
    return super.close();
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/domain/usecases test/features/discovery test/app/dependencies_test.dart`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/domain/usecases/run_discovery.dart test/domain/usecases/run_discovery_test.dart lib/features/discovery/bloc test/features/discovery
git commit -m "feat(discovery): DiscoveryBloc, and a run without a home for the first launch"
```

---

### Task 15: The Discovery screen and the Save light sheet

**Files:**
- Create: `lib/features/discovery/view/discovery_screen.dart`, `lib/features/discovery/widgets/scanning_view.dart`, `lib/features/discovery/widgets/found_row.dart`, `lib/features/discovery/widgets/discovery_empty.dart`, `lib/features/discovery/widgets/save_light_sheet.dart`, `lib/features/discovery/widgets/discovery_notice_listener.dart`, `lib/features/discovery/widgets/skeleton_rows.dart`
- Modify: `lib/core/copy/strings.dart`, `test/support/app_scope.dart`
- Test: `test/features/discovery/view/discovery_screen_test.dart`

**Interfaces:**
- Consumes: `DiscoveryBloc` (Task 14), `BlinkKey`, `LightCardWell`, `WizListRow`, `WizStatusBanner`, `WizFilamentBar`, `WizSkeleton`, `WizEmptyState`, `WizBadge`, `WizButton`, `WizChip`, `WizTextField`, `WizPanel`, `showWizSheet`, `showRoomSheet` (Task 7), `AddRoom` (provided by type), `RoomRepository` (provided), `ScreenScroll`, `FieldLabel`, `Fixture.defaultFor`.
- Produces:

```dart
class DiscoveryScreen extends StatelessWidget { const DiscoveryScreen(); }   // expects a DiscoveryBloc above it
class ScanningView, FoundRow, DiscoveryEmpty, SkeletonRows (widgets)
Future<({String alias, String roomId})?> showSaveLightSheet(BuildContext context, {required DiscoveredDevice device, required String homeId});
class DiscoveryNoticeListener extends StatefulWidget { DiscoveryNoticeListener({required Widget child}); }
// Strings
discoverLightsTitle, discovery, localNetwork, nothingFoundYet, lightsAnswerLocally, sweepTheSubnet, discovering, broadcast, sweepSubnet,
saved, nameThisLight, room, saveLight, tryAgain, portBusyTitle, portBusyBody, listeningForLights;
addedToHome(ip), saving(alias), aliasSaved(alias), lightsAnswered(n), addresses(probed, total), sweeping(subnet), listeningOn(subnet),
sweptSubnet(subnet, total), broadcastOn(subnet), ipAndClass(ip, cls)
```

- [ ] **Step 1: Write the failing test**

`test/features/discovery/view/discovery_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_skeleton.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/discovery/widgets/discovery_notice_listener.dart';

import '../../../support/app_scope.dart';
import '../../../support/fakes.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

const _rgb = DiscoveredLight(ip: '192.168.1.126', mac: 'newrgb', moduleName: 'ESP01_SHRGB1C_31');
const _known = DiscoveredLight(ip: '192.168.1.104', mac: 'a8bb50f1c204', moduleName: 'ESP01_SHRGB1C_31');

void main() {
  late AppScope scope;
  late DiscoveryBloc bloc;

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
    scope.gateway.probeEvents = [const ScanDone([])];
    scope.gateway.broadcastResult = [_rgb, _known];
    scope.gateway.states['192.168.1.126'] = const LightState(isOn: true, dimming: 40);
    bloc = DiscoveryBloc(
      homeId: 'h1',
      runDiscovery: RunDiscovery(
        gateway: scope.gateway,
        lights: scope.seed.lights,
        store: scope.seed.store,
        network: FakeNetworkInfo('192.168.1'),
        clock: scope.clock,
      ),
      saveDiscoveredLight: SaveDiscoveredLight(
        lights: scope.seed.lights,
        store: scope.seed.store,
        ids: scope.ids,
        clock: scope.clock,
      ),
      learnHomeSubnet: LearnHomeSubnet(homes: scope.seed.homes),
      sync: scope.sync,
    );
  });

  tearDown(() async {
    await bloc.close();
    await scope.dispose();
  });

  Widget screen() => scope.wrap(
    BlocProvider.value(
      value: bloc,
      child: const DiscoveryNoticeListener(child: DiscoveryScreen()),
    ),
  );

  testWidgets('idle: the empty state whose key starts a run', (tester) async {
    await pumpRouted(tester, screen());
    expect(find.text('Discover lights'), findsOneWidget);
    expect(find.text('Local network'), findsOneWidget);
    expect(find.text('Nothing found yet'), findsOneWidget);
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pumpAndSettle();
    expect(find.byType(WizStatusBanner), findsOneWidget);
    expect(find.text('2 lights answered'), findsOneWidget);
    expect(find.text('Broadcast on 192.168.1.0/24'), findsOneWidget);
    expect(find.byType(WizListRow), findsNWidgets(2));
    expect(find.text('192.168.1.126 · RGB'), findsOneWidget);
    expect(find.text('SAVE'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget, reason: 'the dome is already in the home');
    expect(find.text('SCAN AGAIN'), findsOneWidget);
    expect(find.text('SWEEP SUBNET'), findsOneWidget);
  });

  testWidgets('while scanning: the loading banner, the filament and three skeletons', (
    tester,
  ) async {
    scope.gateway.sendLatency = const Duration(seconds: 1);
    await pumpRouted(tester, screen());
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pump();
    expect(find.byType(WizFilamentBar), findsOneWidget);
    expect(find.text('DISCOVERING'), findsOneWidget);
    expect(find.byType(WizSkeleton), findsNWidgets(9), reason: 'three rows of a well and two bars');
    await tester.pumpAndSettle();
  });

  testWidgets('nothing found: the empty state offers the sweep and the stale-IP note', (
    tester,
  ) async {
    scope.gateway.broadcastResult = [];
    await pumpRouted(tester, screen());
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pumpAndSettle();
    expect(find.text('No response on the local network'), findsOneWidget);
    expect(
      find.text('Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time.'),
      findsOneWidget,
    );
    expect(
      find.text("The IP shown in the Philips app can be stale — it talks to the cloud. Your router's DHCP client list is the reliable source."),
      findsOneWidget,
    );
    scope.gateway.sweepEvents = [const ScanDone([])];
    await tester.tap(find.text('SCAN SUBNET'));
    await tester.pumpAndSettle();
    expect(scope.gateway.sweepCalls, hasLength(1));
    expect(find.text('Make sure the lights are powered on, then sweep the subnet one address at a time.'), findsOneWidget);
  });

  testWidgets('a busy port is the try-again empty state', (tester) async {
    scope.gateway.failing['broadcast'] = const UnreachableFailure('broadcast', 'busy');
    await pumpRouted(tester, screen());
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pumpAndSettle();
    expect(find.text('Could not open the discovery port'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
  });

  testWidgets('saving a row: sheet, loading toast, then the saved toast', (tester) async {
    await pumpRouted(tester, screen());
    await tester.tap(find.text('DISCOVER LIGHTS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(find.text('Name this light'), findsOneWidget);
    expect(find.text('192.168.1.126 · RGB'), findsNWidgets(2), reason: 'row and sheet');
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'SAVE LIGHT')).enabled, isFalse);
    await tester.enterText(find.byType(WizTextField), 'Reading lamp');
    await tester.pump();
    await tester.tap(find.text('Kitchen'));
    await tester.tap(find.text('SAVE LIGHT'));
    await tester.pump();
    expect(scope.toasts.toasts.single.tone, WizToastTone.loading);
    expect(scope.toasts.toasts.single.title, 'Saving Reading lamp');
    await tester.pumpAndSettle();
    expect(scope.toasts.toasts.single.tone, WizToastTone.success);
    expect(scope.toasts.toasts.single.title, 'Reading lamp saved');
    expect(scope.toasts.toasts.single.body, '192.168.1.126 added to this home');
    expect(find.text('SAVED'), findsNWidgets(2));
    expect((await scope.seed.lights.getByMac('h1', 'newrgb'))?.roomId, 'kitchen');
  });

  testWidgets('on a desktop the bar is titled Discovery with a Rescan key', (tester) async {
    await setSurface(tester, const Size(1200, 800));
    await pumpRouted(tester, screen(), size: const Size(1200, 800));
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('RESCAN'), findsOneWidget);
  });

  testWidgets('back goes home when there is nothing to pop', (tester) async {
    var router = await pumpRouted(tester, screen(), targets: [AppRoutes.home]);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.home);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/discovery/view`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the widgets, the sheet and the screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Discovery (spec §10.8, §15).
  static const discoverLightsTitle = 'Discover lights';
  static const discovery = 'Discovery';
  static const localNetwork = 'Local network';
  static const nothingFoundYet = 'Nothing found yet';
  static const lightsAnswerLocally =
      'Lights answer on your local network. Make sure they are powered on, then scan the subnet.';
  static const sweepTheSubnet =
      'Make sure the lights are powered on, then sweep the subnet one address at a time.';
  static const discovering = 'Discovering';
  static const broadcast = 'Broadcast';
  static const sweepSubnet = 'Sweep subnet';
  static const saved = 'Saved';
  static const nameThisLight = 'Name this light';
  static const room = 'Room';
  static const saveLight = 'Save light';
  static const tryAgain = 'Try again';
  static const portBusyTitle = 'Could not open the discovery port';
  static const portBusyBody = 'Another app is using UDP 38899. Close it, then try again.';
  static const listeningForLights = 'Listening for lights';
  static String addedToHome(String ip) => '$ip added to this home';
  static String saving(String alias) => 'Saving $alias';
  static String aliasSaved(String alias) => '$alias saved';
  static String lightsAnswered(int n) => '${plural(n, 'light')} answered';
  static String addresses(int probed, int total) => '$probed of $total addresses';
  static String sweeping(String subnet) => 'Sweeping $subnet.0/24';
  static String listeningOn(String subnet) => 'Listening on $subnet.0/24';
  static String sweptSubnet(String subnet, int total) => 'Swept $subnet.0/24 · $total addresses';
  static String broadcastOn(String subnet) => 'Broadcast on $subnet.0/24';
  static String ipAndClass(String ip, String cls) => '$ip · $cls';
```

`lib/features/discovery/widgets/skeleton_rows.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_skeleton.dart';

/// Three placeholder rows while a scan runs (spec §15, "three skeleton
/// rows"): a round well and two bars, the gallery's proportions.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key});

  static const int rows = 3;
  static const double well = 40;
  static const double titleWidth = 160, titleHeight = 14;
  static const double metaWidth = 90, metaHeight = 10;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Column(
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) SizedBox(height: space.s4),
          WizPanel(
            padding: EdgeInsets.symmetric(horizontal: space.s6, vertical: space.s5),
            child: Row(
              children: [
                const WizSkeleton(width: well, height: well, circle: true),
                SizedBox(width: space.s5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WizSkeleton(width: titleWidth, height: titleHeight),
                    SizedBox(height: space.s3),
                    const WizSkeleton(width: metaWidth, height: metaHeight),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
```

`lib/features/discovery/widgets/scanning_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_filament_bar.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../bloc/discovery_state.dart';
import 'skeleton_rows.dart';

/// The loading banner, the filament and the skeletons (spec §10.8).
class ScanningView extends StatelessWidget {
  final DiscoveryState state;
  const ScanningView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var sweeping = state.view == DiscoveryView.sweeping;
    var progress = state.progress;
    var subnet = state.subnet;
    var title = sweeping
        ? (subnet == null ? Strings.sweepSubnet : Strings.sweeping(subnet))
        : (subnet == null ? Strings.listeningForLights : Strings.listeningOn(subnet));
    var body = sweeping && progress != null && progress.isDeterminate
        ? Strings.addresses(progress.probed, progress.total)
        : Strings.broadcast;
    return Column(
      children: [
        WizStatusBanner(status: WizStatus.loading, title: title, body: body),
        SizedBox(height: space.s6),
        WizFilamentBar(
          label: Strings.discovering,
          value: sweeping && progress != null && progress.isDeterminate
              ? progress.fraction
              : null,
        ),
        SizedBox(height: space.s6),
        const SkeletonRows(),
      ],
    );
  }
}
```

`lib/features/discovery/widgets/discovery_empty.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';

/// The three empty states (spec §10.8, §15): nothing tried yet, nothing
/// answered (before or after a sweep), and a port that would not open.
class DiscoveryEmpty extends StatelessWidget {
  final DiscoveryState state;
  const DiscoveryEmpty({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<DiscoveryBloc>();
    switch (state.view) {
      case DiscoveryView.idle:
        return WizEmptyState(
          icon: WizIcons.radio,
          title: Strings.nothingFoundYet,
          body: Strings.lightsAnswerLocally,
          action: WizButton(
            label: Strings.discoverLights,
            variant: WizButtonVariant.primary,
            icon: WizIcons.radio,
            onPressed: () => bloc.add(const DiscoveryStarted()),
          ),
        );
      case DiscoveryView.error:
        return WizEmptyState(
          icon: WizIcons.radio,
          title: Strings.portBusyTitle,
          body: Strings.portBusyBody,
          action: WizButton(
            label: Strings.tryAgain,
            variant: WizButtonVariant.primary,
            onPressed: () => bloc.add(const DiscoveryStarted()),
          ),
        );
      case _:
        return Column(
          children: [
            WizEmptyState(
              icon: WizIcons.radio,
              title: Strings.noResponse,
              body: state.sweptOnce ? Strings.sweepTheSubnet : Strings.broadcastHint,
              action: WizButton(
                label: Strings.scanSubnet,
                variant: WizButtonVariant.primary,
                icon: WizIcons.radio,
                onPressed: () => bloc.add(const DiscoverySweepRequested()),
              ),
            ),
            SizedBox(height: wiz.space.s6),
            WizPanel(
              variant: WizPanelVariant.inset,
              child: Text(
                Strings.staleIp,
                style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
              ),
            ),
          ],
        );
    }
  }
}
```

`lib/features/discovery/widgets/found_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/blink_cubit.dart';
import '../../../app/widgets/blink_key.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/light_card_well.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../bloc/discovery_state.dart';

/// One device that answered (spec §10.8): the well emits while it blinks,
/// the flash key, and Save or a spent Saved.
class FoundRow extends StatelessWidget {
  final FoundDevice row;
  final VoidCallback? onSave;
  const FoundRow({super.key, required this.row, required this.onSave});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var device = row.device;
    var blinking = context.select<BlinkCubit, bool>(
      (c) => c.state.isBlinking(device.ip),
    );
    var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
    return WizListRow(
      iconWidget: LightCardWell(icon: WizIcons.lightbulb, lit: blinking),
      title: device.displayName,
      meta: Strings.ipAndClass(device.ip, cls),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlinkKey(ip: device.ip, bulbClass: device.bulbClass),
          SizedBox(width: space.s3),
          device.alreadySaved
              ? const WizButton(
                  label: Strings.saved,
                  variant: WizButtonVariant.ghost,
                  size: WizButtonSize.sm,
                  enabled: false,
                )
              : WizButton(
                  label: Strings.save,
                  variant: WizButtonVariant.primary,
                  size: WizButtonSize.sm,
                  onPressed: onSave,
                ),
        ],
      ),
    );
  }
}
```

Add `static const unknownClass = 'Unknown';` to `Strings` (spec §4: "unknown class shows Unknown").

`lib/features/discovery/widgets/save_light_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_chip.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/usecases/usecases.dart';
import '../../rooms/widgets/add_room_sheet.dart';

/// "Name this light" (spec §10.8): the address, ALIAS, ROOM chips (or a
/// New room chip when the home has none). Resolves to the alias and room,
/// or null.
Future<({String alias, String roomId})?> showSaveLightSheet(
  BuildContext context, {
  required DiscoveredDevice device,
  required String homeId,
}) async {
  var roomsRepo = context.read<RoomRepository>();
  var addRoom = context.read<AddRoom>();
  var rooms = await roomsRepo.getByHome(homeId);
  if (!context.mounted) return null;
  var navigator = Navigator.of(context, rootNavigator: true);
  var controller = TextEditingController();
  var picked = ValueNotifier<String?>(rooms.isEmpty ? null : rooms.first.id);
  var roomList = ValueNotifier<List<Room>>(rooms);
  var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
  return showWizSheet<({String alias, String roomId})>(
    context,
    title: Strings.nameThisLight,
    builder: (context) {
      var wiz = context.wiz;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Strings.ipAndClass(device.ip, cls),
            style: wiz.typography.mono.copyWith(color: wiz.colors.textTertiary),
          ),
          SizedBox(height: wiz.space.s6),
          const FieldLabel(Strings.alias),
          SizedBox(height: wiz.space.s3),
          WizTextField(
            controller: controller,
            placeholder: Strings.aliasPlaceholder,
            autofocus: true,
          ),
          SizedBox(height: wiz.space.s6),
          const FieldLabel(Strings.room),
          SizedBox(height: wiz.space.s3),
          ValueListenableBuilder(
            valueListenable: roomList,
            builder: (context, list, _) => ValueListenableBuilder(
              valueListenable: picked,
              builder: (context, current, _) => Wrap(
                spacing: wiz.space.s3,
                runSpacing: wiz.space.s3,
                children: [
                  for (var room in list)
                    WizChip(
                      label: room.name,
                      selected: room.id == current,
                      onTap: () => picked.value = room.id,
                    ),
                  if (list.isEmpty)
                    WizChip(
                      label: Strings.newRoom,
                      onTap: () async {
                        var result = await showRoomSheet(
                          context,
                          title: Strings.newRoom,
                          primaryLabel: Strings.createRoom,
                        );
                        if (result == null) return;
                        var room = await addRoom(homeId, result.name, result.glyph);
                        roomList.value = [...roomList.value, room];
                        picked.value = room.id;
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, text, _) => ValueListenableBuilder(
          valueListenable: picked,
          builder: (context, room, _) => WizButton(
            label: Strings.saveLight,
            variant: WizButtonVariant.primary,
            fullWidth: true,
            enabled: text.text.trim().isNotEmpty && room != null,
            onPressed: () => navigator.pop((alias: controller.text.trim(), roomId: room!)),
          ),
        ),
      ),
    ],
  ).whenComplete(() {
    controller.dispose();
    picked.dispose();
    roomList.dispose();
  });
}
```

`lib/features/discovery/widgets/discovery_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';

/// "Saving <alias>" while a save runs, resolved in place to "<alias> saved"
/// (spec §15). Stateful because the loading toast's id has to outlive one
/// build.
class DiscoveryNoticeListener extends StatefulWidget {
  final Widget child;
  const DiscoveryNoticeListener({super.key, required this.child});

  @override
  State<DiscoveryNoticeListener> createState() => _DiscoveryNoticeListenerState();
}

class _DiscoveryNoticeListenerState extends State<DiscoveryNoticeListener> {
  /// Loading toasts by the ip being saved.
  final Map<String, String> _saving = {};

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoveryBloc, DiscoveryState>(
      listenWhen: (a, b) => a.saving != b.saving || (b.notice != null && a.notice != b.notice),
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        for (var entry in state.saving.entries) {
          _saving[entry.key] ??= toasts.push(
            tone: WizToastTone.loading,
            title: Strings.saving(entry.value),
          );
        }
        switch (state.notice) {
          case LightSavedNotice(:var alias, :var ip):
            var id = _saving.remove(ip);
            if (id != null) {
              toasts.update(
                id,
                tone: WizToastTone.success,
                title: Strings.aliasSaved(alias),
                body: Strings.addedToHome(ip),
              );
            } else {
              toasts.push(
                tone: WizToastTone.success,
                title: Strings.aliasSaved(alias),
                body: Strings.addedToHome(ip),
              );
            }
            context.read<DiscoveryBloc>().add(const DiscoveryNoticeCleared());
          case SaveFailedNotice(:var message):
            for (var id in _saving.values) {
              toasts.dismiss(id);
            }
            _saving.clear();
            toasts.push(tone: WizToastTone.error, title: message);
            context.read<DiscoveryBloc>().add(const DiscoveryNoticeCleared());
          case null:
            break;
        }
      },
      child: widget.child,
    );
  }
}
```

`lib/features/discovery/view/discovery_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/discovery_empty.dart';
import '../widgets/found_row.dart';
import '../widgets/save_light_sheet.dart';
import '../widgets/scanning_view.dart';

/// Discovery (spec §10.8): "Discover lights" with a back key on a phone,
/// "Discovery" with a Rescan key on a desktop; then whichever of idle,
/// scanning, empty, error or found applies.
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _save(BuildContext context, FoundDevice row) async {
    var bloc = context.read<DiscoveryBloc>();
    var homeId = bloc.homeId;
    if (homeId == null) return;
    var result = await showSaveLightSheet(context, device: row.device, homeId: homeId);
    if (result == null) return;
    bloc.add(
      DiscoverySaveRequested(
        ip: row.device.ip,
        alias: result.alias,
        roomId: result.roomId,
        fixture: Fixture.defaultFor(row.device.bulbClass),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var compact = context.layout.widthClass.isCompact;
    var offNetwork = context.select<NetworkCubit, bool>((c) => c.state.offNetwork);
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        var bloc = context.read<DiscoveryBloc>();
        var progress = state.progress;
        var subtitle = state.view == DiscoveryView.sweeping && progress != null && progress.isDeterminate
            ? Strings.addresses(progress.probed, progress.total)
            : Strings.localNetwork;
        var subnet = state.subnet;
        return ScreenScroll(
          children: [
            WizTopBar(
              title: compact ? Strings.discoverLightsTitle : Strings.discovery,
              subtitle: subtitle,
              leading: compact
                  ? WizIconKey(
                      icon: WizIcons.chevronLeft,
                      semanticsLabel: Strings.back,
                      onPressed: () => _back(context),
                    )
                  : null,
              trailing: compact
                  ? null
                  : WizButton(
                      label: Strings.rescan,
                      variant: WizButtonVariant.ghost,
                      size: WizButtonSize.sm,
                      icon: WizIcons.refreshCw,
                      onPressed: state.isScanning ? null : () => bloc.add(const DiscoveryStarted()),
                    ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            if (state.isScanning)
              ScanningView(state: state)
            else if (state.view == DiscoveryView.found) ...[
              WizStatusBanner(
                status: WizStatus.success,
                title: Strings.lightsAnswered(state.found.length),
                body: subnet == null
                    ? Strings.localNetwork
                    : state.sweptOnce
                        ? Strings.sweptSubnet(subnet, progress?.total ?? 0)
                        : Strings.broadcastOn(subnet),
                action: const WizBadge(label: Strings.live, tone: WizBadgeTone.online, dot: true),
              ),
              for (var row in state.found)
                FoundRow(row: row, onSave: () => _save(context, row)),
              WizButton(
                label: Strings.scanAgain,
                variant: WizButtonVariant.ghost,
                icon: WizIcons.refreshCw,
                fullWidth: true,
                onPressed: () => bloc.add(const DiscoveryStarted()),
              ),
              WizButton(
                label: Strings.sweepSubnet,
                variant: WizButtonVariant.ghost,
                icon: WizIcons.radio,
                fullWidth: true,
                onPressed: () => bloc.add(const DiscoverySweepRequested()),
              ),
            ] else
              DiscoveryEmpty(state: state),
          ],
        );
      },
    );
  }
}
```

The sweep's total after a sweep: `progress?.total ?? 0` reads the last progress; `FaultInjectingGateway.fakeAddressCount` and the real sweep both report 254 through `ScanProgress.addressCount`, so no literal is needed.

`test/support/app_scope.dart`: add `RepositoryProvider<AddRoom>.value(value: AddRoom(rooms: seed.rooms, ids: ids))` to `wrap`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/discovery`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/discovery lib/core/copy/strings.dart test/features/discovery test/support/app_scope.dart
git commit -m "feat(discovery): the Discovery screen and the Name this light sheet"
```

---

### Task 16: OnboardingBloc

**Files:**
- Create: `lib/features/onboarding/bloc/onboarding_bloc.dart`, `lib/features/onboarding/bloc/onboarding_event.dart`, `lib/features/onboarding/bloc/onboarding_state.dart`
- Test: `test/features/onboarding/bloc/onboarding_bloc_test.dart`

**Interfaces:**
- Consumes: `FinishOnboarding(OnboardingResult)` returning the `Home`; `OnboardingRoom(tempId, name, glyph, custom)`, `OnboardingLight(device, alias, roomTempId, fixture, initial)`, `OnboardingResult(homeName, subnet, rooms, lights)`; `FoundDevice` (Task 14); `Fixture.defaultFor`; `IdGenerator.next`; `EmptyNameException`.
- Produces:

```dart
enum OnboardingStep { nameHome, discovering, nameLights }
class Assignment extends Equatable { String alias; String roomTempId; Fixture fixture; }
sealed class OnboardingEvent; final class OnboardingNameChanged(String name), OnboardingHomeCreated, OnboardingBack,
    OnboardingToNaming(List<FoundDevice> kept, String? subnet), OnboardingAliasChanged(String ip, String alias),
    OnboardingRoomPicked(String ip, String roomTempId), OnboardingFixturePicked(String ip, Fixture fixture),
    OnboardingRoomAdded(String name, RoomGlyph glyph, {String? forIp}), OnboardingFinished, OnboardingNoticeCleared
sealed class OnboardingNotice; final class OnboardingDone(Home home, int lightCount, int roomCount), OnboardingError(String message)
class OnboardingState extends Equatable {
  OnboardingStep step; String draftName; List<OnboardingRoom> setupRooms; List<FoundDevice> kept; String? subnet;
  Map<String, Assignment> assignments; bool finishing; OnboardingNotice? notice;
  bool get nameEmpty; bool get namesComplete; int get roomsToWrite;
  static const List<OnboardingRoom> defaultRooms;
}
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required FinishOnboarding finishOnboarding, required IdGenerator ids});
}
```

- [ ] **Step 1: Write the failing test**

`test/features/onboarding/bloc/onboarding_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_state.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_event.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

const _rgb = FoundDevice(
  device: DiscoveredDevice(ip: '192.168.1.126', mac: 'rgb', bulbClass: BulbClass.rgb),
  initial: LiveState.initial,
);
const _plug = FoundDevice(
  device: DiscoveredDevice(ip: '192.168.1.140', mac: 'plug', bulbClass: BulbClass.socket),
);
const _dropped = FoundDevice(
  device: DiscoveredDevice(ip: '192.168.1.131', mac: 'dw', bulbClass: BulbClass.dw),
  kept: false,
);

void main() {
  late SeedHome seed;

  OnboardingBloc build() => OnboardingBloc(
    finishOnboarding: FinishOnboarding(
      homes: seed.homes,
      rooms: seed.rooms,
      lights: seed.lights,
      settings: seed.settings,
      store: seed.store,
      ids: SequenceIds(),
      clock: FakeClock(),
    ),
    ids: SequenceIds(),
  );

  setUp(() => seed = SeedHome.empty());

  test('the first state is step one with the three offered rooms', () {
    var s = OnboardingState.initial;
    expect(s.step, OnboardingStep.nameHome);
    expect(s.nameEmpty, isTrue);
    expect(s.setupRooms.map((r) => r.name), ['Living Room', 'Bedroom', 'Kitchen']);
    expect(s.setupRooms.every((r) => !r.custom), isTrue);
  });

  blocTest<OnboardingBloc, OnboardingState>(
    'a name moves to discovering; a blank one does not',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('   '))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated()),
    verify: (bloc) {
      expect(bloc.state.step, OnboardingStep.discovering);
      expect(bloc.state.draftName, 'Kaverappa House');
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'to naming: only kept devices, each assigned the first room and its default fixture',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _dropped, _plug], '192.168.1')),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.step, OnboardingStep.nameLights);
      expect(s.kept.map((f) => f.device.ip), ['192.168.1.126', '192.168.1.140']);
      expect(s.subnet, '192.168.1');
      expect(s.assignments['192.168.1.126'], const Assignment(alias: '', roomTempId: 'sr-living', fixture: Fixture.bulb));
      expect(s.assignments['192.168.1.140']?.fixture, Fixture.socket);
      expect(s.namesComplete, isFalse);
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'back walks the steps down',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb], null))
      ..add(const OnboardingBack())
      ..add(const OnboardingBack())
      ..add(const OnboardingBack()),
    verify: (bloc) => expect(bloc.state.step, OnboardingStep.nameHome),
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'alias, room and fixture edits; a new room is custom and can take the light',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingRoomPicked('192.168.1.126', 'sr-bedroom'))
      ..add(const OnboardingFixturePicked('192.168.1.126', Fixture.dome))
      ..add(const OnboardingRoomAdded('Study', RoomGlyph.lampDesk, forIp: '192.168.1.140'))
      ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV')),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.assignments['192.168.1.126'], const Assignment(alias: 'Ceiling dome light', roomTempId: 'sr-bedroom', fixture: Fixture.dome));
      expect(s.setupRooms.last.name, 'Study');
      expect(s.setupRooms.last.custom, isTrue);
      expect(s.assignments['192.168.1.140']?.roomTempId, s.setupRooms.last.tempId);
      expect(s.namesComplete, isTrue);
      expect(s.roomsToWrite, 2, reason: 'Bedroom took a light, Study is custom; Living Room and Kitchen are dropped');
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'finishing writes the home and reports the counts',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV'))
      ..add(const OnboardingFinished()),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) async {
      var notice = bloc.state.notice;
      expect(notice, isA<OnboardingDone>());
      var done = notice! as OnboardingDone;
      expect(done.home.name, 'Kaverappa House');
      expect(done.home.subnet, '192.168.1');
      expect(done.lightCount, 2);
      expect(done.roomCount, 1, reason: 'both lights went to the Living Room');
      expect((await seed.settings.get()).activeHomeId, done.home.id);
      expect(await seed.lights.getByHome(done.home.id), hasLength(2));
      expect(seed.store.of((await seed.lights.getByMac(done.home.id, 'rgb'))!.id), LiveState.initial);
      expect(bloc.state.finishing, isFalse);
    },
  );
}
```

`DiscoveredDevice(bulbClass:)` is a constructor parameter of the app's entity (Plan 3), unlike the package's `DiscoveredLight`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/onboarding`
Expected: FAIL to compile.

- [ ] **Step 3: Write the event, state and bloc**

`lib/features/onboarding/bloc/onboarding_event.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../discovery/bloc/discovery_state.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => const [];
}

final class OnboardingNameChanged extends OnboardingEvent {
  final String name;
  const OnboardingNameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

/// "Create home": the name is kept as a draft and the flow moves on; the
/// home itself is written at the end (spec §10.1).
final class OnboardingHomeCreated extends OnboardingEvent {
  const OnboardingHomeCreated();
}

final class OnboardingBack extends OnboardingEvent {
  const OnboardingBack();
}

/// "Save <n> lights": the discovery step hands over what it kept and the
/// subnet it saw.
final class OnboardingToNaming extends OnboardingEvent {
  final List<FoundDevice> kept;
  final String? subnet;
  const OnboardingToNaming(this.kept, this.subnet);
  @override
  List<Object?> get props => [kept, subnet];
}

final class OnboardingAliasChanged extends OnboardingEvent {
  final String ip;
  final String alias;
  const OnboardingAliasChanged(this.ip, this.alias);
  @override
  List<Object?> get props => [ip, alias];
}

final class OnboardingRoomPicked extends OnboardingEvent {
  final String ip;
  final String roomTempId;
  const OnboardingRoomPicked(this.ip, this.roomTempId);
  @override
  List<Object?> get props => [ip, roomTempId];
}

final class OnboardingFixturePicked extends OnboardingEvent {
  final String ip;
  final Fixture fixture;
  const OnboardingFixturePicked(this.ip, this.fixture);
  @override
  List<Object?> get props => [ip, fixture];
}

/// The New room sheet: a custom room, optionally given the light whose
/// card opened the sheet.
final class OnboardingRoomAdded extends OnboardingEvent {
  final String name;
  final RoomGlyph glyph;
  final String? forIp;
  const OnboardingRoomAdded(this.name, this.glyph, {this.forIp});
  @override
  List<Object?> get props => [name, glyph, forIp];
}

final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}

final class OnboardingNoticeCleared extends OnboardingEvent {
  const OnboardingNoticeCleared();
}
```

`lib/features/onboarding/bloc/onboarding_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import '../../discovery/bloc/discovery_state.dart';

enum OnboardingStep { nameHome, discovering, nameLights }

/// What one kept light will be saved as.
class Assignment extends Equatable {
  final String alias;
  final String roomTempId;
  final Fixture fixture;
  const Assignment({
    required this.alias,
    required this.roomTempId,
    required this.fixture,
  });

  Assignment copyWith({String? alias, String? roomTempId, Fixture? fixture}) =>
      Assignment(
        alias: alias ?? this.alias,
        roomTempId: roomTempId ?? this.roomTempId,
        fixture: fixture ?? this.fixture,
      );

  @override
  List<Object?> get props => [alias, roomTempId, fixture];
}

sealed class OnboardingNotice extends Equatable {
  const OnboardingNotice();
}

/// "<Home> is set up" / "<n> lights in <m> rooms", then `/home`.
final class OnboardingDone extends OnboardingNotice {
  final Home home;
  final int lightCount;
  final int roomCount;
  const OnboardingDone(this.home, this.lightCount, this.roomCount);
  @override
  List<Object?> get props => [home, lightCount, roomCount];
}

final class OnboardingError extends OnboardingNotice {
  final String message;
  const OnboardingError(this.message);
  @override
  List<Object?> get props => [message];
}

class OnboardingState extends Equatable {
  final OnboardingStep step;
  final String draftName;
  final List<OnboardingRoom> setupRooms;
  final List<FoundDevice> kept;
  final String? subnet;
  final Map<String, Assignment> assignments;
  final bool finishing;
  final OnboardingNotice? notice;

  const OnboardingState({
    required this.step,
    required this.draftName,
    required this.setupRooms,
    required this.kept,
    required this.subnet,
    required this.assignments,
    required this.finishing,
    this.notice,
  });

  /// The rooms the first run offers (`WizCtl_Mobile.dc.html` `setupRooms`).
  static const List<OnboardingRoom> defaultRooms = [
    OnboardingRoom(tempId: 'sr-living', name: 'Living Room', glyph: RoomGlyph.sofa, custom: false),
    OnboardingRoom(tempId: 'sr-bedroom', name: 'Bedroom', glyph: RoomGlyph.bed, custom: false),
    OnboardingRoom(tempId: 'sr-kitchen', name: 'Kitchen', glyph: RoomGlyph.utensils, custom: false),
  ];

  static const OnboardingState initial = OnboardingState(
    step: OnboardingStep.nameHome,
    draftName: '',
    setupRooms: defaultRooms,
    kept: [],
    subnet: null,
    assignments: {},
    finishing: false,
  );

  bool get nameEmpty => draftName.trim().isEmpty;

  /// "Finish setup" waits until every kept light has a name (spec §10.1).
  bool get namesComplete =>
      kept.isNotEmpty &&
      kept.every((f) => (assignments[f.device.ip]?.alias ?? '').trim().isNotEmpty);

  /// Rooms that will be written: those that received a light plus the
  /// custom ones (spec §10.1 step 3).
  int get roomsToWrite {
    var used = {for (var a in assignments.values) a.roomTempId};
    return setupRooms.where((r) => r.custom || used.contains(r.tempId)).length;
  }

  OnboardingState copyWith({
    OnboardingStep? step,
    String? draftName,
    List<OnboardingRoom>? setupRooms,
    List<FoundDevice>? kept,
    String? subnet,
    Map<String, Assignment>? assignments,
    bool? finishing,
    OnboardingNotice? notice,
    bool clearNotice = false,
  }) => OnboardingState(
    step: step ?? this.step,
    draftName: draftName ?? this.draftName,
    setupRooms: setupRooms ?? this.setupRooms,
    kept: kept ?? this.kept,
    subnet: subnet ?? this.subnet,
    assignments: assignments ?? this.assignments,
    finishing: finishing ?? this.finishing,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    step, draftName, setupRooms, kept, subnet, assignments, finishing, notice,
  ];
}
```

`lib/features/onboarding/bloc/onboarding_bloc.dart`:

```dart
import 'package:bloc/bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/id_generator.dart';
import '../../../domain/usecases/usecases.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// The first run (spec §8, §10.1): the draft name, the kept lights and
/// what each becomes, written as one home at the end.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final FinishOnboarding _finish;
  final IdGenerator _ids;

  OnboardingBloc({
    required FinishOnboarding finishOnboarding,
    required IdGenerator ids,
  }) : _finish = finishOnboarding, // ignore: prefer_initializing_formals
       _ids = ids, // ignore: prefer_initializing_formals
       super(OnboardingState.initial) {
    on<OnboardingNameChanged>(
      (e, emit) => emit(state.copyWith(draftName: e.name)),
    );
    on<OnboardingHomeCreated>((_, emit) {
      if (state.nameEmpty) return;
      emit(state.copyWith(step: OnboardingStep.discovering));
    });
    on<OnboardingBack>((_, emit) {
      emit(
        state.copyWith(
          step: switch (state.step) {
            OnboardingStep.nameHome => OnboardingStep.nameHome,
            OnboardingStep.discovering => OnboardingStep.nameHome,
            OnboardingStep.nameLights => OnboardingStep.discovering,
          },
        ),
      );
    });
    on<OnboardingToNaming>(_onToNaming);
    on<OnboardingAliasChanged>(
      (e, emit) => _assign(emit, e.ip, (a) => a.copyWith(alias: e.alias)),
    );
    on<OnboardingRoomPicked>(
      (e, emit) => _assign(emit, e.ip, (a) => a.copyWith(roomTempId: e.roomTempId)),
    );
    on<OnboardingFixturePicked>(
      (e, emit) => _assign(emit, e.ip, (a) => a.copyWith(fixture: e.fixture)),
    );
    on<OnboardingRoomAdded>(_onRoomAdded);
    on<OnboardingFinished>(_onFinished);
    on<OnboardingNoticeCleared>((_, emit) => emit(state.copyWith(clearNotice: true)));
  }

  void _onToNaming(OnboardingToNaming event, Emitter<OnboardingState> emit) {
    var kept = event.kept.where((f) => f.kept).toList();
    var first = state.setupRooms.first.tempId;
    emit(
      state.copyWith(
        step: OnboardingStep.nameLights,
        kept: kept,
        subnet: event.subnet,
        assignments: {
          for (var f in kept)
            f.device.ip:
                state.assignments[f.device.ip] ??
                Assignment(
                  alias: '',
                  roomTempId: first,
                  fixture: Fixture.defaultFor(f.device.bulbClass),
                ),
        },
      ),
    );
  }

  void _assign(
    Emitter<OnboardingState> emit,
    String ip,
    Assignment Function(Assignment current) change,
  ) {
    var current = state.assignments[ip];
    if (current == null) return;
    emit(state.copyWith(assignments: {...state.assignments, ip: change(current)}));
  }

  void _onRoomAdded(OnboardingRoomAdded event, Emitter<OnboardingState> emit) {
    var name = event.name.trim();
    if (name.isEmpty) return;
    var room = OnboardingRoom(
      tempId: 'sr-${_ids.next()}',
      name: name,
      glyph: event.glyph,
      custom: true,
    );
    var assignments = state.assignments;
    var forIp = event.forIp;
    if (forIp != null && assignments[forIp] != null) {
      assignments = {
        ...assignments,
        forIp: assignments[forIp]!.copyWith(roomTempId: room.tempId),
      };
    }
    emit(
      state.copyWith(
        setupRooms: [...state.setupRooms, room],
        assignments: assignments,
      ),
    );
  }

  Future<void> _onFinished(
    OnboardingFinished event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.namesComplete || state.finishing) return;
    emit(state.copyWith(finishing: true));
    var lights = [
      for (var f in state.kept)
        OnboardingLight(
          device: f.device,
          alias: state.assignments[f.device.ip]!.alias,
          roomTempId: state.assignments[f.device.ip]!.roomTempId,
          fixture: state.assignments[f.device.ip]!.fixture,
          initial: f.initial,
        ),
    ];
    try {
      var home = await _finish(
        OnboardingResult(
          homeName: state.draftName,
          subnet: state.subnet,
          rooms: state.setupRooms,
          lights: lights,
        ),
      );
      emit(
        state.copyWith(
          finishing: false,
          notice: OnboardingDone(home, lights.length, state.roomsToWrite),
        ),
      );
    } on DomainException catch (e) {
      emit(state.copyWith(finishing: false, notice: OnboardingError(e.message)));
    }
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/onboarding test/features/layering_test.dart`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/onboarding/bloc test/features/onboarding
git commit -m "feat(onboarding): OnboardingBloc"
```

---

### Task 17: The first-run screens

**Files:**
- Create: `lib/features/onboarding/view/onboarding_screen.dart`, `lib/features/onboarding/view/name_home_step.dart`, `lib/features/onboarding/view/discovering_step.dart`, `lib/features/onboarding/view/name_lights_step.dart`, `lib/features/onboarding/widgets/radar.dart`, `lib/features/onboarding/widgets/keep_row.dart`, `lib/features/onboarding/widgets/assign_card.dart`, `lib/features/onboarding/widgets/onboarding_notice_listener.dart`
- Modify: `lib/core/copy/strings.dart`
- Test: `test/features/onboarding/view/onboarding_screen_test.dart`, `test/features/onboarding/widgets/radar_test.dart`

**Interfaces:**
- Consumes: `OnboardingBloc` (Task 16), `DiscoveryBloc` (Task 14, `homeId: null, onboarding: true`), `ScanningView`'s pieces (`SkeletonRows`), `BlinkKey`, `LightCardWell`, `showRoomSheet` (Task 7), `WizTopBar`, `WizIconKey`, `WizTextField`, `WizButton`, `WizChip`, `WizStatusBanner`, `WizEmptyState`, `WizFilamentBar`, `WizPanel`, `WizSurface`, `WizPressable`, `RiseIn`, `wizReducedMotion`, `ScreenScroll`, `FieldLabel`, `Fixture.values/label/iconName`.
- Produces:

```dart
class OnboardingScreen extends StatelessWidget { const OnboardingScreen(); static const double desktopColumn = 560; }   // expects OnboardingBloc and DiscoveryBloc above it
class NameHomeStep, DiscoveringStep, NameLightsStep (views)
class Radar extends StatefulWidget { const Radar(); static const double well = 150, key = 64, ringDelayFraction = 0.32; }
class KeepRow extends StatelessWidget { KeepRow({required FoundDevice row, required VoidCallback onToggle}); }
class AssignCard extends StatelessWidget { AssignCard({required FoundDevice row, required Assignment assignment, required List<OnboardingRoom> rooms}); }
class OnboardingNoticeListener extends StatelessWidget { OnboardingNoticeListener({required Widget child}); }
// Strings
wordmark, nameThisHome, homeStoredHere, homeName, homeNamePlaceholder, createHome, homeRequired, discoveringTitle, sweepingSubnet,
nameYourLights, nameReplacesAddress, finishSetup, plugPlaceholder, bulbPlaceholder, keepLight;
saveNLights(n), homeSetUp(name), lightsInRooms(lights, rooms)
```

- [ ] **Step 1: Write the failing tests**

`test/features/onboarding/widgets/radar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/features/onboarding/widgets/radar.dart';

import '../../../support/wiz_test_app.dart';

void main() {
  testWidgets('the radar is 150 tall with a 64 key and two rings that ping', (tester) async {
    await tester.pumpWidget(wizTestApp(const Radar()));
    expect(tester.getSize(find.byType(Radar)).height, Radar.well);
    expect(find.byKey(Radar.keyKey), findsOneWidget);
    expect(tester.getSize(find.byKey(Radar.keyKey)).width, Radar.key);
    expect(find.byType(PingRing), findsNWidgets(2));
    var before = tester.widget<Transform>(find.descendant(of: find.byType(PingRing).first, matching: find.byType(Transform)).first).transform;
    await tester.pump(const Duration(milliseconds: 700));
    var after = tester.widget<Transform>(find.descendant(of: find.byType(PingRing).first, matching: find.byType(Transform)).first).transform;
    expect(before, isNot(equals(after)), reason: 'the ring grows');
  });

  testWidgets('under reduced motion the rings stand still', (tester) async {
    await tester.pumpWidget(wizTestApp(reducedMotion(const Radar())));
    var before = tester.widget<Transform>(find.descendant(of: find.byType(PingRing).first, matching: find.byType(Transform)).first).transform;
    await tester.pump(const Duration(milliseconds: 700));
    var after = tester.widget<Transform>(find.descendant(of: find.byType(PingRing).first, matching: find.byType(Transform)).first).transform;
    expect(before, equals(after));
  });
}
```

`test/features/onboarding/view/onboarding_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';
import 'package:wizctl_app/features/onboarding/widgets/assign_card.dart';
import 'package:wizctl_app/features/onboarding/widgets/keep_row.dart';
import 'package:wizctl_app/features/onboarding/widgets/onboarding_notice_listener.dart';
import 'package:wizctl_app/features/onboarding/widgets/radar.dart';

import '../../../support/app_scope.dart';
import '../../../support/fakes.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';

const _rgb = DiscoveredLight(ip: '192.168.1.126', mac: 'newrgb', moduleName: 'ESP01_SHRGB1C_31');
const _plug = DiscoveredLight(ip: '192.168.1.140', mac: 'newplug', moduleName: 'ESP01_SOCKET_01');

void main() {
  late AppScope scope;
  late OnboardingBloc onboarding;
  late DiscoveryBloc discovery;

  setUp(() async {
    scope = AppScope(SeedHome.empty());
    await scope.start();
    scope.gateway.broadcastResult = [_rgb, _plug];
    scope.gateway.states['192.168.1.126'] = const LightState(isOn: true, dimming: 40);
    scope.gateway.states['192.168.1.140'] = const LightState(isOn: false);
    onboarding = OnboardingBloc(
      finishOnboarding: FinishOnboarding(
        homes: scope.seed.homes,
        rooms: scope.seed.rooms,
        lights: scope.seed.lights,
        settings: scope.seed.settings,
        store: scope.seed.store,
        ids: scope.ids,
        clock: scope.clock,
      ),
      ids: scope.ids,
    );
    discovery = DiscoveryBloc(
      onboarding: true,
      runDiscovery: RunDiscovery(
        gateway: scope.gateway,
        lights: scope.seed.lights,
        store: scope.seed.store,
        network: FakeNetworkInfo('192.168.1'),
        clock: scope.clock,
      ),
      saveDiscoveredLight: SaveDiscoveredLight(
        lights: scope.seed.lights,
        store: scope.seed.store,
        ids: scope.ids,
        clock: scope.clock,
      ),
      learnHomeSubnet: LearnHomeSubnet(homes: scope.seed.homes),
      sync: scope.sync,
    );
  });

  tearDown(() async {
    await onboarding.close();
    await discovery.close();
    await scope.dispose();
  });

  Widget screen() => scope.wrap(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: onboarding),
        BlocProvider.value(value: discovery),
      ],
      child: const OnboardingNoticeListener(child: OnboardingScreen()),
    ),
  );

  testWidgets('the whole first run, on a phone', (tester) async {
    var router = await pumpRouted(tester, screen(), targets: [AppRoutes.home]);

    // Step 1.
    expect(find.text('WIZCTL'), findsOneWidget);
    expect(find.text('Name this home'), findsOneWidget);
    expect(find.text('No account, no cloud. Lights are reached over UDP on port 38899 on your own network.'), findsOneWidget);
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'CREATE HOME')).enabled, isFalse);
    await tester.enterText(find.byType(WizTextField), 'Kaverappa House');
    await tester.pump();
    await tester.tap(find.text('CREATE HOME'));
    await tester.pump();

    // Step 2 runs the broadcast on entry.
    expect(find.text('Discovering'), findsOneWidget);
    expect(find.byType(Radar), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('2 lights answered'), findsOneWidget);
    expect(find.text('Broadcast on 192.168.1.0/24'), findsOneWidget);
    expect(find.byType(KeepRow), findsNWidgets(2));
    expect(find.text('SAVE 2 LIGHTS'), findsOneWidget);
    await tester.tap(find.text('WiZ Smart Plug'));
    await tester.pump();
    expect(find.text('SAVE 1 LIGHT'), findsOneWidget);
    await tester.tap(find.text('WiZ Smart Plug'));
    await tester.pump();
    await tester.tap(find.text('SAVE 2 LIGHTS'));
    await tester.pumpAndSettle();

    // Step 3.
    expect(find.text('Name your lights'), findsOneWidget);
    expect(find.text('A name replaces the address'), findsOneWidget);
    expect(find.byType(AssignCard), findsNWidgets(2));
    expect(find.text('Living Room'), findsNWidgets(2));
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'FINISH SETUP')).enabled, isFalse);
    var fields = find.byType(WizTextField);
    await tester.enterText(fields.at(0), 'Ceiling dome light');
    await tester.enterText(fields.at(1), 'Plug by the TV');
    await tester.pump();
    await tester.tap(find.text('Bedroom').last);
    await tester.pump();
    expect(tester.widget<WizButton>(find.widgetWithText(WizButton, 'FINISH SETUP')).enabled, isTrue);
    await tester.tap(find.text('FINISH SETUP'));
    await tester.pumpAndSettle();

    expect(scope.toasts.toasts.single.title, 'Kaverappa House is set up');
    expect(scope.toasts.toasts.single.body, '2 lights in 2 rooms');
    expect(currentLocation(router), AppRoutes.home);
    expect(await scope.seed.homes.getAll(), hasLength(1));
  });

  testWidgets('a New room chip creates a custom room and gives it the light', (tester) async {
    await pumpRouted(tester, screen());
    await tester.enterText(find.byType(WizTextField), 'Kaverappa House');
    await tester.pump();
    await tester.tap(find.text('CREATE HOME'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE 2 LIGHTS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New room').first);
    await tester.pumpAndSettle();
    expect(find.text('New room'), findsNWidgets(3), reason: 'two chips and the sheet title');
    await tester.enterText(find.byType(WizTextField).last, 'Study');
    await tester.pump();
    await tester.tap(find.text('CREATE ROOM'));
    await tester.pumpAndSettle();
    expect(onboarding.state.setupRooms.last.name, 'Study');
    expect(onboarding.state.assignments['192.168.1.126']?.roomTempId, onboarding.state.setupRooms.last.tempId);
    expect(find.text('Study'), findsNWidgets(2), reason: 'a chip on each card');
  });

  testWidgets('on a wide surface the steps sit in a centred 560 column', (tester) async {
    await setSurface(tester, const Size(1200, 800));
    await pumpRouted(tester, screen(), size: const Size(1200, 800));
    expect(tester.getSize(find.byType(ConstrainedBox).first).width, lessThanOrEqualTo(OnboardingScreen.desktopColumn));
  });
}
```

(`setSurface` from `../../../support/wiz_test_app.dart`.) The last assertion is loose on purpose: find the `ConstrainedBox` the screen adds by giving it `key: OnboardingScreen.columnKey` and assert on that key instead of `.first`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/onboarding`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the widgets and the steps**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // First run (spec §10.1).
  static const wordmark = 'WIZCTL';
  static const nameThisHome = 'Name this home';
  static const homeStoredHere =
      "Rooms and lights are stored in this home's config file on this machine. You can keep several homes here.";
  static const homeName = 'Home name';
  static const homeNamePlaceholder = 'Kaverappa House';
  static const createHome = 'Create home';
  static const homeRequired = 'A home is required. You can add more homes later and switch between them.';
  static const discoveringTitle = 'Discovering';
  static const sweepingSubnet = 'Sweeping subnet';
  static const nameYourLights = 'Name your lights';
  static const nameReplacesAddress = 'A name replaces the address';
  static const finishSetup = 'Finish setup';
  static const plugPlaceholder = 'Plug by the TV';
  static const bulbPlaceholder = 'Ceiling dome light';
  static const keepLight = 'Keep this light';
  static String saveNLights(int n) => 'Save ${plural(n, 'light')}';
  static String homeSetUp(String name) => '$name is set up';
  static String lightsInRooms(int lights, int rooms) =>
      '${plural(lights, 'light')} in ${plural(rooms, 'room')}';
```

`lib/features/onboarding/widgets/radar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/reduced_motion.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_surface.dart';

/// The scanning art of the first run (spec §10.1 step 2): a 150 well, two
/// ping rings on the 2.2 s clock, the second 0.7 s behind, and a 64 key
/// with the radio glyph.
class Radar extends StatefulWidget {
  const Radar({super.key});

  /// `WizCtl_Mobile.dc.html` lines 72–79.
  static const double well = 150;
  static const double key = 64;
  static const double ringWidth = 1;
  static const double ringAlpha = 0.35;
  static const double glyph = 26;

  /// The second ring starts this far into the first's cycle (0.7 of 2.2 s).
  static const double ringDelayFraction = 0.7 / 2.2;

  static const Key keyKey = Key('radar-key');

  @override
  State<Radar> createState() => _RadarState();
}

class _RadarState extends State<Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: context.wiz.motion.ping,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (wizReducedMotion(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return SizedBox(
      width: Radar.well,
      height: Radar.well,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WizSurface(
            spec: wiz.elevation.well,
            radius: BorderRadius.circular(Radar.well / 2),
            color: wiz.colors.surfaceWell,
            width: Radar.well,
            height: Radar.well,
          ),
          PingRing(clock: _clock, offset: 0),
          PingRing(clock: _clock, offset: Radar.ringDelayFraction),
          WizSurface(
            key: Radar.keyKey,
            spec: wiz.elevation.key,
            radius: BorderRadius.circular(Radar.key / 2),
            gradient: wizVertical(wiz.colors.surfaceKey, wiz.colors.surfaceRaised),
            width: Radar.key,
            height: Radar.key,
            alignment: Alignment.center,
            child: WizIcon(WizIcons.radio, size: Radar.glyph, color: wiz.colors.amber500),
          ),
        ],
      ),
    );
  }
}

/// One ring: scale .35 → 1 while its alpha .55 → 0 (`wz-ping`). The alpha
/// is folded into the stroke colour, not an opacity layer.
class PingRing extends StatelessWidget {
  final Animation<double> clock;
  final double offset;
  const PingRing({super.key, required this.clock, required this.offset});

  static const double scaleFrom = 0.35;
  static const double alphaFrom = 0.55;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        var t = (clock.value + offset) % 1;
        var eased = wiz.motion.tactile.transform(t);
        var scale = scaleFrom + (1 - scaleFrom) * eased;
        var alpha = alphaFrom * (1 - eased);
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: wiz.colors.amber500.withValues(alpha: alpha * Radar.ringAlpha / alphaFrom),
                width: Radar.ringWidth,
              ),
            ),
            child: const SizedBox(width: Radar.well, height: Radar.well),
          ),
        );
      },
    );
  }
}
```

The ring's colour is `rgba(255,176,32,.35)` at its brightest and the keyframe multiplies the element's opacity by .55 → 0; folding both into one alpha gives `0.35 × 0.55 × (1 − t)` at the start, which is what the product above computes.

`lib/features/onboarding/widgets/keep_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/blink_cubit.dart';
import '../../../app/widgets/blink_key.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/light_card_well.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../discovery/bloc/discovery_state.dart';

/// A found light in the first run (spec §10.1 step 2): the well, name and
/// address, the flash key, and the check cap; tapping the row toggles keep.
class KeepRow extends StatelessWidget {
  final FoundDevice row;
  final VoidCallback onToggle;
  const KeepRow({super.key, required this.row, required this.onToggle});

  /// `WizCtl_Mobile.dc.html` lines 101–110: a 26 check cap with a 15 glyph.
  static const double cap = 26;
  static const double capGlyph = 15;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var device = row.device;
    var blinking = context.select<BlinkCubit, bool>((c) => c.state.isBlinking(device.ip));
    var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
    return WizPressable(
      onTap: onToggle,
      semanticsLabel: Strings.keepLight,
      toggled: row.kept,
      scale: wiz.motion.cardScale,
      focusRadius: BorderRadius.circular(wiz.space.r4),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.panel,
        radius: BorderRadius.circular(wiz.space.r4),
        gradient: wizVertical(wiz.colors.surfaceRaised, wiz.colors.surfacePanel),
        padding: EdgeInsets.symmetric(horizontal: wiz.space.s6, vertical: wiz.space.s5),
        child: Row(
          children: [
            LightCardWell(icon: WizIcons.lightbulb, lit: blinking),
            SizedBox(width: wiz.space.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    style: wiz.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: wiz.colors.textPrimary,
                    ),
                  ),
                  Text(
                    Strings.ipAndClass(device.ip, cls),
                    style: wiz.typography.mono.copyWith(color: wiz.colors.textTertiary),
                  ),
                ],
              ),
            ),
            BlinkKey(ip: device.ip, bulbClass: device.bulbClass),
            SizedBox(width: wiz.space.s4),
            WizSurface(
              spec: row.kept ? wiz.elevation.key : wiz.elevation.well,
              radius: BorderRadius.circular(wiz.space.r1),
              gradient: row.kept
                  ? wizVertical(wiz.colors.amber400, wiz.colors.amber600)
                  : wizVertical(wiz.colors.char1000, wiz.colors.char900),
              width: cap,
              height: cap,
              alignment: Alignment.center,
              child: WizIcon(
                WizIcons.check,
                size: capGlyph,
                color: row.kept ? wiz.colors.textOnAccent : wiz.colors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/onboarding/widgets/assign_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../../app/widgets/blink_key.dart';
import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_chip.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import '../../discovery/bloc/discovery_state.dart';
import '../../rooms/widgets/add_room_sheet.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// One kept light on step 3 (spec §10.1): its address and flash key, the
/// alias field, the ROOM chips with New room, and SHOW IT AS.
class AssignCard extends StatefulWidget {
  final FoundDevice row;
  final Assignment assignment;
  final List<OnboardingRoom> rooms;

  const AssignCard({
    super.key,
    required this.row,
    required this.assignment,
    required this.rooms,
  });

  /// `WizCtl_Mobile.dc.html` line 139: the 56 alias field.
  static const double fieldHeight = 56;

  @override
  State<AssignCard> createState() => _AssignCardState();
}

class _AssignCardState extends State<AssignCard> {
  late final TextEditingController _alias = TextEditingController(
    text: widget.assignment.alias,
  );

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<OnboardingBloc>();
    var device = widget.row.device;
    var ip = device.ip;
    var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
    return WizPanel(
      padding: EdgeInsets.symmetric(horizontal: wiz.space.s7, vertical: wiz.space.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Strings.ipAndClass(ip, cls),
                  style: wiz.typography.mono.copyWith(color: wiz.colors.textTertiary),
                ),
              ),
              BlinkKey(ip: ip, bulbClass: device.bulbClass),
            ],
          ),
          SizedBox(height: wiz.space.s5),
          WizTextField(
            controller: _alias,
            height: AssignCard.fieldHeight,
            placeholder: device.bulbClass == BulbClass.socket
                ? Strings.plugPlaceholder
                : Strings.bulbPlaceholder,
            onChanged: (v) => bloc.add(OnboardingAliasChanged(ip, v)),
          ),
          SizedBox(height: wiz.space.s6),
          const FieldLabel(Strings.room),
          SizedBox(height: wiz.space.s3),
          Wrap(
            spacing: wiz.space.s3,
            runSpacing: wiz.space.s3,
            children: [
              for (var room in widget.rooms)
                WizChip(
                  label: room.name,
                  selected: room.tempId == widget.assignment.roomTempId,
                  onTap: () => bloc.add(OnboardingRoomPicked(ip, room.tempId)),
                ),
              WizChip(
                label: Strings.newRoom,
                icon: WizIcons.plus,
                onTap: () async {
                  var result = await showRoomSheet(
                    context,
                    title: Strings.newRoom,
                    primaryLabel: Strings.createRoom,
                  );
                  if (result != null) {
                    bloc.add(OnboardingRoomAdded(result.name, result.glyph, forIp: ip));
                  }
                },
              ),
            ],
          ),
          SizedBox(height: wiz.space.s6),
          const FieldLabel(Strings.showItAs),
          SizedBox(height: wiz.space.s3),
          Wrap(
            spacing: wiz.space.s3,
            runSpacing: wiz.space.s3,
            children: [
              for (var f in Fixture.values)
                WizIconKey(
                  icon: WizIcons.byName(f.iconName)!,
                  shape: WizKeyShape.squircle,
                  active: f == widget.assignment.fixture,
                  semanticsLabel: f.label,
                  onPressed: () => bloc.add(OnboardingFixturePicked(ip, f)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

`lib/features/onboarding/widgets/onboarding_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// "<Home> is set up" / "<n> lights in <m> rooms", then home (spec §10.1).
class OnboardingNoticeListener extends StatelessWidget {
  final Widget child;
  const OnboardingNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        switch (state.notice!) {
          case OnboardingDone(:var home, :var lightCount, :var roomCount):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.homeSetUp(home.name),
              body: Strings.lightsInRooms(lightCount, roomCount),
            );
            context.go(AppRoutes.home);
          case OnboardingError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
        context.read<OnboardingBloc>().add(const OnboardingNoticeCleared());
      },
      child: child,
    );
  }
}
```

`lib/features/onboarding/view/name_home_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/theme/wiz_type.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// Step 1, "Name this home" (spec §10.1): wordmark, hero, body, the field,
/// the key, and the two lines beneath, rising in one after another.
class NameHomeStep extends StatefulWidget {
  const NameHomeStep({super.key});

  /// `WizCtl_Mobile.dc.html` line 49: the brand mark.
  static const double wordmarkSize = 15;
  static const double wordmarkTracking = 0.22;
  static const double fieldHeight = 56;

  @override
  State<NameHomeStep> createState() => _NameHomeStepState();
}

class _NameHomeStepState extends State<NameHomeStep> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<OnboardingBloc>().state.draftName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<OnboardingBloc>();
    var compact = context.layout.widthClass.isCompact;
    var nameEmpty = context.select<OnboardingBloc, bool>((b) => b.state.nameEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RiseIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.wordmark,
                style: TextStyle(
                  fontFamily: WizType.familyDisplay,
                  fontSize: NameHomeStep.wordmarkSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: NameHomeStep.wordmarkSize * NameHomeStep.wordmarkTracking,
                  color: wiz.colors.amber500,
                ),
              ),
              SizedBox(height: wiz.space.s8),
              Text(
                Strings.nameThisHome,
                style: (compact ? wiz.typography.display : wiz.typography.hero)
                    .copyWith(color: wiz.colors.textPrimary),
              ),
              SizedBox(height: wiz.space.s5),
              Text(
                Strings.homeStoredHere,
                style: wiz.typography.body.copyWith(color: wiz.colors.textTertiary),
              ),
            ],
          ),
        ),
        SizedBox(height: wiz.space.s7),
        RiseIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(Strings.homeName),
              SizedBox(height: wiz.space.s3),
              WizTextField(
                controller: _name,
                height: NameHomeStep.fieldHeight,
                placeholder: Strings.homeNamePlaceholder,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (v) => bloc.add(OnboardingNameChanged(v)),
                onSubmitted: (_) => bloc.add(const OnboardingHomeCreated()),
              ),
            ],
          ),
        ),
        SizedBox(height: wiz.space.s7),
        RiseIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizButton(
                label: Strings.createHome,
                variant: WizButtonVariant.primary,
                icon: WizIcons.radio,
                fullWidth: compact,
                enabled: !nameEmpty,
                onPressed: () => bloc.add(const OnboardingHomeCreated()),
              ),
              SizedBox(height: wiz.space.s4),
              Text(
                Strings.homeRequired,
                style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
              ),
            ],
          ),
        ),
        SizedBox(height: wiz.space.s7),
        RiseIn(
          index: 3,
          child: Text(
            Strings.privacy,
            style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
          ),
        ),
      ],
    );
  }
}
```

The wordmark's style is the one place a screen sets a face by name: it is a brand mark at a size no token carries (`GalleryWordmark` does the same for the rail's 30 px mark). The hero uses `typography.hero` on desktop-like widths and `typography.display` on a phone, which is what the two prototypes draw (64 and 44).

`lib/features/onboarding/view/discovering_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_filament_bar.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../discovery/bloc/discovery_bloc.dart';
import '../../discovery/bloc/discovery_event.dart';
import '../../discovery/bloc/discovery_state.dart';
import '../../discovery/widgets/skeleton_rows.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../widgets/keep_row.dart';
import '../widgets/radar.dart';

/// Step 2, "Discovering" (spec §10.1): the broadcast runs on entry; the
/// sweep only from the key. Kept rows go on to naming.
class DiscoveringStep extends StatefulWidget {
  const DiscoveringStep({super.key});

  @override
  State<DiscoveringStep> createState() => _DiscoveringStepState();
}

class _DiscoveringStepState extends State<DiscoveringStep> {
  @override
  void initState() {
    super.initState();
    var discovery = context.read<DiscoveryBloc>();
    if (discovery.state.view == DiscoveryView.idle) {
      discovery.add(const DiscoveryStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var onboarding = context.read<OnboardingBloc>();
    var discovery = context.read<DiscoveryBloc>();
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        var progress = state.progress;
        var subnet = state.subnet;
        var sweeping = state.view == DiscoveryView.sweeping;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WizTopBar(
              title: Strings.discoveringTitle,
              subtitle: sweeping && progress != null && progress.isDeterminate
                  ? Strings.addresses(progress.probed, progress.total)
                  : Strings.localNetwork,
              leading: WizIconKey(
                icon: WizIcons.chevronLeft,
                semanticsLabel: Strings.back,
                onPressed: () {
                  discovery.add(const DiscoveryCancelled());
                  onboarding.add(const OnboardingBack());
                },
              ),
            ),
            SizedBox(height: wiz.space.s6),
            if (state.isScanning) ...[
              const Center(child: Radar()),
              SizedBox(height: wiz.space.s6),
              WizFilamentBar(
                label: sweeping ? Strings.sweepingSubnet : Strings.listeningForLights,
                value: sweeping && progress != null && progress.isDeterminate
                    ? progress.fraction
                    : null,
              ),
              SizedBox(height: wiz.space.s6),
              const SkeletonRows(),
            ] else if (state.view == DiscoveryView.found) ...[
              WizStatusBanner(
                status: WizStatus.success,
                title: Strings.lightsAnswered(state.found.length),
                body: subnet == null
                    ? Strings.localNetwork
                    : state.sweptOnce
                        ? Strings.sweptSubnet(subnet, progress?.total ?? 0)
                        : Strings.broadcastOn(subnet),
                action: const WizBadge(label: Strings.live, tone: WizBadgeTone.online, dot: true),
              ),
              for (var row in state.found) ...[
                SizedBox(height: wiz.space.s4),
                KeepRow(
                  row: row,
                  onToggle: () => discovery.add(DiscoveryKeepToggled(row.device.ip)),
                ),
              ],
              SizedBox(height: wiz.space.s6),
              WizButton(
                label: Strings.saveNLights(state.keptCount),
                variant: WizButtonVariant.primary,
                fullWidth: true,
                enabled: state.keptCount > 0,
                onPressed: () => onboarding.add(OnboardingToNaming(state.found, subnet)),
              ),
              SizedBox(height: wiz.space.s4),
              WizButton(
                label: Strings.scanAgain,
                variant: WizButtonVariant.ghost,
                icon: WizIcons.refreshCw,
                fullWidth: true,
                onPressed: () => discovery.add(const DiscoveryStarted()),
              ),
            ] else
              WizEmptyState(
                icon: WizIcons.radio,
                title: state.view == DiscoveryView.error ? Strings.portBusyTitle : Strings.noResponse,
                body: state.view == DiscoveryView.error
                    ? Strings.portBusyBody
                    : state.sweptOnce ? Strings.sweepTheSubnet : Strings.broadcastHint,
                action: WizButton(
                  label: state.view == DiscoveryView.error ? Strings.tryAgain : Strings.scanSubnet,
                  variant: WizButtonVariant.primary,
                  icon: WizIcons.radio,
                  onPressed: () => discovery.add(
                    state.view == DiscoveryView.error
                        ? const DiscoveryStarted()
                        : const DiscoverySweepRequested(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

`lib/features/onboarding/view/name_lights_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/assign_card.dart';

/// Step 3, "Name your lights" (spec §10.1).
class NameLightsStep extends StatelessWidget {
  const NameLightsStep({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<OnboardingBloc>();
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizTopBar(
            title: Strings.nameYourLights,
            subtitle: Strings.nameReplacesAddress,
            leading: WizIconKey(
              icon: WizIcons.chevronLeft,
              semanticsLabel: Strings.back,
              onPressed: () => bloc.add(const OnboardingBack()),
            ),
          ),
          SizedBox(height: wiz.space.s5),
          Text(
            Strings.blinkHint,
            style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
          ),
          for (var (i, row) in state.kept.indexed) ...[
            SizedBox(height: wiz.space.s6),
            RiseIn(
              index: i,
              child: AssignCard(
                key: ValueKey(row.device.ip),
                row: row,
                assignment: state.assignments[row.device.ip]!,
                rooms: state.setupRooms,
              ),
            ),
          ],
          SizedBox(height: wiz.space.s7),
          WizButton(
            label: Strings.finishSetup,
            variant: WizButtonVariant.primary,
            fullWidth: true,
            enabled: state.namesComplete && !state.finishing,
            onPressed: () => bloc.add(const OnboardingFinished()),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/onboarding/view/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_theme.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_state.dart';
import 'discovering_step.dart';
import 'name_home_step.dart';
import 'name_lights_step.dart';

/// The first run (spec §10.1): stacked on a phone, a centred 560 column
/// on anything wider. Scrolls as one, inside the safe areas and the
/// gutter; no tab bar exists yet, so no bottom inset beyond the safe area.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  /// `WizCtl_Desktop.dc.html` line 43: `width:560px`.
  static const double desktopColumn = 560;
  static const Key columnKey = Key('onboarding-column');

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var gutter = context.layout.gutter;
    var step = context.select<OnboardingBloc, OnboardingStep>((b) => b.state.step);
    var body = switch (step) {
      OnboardingStep.nameHome => const NameHomeStep(),
      OnboardingStep.discovering => const DiscoveringStep(),
      OnboardingStep.nameLights => const NameLightsStep(),
    };
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          key: columnKey,
          constraints: const BoxConstraints(maxWidth: desktopColumn),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, wiz.space.s4, gutter, wiz.space.s8),
            child: AnimatedSwitcher(
              duration: wiz.motion.screenEnter,
              switchInCurve: wiz.motion.tactile,
              child: KeyedSubtree(key: ValueKey(step), child: body),
            ),
          ),
        ),
      ),
    );
  }
}
```

Step 1 centres vertically in the prototype (`justify-content:center`); with `SingleChildScrollView` the column starts at the top, which is what a keyboard-safe layout needs. Give `NameHomeStep`'s column `mainAxisAlignment: MainAxisAlignment.start` and a top spacing of `wiz.space.s12` on phones so the wordmark does not touch the status bar.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/onboarding`
Expected: PASS. If the `AnimatedSwitcher` keeps two steps mounted for a frame and a finder sees duplicates, `pumpAndSettle` before asserting (the tests above do after each step change).

- [ ] **Step 5: Gates and commit**

```bash
git add lib/features/onboarding lib/core/copy/strings.dart test/features/onboarding
git commit -m "feat(onboarding): the three first-run steps"
```

---

### Task 18: Settings, the unreachable banner and the not-answering cubit

**Files:**
- Create: `lib/app/blocs/unreachable_cubit.dart`, `lib/app/widgets/unreachable_banner.dart`, `lib/features/settings/view/settings_screen.dart`, `lib/features/settings/widgets/settings_rows.dart`, `lib/features/settings/widgets/prototype_switches.dart`, `lib/features/settings/widgets/rename_home_sheet.dart`, `lib/features/settings/widgets/about_caption.dart`
- Modify: `lib/core/copy/strings.dart`, `test/support/app_scope.dart`
- Test: `test/app/blocs/unreachable_cubit_test.dart`, `test/app/widgets/unreachable_banner_test.dart`, `test/features/settings/view/settings_screen_test.dart`

**Interfaces:**
- Consumes: `SettingsCubit`/`SettingsState` (Task 3), `HomesBloc` (rename), `LightRepository.watchByHome`, `LiveStateStore.watchAll`, `SettingsRepository.watch`, `WizListRow`, `WizToggle` (sm), `WizPanel`, `WizStatusBanner`, `WizButton`, `WizTextField`, `showWizSheet`, `ScreenScroll`, `FieldLabel`, `PackageInfo.fromPlatform()` (package_info_plus), `cliVersion` (wizctl), `Clipboard.setData` (flutter/services), `kDebugMode`, `AppRoutes.discover/gallery`, `combineLatest2`.
- Produces:

```dart
class UnreachableCubit extends Cubit<List<Light>> { UnreachableCubit({required LightRepository lights, required LiveStateStore store, required SettingsRepository settings}); void subscribe(); }
class UnreachableBanner extends StatelessWidget { const UnreachableBanner(); }   // nothing when every light answers
class SettingsScreen extends StatelessWidget { const SettingsScreen(); }
class SettingsRows, PrototypeSwitches, AboutCaption (widgets)
Future<String?> showRenameHomeSheet(BuildContext context, {required String name});
// Strings
settings, homeLivesOnDevice, homeLivesOnMachine, homeNameMeta, discoveryMeta, configFile, configFilePath, configFileNote, cliParity,
rescanOnLaunch, soundAndHaptics, clicksAndVibration, clicksOnly, prototypeSwitches, wrongNetwork, showOffline, forceTimeout,
forceTimeoutMeta, findsNothing, findsNothingMeta, widgetGallery, widgetGalleryMeta, renameHome, saveHome, copied;
cliCommand(name), lightDidNotAnswer(n), mayBeOffAtWallNamed(name), version(app, package)
```

- [ ] **Step 1: Write the failing tests**

`test/app/blocs/unreachable_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/unreachable_cubit.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/seed.dart';

void main() {
  late SeedHome seed;
  setUp(() => seed = SeedHome());

  blocTest<UnreachableCubit, List<Light>>(
    'lists the active home\'s lights that do not answer, and follows the store',
    build: () => UnreachableCubit(lights: seed.lights, store: seed.store, settings: seed.settings),
    act: (cubit) async {
      cubit.subscribe();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cubit.state.map((l) => l.name), ['Hallway']);
      seed.store.update('hall', (s) => s.copyWith(reachable: true));
      seed.store.update('dome', (s) => s.copyWith(reachable: false));
    },
    wait: const Duration(milliseconds: 5),
    verify: (cubit) => expect(cubit.state.map((l) => l.name), ['Ceiling dome light']),
  );

  blocTest<UnreachableCubit, List<Light>>(
    'no active home means nothing',
    build: () {
      seed = SeedHome(active: false);
      return UnreachableCubit(lights: seed.lights, store: seed.store, settings: seed.settings);
    },
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 5),
    verify: (cubit) => expect(cubit.state, isEmpty),
  );
}
```

`test/app/widgets/unreachable_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/widgets/unreachable_banner.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';

void main() {
  testWidgets('one light: the singular line names it; the action goes to discovery', (tester) async {
    var scope = AppScope(SeedHome());
    addTearDown(scope.dispose);
    await scope.start();
    var router = await pumpRouted(tester, scope.wrap(const UnreachableBanner()), targets: [AppRoutes.discover]);
    await tester.pump();
    expect(find.text('One light did not answer'), findsOneWidget);
    expect(find.text('Hallway may be switched off at the wall, or the router changed its address.'), findsOneWidget);
    await tester.tap(find.text('RESCAN'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.discover);
  });

  testWidgets('several lights: the count, and the first one named; none: nothing', (tester) async {
    var scope = AppScope(SeedHome());
    addTearDown(scope.dispose);
    await scope.start();
    scope.seed.store.update('dome', (s) => s.copyWith(reachable: false));
    await pumpRouted(tester, scope.wrap(const UnreachableBanner()));
    await tester.pump();
    expect(find.text('2 lights did not answer'), findsOneWidget);
    expect(find.textContaining('Ceiling dome light may be switched off'), findsOneWidget);
    scope.seed.store.update('dome', (s) => s.copyWith(reachable: true));
    scope.seed.store.update('hall', (s) => s.copyWith(reachable: true));
    await tester.pump();
    expect(find.byType(WizStatusBanner), findsNothing);
  });
}
```

`test/features/settings/view/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';
import 'package:wizctl_app/features/settings/view/settings_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

void main() {
  late AppScope scope;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'WizCtl', packageName: 'com.dotstudios.wizctlApp', version: '0.1.0',
      buildNumber: '1', buildSignature: '', installerStore: null,
    );
  });

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
  });

  tearDown(() => scope.dispose());

  Widget screen() => scope.wrap(const SettingsScreen());

  testWidgets('the phone rows, in order, with the caption', (tester) async {
    await pumpRouted(tester, screen());
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('This home lives on this device'), findsOneWidget);
    expect(find.text('One light did not answer'), findsOneWidget);
    var rows = tester.widgetList<WizListRow>(find.byType(WizListRow)).map((r) => r.title).toList();
    expect(rows.take(4), ['Kaverappa House', 'Discovery', 'Re-scan on launch', 'Sound & haptics']);
    expect(find.text('Clicks and vibration on every control'), findsOneWidget);
    expect(find.text('No account, no cloud. Lights are reached over UDP on port 38899 on your own network.'), findsOneWidget);
    expect(find.text('PROTOTYPE SWITCHES'), findsOneWidget);
    expect(rows.skip(4), ['Wrong network', 'Force command timeout', 'Discovery finds nothing', 'Widget gallery']);
    expect(find.text('WizCtl 0.1.0 · wizctl 1.1.0'), findsOneWidget);
    expect(find.text('Config file'), findsNothing);
  });

  testWidgets('the toggles reach the cubit', (tester) async {
    await pumpRouted(tester, screen());
    await tester.pumpAndSettle();
    var toggles = find.byType(WizToggle);
    await tester.tap(toggles.at(1));
    await tester.pump();
    expect(scope.feedback.enabled, isFalse);
    await tester.tap(toggles.at(2));
    await tester.pump();
    expect(scope.flags.value.offNetwork, isTrue);
  });

  testWidgets('rename home and the navigation rows', (tester) async {
    var router = await pumpRouted(tester, screen(), targets: [AppRoutes.discover, AppRoutes.gallery]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaverappa House'));
    await tester.pumpAndSettle();
    expect(find.text('Rename home'), findsOneWidget);
    await tester.enterText(find.byType(WizTextField), 'Kaverappa Villa');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(scope.homes.state.activeHome?.name, 'Kaverappa Villa');
    await tester.tap(find.text('Discovery'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.discover);
    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Widget gallery'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.gallery);
  });

  testWidgets('on a desktop: machine, the two CLI rows, no Discovery row, copy works', (tester) async {
    await setSurface(tester, const Size(1200, 800));
    var copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    await pumpRouted(tester, screen(), size: const Size(1200, 800));
    await tester.pumpAndSettle();
    expect(find.text('This home lives on this machine'), findsOneWidget);
    expect(find.text('Discovery'), findsNothing);
    expect(find.text('Config file'), findsOneWidget);
    expect(find.textContaining('~/.config/wizctl/config.json'), findsOneWidget);
    expect(find.text('Clicks on every control'), findsOneWidget);
    await tester.tap(find.text('CLI parity'));
    await tester.pump();
    expect(copied.single, 'wizctl on -t "Ceiling dome light"');
    expect(scope.toasts.toasts.single.title, 'Copied to the clipboard');
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app/blocs/unreachable_cubit_test.dart test/app/widgets/unreachable_banner_test.dart test/features/settings`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the cubit, the banner and the screen**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Settings (spec §10.7) and the unreachable banner (spec §15).
  static const settings = 'Settings';
  static const homeLivesOnDevice = 'This home lives on this device';
  static const homeLivesOnMachine = 'This home lives on this machine';
  static const homeNameMeta = 'Home name';
  static const discoveryMeta = 'Broadcast, then unicast sweep';
  static const configFile = 'Config file';
  static const configFilePath = '~/.config/wizctl/config.json';
  static const configFileNote = 'Aliases and rooms are exported here for the CLI';
  static const cliParity = 'CLI parity';
  static const rescanOnLaunch = 'Re-scan on launch';
  static const soundAndHaptics = 'Sound & haptics';
  static const clicksAndVibration = 'Clicks and vibration on every control';
  static const clicksOnly = 'Clicks on every control';
  static const prototypeSwitches = 'Prototype switches';
  static const wrongNetwork = 'Wrong network';
  static const showOffline = 'Show the offline state';
  static const forceTimeout = 'Force command timeout';
  static const forceTimeoutMeta = 'Every write fails after 1.1s';
  static const findsNothing = 'Discovery finds nothing';
  static const findsNothingMeta = 'Scan returns zero lights';
  static const widgetGallery = 'Widget gallery';
  static const widgetGalleryMeta = 'Every kit widget, live';
  static const renameHome = 'Rename home';
  static const copied = 'Copied to the clipboard';
  static const oneLightDidNotAnswer = 'One light did not answer';
  static String cliCommand(String name) => 'wizctl on -t "$name"';
  static String lightsDidNotAnswer(int n) => '${plural(n, 'light')} did not answer';
  static String mayBeOffAtWallNamed(String name) =>
      '$name may be switched off at the wall, or the router changed its address.';
  static String version(String app, String package) => 'WizCtl $app · wizctl $package';
```

Rulings recorded: the CLI parity row confirms the copy with an info toast "Copied to the clipboard" (spec §10.7 says only "tap copies to the clipboard"; a silent copy gives the user nothing to go on; cost if wrong: one line). The "Config file" row shows its explanatory sentence as a second meta line under the path (the kit row has one meta slot; a newline in it keeps the copy without a new widget).

`lib/app/blocs/unreachable_cubit.dart`:

```dart
import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../core/util/latest.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/light_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/live_state_store.dart';

/// The active home's lights that are not answering, in repository order;
/// the unreachable banner and the desktop "Not answering" tile read it.
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
    _subscription ??= _settings
        .watch()
        .map((s) => s.activeHomeId)
        .distinct()
        .asyncExpand(
          (id) => id == null
              ? Stream.value(const <Light>[])
              : combineLatest2(_lights.watchByHome(id), _store.watchAll()).map((
                  tuple,
                ) {
                  var (lights, states) = tuple;
                  return [
                    for (var l in lights)
                      if (!(states[l.id] ?? LiveState.initial).reachable) l,
                  ];
                }),
        )
        .listen(emit);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
```

`lib/app/widgets/unreachable_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/copy/strings.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_status_banner.dart';
import '../../domain/entities/entities.dart';
import '../blocs/unreachable_cubit.dart';
import '../routes.dart';

/// "One light did not answer" / "<n> lights did not answer" with the first
/// one named, and Rescan (spec §15). Nothing when every light answers.
class UnreachableBanner extends StatelessWidget {
  const UnreachableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreachableCubit, List<Light>>(
      builder: (context, lights) {
        if (lights.isEmpty) return const SizedBox.shrink();
        return WizStatusBanner(
          status: WizStatus.error,
          title: lights.length == 1
              ? Strings.oneLightDidNotAnswer
              : Strings.lightsDidNotAnswer(lights.length),
          body: Strings.mayBeOffAtWallNamed(lights.first.name),
          action: WizButton(
            label: Strings.rescan,
            variant: WizButtonVariant.ghost,
            size: WizButtonSize.sm,
            onPressed: () => context.go(AppRoutes.discover),
          ),
        );
      },
    );
  }
}
```

`lib/features/settings/widgets/rename_home_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';

/// "Rename home": HOME NAME, Cancel / Save. Resolves to the trimmed name.
Future<String?> showRenameHomeSheet(
  BuildContext context, {
  required String name,
}) {
  var navigator = Navigator.of(context, rootNavigator: true);
  var controller = TextEditingController(text: name);
  return showWizSheet<String>(
    context,
    title: Strings.renameHome,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel(Strings.homeName),
        SizedBox(height: context.wiz.space.s3),
        WizTextField(
          controller: controller,
          placeholder: Strings.homeNamePlaceholder,
          autofocus: true,
        ),
      ],
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => WizButton(
          label: Strings.save,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: value.text.trim().isNotEmpty,
          onPressed: () => navigator.pop(controller.text.trim()),
        ),
      ),
    ],
  ).whenComplete(controller.dispose);
}
```

`lib/features/settings/widgets/about_caption.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wizctl/wizctl.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';

/// "WizCtl <version> · wizctl <package version>" (spec §10.7).
class AboutCaption extends StatelessWidget {
  const AboutCaption({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        var app = snapshot.data?.version;
        if (app == null) return const SizedBox.shrink();
        return Text(
          Strings.version(app, cliVersion),
          textAlign: TextAlign.center,
          style: wiz.typography.caption.copyWith(color: wiz.colors.textTertiary),
        );
      },
    );
  }
}
```

`lib/features/settings/widgets/prototype_switches.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/settings_cubit.dart';
import '../../../app/blocs/settings_state.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_toggle.dart';

/// The debug-only block (spec §18): the three prototype switches and, per
/// the user's decision, the row to the widget gallery. Only ever built
/// under `kDebugMode`; the screen checks.
class PrototypeSwitches extends StatelessWidget {
  const PrototypeSwitches({super.key});

  static const double chevron = 18;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var cubit = context.read<SettingsCubit>();
    var flags = context.select<SettingsCubit, SettingsState>((c) => c.state).debugFlags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(Strings.prototypeSwitches),
        SizedBox(height: wiz.space.s3),
        WizListRow(
          icon: WizIcons.wifi,
          title: Strings.wrongNetwork,
          meta: Strings.showOffline,
          trailing: WizToggle(
            value: flags.offNetwork,
            size: WizToggleSize.sm,
            onChanged: cubit.setOffNetwork,
            semanticsLabel: Strings.wrongNetwork,
          ),
        ),
        SizedBox(height: wiz.space.s3),
        WizListRow(
          icon: WizIcons.clock,
          title: Strings.forceTimeout,
          meta: Strings.forceTimeoutMeta,
          trailing: WizToggle(
            value: flags.forceTimeout,
            size: WizToggleSize.sm,
            onChanged: cubit.setForceTimeout,
            semanticsLabel: Strings.forceTimeout,
          ),
        ),
        SizedBox(height: wiz.space.s3),
        WizListRow(
          icon: WizIcons.search,
          title: Strings.findsNothing,
          meta: Strings.findsNothingMeta,
          trailing: WizToggle(
            value: flags.findNothing,
            size: WizToggleSize.sm,
            onChanged: cubit.setFindNothing,
            semanticsLabel: Strings.findsNothing,
          ),
        ),
        SizedBox(height: wiz.space.s3),
        WizListRow(
          icon: WizIcons.layoutGrid,
          title: Strings.widgetGallery,
          meta: Strings.widgetGalleryMeta,
          trailing: WizIcon(WizIcons.chevronRight, size: chevron, color: wiz.colors.textTertiary),
          onTap: () => context.push(AppRoutes.gallery),
        ),
      ],
    );
  }
}
```

`lib/features/settings/widgets/settings_rows.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/homes_event.dart';
import '../../../app/blocs/homes_state.dart';
import '../../../app/blocs/settings_cubit.dart';
import '../../../app/blocs/settings_state.dart';
import '../../../app/routes.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_toggle.dart';
import '../../../domain/repositories/light_repository.dart';
import 'rename_home_sheet.dart';

/// The rows of spec §10.7, in order: home name, Discovery (phone) or Config
/// file and CLI parity (desktop), Re-scan on launch, Sound & haptics.
class SettingsRows extends StatelessWidget {
  const SettingsRows({super.key});

  static const double chevron = 18;
  static const double glyph = 18;

  Future<void> _rename(BuildContext context, HomesState homes) async {
    var home = homes.activeHome;
    if (home == null) return;
    var bloc = context.read<HomesBloc>();
    var name = await showRenameHomeSheet(context, name: home.name);
    if (name != null) bloc.add(HomeRenamed(home.id, name));
  }

  Future<void> _copyCli(BuildContext context, String homeId) async {
    var toasts = context.read<ToastController>();
    var lights = await context.read<LightRepository>().getByHome(homeId);
    var name = lights.isEmpty ? Strings.wholeHome : lights.first.name;
    await Clipboard.setData(ClipboardData(text: Strings.cliCommand(name)));
    toasts.push(tone: WizToastTone.info, title: Strings.copied);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var desktop = context.layout.widthClass.isDesktopLike;
    var cubit = context.read<SettingsCubit>();
    var settings = context.watch<SettingsCubit>().state;
    var homes = context.watch<HomesBloc>().state;
    var home = homes.activeHome;
    var gap = SizedBox(height: wiz.space.s3);
    Widget chevronIcon() => WizIcon(WizIcons.chevronRight, size: chevron, color: wiz.colors.textTertiary);
    return Column(
      children: [
        WizListRow(
          icon: WizIcons.house,
          title: home?.name ?? '',
          meta: Strings.homeNameMeta,
          trailing: WizIcon(WizIcons.pencil, size: glyph, color: wiz.colors.textTertiary),
          onTap: () => _rename(context, homes),
        ),
        if (!desktop) ...[
          gap,
          WizListRow(
            icon: WizIcons.radio,
            title: Strings.discovery,
            meta: Strings.discoveryMeta,
            trailing: chevronIcon(),
            onTap: () => context.go(AppRoutes.discover),
          ),
        ] else if (home != null) ...[
          gap,
          WizListRow(
            icon: WizIcons.terminal,
            title: Strings.configFile,
            meta: '${Strings.configFilePath}\n${Strings.configFileNote}',
          ),
          gap,
          FutureBuilder(
            future: context.read<LightRepository>().getByHome(home.id),
            builder: (context, snapshot) {
              var first = snapshot.data?.firstOrNull;
              return WizListRow(
                icon: WizIcons.terminal,
                title: Strings.cliParity,
                meta: Strings.cliCommand(first?.name ?? Strings.wholeHome),
                trailing: chevronIcon(),
                onTap: () => _copyCli(context, home.id),
              );
            },
          ),
        ],
        gap,
        WizListRow(
          icon: WizIcons.refreshCw,
          title: Strings.rescanOnLaunch,
          trailing: WizToggle(
            value: settings.rescanOnLaunch,
            size: WizToggleSize.sm,
            onChanged: cubit.setRescanOnLaunch,
            semanticsLabel: Strings.rescanOnLaunch,
          ),
        ),
        gap,
        WizListRow(
          icon: WizIcons.zap,
          title: Strings.soundAndHaptics,
          meta: desktop ? Strings.clicksOnly : Strings.clicksAndVibration,
          trailing: WizToggle(
            value: settings.feedbackEnabled,
            size: WizToggleSize.sm,
            onChanged: cubit.setFeedback,
            semanticsLabel: Strings.soundAndHaptics,
          ),
        ),
      ],
    );
  }
}
```

`lib/features/settings/view/settings_screen.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/widgets/screen_scroll.dart';
import '../../../app/widgets/unreachable_banner.dart';
import '../../../core/copy/strings.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../widgets/about_caption.dart';
import '../widgets/prototype_switches.dart';
import '../widgets/settings_rows.dart';

/// Settings (spec §10.7, §18).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var desktop = context.layout.widthClass.isDesktopLike;
    return ScreenScroll(
      gap: wiz.space.s5,
      children: [
        WizTopBar(
          title: Strings.settings,
          subtitle: desktop ? Strings.homeLivesOnMachine : Strings.homeLivesOnDevice,
        ),
        const UnreachableBanner(),
        const SettingsRows(),
        WizPanel(
          variant: WizPanelVariant.inset,
          child: Text(
            Strings.privacy,
            style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
          ),
        ),
        if (kDebugMode) const PrototypeSwitches(),
        const AboutCaption(),
      ],
    );
  }
}
```

`UnreachableBanner` shrinks to nothing and the list still puts a gap after it; accept that gap on this screen (it is 12 px) rather than reading the cubit twice. On a desktop, `SettingsRows` reads the layout, so the Settings screen sits inside the desktop shell's 660 max width (Task 20).

`test/support/app_scope.dart`: add `late final UnreachableCubit unreachable;` built in the constructor, subscribed in `start()`, closed in `dispose()`, and provided in `wrap`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app test/features/settings`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app lib/features/settings lib/core/copy/strings.dart test/
git commit -m "feat(settings): the Settings screen, the prototype switches and the not-answering banner"
```

---

### Task 19: The router, the lifecycle driver, the phone shell and the app root

**Files:**
- Create: `lib/app/shell/shell_branch.dart`, `lib/app/shell/app_shell.dart`, `lib/app/shell/compact_shell.dart`, `lib/app/router.dart`, `lib/app/router_pages.dart`, `lib/app/lifecycle.dart`, `lib/app/widgets/blink_notice_listener.dart`, `lib/app/gallery_page.dart`
- Modify: `lib/app/app.dart`, `lib/main.dart`, `lib/core/copy/strings.dart`
- Test: `test/app/lifecycle_test.dart`, `test/app/router_test.dart`, `test/app/shell/compact_shell_test.dart`, `test/app/app_test.dart`

**Interfaces:**
- Consumes: every screen and bloc above; `GoRouter`, `StatefulShellRoute.indexedStack`, `StatefulShellBranch`, `StatefulNavigationShell.goBranch/currentIndex`, `GoRouterState.pageKey/pathParameters/matchedLocation`, `wizFadePage`, `AppLifecycleListener`, `WizTabBar`/`WizTab`, `WizLayoutScope`, `WizAppBackground`, `WizToastLayer`, `FeedbackScope`, `buildWizThemeData`, `GalleryScreen`, `kDebugMode`.
- Produces:

```dart
enum ShellBranch { home, rooms, modes, settings, discover; String get path; static ShellBranch of(int index); }
GoRouter buildRouter({required HomesBloc homes, required WizMotion motion, required AppPages pages, GlobalKey<NavigatorState>? rootNavigatorKey});
class AppPages { AppPages({required AppDependencies deps, required ModesBlocFactory modesBlocFor}); Page<void> home/rooms/room/light/modes/settings/discover/setup/gallery(BuildContext, GoRouterState); }
class AppLifecycleDriver { AppLifecycleDriver({required SyncCoordinator sync, required NetworkMonitor network, required HomesBloc homes}); void start(); void dispose(); }
class AppShell extends StatelessWidget { AppShell({required StatefulNavigationShell shell}); }
class CompactShell extends StatelessWidget { CompactShell({required StatefulNavigationShell shell}); static bool showsTabBar(int branchIndex); }
class BlinkNoticeListener extends StatelessWidget { BlinkNoticeListener({required Widget child}); }
class GalleryPage extends StatelessWidget {}
class WizCtlApp extends StatefulWidget { WizCtlApp({required AppServices services}); }
// Strings
tabHome, tabRooms, tabScenes, tabSettings; windowTitle(home)   ('wizctl · <home>' / 'wizctl · setup')
```

- [ ] **Step 1: Write the failing tests**

`test/app/lifecycle_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/lifecycle.dart';

import '../support/app_scope.dart';
import '../support/seed.dart';

void main() {
  testWidgets('cold start reads the home; hide pauses; show and resume refresh', (tester) async {
    var scope = AppScope(SeedHome());
    addTearDown(scope.dispose);
    await scope.monitor.refresh();
    scope.homes.add(const HomesSubscribed());
    var driver = AppLifecycleDriver(sync: scope.sync, network: scope.monitor, homes: scope.homes)..start();
    addTearDown(driver.dispose);
    await tester.pump(const Duration(milliseconds: 20));
    expect(scope.gateway.reads.toSet(), scope.seed.all.where((l) => l.homeId == 'h1').map((l) => l.ip).toSet(),
        reason: 'rescan on launch is on by default');

    scope.gateway.reads.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 20));
    expect(scope.gateway.reads, isNotEmpty, reason: 'coming back reads again');
  });

  testWidgets('switching home activates it for polling', (tester) async {
    var scope = AppScope(SeedHome());
    addTearDown(scope.dispose);
    await scope.monitor.refresh();
    scope.homes.add(const HomesSubscribed());
    var driver = AppLifecycleDriver(sync: scope.sync, network: scope.monitor, homes: scope.homes)..start();
    addTearDown(driver.dispose);
    await tester.pump(const Duration(milliseconds: 20));
    scope.gateway.reads.clear();
    scope.homes.add(const HomeSwitched('h2'));
    await tester.pump(const Duration(milliseconds: 20));
    await scope.sync.refreshAll();
    expect(scope.gateway.reads, ['10.0.0.42'], reason: 'the Studio is the active home now');
  });
}
```

(`gateway.states` for `10.0.0.42` is seeded by `AppScope`; `LightState` import covers the type.)

`test/app/router_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/blocs/homes_state.dart';
import 'package:wizctl_app/app/router.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../support/app_scope.dart';
import '../support/seed.dart';

void main() {
  test('branches map to paths and back', () {
    expect(ShellBranch.home.path, AppRoutes.home);
    expect(ShellBranch.rooms.path, AppRoutes.rooms);
    expect(ShellBranch.modes.path, AppRoutes.modes);
    expect(ShellBranch.settings.path, AppRoutes.settings);
    expect(ShellBranch.discover.path, AppRoutes.discover);
    for (var b in ShellBranch.values) {
      expect(ShellBranch.of(b.index), b);
    }
  });

  test('without a home every location redirects to setup; with one, setup goes home', () async {
    var scope = AppScope(SeedHome.empty());
    addTearDown(scope.dispose);
    var router = buildRouter(homes: scope.homes, motion: scope.motion, pages: scope.pages);
    addTearDown(router.dispose);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), AppRoutes.setup);

    var withHome = AppScope(SeedHome());
    addTearDown(withHome.dispose);
    withHome.homes.add(const HomesSubscribed());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(withHome.homes.state.status, HomesStatus.ready);
    var router2 = buildRouter(homes: withHome.homes, motion: withHome.motion, pages: withHome.pages);
    addTearDown(router2.dispose);
    expect(router2.routerDelegate.currentConfiguration.uri.toString(), AppRoutes.home);
  });
}
```

`AppScope` gains, built over its fakes in the constructor and provided by `wrap` as `RepositoryProvider<ShellDeps>`:

```dart
  WizMotion get motion => WizMotion.standard;
  late final ShellDeps shellDeps = (
    homes: seed.homes, rooms: seed.rooms, lights: seed.lights, settings: seed.settings, store: seed.store, sync: sync,
    setPower: setPower, setBrightness: setBrightness, setKelvin: setKelvin, setSpeed: setSpeed,
    setFixture: SetFixture(lights: seed.lights), renameLight: RenameLight(lights: seed.lights),
    forgetLight: ForgetLight(lights: seed.lights, store: seed.store),
    addRoom: AddRoom(rooms: seed.rooms, ids: ids), renameRoom: RenameRoom(rooms: seed.rooms),
    deleteRoom: DeleteRoom(rooms: seed.rooms, lights: seed.lights),
    runDiscovery: RunDiscovery(gateway: gateway, lights: seed.lights, store: seed.store, network: FakeNetworkInfo('192.168.1'), clock: clock),
    saveDiscoveredLight: SaveDiscoveredLight(lights: seed.lights, store: seed.store, ids: ids, clock: clock),
    learnHomeSubnet: LearnHomeSubnet(homes: seed.homes),
    finishOnboarding: FinishOnboarding(homes: seed.homes, rooms: seed.rooms, lights: seed.lights, settings: seed.settings, store: seed.store, ids: ids, clock: clock),
    ids: ids,
  );
  late final AppPages pages = AppPages(deps: shellDeps, modesBlocFor: modesBlocFor, motion: motion);
```

(`ShellDeps` is the record typedef Step 3 defines in `lib/app/shell_deps.dart`.)

`test/app/shell/compact_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/shell/compact_shell.dart';
import 'package:wizctl_app/app/shell/shell_branch.dart';

void main() {
  test('the tab bar shows on every branch but discovery', () {
    for (var b in ShellBranch.values) {
      expect(CompactShell.showsTabBar(b.index), b != ShellBranch.discover);
    }
  });
}
```

`test/app/app_test.dart` (the whole app over an in-memory graph):

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/app/dependencies.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/features/discovery/view/discovery_screen.dart';
import 'package:wizctl_app/features/home/view/home_screen.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';
import 'package:wizctl_app/features/rooms/view/room_screen.dart';
import 'package:wizctl_app/features/rooms/view/rooms_screen.dart';

import '../support/fakes.dart';
import '../support/wiz_test_app.dart';

Future<AppServices> _services(FakeGateway gateway, {bool withHome = true}) async {
  var deps = await AppDependencies.build(
    database: AppDatabase.inMemory(),
    gateway: gateway,
    networkInfo: FakeNetworkInfo('192.168.1'),
    exportCli: false,
    clock: FakeClock(),
    ids: SequenceIds(),
  );
  if (withHome) {
    var home = await deps.createHome('Kaverappa House', subnet: '192.168.1');
    var room = await deps.addRoom(home.id, 'Living Room', RoomGlyph.sofa);
    await deps.saveDiscoveredLight(
      homeId: home.id,
      roomId: room.id,
      device: const DiscoveredDevice(ip: '192.168.1.104', mac: 'aa', bulbClass: BulbClass.rgb),
      alias: 'Ceiling dome light',
      fixture: Fixture.dome,
    );
    gateway.states['192.168.1.104'] = const LightState(isOn: true, dimming: 70);
  }
  return AppServices(
    feedback: NoopFeedbackService(),
    toasts: ToastController(),
    deps: deps,
    homes: await deps.homes.getAll(),
    settings: await deps.settings.get(),
  );
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('a fresh install opens on setup with no tab bar', (tester) async {
    var services = await _services(FakeGateway(), withHome: false);
    addTearDown(services.deps.dispose);
    await tester.pumpWidget(WizCtlApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(WizTabBar<Object>), findsNothing);
  });

  testWidgets('with a home: home, the tab bar, rooms, a room, discovery without the bar', (tester) async {
    var services = await _services(FakeGateway());
    addTearDown(services.deps.dispose);
    await tester.pumpWidget(WizCtlApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Kaverappa House'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is WizTabBar), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Rooms'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomsScreen), findsOneWidget);
    await tester.tap(find.text('Living Room'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomScreen), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is WizTabBar), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomsScreen), findsOneWidget, reason: 'Back pops to the Rooms list');

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Discover lights'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryScreen), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is WizTabBar), findsNothing);
  });

  testWidgets('the window title follows the home', (tester) async {
    var services = await _services(FakeGateway());
    addTearDown(services.deps.dispose);
    await tester.pumpWidget(WizCtlApp(services: services));
    await tester.pumpAndSettle();
    var title = tester.widget<Title>(find.byType(Title));
    expect(title.title, 'wizctl · Kaverappa House');
  });
}
```

`MaterialApp` builds a `Title` widget from `onGenerateTitle`; the test reads it. `WizTabBar` is generic (`WizTabBar<ShellBranch>`), hence the predicate finder.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app`
Expected: FAIL to compile.

- [ ] **Step 3: Write the shell branch, the pages, the router, the driver, the shell and the app**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Shells (spec §9, §10.9).
  static const tabHome = 'Home';
  static const tabRooms = 'Rooms';
  static const tabScenes = 'Scenes';
  static const tabSettings = 'Settings';
  static const windowSetup = 'wizctl · setup';
  static String windowTitle(String home) => 'wizctl · $home';
```

`lib/app/shell/shell_branch.dart`:

```dart
import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/widgets/wiz_tab_bar.dart';
import '../routes.dart';

/// The shell's branches, in the order the `StatefulShellRoute` lists them
/// (spec §9): the four tabs, then discovery, which has no tab.
enum ShellBranch {
  home(AppRoutes.home),
  rooms(AppRoutes.rooms),
  modes(AppRoutes.modes),
  settings(AppRoutes.settings),
  discover(AppRoutes.discover);

  final String path;
  const ShellBranch(this.path);

  static ShellBranch of(int index) => values[index];

  /// The phone's tab bar (`WizCtl_Mobile.dc.html` `tabs`).
  static const List<WizTab<ShellBranch>> tabs = [
    WizTab(value: home, icon: WizIcons.house, label: Strings.tabHome),
    WizTab(value: rooms, icon: WizIcons.layoutGrid, label: Strings.tabRooms),
    WizTab(value: modes, icon: WizIcons.sparkles, label: Strings.tabScenes),
    WizTab(value: settings, icon: WizIcons.slidersHorizontal, label: Strings.tabSettings),
  ];
}
```

`lib/app/shell_deps.dart` — what the pages and the shells need from the graph, as one record, so a test can build it over fakes without an `AppDependencies`:

```dart
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
```

`lib/app/router_pages.dart` — every route's page, with its bloc created in the page's own subtree (closed when the page goes):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/wiz_fade_page.dart';
import '../core/theme/wiz_motion.dart';
import '../domain/entities/entities.dart';
import '../features/discovery/bloc/discovery_bloc.dart';
import '../features/discovery/view/discovery_screen.dart';
import '../features/discovery/widgets/discovery_notice_listener.dart';
import '../features/home/bloc/home_screen_bloc.dart';
import '../features/home/bloc/home_screen_event.dart';
import '../features/home/view/home_screen.dart';
import '../features/lights/bloc/light_bloc.dart';
import '../features/lights/bloc/light_event.dart';
import '../features/lights/view/light_screen.dart';
import '../features/lights/widgets/light_notice_listener.dart';
import '../features/modes/bloc/light_modes_bloc.dart';
import '../features/modes/bloc/light_modes_event.dart';
import '../features/modes/modes_bloc_factory.dart';
import '../features/modes/view/modes_screen.dart';
import '../features/modes/widgets/modes_notice_listener.dart';
import '../features/onboarding/bloc/onboarding_bloc.dart';
import '../features/onboarding/view/onboarding_screen.dart';
import '../features/onboarding/widgets/onboarding_notice_listener.dart';
import '../features/rooms/bloc/room_bloc.dart';
import '../features/rooms/bloc/room_event.dart';
import '../features/rooms/bloc/rooms_list_bloc.dart';
import '../features/rooms/bloc/rooms_list_event.dart';
import '../features/rooms/view/room_screen.dart';
import '../features/rooms/view/rooms_screen.dart';
import '../features/rooms/widgets/rooms_notice_listener.dart';
import '../features/settings/view/settings_screen.dart';
import 'blocs/homes_bloc.dart';
import 'gallery_page.dart';
import 'routes.dart';
import 'shell_deps.dart';

/// Builds each route's page: a fade transition around the screen, with the
/// screen's bloc created there and closed with it (spec §8, "route-scoped
/// blocs are created in route builders and closed on pop").
class AppPages {
  final ShellDeps deps;
  final ModesBlocFactory modesBlocFor;
  final WizMotion motion;

  AppPages({required this.deps, required this.modesBlocFor, required this.motion});

  Page<void> _fade(GoRouterState state, Widget child) =>
      wizFadePage<void>(key: state.pageKey, motion: motion, child: child);

  String? _activeHome(BuildContext context) =>
      context.read<HomesBloc>().state.activeHomeId;

  Page<void> setup(BuildContext context, GoRouterState state) => _fade(
    state,
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OnboardingBloc(finishOnboarding: deps.finishOnboarding, ids: deps.ids),
        ),
        BlocProvider(
          create: (_) => DiscoveryBloc(
            onboarding: true,
            runDiscovery: deps.runDiscovery,
            saveDiscoveredLight: deps.saveDiscoveredLight,
            learnHomeSubnet: deps.learnHomeSubnet,
            sync: deps.sync,
          ),
        ),
      ],
      child: const OnboardingNoticeListener(child: OnboardingScreen()),
    ),
  );

  Page<void> home(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => HomeScreenBloc(
        homes: deps.homes,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        settings: deps.settings,
        setPower: deps.setPower,
        sync: deps.sync,
      )..add(const HomeScreenSubscribed()),
      child: const HomeScreen(),
    ),
  );

  Page<void> rooms(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => RoomsListBloc(
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        settings: deps.settings,
        addRoom: deps.addRoom,
        renameRoom: deps.renameRoom,
        deleteRoom: deps.deleteRoom,
      )..add(const RoomsListSubscribed()),
      child: const RoomsNoticeListener(child: RoomsScreen()),
    ),
  );

  Page<void> room(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => RoomBloc(
        roomId: state.pathParameters[AppRoutes.roomParam]!,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        sync: deps.sync,
      )..add(const RoomSubscribed()),
      child: const RoomScreen(),
    ),
  );

  /// On a phone the detail screen; Task 21 adds the desktop reading, where
  /// the light is selected into the inspector over its room.
  Page<void> light(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => LightBloc(
        lightId: state.pathParameters[AppRoutes.lightParam]!,
        lights: deps.lights,
        rooms: deps.rooms,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        setSpeed: deps.setSpeed,
        setFixture: deps.setFixture,
        renameLight: deps.renameLight,
        forgetLight: deps.forgetLight,
        sync: deps.sync,
      )..add(const LightSubscribed()),
      child: const LightNoticeListener(child: LightScreen()),
    ),
  );

  Page<void> modes(BuildContext context, GoRouterState state) {
    var homeId = _activeHome(context) ?? '';
    return _fade(
      state,
      BlocProvider(
        create: (_) => modesBlocFor(WholeHomeTarget(homeId))..add(const ModesSubscribed()),
        child: ModesNoticeListener(child: ModesScreen(homeId: homeId)),
      ),
    );
  }

  Page<void> settings(BuildContext context, GoRouterState state) =>
      _fade(state, const SettingsScreen());

  Page<void> discover(BuildContext context, GoRouterState state) => _fade(
    state,
    BlocProvider(
      create: (_) => DiscoveryBloc(
        homeId: _activeHome(context),
        runDiscovery: deps.runDiscovery,
        saveDiscoveredLight: deps.saveDiscoveredLight,
        learnHomeSubnet: deps.learnHomeSubnet,
        sync: deps.sync,
      ),
      child: const DiscoveryNoticeListener(child: DiscoveryScreen()),
    ),
  );

  Page<void> gallery(BuildContext context, GoRouterState state) =>
      _fade(state, const GalleryPage());
}
```

`lib/app/router.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/wiz_motion.dart';
import 'blocs/homes_bloc.dart';
import 'blocs/homes_state.dart';
import 'router_pages.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

/// Wakes the router whenever the homes change, so the `/setup` redirect
/// re-evaluates the moment the first home is written or the last deleted.
/// Owned by whoever builds the router (`WizCtlApp`), disposed beside it:
/// `GoRouter.dispose` leaves a `refreshListenable` it was handed alone.
class HomesListenable extends ChangeNotifier {
  late final StreamSubscription<HomesState> _subscription;
  HomesListenable(HomesBloc homes) {
    _subscription = homes.stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

/// The routes of spec §9: `/setup` outside the shell, one stateful shell
/// with five branches (the four tabs and discovery), and the debug gallery.
/// The shell's builder picks the phone or desktop chrome by width, so a
/// resize keeps the route and its blocs.
GoRouter buildRouter({
  required HomesBloc homes,
  required HomesListenable listenable,
  required WizMotion motion,
  required AppPages pages,
  GlobalKey<NavigatorState>? rootNavigatorKey,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: homes.state.hasHome ? AppRoutes.home : AppRoutes.setup,
    refreshListenable: listenable,
    redirect: (context, state) {
      var hasHome = homes.state.hasHome;
      var location = state.matchedLocation;
      if (!hasHome && location != AppRoutes.setup) return AppRoutes.setup;
      if (hasHome && location == AppRoutes.setup) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.setup, pageBuilder: pages.setup),
      if (kDebugMode)
        GoRoute(path: AppRoutes.gallery, pageBuilder: pages.gallery),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, pageBuilder: pages.home)],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rooms,
                pageBuilder: pages.rooms,
                routes: [
                  GoRoute(path: ':${AppRoutes.roomParam}', pageBuilder: pages.room),
                ],
              ),
              GoRoute(path: AppRoutes.lightPattern, pageBuilder: pages.light),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.modes, pageBuilder: pages.modes)],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.settings, pageBuilder: pages.settings)],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.discover, pageBuilder: pages.discover)],
          ),
        ],
      ),
    ],
  );
}
```

The router test builds it as `buildRouter(homes: scope.homes, listenable: HomesListenable(scope.homes), motion: scope.motion, pages: scope.pages)` and disposes the listenable in a tear-down.

`lib/app/lifecycle.dart`:

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/services/network_monitor.dart';
import '../domain/services/sync_coordinator.dart';
import 'blocs/homes_bloc.dart';

/// What the shell owes the logic layer (Plan 3 ledger, `AppDependencies`
/// doc): the active home reaches `SyncCoordinator`, the cold start reads
/// once, the app going away pauses polling and coming back refreshes, and a
/// desktop window regaining focus refreshes too (spec §5.8, §5.9).
class AppLifecycleDriver {
  final SyncCoordinator _sync;
  final NetworkMonitor _network;
  final HomesBloc _homes;
  StreamSubscription<String?>? _subscription;
  AppLifecycleListener? _listener;
  bool _coldStarted = false;

  AppLifecycleDriver({
    required SyncCoordinator sync,
    required NetworkMonitor network,
    required HomesBloc homes,
  }) : _sync = sync, // ignore: prefer_initializing_formals
       _network = network, // ignore: prefer_initializing_formals
       _homes = homes; // ignore: prefer_initializing_formals

  void start() {
    _listener ??= AppLifecycleListener(
      onShow: _resumed,
      onResume: _resumed,
      onHide: _sync.onPaused,
    );
    _subscription ??= _homes.stream
        .map((s) => s.activeHomeId)
        .distinct()
        .listen(_activate);
    _activate(_homes.state.activeHomeId);
  }

  void _activate(String? homeId) {
    _sync.activateHome(homeId);
    if (homeId != null && !_coldStarted) {
      _coldStarted = true;
      unawaited(_sync.onColdStart());
    }
  }

  void _resumed() {
    unawaited(_network.refresh());
    unawaited(_sync.onResumed());
  }

  void dispose() {
    _listener?.dispose();
    unawaited(_subscription?.cancel());
  }
}
```

`lib/app/widgets/blink_notice_listener.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/copy/strings.dart';
import '../../core/widgets/toast_controller.dart';
import '../blocs/blink_cubit.dart';
import '../blocs/blink_state.dart';

/// A blink that could not read or restore its bulb shows the timeout toast
/// (spec §5.10); nothing to retry, the restore is one-shot.
class BlinkNoticeListener extends StatelessWidget {
  final Widget child;
  const BlinkNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BlinkCubit, BlinkState>(
      listenWhen: (a, b) => b.failure != null && a.failure != b.failure,
      listener: (context, state) {
        context.read<ToastController>().push(
          tone: WizToastTone.error,
          title: Strings.noResponseAfterTries,
          body: Strings.didNotAnswer(state.failure!.ip),
        );
        context.read<BlinkCubit>().clearFailure();
      },
      child: child,
    );
  }
}
```

`lib/app/shell/compact_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/wiz_layout.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_tab_bar.dart';
import 'shell_branch.dart';

/// The phone chrome (spec §9): the branch navigator under a floating tab
/// bar that hides on discovery. The bar's height and float are added to
/// the bottom inset the screens read, so their content scrolls clear of it.
class CompactShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const CompactShell({super.key, required this.shell});

  static bool showsTabBar(int branchIndex) =>
      ShellBranch.of(branchIndex) != ShellBranch.discover;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var media = MediaQuery.of(context);
    var shows = showsTabBar(shell.currentIndex);
    var lift = shows ? space.tabBar + space.tabBarFloat : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(bottom: media.padding.bottom + lift),
          ),
          child: shell,
        ),
        if (shows)
          Positioned(
            left: context.layout.gutter,
            right: context.layout.gutter,
            bottom: media.padding.bottom + space.tabBarFloat,
            child: WizTabBar<ShellBranch>(
              tabs: ShellBranch.tabs,
              value: ShellBranch.of(shell.currentIndex),
              onChanged: (branch) => shell.goBranch(
                branch.index,
                initialLocation: branch.index == shell.currentIndex,
              ),
            ),
          ),
      ],
    );
  }
}
```

`WizTabBar` receives a `value` that is always one of its four tabs while shown; on the discovery branch the bar is not built.

`lib/app/shell/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/widgets/homes_notice_listener.dart';
import '../widgets/blink_notice_listener.dart';
import 'compact_shell.dart';

/// One shell builder for every width (spec §9): the branch navigator is the
/// same object whichever chrome wraps it, so the route and its blocs
/// survive a resize. Task 20 adds the desktop chrome for the wider classes;
/// until then every width gets the phone chrome.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return HomesNoticeListener(
      child: BlinkNoticeListener(
        child: CompactShell(shell: shell),
      ),
    );
  }
}
```

`lib/app/gallery_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/copy/strings.dart';
import '../core/icons/wiz_icon_data.dart';
import '../core/theme/wiz_theme.dart';
import '../core/widgets/toast_controller.dart';
import '../core/widgets/wiz_icon_key.dart';
import '../features/gallery/gallery_screen.dart';

/// The widget gallery behind the Settings row (debug builds only): the
/// Plan 2 screen with a back key floating in the top-left, since the
/// gallery has no bar of its own.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Stack(
      children: [
        GalleryScreen(toasts: context.read<ToastController>()),
        Positioned(
          top: MediaQuery.paddingOf(context).top + space.s4,
          left: space.s4,
          child: WizIconKey(
            icon: WizIcons.chevronLeft,
            semanticsLabel: Strings.back,
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
```

`lib/app/app.dart` — rewrite:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/copy/strings.dart';
import '../core/feedback/feedback_scope.dart';
import '../core/layout/wiz_layout.dart';
import '../core/theme/wiz_theme.dart';
import '../core/widgets/toast_controller.dart';
import '../core/widgets/wiz_app_background.dart';
import '../core/widgets/wiz_toast_layer.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/repositories/light_repository.dart';
import '../domain/repositories/room_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/live_state_store.dart';
import '../domain/usecases/usecases.dart';
import '../features/modes/bloc/light_modes_bloc.dart';
import '../features/modes/modes_bloc_factory.dart';
import 'blocs/blink_cubit.dart';
import 'blocs/homes_bloc.dart';
import 'blocs/homes_event.dart';
import 'blocs/homes_state.dart';
import 'blocs/inspector_cubit.dart';
import 'blocs/network_cubit.dart';
import 'blocs/settings_cubit.dart';
import 'blocs/unreachable_cubit.dart';
import 'bootstrap.dart';
import 'command_toasts.dart';
import 'dependencies.dart';
import 'lifecycle.dart';
import 'router.dart';
import 'router_pages.dart';
import 'shell_deps.dart';

/// The root (spec §7, §9): the app-scope blocs, the providers the screens
/// read, the router, and the chassis the kit's theme, background and toast
/// stack wrap around every screen.
class WizCtlApp extends StatefulWidget {
  final AppServices services;
  const WizCtlApp({super.key, required this.services});

  @override
  State<WizCtlApp> createState() => _WizCtlAppState();
}

class _WizCtlAppState extends State<WizCtlApp> {
  AppDependencies get _deps => widget.services.deps;
  late final HomesBloc _homes;
  late final SettingsCubit _settings;
  late final NetworkCubit _network;
  late final BlinkCubit _blink;
  late final InspectorCubit _inspector;
  late final UnreachableCubit _unreachable;
  late final CommandToastListener _commandToasts;
  late final AppLifecycleDriver _lifecycle;
  late final HomesListenable _homesListenable;
  late final ShellDeps _shellDeps;
  late final GoRouter _router;

  LightModesBloc _modesBlocFor(ModeTarget target) => LightModesBloc(
    target: target,
    rooms: _deps.rooms,
    lights: _deps.lights,
    store: _deps.store,
    applyColour: _deps.applyColour,
    applyWhite: _deps.applyWhite,
    applyScene: _deps.applyScene,
    setSpeed: _deps.setSpeed,
  );

  @override
  void initState() {
    super.initState();
    var services = widget.services;
    _homes = HomesBloc(
      homes: _deps.homes,
      rooms: _deps.rooms,
      lights: _deps.lights,
      settings: _deps.settings,
      createHome: _deps.createHome,
      switchHome: _deps.switchHome,
      renameHome: _deps.renameHome,
      deleteHome: _deps.deleteHome,
      initial: HomesState.snapshot(services.homes, services.settings),
    )..add(const HomesSubscribed());
    _settings = SettingsCubit(
      settings: _deps.settings,
      feedback: services.feedback,
      debugFlags: _deps.debugFlags,
      initial: services.settings,
    )..subscribe();
    _network = NetworkCubit(
      network: _deps.network,
      settings: _deps.settings,
      homes: _deps.homes,
    )..subscribe();
    _blink = BlinkCubit(blink: _deps.blinkLight);
    _inspector = InspectorCubit();
    _unreachable = UnreachableCubit(
      lights: _deps.lights,
      store: _deps.store,
      settings: _deps.settings,
    )..subscribe();
    _commandToasts = CommandToastListener(
      toasts: services.toasts,
      pipeline: _deps.pipeline,
      lights: _deps.lights,
      delay: WizTheme.standard.motion.toastDelay,
    )..start();
    _lifecycle = AppLifecycleDriver(
      sync: _deps.sync,
      network: _deps.network,
      homes: _homes,
    )..start();
    _homesListenable = HomesListenable(_homes);
    _shellDeps = (
      homes: _deps.homes,
      rooms: _deps.rooms,
      lights: _deps.lights,
      settings: _deps.settings,
      store: _deps.store,
      sync: _deps.sync,
      setPower: _deps.setPower,
      setBrightness: _deps.setBrightness,
      setKelvin: _deps.setKelvin,
      setSpeed: _deps.setSpeed,
      setFixture: _deps.setFixture,
      renameLight: _deps.renameLight,
      forgetLight: _deps.forgetLight,
      addRoom: _deps.addRoom,
      renameRoom: _deps.renameRoom,
      deleteRoom: _deps.deleteRoom,
      runDiscovery: _deps.runDiscovery,
      saveDiscoveredLight: _deps.saveDiscoveredLight,
      learnHomeSubnet: _deps.learnHomeSubnet,
      finishOnboarding: _deps.finishOnboarding,
      ids: _deps.ids,
    );
    _router = buildRouter(
      homes: _homes,
      motion: WizTheme.standard.motion,
      listenable: _homesListenable,
      pages: AppPages(
        deps: _shellDeps,
        modesBlocFor: _modesBlocFor,
        motion: WizTheme.standard.motion,
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _homesListenable.dispose();
    _lifecycle.dispose();
    _commandToasts.dispose();
    _unreachable.close();
    _inspector.close();
    _blink.close();
    _network.close();
    _settings.close();
    _homes.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var services = widget.services;
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomesBloc>.value(value: _homes),
        BlocProvider<SettingsCubit>.value(value: _settings),
        BlocProvider<NetworkCubit>.value(value: _network),
        BlocProvider<BlinkCubit>.value(value: _blink),
        BlocProvider<InspectorCubit>.value(value: _inspector),
        BlocProvider<UnreachableCubit>.value(value: _unreachable),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ToastController>.value(value: services.toasts),
          RepositoryProvider<AppDependencies>.value(value: _deps),
          RepositoryProvider<HomeRepository>.value(value: _deps.homes),
          RepositoryProvider<RoomRepository>.value(value: _deps.rooms),
          RepositoryProvider<LightRepository>.value(value: _deps.lights),
          RepositoryProvider<SettingsRepository>.value(value: _deps.settings),
          RepositoryProvider<LiveStateStore>.value(value: _deps.store),
          RepositoryProvider<AddRoom>.value(value: _deps.addRoom),
          RepositoryProvider<ModesBlocFactory>.value(value: _modesBlocFor),
          RepositoryProvider<ShellDeps>.value(value: _shellDeps),
        ],
        child: FeedbackScope(
          service: services.feedback,
          child: BlocBuilder<HomesBloc, HomesState>(
            buildWhen: (a, b) => a.activeHome?.name != b.activeHome?.name,
            builder: (context, homes) => MaterialApp.router(
              onGenerateTitle: (_) {
                var home = homes.activeHome;
                return home == null ? Strings.windowSetup : Strings.windowTitle(home.name);
              },
              debugShowCheckedModeBanner: false,
              theme: buildWizThemeData(),
              routerConfig: _router,
              builder: (context, child) => WizLayoutScope(
                child: WizAppBackground(
                  child: _ToastOverlay(
                    toasts: services.toasts,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Keep the existing `_ToastOverlay` from the current `app.dart` as is (it already places the stack above the tab bar on compact and bottom-right elsewhere) and delete `_ReleasePlaceholder` and the `appTitle` constant. `main.dart` stays `runApp(WizCtlApp(services: await bootstrap()))`.

`WizTheme.standard.motion` is used where no `BuildContext` exists yet (the router and the toast listener are built before the first frame); it is the same object the theme installs.

- [ ] **Step 4: Run the tests**

Run: `flutter test`
Expected: PASS across the suite. The gallery's coverage test keeps passing: `GalleryScreen` is untouched.

- [ ] **Step 5: Run on macOS once** (no commit gate, a sanity check): `flutter run -d macos`, confirm the app opens on setup with a fresh database, and quit. If the app's database from an earlier run exists (`~/Library/Containers/com.dotstudios.wizctlApp/...`), the home screen appears instead; both are correct.

- [ ] **Step 6: Gates and commit**

```bash
git add lib/app lib/main.dart lib/core/copy/strings.dart test/app test/support/app_scope.dart
git commit -m "feat(app): the router, the lifecycle driver, the phone shell and the app root"
```

---

### Task 20: The desktop shell, the rail and the grid view

**Files:**
- Create: `lib/app/shell/desktop_shell.dart`, `lib/app/shell/desktop_rail.dart`, `lib/app/shell/rail_item.dart`, `lib/features/desktop/view/grid_screen.dart`, `lib/features/desktop/widgets/grid_stats.dart`, `lib/features/desktop/widgets/light_grid.dart`, `lib/features/desktop/widgets/grid_room_panel.dart`, `lib/features/home/view/home_page.dart`, `lib/features/rooms/view/room_page.dart`
- Modify: `lib/app/shell/app_shell.dart`, `lib/app/router_pages.dart`, `lib/app/widgets/screen_scroll.dart`, `lib/core/copy/strings.dart`
- Test: `test/app/shell/desktop_rail_test.dart`, `test/features/desktop/view/grid_screen_test.dart`, `test/app/app_test.dart` (additions)

**Interfaces:**
- Consumes: `WizRail<T>`/`WizRailSection`/`WizRailItem`, `HomeScreenBloc` (rooms with counts, lights, onCount, unreachableCount), `RoomBloc`, `InspectorCubit`, `LightCard(control: meter, selected:)`, `WizStatTile`, `WizGrid`, `WizPanel`, `WizTopBar`, `WizButton`, `WizToggle`, `WizEmptyState`, `DualDials`, `ModeRow`, `modeArtOf`, `showModesSheet`, `showRoomSheet`, `AddRoom`, `showHomesSheet`, `OffNetworkBanner`, `UnreachableBanner`, `sceneGradients.length`, `GoRouter.of(context).routerDelegate.currentConfiguration.uri`.
- Produces:

```dart
sealed class RailItem (RoomRailItem(roomId), AllLightsRailItem, ScenesRailItem, DiscoveryRailItem, SettingsRailItem) with == and hashCode
class DesktopRail extends StatelessWidget { const DesktopRail({required bool collapsed}); static RailItem? itemFor(String location); }
class DesktopShell extends StatelessWidget { DesktopShell({required StatefulNavigationShell shell}); }
class HomePage extends StatelessWidget {}   // HomeScreen on a phone, GridScreen.allLights() elsewhere
class RoomPage extends StatelessWidget {}   // RoomScreen on a phone, GridScreen.room() elsewhere
class GridScreen extends StatelessWidget { const GridScreen.allLights(); const GridScreen.room(); static const double dialSize = 140; static const double cardMin = 340; }
class GridStats, LightGrid, GridRoomPanel (widgets)
// Strings
allLightsTitle ('All lights'), lightsOn ('Lights on'), notAnswering ('Not answering'), lights ('Lights'), scenesRail ('Scenes'),
railRooms ('Rooms'), railHouse ('House'), noRoom ('No room'), createRoomToGroup ('Create a room to group lights');
lightsAndOn(n, k) ('<n> lights · <k> on'), onOf(k, n) ('<k> / <n>'), railFooter(k) ('<k> on · udp 38899')
```

- [ ] **Step 1: Write the failing tests**

`test/app/shell/desktop_rail_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/routes.dart';
import 'package:wizctl_app/app/shell/desktop_rail.dart';
import 'package:wizctl_app/app/shell/rail_item.dart';
import 'package:wizctl_app/core/widgets/wiz_rail.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';

import '../../support/app_scope.dart';
import '../../support/router_harness.dart';
import '../../support/seed.dart';
import '../../support/wiz_test_app.dart';

void main() {
  test('the location decides the lit item', () {
    expect(DesktopRail.itemFor('/home'), const AllLightsRailItem());
    expect(DesktopRail.itemFor('/rooms/living'), const RoomRailItem('living'));
    expect(DesktopRail.itemFor('/lights/dome'), isNull, reason: 'Task 21 lights the room through the inspector');
    expect(DesktopRail.itemFor('/modes'), const ScenesRailItem());
    expect(DesktopRail.itemFor('/discover'), const DiscoveryRailItem());
    expect(DesktopRail.itemFor('/settings'), const SettingsRailItem());
    expect(DesktopRail.itemFor('/rooms'), isNull);
  });

  testWidgets('the rail lists rooms with counts, the house items, and the footer', (tester) async {
    await setSurface(tester, const Size(1200, 800));
    var scope = AppScope(SeedHome());
    addTearDown(scope.dispose);
    await scope.start();
    var bloc = HomeScreenBloc(
      homes: scope.seed.homes, rooms: scope.seed.rooms, lights: scope.seed.lights, store: scope.seed.store,
      settings: scope.seed.settings, setPower: scope.setPower, sync: scope.sync,
    )..add(const HomeScreenSubscribed());
    addTearDown(bloc.close);
    var router = await pumpRouted(
      tester,
      scope.wrap(BlocProvider.value(value: bloc, child: const DesktopRail(collapsed: false))),
      targets: [AppRoutes.roomPattern, AppRoutes.home, AppRoutes.modes, AppRoutes.discover, AppRoutes.settings],
      size: const Size(1200, 800),
    );
    await tester.pump();
    expect(find.text('WIZCTL'), findsOneWidget);
    expect(find.text('Kaverappa House'), findsOneWidget);
    expect(find.text('ROOMS'), findsOneWidget);
    expect(find.text('HOUSE'), findsOneWidget);
    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text('3'), findsOneWidget, reason: 'the living room count');
    expect(find.text('All lights'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('36'), findsOneWidget, reason: 'the scene count');
    expect(find.text('3 on · udp 38899'), findsOneWidget);
    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), '/rooms/bedroom');
    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(currentLocation(router), AppRoutes.settings);
  });
}
```

`test/features/desktop/view/grid_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/features/desktop/view/grid_screen.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/room_event.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

void main() {
  late AppScope scope;
  const wide = Size(1200, 800);

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
  });

  tearDown(() => scope.dispose());

  testWidgets('All lights: bar, tiles, the meter cards, selection', (tester) async {
    await setSurface(tester, wide);
    var bloc = HomeScreenBloc(
      homes: scope.seed.homes, rooms: scope.seed.rooms, lights: scope.seed.lights, store: scope.seed.store,
      settings: scope.seed.settings, setPower: scope.setPower, sync: scope.sync,
    )..add(const HomeScreenSubscribed());
    addTearDown(bloc.close);
    await pumpRouted(
      tester,
      scope.wrap(BlocProvider.value(value: bloc, child: const GridScreen.allLights())),
      size: wide,
    );
    await tester.pump();
    expect(find.text('All lights'), findsOneWidget);
    expect(find.text('6 lights · 3 on'), findsOneWidget);
    expect(find.widgetWithText(WizStatTile, 'LIGHTS ON'), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.widgetWithText(WizStatTile, 'NOT ANSWERING'), findsOneWidget);
    expect(find.text('One light did not answer'), findsOneWidget);
    expect(find.text('LIGHTS'), findsOneWidget);
    expect(find.byType(LightCard), findsNWidgets(6));
    expect(tester.widgetList<LightCard>(find.byType(LightCard)).every((c) => c.control == WizBrightnessControl.meter), isTrue);
    await tester.tap(find.text('Bedside bulb'));
    await tester.pump();
    expect(scope.inspector.state, 'bedside');
    expect(tester.widget<LightCard>(find.widgetWithText(LightCard, 'Bedside bulb')).selected, isTrue);
    expect(find.text('ADD ROOM'), findsOneWidget);
  });

  testWidgets('a room: the whole-room panel with 140 dials, the toggle, the room\'s cards', (tester) async {
    await setSurface(tester, wide);
    var bloc = RoomBloc(
      roomId: 'living', rooms: scope.seed.rooms, lights: scope.seed.lights, store: scope.seed.store,
      setPower: scope.setPower, setBrightness: scope.setBrightness, setKelvin: scope.setKelvin, sync: scope.sync,
    )..add(const RoomSubscribed());
    addTearDown(bloc.close);
    await pumpRouted(
      tester,
      scope.wrap(BlocProvider.value(value: bloc, child: const GridScreen.room())),
      size: wide,
    );
    await tester.pump();
    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text('3 lights'), findsOneWidget);
    expect(find.text('WHOLE ROOM'), findsOneWidget);
    expect(find.byType(WizDial), findsNWidgets(2));
    expect(tester.getSize(find.byType(WizDial).first).width, GridScreen.dialSize);
    expect(find.widgetWithText(ModeRow, 'Mixed'), findsOneWidget);
    expect(find.byType(LightCard), findsNWidgets(3));
    await tester.tap(find.bySemanticsLabel('Living Room power'));
    await tester.pump();
    await tester.pump();
    expect(scope.gateway.sends, hasLength(3));
  });

  testWidgets('an empty room on a desktop uses the desktop line', (tester) async {
    await setSurface(tester, wide);
    await scope.seed.lights.delete('counter');
    var bloc = RoomBloc(
      roomId: 'kitchen', rooms: scope.seed.rooms, lights: scope.seed.lights, store: scope.seed.store,
      setPower: scope.setPower, setBrightness: scope.setBrightness, setKelvin: scope.setKelvin, sync: scope.sync,
    )..add(const RoomSubscribed());
    addTearDown(bloc.close);
    await pumpRouted(
      tester,
      scope.wrap(BlocProvider.value(value: bloc, child: const GridScreen.room())),
      size: wide,
    );
    await tester.pump();
    expect(find.byType(WizEmptyState), findsOneWidget);
    expect(find.text('Discover lights on the network, then save them into this room.'), findsOneWidget);
  });
}
```

Additions to `test/app/app_test.dart`:

```dart
  testWidgets('a wide window gets the rail and the grid; shrinking it keeps the route', (tester) async {
    await setSurface(tester, const Size(1200, 800));
    var services = await _services(FakeGateway());
    addTearDown(services.deps.dispose);
    await tester.pumpWidget(WizCtlApp(services: services));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopRail), findsOneWidget);
    expect(find.byType(GridScreen), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is WizTabBar), findsNothing);
    await tester.tap(find.text('Living Room'));
    await tester.pumpAndSettle();
    expect(find.text('WHOLE ROOM'), findsOneWidget);

    await setSurface(tester, const Size(390, 844));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopRail), findsNothing);
    expect(find.byWidgetPredicate((w) => w is WizTabBar), findsOneWidget);
    expect(find.byType(RoomScreen), findsOneWidget, reason: 'same route, phone chrome');
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/app test/features/desktop`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the rail, the shell, the pages and the grid**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Desktop (spec §10.9).
  static const allLightsTitle = 'All lights';
  static const lightsOnTile = 'Lights on';
  static const notAnsweringTile = 'Not answering';
  static const lights = 'Lights';
  static const railRooms = 'Rooms';
  static const railHouse = 'House';
  static const scenesRail = 'Scenes';
  static const noRoom = 'No room';
  static const createRoomToGroup = 'Create a room to group lights';
  static String lightsAndOn(int lights, int on) => '${plural(lights, 'light')} · $on on';
  static String onOf(int on, int total) => '$on / $total';
  static String railFooter(int on) => '$on on · udp $wizPort';
```

`lib/app/widgets/screen_scroll.dart`: the top padding becomes `inset.top + (context.layout.widthClass.isCompact ? space.s4 : space.s8)` (`WizCtl_Desktop.dc.html` line 164: `padding: 24px 32px`); update the doc comment.

`lib/app/shell/rail_item.dart`:

```dart
/// What the rail can light (spec §10.9): a room, or one of the house items.
sealed class RailItem {
  const RailItem();
}

final class RoomRailItem extends RailItem {
  final String roomId;
  const RoomRailItem(this.roomId);
  @override
  bool operator ==(Object other) => other is RoomRailItem && other.roomId == roomId;
  @override
  int get hashCode => roomId.hashCode;
}

final class AllLightsRailItem extends RailItem {
  const AllLightsRailItem();
}

final class ScenesRailItem extends RailItem {
  const ScenesRailItem();
}

final class DiscoveryRailItem extends RailItem {
  const DiscoveryRailItem();
}

final class SettingsRailItem extends RailItem {
  const SettingsRailItem();
}
```

(`const` instances of the four parameterless items compare equal by canonicalisation; `RoomRailItem` needs the override.)

`lib/app/shell/desktop_rail.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/layout/wiz_breakpoints.dart';
import '../../core/layout/wiz_layout.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/theme/wiz_type.dart';
import '../../core/widgets/scene_gradients.dart';
import '../../core/widgets/wiz_panel.dart';
import '../../core/widgets/wiz_pressable.dart';
import '../../core/widgets/wiz_rail.dart';
import '../../core/widgets/wiz_surface.dart';
import '../../features/home/bloc/home_screen_bloc.dart';
import '../../features/home/bloc/home_screen_state.dart';
import '../../features/home/widgets/homes_sheet.dart';
import '../blocs/homes_bloc.dart';
import '../blocs/homes_state.dart';
import '../routes.dart';
import 'rail_item.dart';

/// The desktop rail (spec §10.9): the wordmark and home pill, ROOMS with a
/// count each, HOUSE, and the footer. Collapsed to icons on medium widths.
class DesktopRail extends StatelessWidget {
  final bool collapsed;
  const DesktopRail({super.key, required this.collapsed});

  /// `_ds_bundle.js:3483`: the 30 / 900 wordmark.
  static const double wordmarkSize = 30;
  static const double pillChevron = 14;
  static const double footerGlyph = 15;

  /// Which item a location lights; null for locations the rail does not
  /// name (the rooms list, a light before Task 21 resolves its room).
  static RailItem? itemFor(String location) {
    if (location == AppRoutes.home) return const AllLightsRailItem();
    if (location == AppRoutes.modes) return const ScenesRailItem();
    if (location == AppRoutes.discover) return const DiscoveryRailItem();
    if (location == AppRoutes.settings) return const SettingsRailItem();
    var prefix = '${AppRoutes.rooms}/';
    if (location.startsWith(prefix)) {
      var id = location.substring(prefix.length);
      if (id.isNotEmpty && !id.contains('/')) return RoomRailItem(id);
    }
    return null;
  }

  void _go(BuildContext context, RailItem item) => context.go(switch (item) {
    RoomRailItem(:var roomId) => AppRoutes.room(roomId),
    AllLightsRailItem() => AppRoutes.home,
    ScenesRailItem() => AppRoutes.modes,
    DiscoveryRailItem() => AppRoutes.discover,
    SettingsRailItem() => AppRoutes.settings,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var wide = context.layout.widthClass == WidthClass.wide;
    var location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    var homes = context.watch<HomesBloc>().state;
    var home = context.watch<HomeScreenBloc>().state;
    return WizRail<RailItem>(
      collapsed: collapsed,
      width: collapsed ? wiz.space.railIcon : (wide ? wiz.space.railWide : wiz.space.rail),
      brand: _Brand(homes: homes),
      collapsedBrand: _Brand(homes: homes, collapsed: true),
      sections: [
        WizRailSection(
          title: Strings.railRooms,
          items: [
            for (var tile in home.rooms)
              WizRailItem(
                value: RoomRailItem(tile.room.id),
                label: tile.room.name,
                icon: WizIcons.byName(tile.room.glyph.iconName)!,
                meta: '${tile.lightCount}',
              ),
          ],
        ),
        WizRailSection(
          title: Strings.railHouse,
          items: [
            WizRailItem(
              value: const AllLightsRailItem(),
              label: Strings.allLightsTitle,
              icon: WizIcons.layoutGrid,
              meta: '${home.lightCount}',
            ),
            WizRailItem(
              value: const ScenesRailItem(),
              label: Strings.scenesRail,
              icon: WizIcons.sparkles,
              meta: '${sceneGradients.length}',
            ),
            const WizRailItem(
              value: DiscoveryRailItem(),
              label: Strings.discovery,
              icon: WizIcons.radio,
            ),
            const WizRailItem(
              value: SettingsRailItem(),
              label: Strings.settings,
              icon: WizIcons.slidersHorizontal,
            ),
          ],
        ),
      ],
      value: itemFor(location),
      onChanged: (item) => _go(context, item),
      footer: collapsed
          ? null
          : WizPanel(
              variant: WizPanelVariant.inset,
              padding: EdgeInsets.symmetric(horizontal: wiz.space.s5, vertical: wiz.space.s4),
              child: Row(
                children: [
                  WizIcon(WizIcons.terminal, size: footerGlyph, color: wiz.colors.textTertiary),
                  SizedBox(width: wiz.space.s3),
                  Text(
                    Strings.railFooter(home.onCount),
                    style: wiz.typography.mono.copyWith(color: wiz.colors.textTertiary),
                  ),
                ],
              ),
            ),
    );
  }
}

/// WIZCTL over the home-switcher pill (`_ds_bundle.js:3483–3492`).
class _Brand extends StatelessWidget {
  final HomesState homes;
  final bool collapsed;
  const _Brand({required this.homes, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var name = homes.activeHome?.name ?? '';
    var pill = WizPressable(
      onTap: () => showHomesSheet(context),
      semanticsLabel: Strings.homes,
      scale: wiz.motion.keyScale,
      focusRadius: BorderRadius.circular(wiz.space.pill),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(wiz.space.pill),
        gradient: wizVertical(wiz.colors.surfaceKey, wiz.colors.surfaceRaised),
        padding: EdgeInsets.symmetric(horizontal: wiz.space.s5, vertical: wiz.space.s3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!collapsed) ...[
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: wiz.typography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: wiz.colors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: wiz.space.s2),
            ],
            WizIcon(
              collapsed ? WizIcons.house : WizIcons.chevronDown,
              size: DesktopRail.pillChevron,
              color: wiz.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
    if (collapsed) return pill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.wordmark,
          style: TextStyle(
            fontFamily: WizType.familyDisplay,
            fontSize: DesktopRail.wordmarkSize,
            fontWeight: FontWeight.w900,
            letterSpacing: DesktopRail.wordmarkSize * WizType.wordmarkTracking,
            color: wiz.colors.textPrimary,
          ),
        ),
        SizedBox(height: wiz.space.s3),
        pill,
      ],
    );
  }
}
```

(`wizVertical` from `core/theme/wiz_textures.dart`; the gallery's `GalleryWordmark` draws the same mark and can be pointed at `Strings.wordmark` in Task 24.)

`lib/app/shell/desktop_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/wiz_breakpoints.dart';
import '../../core/layout/wiz_layout.dart';
import '../../features/home/bloc/home_screen_bloc.dart';
import '../../features/home/bloc/home_screen_event.dart';
import '../blocs/homes_bloc.dart';
import '../blocs/homes_state.dart';
import '../blocs/inspector_cubit.dart';
import '../shell_deps.dart';
import 'desktop_rail.dart';

/// The desktop chrome (spec §10.9): the rail, the branch navigator as the
/// content column and, from Task 21, the inspector. The rail's data is a
/// `HomeScreenBloc` of its own (rooms, counts, what is on), which also
/// keeps the whole home polled while the desktop window is up.
class DesktopShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const DesktopShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    var collapsed = context.layout.widthClass == WidthClass.medium;
    var deps = context.read<ShellDeps>();
    return BlocProvider(
      create: (_) => HomeScreenBloc(
        homes: deps.homes,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        settings: deps.settings,
        setPower: deps.setPower,
        sync: deps.sync,
      )..add(const HomeScreenSubscribed()),
      child: BlocListener<HomesBloc, HomesState>(
        listenWhen: (a, b) => a.activeHomeId != b.activeHomeId,
        listener: (context, _) => context.read<InspectorCubit>().clear(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopRail(collapsed: collapsed),
            Expanded(child: shell),
          ],
        ),
      ),
    );
  }
}
```

`ShellDeps` (Task 19, `lib/app/shell_deps.dart`) comes from the `RepositoryProvider` the app root installs; `AppScope.wrap` provides one over the fakes.

`lib/app/shell/app_shell.dart` becomes:

```dart
  @override
  Widget build(BuildContext context) {
    var compact = context.layout.widthClass.isCompact;
    return HomesNoticeListener(
      child: BlinkNoticeListener(
        child: compact ? CompactShell(shell: shell) : DesktopShell(shell: shell),
      ),
    );
  }
```

`lib/features/home/view/home_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/layout/wiz_layout.dart';
import '../../desktop/view/grid_screen.dart';
import 'home_screen.dart';

/// `/home`: the phone's Home, or the desktop's All lights grid. Both read
/// the `HomeScreenBloc` the route provides, so a resize swaps the widget
/// and keeps the data.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => context.layout.widthClass.isCompact
      ? const HomeScreen()
      : const GridScreen.allLights();
}
```

`lib/features/rooms/view/room_page.dart` is the same shape over `RoomScreen` and `GridScreen.room()`. `AppPages.home` and `AppPages.room` now build `HomePage` and `RoomPage`.

`lib/features/desktop/widgets/grid_stats.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_stat_tile.dart';

/// "Lights on" (k / n, accent) and "Not answering" (spec §10.9).
class GridStats extends StatelessWidget {
  final int onCount;
  final int total;
  final int unreachable;
  const GridStats({super.key, required this.onCount, required this.total, required this.unreachable});

  /// `WizCtl_Desktop.dc.html` line 176: `gap:14px`.
  static const double gap = 14;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WizStatTile(
            icon: WizIcons.zap,
            label: Strings.lightsOnTile,
            value: Strings.onOf(onCount, total),
            accent: true,
          ),
        ),
        const SizedBox(width: gap),
        Expanded(
          child: WizStatTile(
            icon: WizIcons.wifi,
            label: Strings.notAnsweringTile,
            value: '$unreachable',
          ),
        ),
      ],
    );
  }
}
```

`lib/features/desktop/widgets/light_grid.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/widgets/light_card.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../app/blocs/inspector_cubit.dart';

/// The meter cards (spec §10.9): min tile 340, gap 14, a click selects the
/// light into the inspector and rings the card.
class LightGrid extends StatelessWidget {
  final List<LiveLight> lights;
  final ValueChanged<(String lightId, bool on)> onToggle;
  const LightGrid({super.key, required this.lights, required this.onToggle});

  static const double cardMin = 340;
  static const double gap = 14;

  @override
  Widget build(BuildContext context) {
    var selected = context.watch<InspectorCubit>().state;
    return WizGrid(
      minTile: cardMin,
      gap: gap,
      children: [
        for (var (i, live) in lights.indexed)
          RiseIn(
            index: i,
            child: LightCard(
              name: live.light.name,
              meta: live.state.reachable
                  ? ModeSummarizer.summarize([live]).name
                  : live.light.ip,
              icon: WizIcons.byName(live.light.fixture.iconName)!,
              on: live.state.isOn,
              unreachable: !live.state.reachable,
              brightness: live.state.brightness.toDouble(),
              control: WizBrightnessControl.meter,
              selected: live.light.id == selected,
              onToggle: (on) => onToggle((live.light.id, on)),
              onTap: () => context.read<InspectorCubit>().select(live.light.id),
            ),
          ),
      ],
    );
  }
}
```

`lib/features/desktop/widgets/grid_room_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/dual_dials.dart';
import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../domain/entities/entities.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../../rooms/bloc/room_state.dart';

/// The desktop's whole-room panel (spec §10.9): dials on the left, the
/// mode row and the note on the right, 28 apart.
class GridRoomPanel extends StatelessWidget {
  final double dialSize;
  const GridRoomPanel({super.key, required this.dialSize});

  /// `WizCtl_Desktop.dc.html` line 195: `gap:28px`.
  static const double columnGap = 28;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<RoomBloc>();
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) => WizPanel(
        variant: WizPanelVariant.inset,
        padding: EdgeInsets.all(wiz.space.panelPadLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel(Strings.wholeRoom),
                  SizedBox(height: wiz.space.s5),
                  DualDials(
                    brightness: state.brightness,
                    kelvin: state.canKelvin ? state.kelvin : null,
                    onBrightness: (v) => bloc.add(RoomBrightnessChanged(v)),
                    onKelvin: (k) => bloc.add(RoomKelvinChanged(k)),
                    preferredSize: dialSize,
                  ),
                ],
              ),
            ),
            const SizedBox(width: columnGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModeRow(
                    art: modeArtOf(state.summary.art),
                    name: state.summary.name,
                    onTap: () => showModesSheet(
                      context,
                      target: RoomTarget(bloc.roomId),
                      blocFor: context.read<ModesBlocFactory>(),
                    ),
                  ),
                  if (state.kelvinNote != null) ...[
                    SizedBox(height: wiz.space.s4),
                    Text(
                      state.kelvinNote!,
                      style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`lib/features/desktop/view/grid_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../app/widgets/unreachable_banner.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/util/plural.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_toggle.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/usecases/usecases.dart';
import '../../home/bloc/home_screen_bloc.dart';
import '../../home/bloc/home_screen_event.dart';
import '../../home/bloc/home_screen_state.dart';
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../../rooms/bloc/room_state.dart';
import '../../rooms/widgets/add_room_sheet.dart';
import '../widgets/grid_room_panel.dart';
import '../widgets/grid_stats.dart';
import '../widgets/light_grid.dart';

/// The desktop's grid view (spec §10.9): All lights over a `HomeScreenBloc`,
/// or a room over a `RoomBloc`.
class GridScreen extends StatelessWidget {
  final bool _room;
  const GridScreen.allLights({super.key}) : _room = false;
  const GridScreen.room({super.key}) : _room = true;

  /// `WizCtl_Desktop.dc.html` `dialSize=140`.
  static const double dialSize = 140;

  Future<void> _addRoom(BuildContext context) async {
    var homeId = context.read<HomesBloc>().state.activeHomeId;
    if (homeId == null) return;
    var addRoom = context.read<AddRoom>();
    var toasts = context.read<ToastController>();
    var result = await showRoomSheet(
      context,
      title: Strings.addARoom,
      primaryLabel: Strings.saveRoom,
      showNote: true,
    );
    if (result == null) return;
    var room = await addRoom(homeId, result.name, result.glyph);
    toasts.push(
      tone: WizToastTone.success,
      title: Strings.roomSaved,
      body: Strings.roomIsEmpty(room.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var offNetwork = context.select<NetworkCubit, bool>((c) => c.state.offNetwork);
    var addRoom = WizButton(
      label: Strings.addRoom,
      variant: WizButtonVariant.ghost,
      size: WizButtonSize.sm,
      icon: WizIcons.housePlus,
      onPressed: () => _addRoom(context),
    );
    if (!_room) {
      return BlocBuilder<HomeScreenBloc, HomeScreenState>(
        builder: (context, state) {
          var bloc = context.read<HomeScreenBloc>();
          return ScreenScroll(
            gap: wiz.space.s7,
            children: [
              WizTopBar(
                title: Strings.allLightsTitle,
                subtitle: Strings.lightsAndOn(state.lightCount, state.onCount),
                trailing: addRoom,
              ),
              if (offNetwork) const OffNetworkBanner(),
              GridStats(onCount: state.onCount, total: state.lightCount, unreachable: state.unreachableCount),
              if (state.unreachableCount > 0) const UnreachableBanner(),
              const FieldLabel(Strings.lights),
              LightGrid(
                lights: state.lights,
                onToggle: (change) => bloc.add(HomeLightPowerToggled(change.$1, change.$2)),
              ),
            ],
          );
        },
      );
    }
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        var bloc = context.read<RoomBloc>();
        var room = state.room;
        if (room == null) {
          return ScreenScroll(
            children: [
              WizTopBar(title: Strings.noRoom, subtitle: Strings.createRoomToGroup, trailing: addRoom),
            ],
          );
        }
        var unreachable = state.aggregates?.unreachableCount ?? 0;
        return ScreenScroll(
          gap: wiz.space.s7,
          children: [
            WizTopBar(
              title: room.name,
              subtitle: plural(state.lights.length, 'light'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  addRoom,
                  SizedBox(width: wiz.space.s4),
                  WizToggle(
                    value: state.anyOn,
                    onChanged: (on) => bloc.add(RoomPowerToggled(on)),
                    semanticsLabel: Strings.roomPower(room.name),
                  ),
                ],
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            GridStats(
              onCount: state.aggregates?.onCount ?? 0,
              total: state.lights.length,
              unreachable: unreachable,
            ),
            if (unreachable > 0) const UnreachableBanner(),
            if (state.isEmpty)
              WizEmptyState(
                icon: WizIcons.lightbulb,
                title: Strings.noLightsInRoom,
                body: Strings.discoverThenSave,
                action: WizButton(
                  label: Strings.discoverLights,
                  variant: WizButtonVariant.primary,
                  onPressed: () => context.go(AppRoutes.discover),
                ),
              )
            else ...[
              const GridRoomPanel(dialSize: dialSize),
              const FieldLabel(Strings.lights),
              LightGrid(
                lights: state.lights,
                onToggle: (change) => bloc.add(LightPowerToggled(change.$1, change.$2)),
              ),
            ],
          ],
        );
      },
    );
  }
}
```

`HomeScreenBloc` has no per-light power event yet: add `HomeLightPowerToggled(String lightId, bool on)` to `home_screen_event.dart` (handled as `SetPower(LightTarget(id), on)`), named so it does not clash with the room's `LightPowerToggled`. Extend the Task 5 bloc test with one case: `HomeLightPowerToggled('strip', true)` sends to `192.168.1.111` only.

The unreachable banner in the room branch names the whole home's unreachable lights (it reads `UnreachableCubit`), which is what the desktop prototype shows in every grid view.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app test/features`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/app lib/features lib/core/copy/strings.dart test/
git commit -m "feat(desktop): the rail, the desktop shell and the grid view"
```

---

### Task 21: The inspector, as a column and as a dialog, and a light's desktop route

**Files:**
- Create: `lib/features/desktop/view/inspector_panel.dart`, `lib/features/desktop/view/inspector_dialog.dart`, `lib/features/desktop/widgets/inspector_hero.dart`, `lib/features/desktop/widgets/inspector_facts.dart`, `lib/features/lights/view/light_page.dart`
- Modify: `lib/app/shell/desktop_shell.dart`, `lib/app/router_pages.dart`, `lib/app/shell/desktop_rail.dart`, `lib/core/copy/strings.dart`
- Test: `test/features/desktop/view/inspector_panel_test.dart`, `test/app/app_test.dart` (additions)

**Interfaces:**
- Consumes: `LightBloc` (Task 12), `InspectorCubit`, `FixtureHero(compact: true)`, `emissionOf`, `fixtureOf`, `DualDials`, `WizPowerKey(size: md)`, `WizStatTile`, `WizBadge`, `ModeRow`, `WizPanel(flat)`, `WizButton`, `showModesSheet`, `showRenameLightSheet`, `showForgetLightSheet`, `showWizSheet`, `WizEmptyState`, `GridScreen.room()`, `RoomBloc`, `ShellDeps`.
- Produces:

```dart
class InspectorPanel extends StatelessWidget { const InspectorPanel(); static const double nameSize = 26; static const double dialSize = 140; }   // the column; nothing selected → empty state
class InspectorBody extends StatelessWidget {}   // the selected light's content, shared by column and dialog; expects a LightBloc
class InspectorHero, InspectorFacts (widgets)
void showInspectorDialog(BuildContext context, {required String lightId});   // medium widths
class LightPage extends StatelessWidget {}   // LightScreen on a phone; on wider widths selects the light and shows its room's grid
// Strings
noLightSelected, pickALight, scene ('Scene'), fw(version) ('udp 38899 · fw <version>')
```

- [ ] **Step 1: Write the failing tests**

`test/features/desktop/view/inspector_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/features/desktop/view/inspector_panel.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

void main() {
  late AppScope scope;
  const wide = Size(1200, 800);

  setUp(() async {
    scope = AppScope(SeedHome());
    await scope.start();
  });

  tearDown(() => scope.dispose());

  testWidgets('nothing selected is the empty state', (tester) async {
    await setSurface(tester, wide);
    await pumpRouted(tester, scope.wrap(const InspectorPanel()), size: wide);
    expect(find.byType(WizEmptyState), findsOneWidget);
    expect(find.text('No light selected'), findsOneWidget);
    expect(find.text('Pick a light on the left to control it.'), findsOneWidget);
    expect(tester.getSize(find.byType(InspectorPanel)).width, 352);
  });

  testWidgets('a selected RGB light: name, address, badge, compact hero, dials, key, tiles, mode row, facts, keys', (
    tester,
  ) async {
    await setSurface(tester, wide);
    scope.inspector.select('dome');
    await pumpRouted(tester, scope.wrap(const InspectorPanel()), size: wide);
    await tester.pumpAndSettle();
    expect(find.text('Ceiling dome light'), findsOneWidget);
    expect(find.text('192.168.1.104 · RGB'), findsOneWidget);
    expect(tester.widget<WizBadge>(find.byType(WizBadge)).label, 'Live');
    expect(tester.widget<FixtureHero>(find.byType(FixtureHero)).compact, isTrue);
    expect(find.byType(WizDial), findsNWidgets(2));
    expect(tester.widget<WizPowerKey>(find.byType(WizPowerKey)).size, WizPowerKeySize.md);
    expect(find.widgetWithText(WizStatTile, 'CLASS'), findsOneWidget);
    expect(find.widgetWithText(WizStatTile, 'SCENE'), findsOneWidget);
    expect(find.text('Cozy'), findsNWidgets(2), reason: 'the tile and the mode row');
    expect(find.byType(ModeRow), findsOneWidget);
    expect(find.text('a8bb50f1c204'), findsOneWidget);
    expect(find.text('udp 38899 · fw 1.25.0'), findsOneWidget);
    expect(find.text('RENAME'), findsOneWidget);
    expect(find.text('FORGET'), findsOneWidget);
  });

  testWidgets('a plug: the power tile and the socket note; forgetting clears the selection', (tester) async {
    await setSurface(tester, wide);
    scope.inspector.select('strip');
    await pumpRouted(tester, scope.wrap(const InspectorPanel()), size: wide);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(WizStatTile, 'BRIGHTNESS'), findsOneWidget);
    await tester.tap(find.text('FORGET'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FORGET').last);
    await tester.pumpAndSettle();
    expect(scope.inspector.state, isNull);
    expect(find.byType(WizEmptyState), findsOneWidget);
    expect(scope.toasts.toasts.single.title, 'Shelf strip forgotten');
  });
}
```

Additions to `test/app/app_test.dart`:

```dart
  testWidgets('a medium window collapses the rail and opens the inspector as a dialog', (tester) async {
    await setSurface(tester, const Size(900, 700));
    var services = await _services(FakeGateway());
    addTearDown(services.deps.dispose);
    await tester.pumpWidget(WizCtlApp(services: services));
    await tester.pumpAndSettle();
    expect(tester.widget<DesktopRail>(find.byType(DesktopRail)).collapsed, isTrue);
    expect(find.byType(InspectorPanel), findsNothing);
    await tester.tap(find.text('Ceiling dome light'));
    await tester.pumpAndSettle();
    expect(find.byType(InspectorBody), findsOneWidget, reason: 'in a dialog');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(InspectorBody), findsNothing);
  });

  testWidgets('a light\'s route on a wide window shows its room with the light selected', (tester) async {
    await setSurface(tester, const Size(1200, 800));
    var services = await _services(FakeGateway());
    addTearDown(services.deps.dispose);
    await tester.pumpWidget(WizCtlApp(services: services));
    await tester.pumpAndSettle();
    var lightId = (await services.deps.lights.getByHome(services.homes.single.id)).single.id;
    GoRouter.of(tester.element(find.byType(GridScreen))).go(AppRoutes.light(lightId));
    await tester.pumpAndSettle();
    expect(find.text('WHOLE ROOM'), findsOneWidget, reason: 'the room grid');
    expect(find.byType(InspectorBody), findsOneWidget);
    expect(find.text('RENAME'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/desktop test/app/app_test.dart`
Expected: FAIL to compile.

- [ ] **Step 3: Write the copy, the inspector, the dialog and the light page**

`lib/core/copy/strings.dart` additions (constants into `all`):

```dart
  // Inspector (spec §10.9).
  static const noLightSelected = 'No light selected';
  static const pickALight = 'Pick a light on the left to control it.';
  static const scene = 'Scene';
  static String fw(String? version) =>
      version == null ? 'udp $wizPort' : 'udp $wizPort · fw $version';
```

`lib/features/desktop/widgets/inspector_hero.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/emission.dart';
import '../../../app/widgets/fixture_kind.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/fixture_hero.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../lights/bloc/light_bloc.dart';
import '../../lights/bloc/light_state.dart';

/// The inspector's stage (spec §10.9): a 132-tall well with the fixture at
/// 0.6 scale; the kit's compact hero draws exactly that.
class InspectorHero extends StatelessWidget {
  const InspectorHero({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        return WizSurface(
          spec: wiz.elevation.well,
          radius: BorderRadius.circular(wiz.space.r4),
          gradient: wizVertical(wiz.colors.char950, wiz.colors.char1000),
          height: FixtureGeometry.compactBox.height,
          child: FixtureHero(
            fixture: fixtureOf(light.fixture),
            emission: emissionOf(state.live, light.bulbClass),
            compact: true,
          ),
        );
      },
    );
  }
}
```

(`FixtureGeometry` from `core/widgets/fixture_geometry.dart`.)

`lib/features/desktop/widgets/inspector_facts.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../lights/bloc/light_bloc.dart';
import '../../lights/bloc/light_state.dart';

/// The flat device panel (spec §10.9): DEVICE, the MAC, "udp 38899 · fw".
class InspectorFacts extends StatelessWidget {
  const InspectorFacts({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var mono = wiz.typography.mono.copyWith(color: wiz.colors.textSecondary);
        return WizPanel(
          variant: WizPanelVariant.flat,
          padding: EdgeInsets.symmetric(horizontal: wiz.space.s6, vertical: wiz.space.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(Strings.device),
              SizedBox(height: wiz.space.s3),
              Text(light.mac, style: mono),
              Text(Strings.fw(light.fwVersion), style: mono),
            ],
          ),
        );
      },
    );
  }
}
```

`lib/features/desktop/view/inspector_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../app/shell_deps.dart';
import '../../../app/widgets/dual_dials.dart';
import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_breakpoints.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_power_key.dart';
import '../../../core/widgets/wiz_stat_tile.dart';
import '../../../domain/entities/entities.dart';
import '../../lights/bloc/light_bloc.dart';
import '../../lights/bloc/light_event.dart';
import '../../lights/bloc/light_state.dart';
import '../../lights/widgets/forget_light_sheet.dart';
import '../../lights/widgets/light_notice_listener.dart';
import '../../lights/widgets/rename_light_sheet.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../widgets/inspector_facts.dart';
import '../widgets/inspector_hero.dart';

/// The inspector column (spec §10.9): 352 wide, 400 on a wide window; the
/// selected light, or "No light selected".
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  /// `WizCtl_Desktop.dc.html` line 349: the 26 / 700 name.
  static const double nameSize = 26;
  static const double dialSize = 140;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var wide = context.layout.widthClass == WidthClass.wide;
    var selected = context.watch<InspectorCubit>().state;
    return Container(
      width: wide ? wiz.space.inspectorWide : wiz.space.inspector,
      decoration: BoxDecoration(
        gradient: wizVertical(wiz.colors.char900, wiz.colors.char950),
        border: Border(left: BorderSide(color: wiz.colors.edgeHairline, width: wiz.space.hairline)),
      ),
      padding: EdgeInsets.symmetric(horizontal: wiz.space.s8, vertical: wiz.space.s8),
      child: selected == null
          ? const Center(
              child: WizEmptyState(
                icon: WizIcons.lightbulb,
                title: Strings.noLightSelected,
                body: Strings.pickALight,
              ),
            )
          : InspectorBody(key: ValueKey(selected), lightId: selected),
    );
  }
}

/// The selected light's controls, built over its own `LightBloc`. Shared by
/// the column and the medium-width dialog. When the light goes (forgotten),
/// the selection clears.
class InspectorBody extends StatelessWidget {
  final String lightId;
  const InspectorBody({super.key, required this.lightId});

  @override
  Widget build(BuildContext context) {
    var deps = context.read<ShellDeps>();
    return BlocProvider(
      create: (_) => LightBloc(
        lightId: lightId,
        lights: deps.lights,
        rooms: deps.rooms,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        setSpeed: deps.setSpeed,
        setFixture: deps.setFixture,
        renameLight: deps.renameLight,
        forgetLight: deps.forgetLight,
        sync: deps.sync,
      )..add(const LightSubscribed()),
      child: BlocListener<LightBloc, LightState>(
        listenWhen: (a, b) => a.status != b.status && b.status == LightStatus.gone,
        listener: (context, _) => context.read<InspectorCubit>().clear(),
        child: const LightNoticeListener(navigate: false, child: _InspectorContent()),
      ),
    );
  }
}

class _InspectorContent extends StatelessWidget {
  const _InspectorContent();

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var reachable = state.live.reachable;
        var sceneName = state.sceneName;
        var second = state.isSocket
            ? WizStatTile(icon: WizIcons.power, label: Strings.power, value: state.live.isOn ? Strings.on : Strings.off)
            : sceneName != null
                ? WizStatTile(icon: WizIcons.sparkles, label: Strings.scene, value: sceneName, accent: state.live.isOn)
                : WizStatTile(icon: WizIcons.gauge, label: Strings.brightness, value: '${state.live.brightness}', unit: '%', accent: state.live.isOn);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          light.name,
                          style: wiz.typography.title.copyWith(
                            fontSize: InspectorPanel.nameSize,
                            color: wiz.colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          Strings.ipAndClass(light.ip, light.className),
                          style: wiz.typography.mono.copyWith(color: wiz.colors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  WizBadge(
                    label: reachable ? Strings.live : Strings.noReply,
                    tone: reachable ? WizBadgeTone.online : WizBadgeTone.danger,
                    dot: true,
                  ),
                ],
              ),
              SizedBox(height: wiz.space.s6),
              const InspectorHero(),
              if (!state.isSocket) ...[
                SizedBox(height: wiz.space.s6),
                DualDials(
                  brightness: state.live.brightness,
                  kelvin: state.canKelvin ? state.live.kelvin : null,
                  onBrightness: (v) => bloc.add(LightBrightnessChanged(v)),
                  onKelvin: (k) => bloc.add(LightKelvinChanged(k)),
                  preferredSize: InspectorPanel.dialSize,
                  note: state.canKelvin ? null : Strings.dimsNoWhite,
                ),
              ],
              SizedBox(height: wiz.space.s6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizPowerKey(
                    on: state.live.isOn,
                    size: WizPowerKeySize.md,
                    onChanged: (on) => bloc.add(LightPowerChanged(on)),
                  ),
                  SizedBox(width: wiz.space.s5),
                  Expanded(
                    child: Column(
                      children: [
                        WizStatTile(icon: WizIcons.lightbulb, label: Strings.classTile, value: light.className),
                        SizedBox(height: wiz.space.s4),
                        second,
                      ],
                    ),
                  ),
                ],
              ),
              if (state.isSocket) ...[
                SizedBox(height: wiz.space.s6),
                WizPanel(
                  variant: WizPanelVariant.inset,
                  child: Text(
                    Strings.plugOnlyNote,
                    style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
                  ),
                ),
              ] else ...[
                SizedBox(height: wiz.space.s6),
                ModeRow(
                  art: modeArtOf(state.summary.art),
                  name: state.summary.name,
                  onTap: () => showModesSheet(
                    context,
                    target: LightTarget(bloc.lightId),
                    blocFor: context.read<ModesBlocFactory>(),
                  ),
                ),
              ],
              SizedBox(height: wiz.space.s6),
              const InspectorFacts(),
              SizedBox(height: wiz.space.s5),
              Row(
                children: [
                  Expanded(
                    child: WizButton(
                      label: Strings.rename,
                      variant: WizButtonVariant.ghost,
                      size: WizButtonSize.sm,
                      icon: WizIcons.pencil,
                      fullWidth: true,
                      onPressed: () async {
                        var name = await showRenameLightSheet(context, name: light.name);
                        if (name != null) bloc.add(LightRenamed(name));
                      },
                    ),
                  ),
                  SizedBox(width: wiz.space.s4),
                  Expanded(
                    child: WizButton(
                      label: Strings.forget,
                      variant: WizButtonVariant.danger,
                      size: WizButtonSize.sm,
                      icon: WizIcons.trash,
                      fullWidth: true,
                      onPressed: () async {
                        var sure = await showForgetLightSheet(context, name: light.name);
                        if (sure) bloc.add(const LightForgotten());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

`LightNoticeListener` (Task 13) pops or goes to the room on a forgotten light; inside the inspector there is nothing to pop and the current location is already the room or All lights. Give the listener a `bool navigate` constructor parameter (default `true`) that skips the pop/go when false; the toast still shows. Make that change in `light_notice_listener.dart` in this task.

`lib/features/desktop/view/inspector_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../core/widgets/wiz_sheet.dart';
import 'inspector_panel.dart';

/// On a medium window the inspector is a dialog that opens on selection and
/// clears the selection when closed (spec §10.9).
Future<void> showInspectorDialog(BuildContext context, {required String lightId}) {
  var inspector = context.read<InspectorCubit>();
  return showWizSheet<void>(
    context,
    title: '',
    scrollable: false,
    builder: (context) => InspectorBody(key: ValueKey(lightId), lightId: lightId),
  ).whenComplete(() {
    if (inspector.state == lightId) inspector.clear();
  });
}
```

`showWizSheet` requires a title; the inspector body carries the light's name as its own heading, so pass the light's name if it is cheap to know (`context.read<LightRepository>().get(lightId)` before opening, as `showTargetSheet` does), else the empty string. Do the read: the sheet's title is the name.

`lib/app/shell/desktop_shell.dart` additions: the inspector column for `hasInspectorColumn` widths, and the dialog listener on medium:

```dart
        child: BlocListener<InspectorCubit, String?>(
          listenWhen: (a, b) => b != null && a != b && collapsed,
          listener: (context, id) => showInspectorDialog(context, lightId: id!),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopRail(collapsed: collapsed),
              Expanded(child: shell),
              if (context.layout.widthClass.hasInspectorColumn) const InspectorPanel(),
            ],
          ),
        ),
```

(nested inside the existing `BlocListener<HomesBloc, ...>`).

`lib/features/lights/view/light_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../app/shell_deps.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../desktop/view/grid_screen.dart';
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_state.dart';
import '../widgets/light_notice_listener.dart';
import 'light_screen.dart';

/// `/lights/:id` (spec §9): the detail screen on a phone; on wider widths
/// the light's room with that light selected in the inspector.
class LightPage extends StatelessWidget {
  const LightPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.layout.widthClass.isCompact) {
      return const LightNoticeListener(child: LightScreen());
    }
    return const _LightOnDesktop();
  }
}

class _LightOnDesktop extends StatefulWidget {
  const _LightOnDesktop();
  @override
  State<_LightOnDesktop> createState() => _LightOnDesktopState();
}

class _LightOnDesktopState extends State<_LightOnDesktop> {
  @override
  void initState() {
    super.initState();
    context.read<InspectorCubit>().select(context.read<LightBloc>().lightId);
  }

  @override
  Widget build(BuildContext context) {
    var roomId = context.select<LightBloc, String?>((b) => b.state.light?.roomId);
    if (roomId == null) return const SizedBox.shrink();
    var deps = context.read<ShellDeps>();
    return BlocProvider(
      key: ValueKey(roomId),
      create: (_) => RoomBloc(
        roomId: roomId,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        sync: deps.sync,
      )..add(const RoomSubscribed()),
      child: const GridScreen.room(),
    );
  }
}
```

`AppPages.light` builds `LightPage` (with the `LightBloc` provider above it, as in Task 19, minus the `LightNoticeListener`, which `LightPage` now places itself on the phone branch). `DesktopRail.itemFor` learns nothing new: the rail lights the room through the grid's `RoomBloc` only when the location is the room; on `/lights/:id` no rail item is lit, which matches a light being "selected" rather than a room being "navigated". Update the rail test's comment accordingly.

- [ ] **Step 4: Run the tests**

Run: `flutter test`
Expected: PASS across the suite.

- [ ] **Step 5: Run on macOS once**: `flutter run -d macos`, click a card, resize the window below 1100 and above 1600, watch the inspector go dialog, column, wide column; quit.

- [ ] **Step 6: Gates and commit**

```bash
git add lib/app lib/features lib/core/copy/strings.dart test/
git commit -m "feat(desktop): the inspector as a column and a dialog, and a light's desktop route"
```

---

### Task 22: Platform configuration and the iOS audio session

**Files:**
- Modify: `ios/Runner/Info.plist`, `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`, `macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner/MainFlutterWindow.swift`, `android/app/src/main/AndroidManifest.xml`, `windows/runner/main.cpp`, `windows/runner/win32_window.cpp`, `linux/runner/my_application.cc`, `pubspec.yaml`, `lib/core/feedback/soloud_player.dart`
- Create: `lib/core/feedback/audio_session_config.dart`, `lib/core/platform/window_limits.dart`
- Test: `test/platform/platform_config_test.dart`, `test/core/feedback/audio_session_config_test.dart`

**Interfaces:**
- Consumes: spec §17; `audio_session` 0.2 (`AudioSession.instance.configure(AudioSessionConfiguration)`, `AVAudioSessionCategory.ambient`, `AVAudioSessionMode.defaultMode`); `SoLoudPlayer.init()`.
- Produces:

```dart
// lib/core/platform/window_limits.dart
class WindowLimits { static const double minWidth = 720; static const double minHeight = 560; }   // spec §14, §17; the runners repeat the numbers
// lib/core/feedback/audio_session_config.dart
const AudioSessionConfiguration wizAudioSession;   // ambient, mixes with others, honours the mute switch
Future<void> configureAudioSession({bool Function()? isIos});   // no-op off iOS; never throws
```

- [ ] **Step 1: Write the failing tests**

`test/platform/platform_config_test.dart` (reads the checked-in files; runs anywhere):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/platform/window_limits.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('iOS declares the local-network use and the display name', () {
    var plist = _read('ios/Runner/Info.plist');
    expect(plist, contains('<key>NSLocalNetworkUsageDescription</key>'));
    expect(plist, contains('WizCtl finds and controls WiZ lights on your local network.'));
    expect(plist, contains('<key>CFBundleDisplayName</key>\n\t<string>WizCtl</string>'));
    expect(plist, isNot(contains('UIBackgroundModes')));
  });

  test('macOS opens the network in both entitlement files and is named WizCtl', () {
    for (var file in ['macos/Runner/DebugProfile.entitlements', 'macos/Runner/Release.entitlements']) {
      var text = _read(file);
      expect(text, contains('com.apple.security.network.client'), reason: file);
      expect(text, contains('com.apple.security.network.server'), reason: file);
      expect(text, contains('com.apple.security.app-sandbox'), reason: file);
    }
    expect(_read('macos/Runner/Configs/AppInfo.xcconfig'), contains('PRODUCT_NAME = WizCtl'));
    expect(_read('macos/Runner/Configs/AppInfo.xcconfig'), contains('PRODUCT_BUNDLE_IDENTIFIER = com.dotstudios.wizctlApp'));
    var window = _read('macos/Runner/MainFlutterWindow.swift');
    expect(window, contains('minSize'));
    expect(window, contains('width: ${WindowLimits.minWidth.toInt()}, height: ${WindowLimits.minHeight.toInt()}'));
  });

  test('Android asks for INTERNET and is named WizCtl', () {
    var manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('<uses-permission android:name="android.permission.INTERNET"/>'));
    expect(manifest, contains('android:label="WizCtl"'));
    expect(_read('android/app/build.gradle.kts'), contains('applicationId = "com.dotstudios.wizctl_app"'));
  });

  test('Windows and Linux title the window WizCtl and set the minimum size', () {
    expect(_read('windows/runner/main.cpp'), contains('L"WizCtl"'));
    expect(_read('windows/runner/win32_window.cpp'), contains('WM_GETMINMAXINFO'));
    expect(_read('windows/runner/win32_window.cpp'), contains('${WindowLimits.minWidth.toInt()}'));
    var linux = _read('linux/runner/my_application.cc');
    expect(linux, contains('"WizCtl"'));
    expect(linux, contains('gtk_window_set_geometry_hints'));
    expect(linux, contains('${WindowLimits.minWidth.toInt()}, ${WindowLimits.minHeight.toInt()}'));
  });
}
```

`test/core/feedback/audio_session_config_test.dart`:

```dart
import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/audio_session_config.dart';

void main() {
  test('the session is ambient, mixing, and off iOS nothing is configured', () async {
    expect(wizAudioSession.avAudioSessionCategory, AVAudioSessionCategory.ambient);
    expect(wizAudioSession.avAudioSessionCategoryOptions, AVAudioSessionCategoryOptions.mixWithOthers);
    // Off iOS the call returns without touching a platform channel.
    await configureAudioSession(isIos: () => false);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/platform test/core/feedback/audio_session_config_test.dart`
Expected: FAIL (missing keys, missing files).

- [ ] **Step 3: Configure every platform**

`lib/core/platform/window_limits.dart`:

```dart
/// The desktop minimum window (spec §14, §17): 720×560, under which the
/// medium layout cannot hold its rail, content and dialog. The three
/// runners repeat these two numbers in their own languages; this file is
/// the Dart side's copy and the tests pin the runners to it.
class WindowLimits {
  WindowLimits._();
  static const double minWidth = 720;
  static const double minHeight = 560;
}
```

`ios/Runner/Info.plist`: set `CFBundleDisplayName` to `WizCtl` and add, inside the top-level `<dict>`:

```xml
	<key>NSLocalNetworkUsageDescription</key>
	<string>WizCtl finds and controls WiZ lights on your local network.</string>
```

`macos/Runner/DebugProfile.entitlements`: add `<key>com.apple.security.network.client</key><true/>` beside the existing server key. `macos/Runner/Release.entitlements`: add both

```xml
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
```

`macos/Runner/Configs/AppInfo.xcconfig`: `PRODUCT_NAME = WizCtl`.

`macos/Runner/MainFlutterWindow.swift`, in `awakeFromNib` after `setFrame`:

```swift
    // Spec §17: the medium layout needs at least this much window.
    self.minSize = NSSize(width: 720, height: 560)
```

`android/app/src/main/AndroidManifest.xml`: `android:label="WizCtl"` and, before `<application>`:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

Ruling recorded: spec §17 names only `INTERNET`. Android may drop the broadcast replies discovery listens for unless the app holds a `WifiManager.MulticastLock`; that is a plugin or platform-channel addition outside this plan. If the Android review finds broadcast discovery empty while the sweep works, the lock is the first suspect; it goes on the polish list.

`windows/runner/main.cpp`: `window.Create(L"WizCtl", origin, size)`. `windows/runner/win32_window.cpp`: in `Win32Window::MessageHandler`, add a case before `default`:

```cpp
    case WM_GETMINMAXINFO: {
      // Spec §17: 720x560 logical, scaled to the monitor's DPI.
      MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lparam);
      UINT dpi = FlutterDesktopGetDpiForHWND(hwnd);
      double scale = dpi / 96.0;
      info->ptMinTrackSize.x = static_cast<LONG>(720 * scale);
      info->ptMinTrackSize.y = static_cast<LONG>(560 * scale);
      return 0;
    }
```

`linux/runner/my_application.cc`: both title strings become `"WizCtl"`, and after `gtk_window_set_default_size`:

```cpp
  // Spec §17: the minimum window.
  GdkGeometry geometry;
  geometry.min_width = 720;
  geometry.min_height = 560;
  gtk_window_set_geometry_hints(window, nullptr, &geometry, GDK_HINT_MIN_SIZE);
```

Write the Linux numbers as `720, 560` on one line somewhere the test can find them; the `geometry.min_width = 720;` form above does not contain `720, 560`, so add a comment line `// minimum 720, 560` beside the hints call, or assert on the two assignments separately. Assert separately: replace that expectation in the test with `contains('min_width = 720')` and `contains('min_height = 560')`.

`pubspec.yaml`: add `audio_session: ^0.2.2` to `dependencies`, then `flutter pub get`.

`lib/core/feedback/audio_session_config.dart`:

```dart
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// The iOS audio session for the clicks (spec §13): ambient, so they mix
/// with whatever is playing and go quiet with the mute switch. SoLoud does
/// not own the session (Plan 2 Task 26 ruling), so the app configures it
/// before the engine starts.
const AudioSessionConfiguration wizAudioSession = AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.ambient,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
  avAudioSessionMode: AVAudioSessionMode.defaultMode,
  avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
  avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
);

/// Configures the session on iOS and does nothing elsewhere. Never throws:
/// a session that will not configure leaves the engine's default in place,
/// which is what Plan 2 shipped.
Future<void> configureAudioSession({bool Function()? isIos}) async {
  var ios = isIos ?? () => !kIsWeb && Platform.isIOS;
  if (!ios()) return;
  try {
    var session = await AudioSession.instance;
    await session.configure(wizAudioSession);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'wizctl feedback',
        context: ErrorDescription('configuring the audio session'),
      ),
    );
  }
}
```

Check `AudioSessionConfiguration`'s constructor in `audio_session` 0.2.x (`~/.pub-cache/hosted/pub.dev/audio_session-0.2.4/lib/src/core.dart`): use exactly the named parameters it declares and drop any of the five above it does not have; `avAudioSessionCategory` and `avAudioSessionCategoryOptions` are the two the test pins.

`lib/core/feedback/soloud_player.dart`: at the top of `init()`, before the engine starts, `await configureAudioSession();`.

`README.md`: a "Platform notes" section listing the four items above (local network prompt on iOS, sandbox network entitlements on macOS, INTERNET on Android, minimum window 720×560 on desktop) and the Android multicast caveat.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/platform test/core/feedback`
Expected: PASS. Then `flutter build macos --debug` and `flutter build ios --debug --no-codesign` (or `flutter run` on each) to prove the entitlements and the pod resolve; Android and Windows/Linux builds are the user's to run where the toolchains exist.

- [ ] **Step 5: Gates and commit**

```bash
git add ios macos android windows linux pubspec.yaml pubspec.lock lib/core README.md test/platform test/core/feedback
git commit -m "chore(platform): local network use, sandbox network, INTERNET, window minimums, ambient audio"
```

---

### Task 23: The accessibility batch, the reduced-motion policy and the kit README

**Files:**
- Modify: `lib/core/feedback/feedback_kind.dart`, `lib/core/motion/reduced_motion.dart`, `lib/features/onboarding/view/onboarding_screen.dart`
- Create: `lib/core/widgets/README.md`
- Test: `test/core/widgets/wiz_toggle_semantics_test.dart`, `test/features/onboarding/view/onboarding_motion_test.dart`

**Interfaces:**
- Consumes: `Semantics(toggled:)` as `WizPressable` already sets it; `SemanticsFlag.hasToggledState/isToggled` (dart:ui); `wizReducedMotion(context)`; `matchesSemantics`.
- Produces: no API change. The three review items resolve as: the toggle's switch semantics are the toggled flags (the pinned engine's `SemanticsRole` has no switch member: `bin/cache/pkg/sky_engine/lib/ui/semantics.dart`, checked 2026-09-19), pinned by a test; a disabled key plays nothing (the pressable never fires on a disabled key, and `reject` is for a refusal after a press), pinned by the doc; the reduced-motion policy is written down and the one Plan 4 animation that did not honour it now does.

- [ ] **Step 1: Write the failing tests**

`test/core/widgets/wiz_toggle_semantics_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a toggle reads as a switch: toggled state, its value, a tap', (tester) async {
    var handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        wizTestApp(WizToggle(value: true, onChanged: (_) {}, semanticsLabel: 'All lights')),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('All lights')),
        matchesSemantics(label: 'All lights', hasToggledState: true, isToggled: true, hasTapAction: true),
      );
      await tester.pumpWidget(
        wizTestApp(WizToggle(value: false, onChanged: (_) {}, semanticsLabel: 'All lights')),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('All lights')),
        matchesSemantics(label: 'All lights', hasToggledState: true, isToggled: false, hasTapAction: true),
      );
    } finally {
      handle.dispose();
    }
  });
}
```

`test/features/onboarding/view/onboarding_motion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

void main() {
  testWidgets('the step switcher takes no time under reduced motion', (tester) async {
    var scope = AppScope(SeedHome.empty());
    addTearDown(scope.dispose);
    var bloc = OnboardingBloc(
      finishOnboarding: FinishOnboarding(
        homes: scope.seed.homes, rooms: scope.seed.rooms, lights: scope.seed.lights,
        settings: scope.seed.settings, store: scope.seed.store, ids: scope.ids, clock: scope.clock,
      ),
      ids: scope.ids,
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      wizTestApp(scope.wrap(BlocProvider.value(value: bloc, child: reducedMotion(const OnboardingScreen())))),
    );
    var switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, Duration.zero);
  });
}
```

(The screen needs a `DiscoveryBloc` only on step 2; step 1 renders without one.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/widgets/wiz_toggle_semantics_test.dart test/features/onboarding/view/onboarding_motion_test.dart`
Expected: the toggle test may already pass (then it is the pin); the motion test fails on the duration.

- [ ] **Step 3: Write the doc changes, the switcher fix and the README**

`lib/core/feedback/feedback_kind.dart`: the `reject` doc becomes

```dart
  /// Something failed or was refused after a press: a write that did not
  /// land, a name that was blank, a sheet that would not take the input. A
  /// disabled key is silent — the pressable never fires on one — so this is
  /// never "you pressed something you could not press".
  reject,
```

`lib/core/motion/reduced_motion.dart`: extend the file doc with the policy, verbatim:

```dart
/// The reduced-motion policy (spec §12, "all skipped under reduced motion").
///
/// When the platform's "reduce motion" switch is on, `wizReducedMotion`
/// returns true and:
///
/// * entrances do not stagger or rise (`RiseIn` shows its child at once);
/// * nothing loops: the powered light's breathe, the radar's pings, the
///   skeleton's sheen, the badge dot's pulse, the filament's travel all
///   stand still at their parked frame;
/// * screen and step transitions take no time (the fade page, the
///   onboarding switcher);
/// * state still changes as it would: caps travel, dials turn, colours
///   change, but on their token durations rather than instantly, because a
///   control that snaps with no motion at all reads as broken.
///
/// Every new animation in the app either checks `wizReducedMotion(context)`
/// or takes its duration from a place that does.
```

`lib/features/onboarding/view/onboarding_screen.dart`: the switcher's `duration` becomes `wizReducedMotion(context) ? Duration.zero : wiz.motion.screenEnter`.

Check every other Plan 4 animation against the policy and list the result in the ledger: `Radar` (checks), `RiseIn` (checks), `WizPullToRefresh` (the kit's filament checks), `ModeRow` art cross-fade (kit), `LightCard` glow (kit). Any that does not check gets the same one-line change.

`lib/core/widgets/README.md`:

```markdown
# The kit

`lib/core/widgets` is the WizCtl design system in Flutter: every control,
surface and instrument the screens compose. This page is the vocabulary
and the rules that are easy to get wrong; the spec (§11) has the geometry.

## Vocabulary

- `value` is a control's number or choice (a dial's brightness, a
  segmented control's tab). It is owned by the caller; the widget reports
  changes through `onChanged` and `onChangeEnd` and never keeps its own.
- `on` is power: a light, a room, a toggle's position. Power draws the
  emission (amber, glow, lit well).
- `active` is "this is the current one" for navigation-like keys: the rail
  item, the icon key, the list row for the active home. Active draws amber
  without emission.
- `selected` is a pick inside a set: a scene tile, a swatch, a card in the
  desktop grid. Selected draws the 1.5 amber ring.
- `enabled: false` draws the control at 42 % and makes it inert and silent.

## Press and feedback

`WizPressable` is the one press recipe (sink 1.5, scale, shadow flip,
settle back) and the one place a cue fires: on pointer down, the kind the
widget was built with. Primary keys play `confirm`, danger keys `reject`,
everything else `press`; toggles play `toggleOn`/`toggleOff` on the
commit, not the touch; dials and sliders play `detent` on each notch; the
power key plays `power` turning on. A disabled key plays nothing.
`reject` is for a refusal after a press (a write that failed), never for
pressing something disabled.

## Arena-resolved widgets

A widget that lives inside something scrollable or tappable (a card's
toggle, a card's rail) passes `arenaResolved: true` so the gesture arena
decides between the tap and the scroll or drag instead of the pressable
claiming the pointer at once. `LightCard` does this for its toggle and its
rail; do the same for any control hosted in a card or a list row.

## Radius typing

Surfaces take a `BorderRadius`; panels take a `double` and build the
radius themselves. A widget that clips or paints a shape takes the
`BorderRadius`; a widget that only lays out takes the number. Do not
convert one to the other at a call site; pick the widget that takes what
you have.

## RiseIn in lazy lists

`RiseIn` runs its entrance on first build. A lazy list (`ListView.builder`)
builds items as they scroll into view, so every item rises in as it
appears, which is not the design's "first build only". Use `RiseIn` in a
non-lazy column, or key each item so its entrance state survives
rebuilding; `ScreenScroll` is a `ListView.separated` over a short list of
sections, which is fine for the screens' section counts.

## Hosted-control semantics

A labelled pressable is one semantics node: its children are excluded and
the label speaks for the whole. A card that hosts a toggle or a rail keeps
those as their own nodes, so a screen reader reaches the switch inside the
card. The toggle reads as a switch through the toggled flags
(`hasToggledState`, `isToggled`); the engine has no switch role.

## Reduced motion

See `lib/core/motion/reduced_motion.dart` for the policy. In short: no
staggers, no loops, no timed transitions; state changes still animate on
their tokens. Every animation checks `wizReducedMotion(context)`.

## Sizes

Nothing in the kit sizes itself from a literal. Tokens come from
`context.wiz.space`, faces and sizes from `context.wiz.typography`, colours
from `context.wiz.colors`, durations and curves from `context.wiz.motion`.
A widget's own geometry (a dial's sweep, a toggle's cap) is a named
`static const` at the top of its file with the design source in a comment.
```

Adjust any sentence above that the kit contradicts (for instance if `LightCard` does not pass `arenaResolved` today): the README describes the kit as it is, so read `light_card.dart` and `wiz_pressable.dart` before writing the arena paragraph and change it to match.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core test/features/onboarding`
Expected: PASS.

- [ ] **Step 5: Gates and commit**

```bash
git add lib/core/feedback/feedback_kind.dart lib/core/motion/reduced_motion.dart lib/core/widgets/README.md lib/features/onboarding/view/onboarding_screen.dart test/core/widgets/wiz_toggle_semantics_test.dart test/features/onboarding/view/onboarding_motion_test.dart
git commit -m "docs(kit): the kit README, the reduced-motion policy and the switch semantics pin"
```

---

### Task 24: Text scale, the spec's amendments, the README, and the closing gates

**Files:**
- Modify: `lib/features/gallery/gallery_wordmark.dart`, `docs/superpowers/specs/2026-09-08-wizctl-app-design.md`, `README.md`
- Test: `test/app/text_scale_test.dart`

**Interfaces:**
- Consumes: everything above.
- Produces: the spec's "Amendments, 2026-09-19 (Plan 4)" section listing every ruling this plan took; a README that describes the app as shipped.

- [ ] **Step 1: Write the failing test**

`test/app/text_scale_test.dart` (spec §19: "text-scale 1.3 does not overflow the light card or room card"):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/features/home/widgets/all_lights_panel.dart';

import '../support/wiz_test_app.dart';

Widget _scaled(Widget child) => MediaQuery(
  data: const MediaQueryData(size: Size(390, 844), textScaler: TextScaler.linear(1.3)),
  child: SizedBox(width: 350, child: child),
);

void main() {
  testWidgets('cards and the All lights panel survive 1.3 text scale', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        _scaled(
          Column(
            children: [
              LightCard(
                name: 'Ceiling dome light with a long name',
                meta: 'Cozy',
                icon: WizIcons.lampCeiling,
                on: true,
                brightness: 70,
                onToggle: (_) {},
              ),
              Row(
                children: [
                  Expanded(
                    child: RoomCard(
                      name: 'Living Room',
                      icon: WizIcons.sofa,
                      lightCount: 3,
                      onCount: 2,
                      on: true,
                      onToggle: (_) {},
                    ),
                  ),
                  Expanded(
                    child: RoomCard(
                      name: 'Kitchen',
                      icon: WizIcons.utensilsCrossed,
                      lightCount: 1,
                      onCount: 1,
                      on: true,
                      onToggle: (_) {},
                    ),
                  ),
                ],
              ),
              AllLightsPanel(onCount: 3, total: 6, onToggle: (_) {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/app/text_scale_test.dart`
Expected: PASS already if the kit honours its `titleMaxLines` and ellipsis rules; if it fails with an overflow, fix the offending widget's constraints (a `Flexible` around the name, `overflow: TextOverflow.ellipsis`), never the test.

- [ ] **Step 3: Point the gallery's wordmark at the copy, and amend the spec**

`lib/features/gallery/gallery_wordmark.dart`: `static const String wordmark = Strings.wordmark;` (the constant stays for the gallery's own tests).

Append to `docs/superpowers/specs/2026-09-08-wizctl-app-design.md`, after §20:

```markdown
## Amendments, 2026-09-19 (Plan 4)

Rulings taken while implementing the features and shells; each is also in the plan's ledger with its cost if wrong.

- §15 wrong-network banner: the `warn` tone (wifi glyph), not `error`.
- §10.5 the Scenes tab's subtitle counts the scenes from the kit's table ("Colour, 13 static and 23 dynamic scenes"), not the prototype's 15 and 21.
- §10.1, §10.2, §10.6, §10.8 sheets: a primary key is disabled while its required field is blank, instead of playing `reject` on press (the key already plays `confirm` on pointer down).
- §9 the Room and Light screens live in the Rooms branch; Back from a room opened from Home goes to the Rooms list, not Home (Back always pops). Discovery is the fifth branch, tab bar hidden; its Back goes Home.
- §10.4 the shared-element hero from card to detail is deferred to the polish list; the 300 ms fade covers the push.
- §10.6 the Rooms list row's meta is pluralised ("1 light · 1 on").
- §10.7 the CLI parity row confirms the copy with an info toast; the Config file row's note is its second meta line.
- §10.9 the desktop rail is fed by a `HomeScreenBloc` of its own; the modes dialog's scene grid uses min tile 140 at 104 tall; the desktop Scenes tab min tile 130 at 140 tall.
- §5.7 `RunDiscovery` accepts no home (the first run): nothing is probed and nothing is already saved.
- §5.12 `ApplyColour` coalesces like a dial drag (throttle key `colour:<target>`), so the wheel writes while dragging.
- §5.4 `RoomAggregates` is `Equatable`.
- §14 the compact scroll body puts 8 px under the top inset and the desktop body 24.
- §17 Android: only `INTERNET`; a multicast lock for broadcast replies is a possible follow-up if the Android review finds broadcast discovery empty.
- §12 reduced motion: the written policy is in `lib/core/motion/reduced_motion.dart` and the kit README (Task 23).
- §15 database error banner ("Could not read this home's config"): not implemented in this plan. A database that will not open fails at bootstrap with a console error; repository stream errors are not surfaced as a banner. On the polish list.
- Sheets that create a room outside the Rooms tab (discovery's save sheet, the desktop grid's Add room) call `AddRoom` directly and toast; the Rooms tab's bloc is not in scope there.
```

Bring the list in line with the ledger at the end of the run: every `Ruling:` line the run recorded that changes what a reader of the spec would expect belongs here.

`README.md`: describe the app as it is now — what it does (one paragraph), the platforms, how to run (`flutter run -d macos`, `-d ios`, the debug gallery through Settings), the architecture in six lines (`app`, `core`, `domain`, `data`, `features`; blocs and use cases), the fonts section as it stands, the platform notes from Task 22, the test command and count. Keep the Neumatic licence caveat.

- [ ] **Step 4: The closing gates**

Run: `flutter analyze --fatal-infos && dart format --output=none --set-exit-if-changed lib test && flutter test`
Expected: clean; every test passes. Record the test count in the ledger.

Run: `flutter run -d macos` and `flutter run -d <iphone>`: walk the first run on a fresh database (delete the app's container first, or use `--dart-define` nothing: a fresh install is the point), then Home, a room, a light, the modes sheet, discovery, Settings, the gallery; on macOS resize across the three widths. Note anything that reads wrong in the ledger for the hand-over; do not fix in this task what a review should decide.

- [ ] **Step 5: Commit**

```bash
git add lib/features/gallery/gallery_wordmark.dart docs/superpowers/specs README.md test/app/text_scale_test.dart
git commit -m "docs: Plan 4 amendments, the README as shipped, and the text-scale check"
```
