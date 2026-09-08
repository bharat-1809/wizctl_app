# Plan 2: WizCtl App Foundation and Design-System Kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the `wizctl_app` Flutter project and build its complete foundation: design tokens as a theme extension, responsive layout primitives, the 49-glyph icon set, bundled fonts, textures, the tactile feedback layer (synthesized sound plus haptics), every widget of the WizCtl design system, and a debug-only gallery screen that shows all of them working on device.

**Architecture:** `lib/core` is UI infrastructure with no domain knowledge: `theme` (one `WizTheme` extension holding colour, type, space, elevation and motion tokens), `layout` (width classes and grids), `icons`, `feedback`, `motion`, `widgets`. Every widget takes its sizes from tokens or from its parent, animates with `WizMotion` durations and curves, and fires feedback through `FeedbackScope`. Nothing in this plan imports `wizctl` or the domain layer; Plan 3 adds those and Plan 4 composes screens from this kit.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13, `flutter_lints` 6, `path_drawing` (icon paths), `flutter_soloud` 5 (playback), `package_info_plus`. Tests with `flutter_test`.

**Spec:** `/Users/bharat/Bharat/github/wizctl_app/docs/superpowers/specs/2026-09-08-wizctl-app-design.md` §2, §11, §12, §13, §14 (and §5.5, §5.6 for the colour maths).

## Global Constraints

- Project root: `/Users/bharat/Bharat/github/wizctl_app` (already a git repo containing `docs/` and `design/`). Dart package name `wizctl_app`, org `com.dotstudios`, platforms `ios,android,macos,windows,linux`, no web.
- Lints: `include: package:flutter_lints/flutter.yaml` plus `strict-casts`, `strict-inference`, `strict-raw-types`. `flutter analyze --fatal-infos` must be clean after every task; `dart format --output=none --set-exit-if-changed lib test` must be clean; `flutter test` must pass.
- No hard-coded sizes in widgets: every dimension comes from `context.wiz.space`, `context.wiz.type`, a widget parameter, or the parent's constraints. Widget-specific geometry (a dial's 280° sweep, a toggle's 46×27) lives as named `static const` values at the top of that widget's file with a one-line comment naming the design-system source.
- Colours only from `context.wiz.colors`; durations and curves only from `context.wiz.motion`; font families only via `context.wiz.type`.
- Use `Color.withValues(alpha: x)`, never the deprecated `withOpacity`.
- One widget per file, files under roughly 300 lines; split painters into `<name>_painter.dart` when a widget file grows.
- Every interactive widget: minimum hit area `space.hitMin` (44), `Semantics` label, keyboard activation, and a feedback kind fired on pointer down through `context.feedback.play(kind)`.
- Tests wrap widgets in `WizTestApp` (Task 4) which installs the theme, a `RecordingFeedbackService` and a fixed `MediaQuery` size.
- Commit after every task with the trailers `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01LHFwuJ7FsQYePfr5j1T1Pe`.
- Copy in code must match the spec verbatim (sentence case, no exclamation marks, no emoji).

---

### Task 1: Scaffold the Flutter project

**Files:**
- Create (via `flutter create`): platform folders, `lib/main.dart`, `pubspec.yaml`, `analysis_options.yaml`
- Modify: `.gitignore`, `pubspec.yaml`, `analysis_options.yaml`
- Create: `pubspec_overrides.yaml` (git-ignored), `test/smoke_test.dart`

**Interfaces:**
- Produces: a building Flutter app with all runtime and dev dependencies declared; `wizctl` resolved from the Plan 1 worktree through `pubspec_overrides.yaml`.

- [ ] **Step 1: Create the project in place**

```bash
cd /Users/bharat/Bharat/github/wizctl_app
flutter create --org com.dotstudios --project-name wizctl_app --platforms=ios,android,macos,windows,linux --empty .
```

Expected: `lib/main.dart`, `pubspec.yaml`, `analysis_options.yaml`, `ios/`, `android/`, `macos/`, `windows/`, `linux/`, `test/` created; `docs/` and `design/` untouched.

- [ ] **Step 2: Declare dependencies**

```bash
flutter pub add flutter_bloc bloc equatable go_router drift drift_flutter flutter_soloud path_drawing uuid package_info_plus
flutter pub add dev:flutter_lints dev:bloc_test dev:mocktail dev:drift_dev dev:build_runner
flutter pub add 'wizctl:{"path":"../wizctl"}'
```

Then create `pubspec_overrides.yaml` pointing at the Plan 1 worktree (replace the path with the one `git -C ../wizctl worktree list` prints for branch `sharma/app-support`):

```yaml
dependency_overrides:
  wizctl:
    path: /absolute/path/to/the/app-support/worktree
```

Append to `.gitignore` (keep everything `flutter create` wrote):

```
# Local package override while wizctl 1.1.0 is unmerged
pubspec_overrides.yaml
```

Set `version: 0.1.0+1` and `description: Control Philips WiZ lights on your local network.` in `pubspec.yaml`. Run `flutter pub get`.

- [ ] **Step 3: Tighten analysis options**

Replace `analysis_options.yaml` with:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "**/*.g.dart"
    - "**/*.drift.dart"
```

- [ ] **Step 4: Write the smoke test and a minimal app**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const WizCtlApp());
}

/// Placeholder root; Task 28 replaces it with the real bootstrap.
class WizCtlApp extends StatelessWidget {
  const WizCtlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'WizCtl',
      home: Scaffold(body: Center(child: Text('WizCtl'))),
    );
  }
}
```

Create `test/smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/main.dart';

void main() {
  testWidgets('the app builds', (tester) async {
    await tester.pumpWidget(const WizCtlApp());
    expect(find.text('WizCtl'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter build macos --debug
```
Expected: analyze clean, format clean, 1 test passes, macOS build succeeds (confirms toolchain and plugins compile).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: scaffold wizctl_app for ios, android, macos, windows, linux"
```

---

### Task 2: Colour and type tokens, colour maths

**Files:**
- Create: `lib/core/theme/wiz_colors.dart`, `lib/core/theme/wiz_type.dart`, `lib/core/util/color_maths.dart`, `lib/core/util/plural.dart`
- Test: `test/core/theme/wiz_colors_test.dart`, `test/core/util/color_maths_test.dart`, `test/core/util/plural_test.dart`

**Interfaces:**
- Produces: `class WizColors` (immutable, `static const standard`) with every colour token from spec §11.1 as a `Color` field, plus semantic aliases; `class WizType` with `TextStyle` fields `hero, display, title, heading, bodyLg, body, bodySm, caption, label, readout, readoutSm, code` and `static const familyDisplay = 'NeumaticCompressed'`, `familyUi = 'HankenGrotesk'`, `familyMono = 'JetBrainsMono'`; `Color kelvinToColor(int kelvin)`, `Color hsvToColor(double hue, double saturation)`, `({double hue, double saturation}) colorToHs(Color)`; `String plural(int n, String word)`.

- [ ] **Step 1: Write the failing tests**

`test/core/theme/wiz_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_type.dart';

void main() {
  const c = WizColors.standard;

  test('the accent is tungsten amber and ink is warm off-white', () {
    expect(c.amber500, const Color(0xFFFFB020));
    expect(c.ink1000, const Color(0xFFF6F3ED));
    expect(c.textPrimary, c.ink1000);
    expect(c.accent, c.amber500);
  });

  test('semantic surfaces alias the charcoal ramp', () {
    expect(c.surfaceApp, c.char950);
    expect(c.surfacePanel, c.char850);
    expect(c.surfaceRaised, c.char800);
    expect(c.surfaceKey, c.char750);
    expect(c.surfaceWell, c.char1000);
  });

  test('the twelve hues and six kelvin stops are present', () {
    expect(c.hues, hasLength(12));
    expect(c.hues.first, const Color(0xFFFF4A3D));
    expect(c.kelvinStops.keys, [2200, 2700, 3500, 4500, 5500, 6500]);
    expect(c.kelvinStops[6500], const Color(0xFFDCE9FF));
  });

  test('type styles carry the design faces and sizes', () {
    const t = WizType.standard;
    expect(t.hero.fontFamily, WizType.familyDisplay);
    expect(t.hero.fontSize, 64);
    expect(t.hero.fontWeight, FontWeight.w800);
    expect(t.body.fontFamily, WizType.familyUi);
    expect(t.body.fontSize, 15);
    expect(t.code.fontFamily, WizType.familyMono);
    expect(t.label.letterSpacing, closeTo(11 * 0.10, 0.001));
    expect(t.readout.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}
```

`test/core/util/color_maths_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/util/color_maths.dart';

void main() {
  test('kelvin stops map exactly and interpolate between', () {
    expect(kelvinToColor(2200), const Color(0xFFFFB25C));
    expect(kelvinToColor(6500), const Color(0xFFDCE9FF));
    var mid = kelvinToColor(2450);
    expect((mid.g * 255).round(), closeTo((178 + 201) ~/ 2, 1));
    expect(kelvinToColor(1000), kelvinToColor(2200));
    expect(kelvinToColor(9000), kelvinToColor(6500));
  });

  test('hsv to colour matches the wheel maths', () {
    expect(hsvToColor(0, 1), const Color(0xFFFF0000));
    expect(hsvToColor(120, 1), const Color(0xFF00FF00));
    expect(hsvToColor(30, 0), const Color(0xFFFFFFFF));
  });

  test('colour to hue and saturation round-trips', () {
    var hs = colorToHs(const Color(0xFFFF8A2B));
    expect(hs.hue, closeTo(28, 1));
    expect(hs.saturation, closeTo(0.83, 0.01));
  });
}
```

`test/core/util/plural_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/util/plural.dart';

void main() {
  test('plural adds an s except for one', () {
    expect(plural(0, 'light'), '0 lights');
    expect(plural(1, 'light'), '1 light');
    expect(plural(3, 'room'), '3 rooms');
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core`
Expected: compile errors, files missing.

- [ ] **Step 3: Implement the colour tokens**

`lib/core/theme/wiz_colors.dart`:

```dart
import 'package:flutter/material.dart';

/// Colour tokens from the WizCtl design system (`tokens/colors.css`).
///
/// One charcoal ramp for the chassis, warm off-white ink, and exactly one
/// accent, tungsten amber, which only ever means "on". Colour beyond that
/// appears only where the product shows light output: the kelvin ramp, the
/// twelve hues and the scene gradients.
@immutable
class WizColors {
  const WizColors._();

  static const WizColors standard = WizColors._();

  // Machined charcoal ramp (the chassis)
  final Color char1000 = const Color(0xFF0C0C0E);
  final Color char950 = const Color(0xFF101013);
  final Color char900 = const Color(0xFF16161A);
  final Color char850 = const Color(0xFF1D1D22);
  final Color char800 = const Color(0xFF24242A);
  final Color char750 = const Color(0xFF2C2C33);
  final Color char700 = const Color(0xFF35353D);
  final Color char600 = const Color(0xFF42424C);
  final Color char500 = const Color(0xFF55555F);
  final Color char400 = const Color(0xFF6E6C69);

  // Warm ink
  final Color ink1000 = const Color(0xFFF6F3ED);
  final Color ink700 = const Color(0xFFC6C2BA);
  final Color ink500 = const Color(0xFF95918A);
  final Color ink400 = const Color(0xFF6E6B65);
  final Color ink300 = const Color(0xFF4B4945);

  // Tungsten amber
  final Color amber300 = const Color(0xFFFFD98A);
  final Color amber400 = const Color(0xFFFFC24D);
  final Color amber500 = const Color(0xFFFFB020);
  final Color amber600 = const Color(0xFFE1930A);
  final Color amber700 = const Color(0xFFA96C05);

  // Kelvin ramp, keyed by kelvin
  final Map<int, Color> kelvinStops = const {
    2200: Color(0xFFFFB25C),
    2700: Color(0xFFFFC98D),
    3500: Color(0xFFFFE0BC),
    4500: Color(0xFFFFF4E6),
    5500: Color(0xFFF2F6FF),
    6500: Color(0xFFDCE9FF),
  };

  // The twelve hues, wheel order
  final Color hueRed = const Color(0xFFFF4A3D);
  final Color hueOrange = const Color(0xFFFF8A2B);
  final Color hueYellow = const Color(0xFFFFD52B);
  final Color hueLime = const Color(0xFFB7F03C);
  final Color hueGreen = const Color(0xFF38D06B);
  final Color hueTeal = const Color(0xFF25D8C0);
  final Color hueCyan = const Color(0xFF2ECBFF);
  final Color hueBlue = const Color(0xFF2E7BFF);
  final Color hueIndigo = const Color(0xFF5B5BFF);
  final Color hueViolet = const Color(0xFFA45BFF);
  final Color hueMagenta = const Color(0xFFFF3FC0);
  final Color huePink = const Color(0xFFFF6FA5);

  List<Color> get hues => [
    hueRed, hueOrange, hueYellow, hueLime, hueGreen, hueTeal,
    hueCyan, hueBlue, hueIndigo, hueViolet, hueMagenta, huePink,
  ];

  // Status
  final Color signalOnline = const Color(0xFF38D06B);
  final Color signalOffline = const Color(0xFF55555F);
  final Color signalWarn = const Color(0xFFFFB020);
  final Color signalDanger = const Color(0xFFFF5A47);

  // Semantic surfaces
  Color get surfaceApp => char950;
  Color get surfaceChassis => char900;
  Color get surfacePanel => char850;
  Color get surfaceRaised => char800;
  Color get surfaceKey => char750;
  Color get surfaceWell => char1000;
  final Color surfaceScrim = const Color(0xB80A0A0C); // rgba(10,10,12,.72)

  // Semantic text
  Color get textPrimary => ink1000;
  Color get textSecondary => ink700;
  Color get textTertiary => ink500;
  Color get textDisabled => ink400;
  final Color textOnAccent = const Color(0xFF1A1305);
  Color get textLink => amber400;
  Color get textLinkHover => amber300;

  // Accents and edges
  Color get accent => amber500;
  Color get accentHover => amber400;
  Color get accentPress => amber600;
  final Color accentSoft = const Color(0x24FFB020); // rgba(255,176,32,.14)
  final Color edgeHairline = const Color(0x0EFFFFFF); // rgba(255,255,255,.055)
  final Color edgeKey = const Color(0x1AFFFFFF); // rgba(255,255,255,.10)
  final Color edgeGroove = const Color(0x8C000000); // rgba(0,0,0,.55)
  final Color focusRing = const Color(0x8CFFC24D); // rgba(255,194,77,.55)

  // Danger key (Button variant danger)
  final Color dangerKeyTop = const Color(0xFFE2543F);
  final Color dangerKeyBottom = const Color(0xFFA82B1C);
  final Color dangerKeyInk = const Color(0xFFFFF1ED);

  // Ivory used by slider handles and toggle caps
  final Color ivoryHi = const Color(0xFFFBFAF7);
  final Color ivoryLo = const Color(0xFFC9C5BD);
}
```

- [ ] **Step 4: Implement the type tokens**

`lib/core/theme/wiz_type.dart`:

```dart
import 'package:flutter/material.dart';

/// Type tokens from `tokens/typography.css`.
///
/// The user's words are set in the grotesque, the machine's words in mono,
/// the instrument's numbers in the display face. Letter-spacing values in the
/// CSS are in em; here they are already multiplied out to logical pixels.
@immutable
class WizType {
  const WizType._();

  static const WizType standard = WizType._();

  static const String familyDisplay = 'NeumaticCompressed';
  static const String familyUi = 'HankenGrotesk';
  static const String familyMono = 'JetBrainsMono';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Uppercase control labels track wide: 0.10 em.
  static const double labelTracking = 0.10;

  final TextStyle hero = const TextStyle(
    fontFamily: familyDisplay, fontSize: 64, height: 0.92,
    letterSpacing: 64 * -0.005, fontWeight: FontWeight.w800,
  );
  final TextStyle display = const TextStyle(
    fontFamily: familyDisplay, fontSize: 44, height: 0.98,
    letterSpacing: 44 * 0.005, fontWeight: FontWeight.w700,
  );
  final TextStyle title = const TextStyle(
    fontFamily: familyDisplay, fontSize: 30, height: 1.06,
    letterSpacing: 30 * 0.015, fontWeight: FontWeight.w700,
  );
  final TextStyle heading = const TextStyle(
    fontFamily: familyDisplay, fontSize: 23, height: 1.16,
    letterSpacing: 23 * 0.025, fontWeight: FontWeight.w600,
  );
  final TextStyle bodyLg = const TextStyle(
    fontFamily: familyUi, fontSize: 17, height: 1.5, fontWeight: FontWeight.w400,
  );
  final TextStyle body = const TextStyle(
    fontFamily: familyUi, fontSize: 15, height: 1.5, fontWeight: FontWeight.w400,
  );
  final TextStyle bodySm = const TextStyle(
    fontFamily: familyUi, fontSize: 13, height: 1.45, fontWeight: FontWeight.w400,
  );
  final TextStyle caption = const TextStyle(
    fontFamily: familyUi, fontSize: 11, height: 1.35,
    letterSpacing: 11 * 0.06, fontWeight: FontWeight.w400,
  );

  /// Uppercase control label; callers pass `text.toUpperCase()`.
  final TextStyle label = const TextStyle(
    fontFamily: familyUi, fontSize: 11, height: 1.35,
    letterSpacing: 11 * labelTracking, fontWeight: FontWeight.w600,
  );
  final TextStyle readout = const TextStyle(
    fontFamily: familyDisplay, fontSize: 34, height: 1,
    fontWeight: FontWeight.w700, fontFeatures: _tabular,
  );
  final TextStyle readoutSm = const TextStyle(
    fontFamily: familyDisplay, fontSize: 18, height: 1,
    fontWeight: FontWeight.w700, fontFeatures: _tabular,
  );
  final TextStyle code = const TextStyle(
    fontFamily: familyMono, fontSize: 12.5, height: 1.55, fontWeight: FontWeight.w400,
  );

  /// Mono at the small size rows use for `ip · class` (11.5).
  final TextStyle mono = const TextStyle(
    fontFamily: familyMono, fontSize: 11.5, height: 1.4, fontWeight: FontWeight.w400,
  );
}
```

- [ ] **Step 5: Implement the colour maths and plural**

`lib/core/util/color_maths.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The kelvin ramp, spec §5.5. Linear interpolation between the stops;
/// clamped outside them.
const List<(int, Color)> _kelvinStops = [
  (2200, Color(0xFFFFB25C)),
  (2700, Color(0xFFFFC98D)),
  (3500, Color(0xFFFFE0BC)),
  (4500, Color(0xFFFFF4E6)),
  (5500, Color(0xFFF2F6FF)),
  (6500, Color(0xFFDCE9FF)),
];

Color kelvinToColor(int kelvin) {
  if (kelvin <= _kelvinStops.first.$1) return _kelvinStops.first.$2;
  for (var i = 1; i < _kelvinStops.length; i++) {
    var (k1, c1) = _kelvinStops[i];
    if (kelvin <= k1) {
      var (k0, c0) = _kelvinStops[i - 1];
      var t = (kelvin - k0) / (k1 - k0);
      return Color.lerp(c0, c1, t)!;
    }
  }
  return _kelvinStops.last.$2;
}

/// HSV with V = 1, the colour wheel's model (design system `hsvToRgb`).
Color hsvToColor(double hue, double saturation) {
  int channel(int n) {
    var k = (n + hue / 60) % 6;
    var v = 1 - saturation * math.max(0, math.min(k, math.min(4 - k, 1)));
    return (255 * v).round().clamp(0, 255);
  }

  return Color.fromARGB(255, channel(5), channel(3), channel(1));
}

/// Hue in degrees and saturation in [0, 1] of a colour (design system `rgbHs`).
({double hue, double saturation}) colorToHs(Color color) {
  var r = color.r, g = color.g, b = color.b;
  var max = math.max(r, math.max(g, b));
  var min = math.min(r, math.min(g, b));
  var d = max - min;
  var h = 0.0;
  if (d != 0) {
    if (max == r) {
      h = ((g - b) / d) % 6;
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h = (h * 60 + 360) % 360;
  }
  return (hue: h, saturation: max == 0 ? 0 : d / max);
}
```

`lib/core/util/plural.dart`:

```dart
/// "1 light", "3 lights". The app never localises, so this is enough.
String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/core`
Expected: all PASS.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test && flutter analyze --fatal-infos
git add lib/core test/core
git commit -m "feat(theme): colour and type tokens, colour maths"
```

---

### Task 3: Space, elevation and motion tokens

**Files:**
- Create: `lib/core/theme/wiz_space.dart`, `lib/core/theme/wiz_elevation.dart`, `lib/core/theme/wiz_motion.dart`
- Test: `test/core/theme/wiz_tokens_test.dart`

**Interfaces:**
- Produces: `class WizSpace` with `s1..s12`, `r1..r6`, `pill`, `controlSm/controlMd/controlLg`, `hitMin`, `knobSm/knobMd/knobLg`, `track`, `panelPad/panelPadLg`, `gutter/gutterDesktop`, `rail/railWide/railIcon`, `inspector/inspectorWide`, `tabBar/tabBarFloat`, `hairline/keyBorder`; `class WizInset { double offsetY; double blur; Color color; }`; `class WizShadowSpec { List<BoxShadow> outer; List<WizInset> insets; }`; `class WizElevation` with `panel, raised, key, knob, pressed, well, wellDeep, overlay, flat` (`WizShadowSpec`) and `glowAmber, glowAmberStrong` (`List<BoxShadow>`), plus texture constants `grainAlpha 0.035, grainDot 0.5, grainTile 3, vignetteAlpha 0.055, knurlHiAlpha 0.07, knurlLoAlpha 0.34`; `class WizMotion` with durations `press 80, release 140, ui 180, panel 260, screenEnter 300, loadIn 360, light 420, breathe 5500, toast 3200, ping 2200, filament 1350, sheen 1600, spin 900, stagger 55, toastDelay 600` and curves `tactile, pressCurve, settle`, scalars `pressTravel 1.5, pressScale 0.985, smallKeyScale 0.94, keyScale 0.97, cardScale 0.975, hoverBrightness 1.08, breatheMin 0.88`.

- [ ] **Step 1: Write the failing test**

`test/core/theme/wiz_tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_elevation.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';

void main() {
  test('spacing scale and hardware sizes', () {
    const s = WizSpace.standard;
    expect([s.s1, s.s2, s.s3, s.s4, s.s5, s.s6, s.s7, s.s8, s.s9, s.s10, s.s11, s.s12],
        [2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 56, 72]);
    expect([s.r1, s.r2, s.r3, s.r4, s.r5, s.r6], [6, 10, 14, 20, 28, 36]);
    expect(s.hitMin, 44);
    expect(s.knobLg, 168);
    expect(s.rail, 264);
    expect(s.inspector, 352);
    expect(s.tabBar, 72);
    expect(s.tabBarFloat, 18);
  });

  test('elevation recipes carry their insets and outer shadows', () {
    const e = WizElevation.standard;
    expect(e.panel.insets, hasLength(1));
    expect(e.panel.outer, hasLength(2));
    expect(e.well.insets.first.blur, 7);
    expect(e.well.insets.first.offsetY, 3);
    expect(e.knob.outer.last.blurRadius, 40);
    expect(e.knob.outer.last.spreadRadius, -14);
    expect(e.glowAmberStrong, hasLength(3));
    expect(e.glowAmber.first.color, const Color(0x33FFB020));
  });

  test('motion durations and curves', () {
    const m = WizMotion.standard;
    expect(m.press, const Duration(milliseconds: 80));
    expect(m.release, const Duration(milliseconds: 140));
    expect(m.panel, const Duration(milliseconds: 260));
    expect(m.light, const Duration(milliseconds: 420));
    expect(m.breathe, const Duration(milliseconds: 5500));
    expect(m.tactile, const Cubic(.2, .8, .2, 1));
    expect(m.settle, const Cubic(.16, 1.02, .3, 1));
    expect(m.pressTravel, 1.5);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/theme/wiz_tokens_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the space tokens**

`lib/core/theme/wiz_space.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Spacing, radii and hardware sizes from `tokens/spacing.css`, plus the
/// layout numbers from the handoff spec (rail, inspector, tab bar).
@immutable
class WizSpace {
  const WizSpace._();

  static const WizSpace standard = WizSpace._();

  final double s1 = 2, s2 = 4, s3 = 6, s4 = 8, s5 = 12, s6 = 16, s7 = 20,
      s8 = 24, s9 = 32, s10 = 40, s11 = 56, s12 = 72;

  final double r1 = 6, r2 = 10, r3 = 14, r4 = 20, r5 = 28, r6 = 36;

  /// Large enough to round any control fully.
  final double pill = 999;

  final double controlSm = 36, controlMd = 48, controlLg = 56;

  /// Touch targets never go below this on any platform.
  final double hitMin = 44;

  final double knobSm = 56, knobMd = 96, knobLg = 168;

  /// Recessed slider well thickness.
  final double track = 14;

  final double panelPad = 16, panelPadLg = 20;

  final double gutter = 20, gutterDesktop = 32;

  /// Desktop rail widths: full, on very wide windows, and icon-only.
  final double rail = 264, railWide = 288, railIcon = 72;

  /// Desktop inspector widths: normal and on very wide windows.
  final double inspector = 352, inspectorWide = 400;

  /// Phone tab bar height and how far it floats above the bottom edge.
  final double tabBar = 72, tabBarFloat = 18;

  final double hairline = 1, keyBorder = 1.5;
}
```

- [ ] **Step 4: Implement the elevation tokens**

`lib/core/theme/wiz_elevation.dart`:

```dart
import 'package:flutter/material.dart';

/// An inset (inner) shadow: CSS `inset 0 <offsetY> <blur> <color>`. A blur of
/// 0 with a 1px offset is the hard highlight or groove line.
@immutable
class WizInset {
  final double offsetY;
  final double blur;
  final Color color;
  const WizInset({required this.offsetY, required this.blur, required this.color});
}

/// One elevation recipe: outer cast shadows plus inner highlight/groove.
@immutable
class WizShadowSpec {
  final List<BoxShadow> outer;
  final List<WizInset> insets;
  const WizShadowSpec({this.outer = const [], this.insets = const []});
}

/// Elevation and texture tokens from `tokens/elevation.css`.
///
/// One light source, low and top-left. Raised parts get a top highlight, a
/// bottom groove and a cast shadow; recessed parts invert it. Never mix the
/// two on one element, and never nest raised directly inside raised.
@immutable
class WizElevation {
  const WizElevation._();

  static const WizElevation standard = WizElevation._();

  static const Color _hi = Color(0x13FFFFFF); // rgba(255,255,255,.075)
  static const Color _hiStrong = Color(0x21FFFFFF); // .13
  static const Color _lo = Color(0x99000000); // rgba(0,0,0,.60)
  static const Color _hairline = Color(0x0EFFFFFF); // .055

  final WizShadowSpec flat = const WizShadowSpec(
    outer: [BoxShadow(color: _hairline, spreadRadius: 1)],
  );
  final WizShadowSpec panel = const WizShadowSpec(
    insets: [WizInset(offsetY: 1, blur: 0, color: _hi)],
    outer: [
      BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: _lo, offset: Offset(0, 10), blurRadius: 24, spreadRadius: -12),
    ],
  );
  final WizShadowSpec raised = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 1, blur: 0, color: _hiStrong),
      WizInset(offsetY: -1, blur: 0, color: Color(0x66000000)),
    ],
    outer: [
      BoxShadow(color: Color(0x59000000), offset: Offset(0, 2), blurRadius: 3),
      BoxShadow(color: _lo, offset: Offset(0, 10), blurRadius: 20, spreadRadius: -8),
    ],
  );
  final WizShadowSpec key = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 1.5, blur: 0, color: _hiStrong),
      WizInset(offsetY: -2, blur: 2, color: Color(0x73000000)),
    ],
    outer: [
      BoxShadow(color: Color(0x6B000000), offset: Offset(0, 3), blurRadius: 5),
      BoxShadow(color: _lo, offset: Offset(0, 14), blurRadius: 26, spreadRadius: -10),
    ],
  );
  final WizShadowSpec knob = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 2, blur: 0, color: _hiStrong),
      WizInset(offsetY: -3, blur: 4, color: Color(0x80000000)),
    ],
    outer: [
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 6), blurRadius: 10),
      BoxShadow(color: _lo, offset: Offset(0, 22), blurRadius: 40, spreadRadius: -14),
    ],
  );
  final WizShadowSpec pressed = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 3, blur: 6, color: Color(0x9E000000)),
      WizInset(offsetY: -1, blur: 0, color: _hi),
    ],
    outer: [BoxShadow(color: _hi, offset: Offset(0, 1))],
  );
  final WizShadowSpec well = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 3, blur: 7, color: Color(0xA8000000)),
      WizInset(offsetY: -1, blur: 0, color: _hi),
    ],
  );
  final WizShadowSpec wellDeep = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 5, blur: 12, color: Color(0xB8000000)),
      WizInset(offsetY: -1.5, blur: 0, color: _hi),
    ],
  );
  final WizShadowSpec overlay = const WizShadowSpec(
    outer: [
      BoxShadow(color: Color(0xD9000000), offset: Offset(0, 30), blurRadius: 70, spreadRadius: -20),
      BoxShadow(color: _hairline, spreadRadius: 1),
    ],
  );

  /// Emission: used only where a light is actually on. Softened values from
  /// the handoff README so adjacent lit cards do not bleed into each other.
  final List<BoxShadow> glowAmber = const [
    BoxShadow(color: Color(0x33FFB020), spreadRadius: 1),
    BoxShadow(color: Color(0x42FFB020), blurRadius: 14, spreadRadius: -6),
  ];
  final List<BoxShadow> glowAmberStrong = const [
    BoxShadow(color: Color(0x47FFB020), spreadRadius: 1),
    BoxShadow(color: Color(0x4DFFB020), blurRadius: 18, spreadRadius: -6),
    BoxShadow(color: Color(0x1AFFB020), blurRadius: 40, spreadRadius: -14),
  ];

  // Textures
  final double grainAlpha = 0.035;
  final double grainDot = 0.5;
  final double grainTile = 3;
  final double vignetteAlpha = 0.055;
  final double knurlHiAlpha = 0.07;
  final double knurlLoAlpha = 0.34;
}
```

- [ ] **Step 5: Implement the motion tokens**

`lib/core/theme/wiz_motion.dart`:

```dart
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Motion tokens from `tokens/motion.css` and the handoff motion table.
/// Fast in, settle out. Nothing bounces except a released knob or cap.
@immutable
class WizMotion {
  const WizMotion._();

  static const WizMotion standard = WizMotion._();

  final Duration press = const Duration(milliseconds: 80);
  final Duration release = const Duration(milliseconds: 140);
  final Duration ui = const Duration(milliseconds: 180);
  final Duration panel = const Duration(milliseconds: 260);
  final Duration screenEnter = const Duration(milliseconds: 300);
  final Duration loadIn = const Duration(milliseconds: 360);
  final Duration light = const Duration(milliseconds: 420);
  final Duration breathe = const Duration(milliseconds: 5500);
  final Duration toast = const Duration(milliseconds: 3200);
  final Duration ping = const Duration(milliseconds: 2200);
  final Duration filament = const Duration(milliseconds: 1350);
  final Duration sheen = const Duration(milliseconds: 1600);
  final Duration spin = const Duration(milliseconds: 900);
  final Duration stagger = const Duration(milliseconds: 55);

  /// A write still in flight after this shows its loading toast.
  final Duration toastDelay = const Duration(milliseconds: 600);

  final Curve tactile = const Cubic(.2, .8, .2, 1);
  final Curve pressCurve = const Cubic(.4, 0, 1, 1);
  final Curve settle = const Cubic(.16, 1.02, .3, 1);

  /// How far a key sinks, in logical pixels.
  final double pressTravel = 1.5;
  final double pressScale = 0.985;
  final double smallKeyScale = 0.94;
  final double keyScale = 0.97;
  final double cardScale = 0.975;
  final double hoverBrightness = 1.08;
  final double breatheMin = 0.88;

  /// Load-in rise distance.
  final double riseDistance = 12;
}
```

- [ ] **Step 6: Run the tests, format, analyze, commit**

```bash
flutter test test/core/theme && dart format lib test && flutter analyze --fatal-infos
git add lib/core/theme test/core/theme
git commit -m "feat(theme): space, elevation and motion tokens"
```

---

### Task 4: WizTheme extension, ThemeData, test harness

**Files:**
- Create: `lib/core/theme/wiz_theme.dart`, `test/support/wiz_test_app.dart`
- Test: `test/core/theme/wiz_theme_test.dart`

**Interfaces:**
- Consumes: `WizColors`, `WizType`, `WizSpace`, `WizElevation`, `WizMotion`, `FeedbackService` (Task 7 provides the interface; this task creates a forward-compatible stub only if Task 7 has not run: implement Task 7 first if executing out of order).
- Produces: `class WizTheme extends ThemeExtension<WizTheme> { colors, type, space, elevation, motion }`, `ThemeData buildWizThemeData()`, `extension WizThemeContext on BuildContext { WizTheme get wiz; }`, and the test helper `Widget wizTestApp(Widget child, {Size size = const Size(390, 844), FeedbackService? feedback})` that wraps in `MaterialApp(theme: buildWizThemeData())`, `MediaQuery`, `FeedbackScope` and a `Scaffold`.

- [ ] **Step 1: Write the failing test**

`test/core/theme/wiz_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('context.wiz exposes every token group', (tester) async {
    late WizTheme wiz;
    await tester.pumpWidget(wizTestApp(Builder(builder: (context) {
      wiz = context.wiz;
      return const SizedBox();
    })));
    expect(wiz.colors.amber500, const Color(0xFFFFB020));
    expect(wiz.space.hitMin, 44);
    expect(wiz.motion.press.inMilliseconds, 80);
    expect(wiz.type.body.fontFamily, 'HankenGrotesk');
    expect(wiz.elevation.panel.outer, isNotEmpty);
  });

  testWidgets('the theme paints the app surface and warm ink', (tester) async {
    late ThemeData theme;
    await tester.pumpWidget(wizTestApp(Builder(builder: (context) {
      theme = Theme.of(context);
      return const SizedBox();
    })));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF101013));
    expect(theme.colorScheme.onSurface, const Color(0xFFF6F3ED));
    expect(theme.brightness, Brightness.dark);
    expect(theme.splashFactory, NoSplash.splashFactory);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/theme/wiz_theme_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the theme extension and ThemeData**

`lib/core/theme/wiz_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'wiz_colors.dart';
import 'wiz_elevation.dart';
import 'wiz_motion.dart';
import 'wiz_space.dart';
import 'wiz_type.dart';

/// All WizCtl tokens as one theme extension. There is exactly one theme
/// (the machined dark chassis), so `lerp` and `copyWith` return this.
@immutable
class WizTheme extends ThemeExtension<WizTheme> {
  final WizColors colors;
  final WizType type;
  final WizSpace space;
  final WizElevation elevation;
  final WizMotion motion;

  const WizTheme({
    this.colors = WizColors.standard,
    this.type = WizType.standard,
    this.space = WizSpace.standard,
    this.elevation = WizElevation.standard,
    this.motion = WizMotion.standard,
  });

  static const WizTheme standard = WizTheme();

  static WizTheme of(BuildContext context) =>
      Theme.of(context).extension<WizTheme>() ?? standard;

  @override
  WizTheme copyWith() => this;

  @override
  WizTheme lerp(ThemeExtension<WizTheme>? other, double t) => this;
}

extension WizThemeContext on BuildContext {
  WizTheme get wiz => WizTheme.of(this);
}

/// The Material theme underneath the kit: dark, no ripples, warm ink, the
/// design faces as defaults so any stray Material widget still reads right.
ThemeData buildWizThemeData() {
  const wiz = WizTheme.standard;
  var c = wiz.colors;
  var t = wiz.type;
  var scheme = ColorScheme.dark(
    surface: c.surfaceApp,
    onSurface: c.textPrimary,
    primary: c.accent,
    onPrimary: c.textOnAccent,
    secondary: c.amber400,
    error: c.signalDanger,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.surfaceApp,
    canvasColor: c.surfaceApp,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    fontFamily: WizType.familyUi,
    textTheme: TextTheme(
      displayLarge: t.hero,
      displayMedium: t.display,
      headlineMedium: t.title,
      titleLarge: t.heading,
      bodyLarge: t.bodyLg,
      bodyMedium: t.body,
      bodySmall: t.bodySm,
      labelSmall: t.caption,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.amber400,
      selectionColor: c.accentSoft,
      selectionHandleColor: c.amber400,
    ),
    extensions: const [wiz],
  );
}
```

- [ ] **Step 4: Create the test harness**

`test/support/wiz_test_app.dart` (depends on Task 7's `FeedbackScope` and `RecordingFeedbackService`; if Task 7 is not yet done, do Task 7 now, then return):

```dart
import 'package:flutter/material.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';

/// Wraps a widget in the WizCtl theme, a fixed phone-sized MediaQuery and a
/// recording feedback service, so widget tests can assert on sounds fired.
Widget wizTestApp(
  Widget child, {
  Size size = const Size(390, 844),
  FeedbackService? feedback,
}) {
  return FeedbackScope(
    service: feedback ?? RecordingFeedbackService(),
    child: MaterialApp(
      theme: buildWizThemeData(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/theme && dart format lib test && flutter analyze --fatal-infos
git add lib/core/theme test/support test/core/theme
git commit -m "feat(theme): WizTheme extension, ThemeData and test harness"
```

---

### Task 5: Width classes, layout scope and grid

**Files:**
- Create: `lib/core/layout/wiz_breakpoints.dart`, `lib/core/layout/wiz_layout.dart`, `lib/core/layout/wiz_grid.dart`
- Test: `test/core/layout/wiz_breakpoints_test.dart`, `test/core/layout/wiz_grid_test.dart`

**Interfaces:**
- Produces: `enum WidthClass { compact, medium, expanded, wide }` with `bool get isCompact`, `isDesktopLike` (medium or above); `class WizBreakpoints { static const compactMax = 720, mediumMax = 1100, wideMin = 1600; static WidthClass classify(double width); }`; `class WizLayout extends InheritedWidget { WidthClass widthClass; double width; double gutter; static WizLayout of(BuildContext) }`; `class WizLayoutScope extends StatelessWidget { child }` (a `LayoutBuilder` that installs `WizLayout`); `extension WizLayoutContext on BuildContext { WizLayout get layout; }`; `int wizGridColumns({required double width, required double minTile, required double gap})` and `class WizGrid extends StatelessWidget { minTile, gap, children, childAspectRatio? , mainAxisExtent? }` that lays children out in `columns` equal-width columns using `Wrap`-free `Column`/`Row` math (so it works inside a scrolling column without slivers).

- [ ] **Step 1: Write the failing tests**

`test/core/layout/wiz_breakpoints_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/layout/wiz_breakpoints.dart';
import 'package:wizctl_app/core/layout/wiz_layout.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('classify maps widths to classes', () {
    expect(WizBreakpoints.classify(320), WidthClass.compact);
    expect(WizBreakpoints.classify(719), WidthClass.compact);
    expect(WizBreakpoints.classify(720), WidthClass.medium);
    expect(WizBreakpoints.classify(1099), WidthClass.medium);
    expect(WizBreakpoints.classify(1100), WidthClass.expanded);
    expect(WizBreakpoints.classify(1600), WidthClass.wide);
    expect(WidthClass.medium.isDesktopLike, isTrue);
    expect(WidthClass.compact.isDesktopLike, isFalse);
  });

  testWidgets('WizLayoutScope exposes the class and gutter', (tester) async {
    late WizLayout layout;
    await tester.pumpWidget(wizTestApp(
      WizLayoutScope(child: Builder(builder: (context) {
        layout = context.layout;
        return const SizedBox();
      })),
      size: const Size(1280, 800),
    ));
    expect(layout.widthClass, WidthClass.expanded);
    expect(layout.gutter, 32);
  });
}
```

`test/core/layout/wiz_grid_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/layout/wiz_grid.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('columns come from the minimum tile width', () {
    expect(wizGridColumns(width: 350, minTile: 150, gap: 16), 2);
    expect(wizGridColumns(width: 280, minTile: 150, gap: 16), 1);
    expect(wizGridColumns(width: 1400, minTile: 340, gap: 14), 3);
    expect(wizGridColumns(width: 100, minTile: 150, gap: 16), 1);
  });

  testWidgets('WizGrid lays children in rows of equal width', (tester) async {
    await tester.pumpWidget(wizTestApp(
      SizedBox(
        width: 350,
        child: WizGrid(
          minTile: 150,
          gap: 16,
          children: List.generate(3, (i) => SizedBox(key: ValueKey(i), height: 40)),
        ),
      ),
    ));
    var first = tester.getRect(find.byKey(const ValueKey(0)));
    var second = tester.getRect(find.byKey(const ValueKey(1)));
    var third = tester.getRect(find.byKey(const ValueKey(2)));
    expect(first.width, closeTo(167, 0.5));
    expect(second.left, closeTo(first.right + 16, 0.5));
    expect(third.top, closeTo(first.bottom + 16, 0.5));
    expect(third.width, first.width);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/layout`
Expected: compile error.

- [ ] **Step 3: Implement breakpoints and layout scope**

`lib/core/layout/wiz_breakpoints.dart`:

```dart
/// Width classes, spec §14. Evaluated from the available width, never from
/// the platform, so a resized desktop window or a folded phone re-lays out.
enum WidthClass {
  compact,
  medium,
  expanded,
  wide;

  bool get isCompact => this == compact;

  /// Medium and above: rail instead of tab bar, dialogs instead of sheets.
  bool get isDesktopLike => this != compact;

  /// Expanded and wide: the inspector is a fixed column.
  bool get hasInspectorColumn => this == expanded || this == wide;
}

class WizBreakpoints {
  WizBreakpoints._();

  static const double compactMax = 720;
  static const double mediumMax = 1100;
  static const double wideMin = 1600;

  static WidthClass classify(double width) {
    if (width < compactMax) return WidthClass.compact;
    if (width < mediumMax) return WidthClass.medium;
    if (width < wideMin) return WidthClass.expanded;
    return WidthClass.wide;
  }
}
```

`lib/core/layout/wiz_layout.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../theme/wiz_theme.dart';
import 'wiz_breakpoints.dart';

/// The current width class and gutter, installed by [WizLayoutScope].
class WizLayout extends InheritedWidget {
  final WidthClass widthClass;
  final double width;
  final double gutter;

  const WizLayout({
    super.key,
    required this.widthClass,
    required this.width,
    required this.gutter,
    required super.child,
  });

  static WizLayout of(BuildContext context) {
    var layout = context.dependOnInheritedWidgetOfExactType<WizLayout>();
    assert(layout != null, 'No WizLayoutScope above this widget');
    return layout!;
  }

  @override
  bool updateShouldNotify(WizLayout oldWidget) =>
      widthClass != oldWidget.widthClass ||
      width != oldWidget.width ||
      gutter != oldWidget.gutter;
}

/// Measures its constraints and installs a [WizLayout] for descendants.
class WizLayoutScope extends StatelessWidget {
  final Widget child;

  const WizLayoutScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var widthClass = WizBreakpoints.classify(width);
        return WizLayout(
          widthClass: widthClass,
          width: width,
          gutter: widthClass.isCompact ? space.gutter : space.gutterDesktop,
          child: child,
        );
      },
    );
  }
}

extension WizLayoutContext on BuildContext {
  WizLayout get layout => WizLayout.of(this);
}
```

- [ ] **Step 4: Implement the grid**

`lib/core/layout/wiz_grid.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How many equal columns of at least [minTile] fit in [width] with [gap]
/// between them. Never fewer than one.
int wizGridColumns({required double width, required double minTile, required double gap}) {
  var columns = ((width + gap) / (minTile + gap)).floor();
  return math.max(1, columns);
}

/// A grid whose column count comes from a minimum tile width, so phones of
/// different widths and desktop windows of any size get a sensible layout
/// without a hard-coded column count. Plain rows and columns, so it can sit
/// inside any scrolling column.
class WizGrid extends StatelessWidget {
  final double minTile;
  final double gap;
  final List<Widget> children;

  /// Fixed tile height; when null tiles size to their content.
  final double? tileHeight;

  const WizGrid({
    super.key,
    required this.minTile,
    required this.gap,
    required this.children,
    this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = wizGridColumns(width: constraints.maxWidth, minTile: minTile, gap: gap);
        var rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          var cells = <Widget>[];
          for (var i = 0; i < columns; i++) {
            var index = start + i;
            if (i > 0) cells.add(SizedBox(width: gap));
            cells.add(
              Expanded(
                child: index < children.length
                    ? (tileHeight == null
                        ? children[index]
                        : SizedBox(height: tileHeight, child: children[index]))
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
          rows.add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      },
    );
  }
}
```

Each row sits in an `IntrinsicHeight` so `stretch` has a bounded cross axis inside a scrolling column; without it a stretched `Row` under unbounded height asserts.

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/layout && dart format lib test && flutter analyze --fatal-infos
git add lib/core/layout test/core/layout
git commit -m "feat(layout): width classes, layout scope and min-tile grid"
```

---

### Task 6: The 49-glyph icon set

**Files:**
- Create: `tool/gen_icons.py`, `lib/core/icons/wiz_icon_data.dart` (generated), `lib/core/icons/wiz_icon.dart`
- Test: `test/core/icons/wiz_icon_test.dart`

**Interfaces:**
- Produces: `class WizIconData { final String name; final String path; const WizIconData(this.name, this.path); }`; `class WizIcons { static const WizIconData arrowLeft = ...; ... static const List<WizIconData> all; static WizIconData? byName(String name); }` with one camelCase constant per glyph (`arrowLeft, arrowRight, bath, bed, check, chevronDown, chevronLeft, chevronRight, circleDot, clock, coffee, droplet, ellipsis, flame, gauge, house, housePlus, lampCeiling, lampDesk, layoutGrid, lightbulb, minus, monitor, moon, palette, pause, pencil, play, plus, power, radio, refreshCw, search, settings, slidersHorizontal, smartphone, sofa, sparkles, sun, terminal, thermometer, trash, trees, tv, utensilsCrossed, wavesHorizontal, wifi, x, zap`); `class WizIcon extends StatelessWidget { final WizIconData icon; final double size; final Color? color; }` painting the 256-grid path scaled to `size`, defaulting to `DefaultTextStyle` colour (so it inherits like `currentColor`).

- [ ] **Step 1: Write the failing test**

`test/core/icons/wiz_icon_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('all 49 glyphs are present and unique', () {
    expect(WizIcons.all, hasLength(49));
    expect(WizIcons.all.map((i) => i.name).toSet(), hasLength(49));
    expect(WizIcons.byName('lightbulb'), same(WizIcons.lightbulb));
    expect(WizIcons.byName('utensils-crossed'), same(WizIcons.utensilsCrossed));
    expect(WizIcons.lightbulb.path, startsWith('M'));
  });

  testWidgets('WizIcon sizes itself and paints', (tester) async {
    await tester.pumpWidget(wizTestApp(const WizIcon(WizIcons.power, size: 24)));
    expect(tester.getSize(find.byType(WizIcon)), const Size(24, 24));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/icons`
Expected: compile error.

- [ ] **Step 3: Generate the icon data from the design bundle**

Create `tool/gen_icons.py`:

```python
#!/usr/bin/env python3
"""Emit lib/core/icons/wiz_icon_data.dart from the ICONS map in the design bundle."""
import re, pathlib

root = pathlib.Path(__file__).resolve().parents[1]
bundle = (root / 'design/reference/_ds_bundle.js').read_text()
block = re.search(r"const ICONS = \{(.*?)\n\};", bundle, re.S).group(1)
entries = re.findall(r"'([a-z0-9-]+)': '<path d=\"([^\"]+)\"></path>'", block)
assert len(entries) == 49, len(entries)

def camel(name):
    head, *rest = name.split('-')
    return head + ''.join(p.capitalize() for p in rest)

out = ["// GENERATED by tool/gen_icons.py from design/reference/_ds_bundle.js.",
       "// Phosphor Bold glyphs (256 grid) under WizCtl names. Do not edit by hand.",
       "",
       "/// One Phosphor Bold glyph: its WizCtl name and SVG path data on a 256 grid.",
       "class WizIconData {",
       "  final String name;",
       "  final String path;",
       "  const WizIconData(this.name, this.path);",
       "}",
       "",
       "/// The 49 glyphs the design system uses.",
       "class WizIcons {",
       "  WizIcons._();",
       ""]
for name, path in entries:
    out.append(f"  static const WizIconData {camel(name)} = WizIconData('{name}', '{path}');")
out.append("")
out.append("  static const List<WizIconData> all = [")
for name, _ in entries:
    out.append(f"    {camel(name)},")
out.append("  ];")
out.append("")
out.append("  static WizIconData? byName(String name) {")
out.append("    for (var icon in all) {")
out.append("      if (icon.name == name) return icon;")
out.append("    }")
out.append("    return null;")
out.append("  }")
out.append("}")
(root / 'lib/core/icons').mkdir(parents=True, exist_ok=True)
(root / 'lib/core/icons/wiz_icon_data.dart').write_text("\n".join(out) + "\n")
print(f"wrote {len(entries)} icons")
```

Run: `python3 tool/gen_icons.py` then `dart format lib/core/icons`.

- [ ] **Step 4: Implement the icon widget**

`lib/core/icons/wiz_icon.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'wiz_icon_data.dart';

/// Paints a Phosphor Bold glyph. Filled, so scale is the only control:
/// 20–24 in rows, 26–30 in empty-state wells, 0.34 × diameter in a power key.
/// Colour defaults to the ambient text colour, like SVG `currentColor`.
class WizIcon extends StatelessWidget {
  final WizIconData icon;
  final double size;
  final Color? color;

  const WizIcon(this.icon, {super.key, required this.size, this.color});

  /// The design grid every glyph is drawn on.
  static const double grid = 256;

  static final Map<String, Path> _cache = {};

  static Path pathFor(WizIconData icon) =>
      _cache.putIfAbsent(icon.name, () => parseSvgPathData(icon.path));

  @override
  Widget build(BuildContext context) {
    var paintColor = color ?? DefaultTextStyle.of(context).style.color ?? Colors.white;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _IconPainter(pathFor(icon), paintColor)),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final Path path;
  final Color color;

  _IconPainter(this.path, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var scale = size.width / WizIcon.grid;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.path != path || old.color != color;
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/icons && dart format lib test && flutter analyze --fatal-infos
git add tool lib/core/icons test/core/icons
git commit -m "feat(icons): the 49 Phosphor Bold glyphs and WizIcon"
```

---
### Task 7: Feedback interface and scope

**Files:**
- Create: `lib/core/feedback/feedback_kind.dart`, `lib/core/feedback/feedback_service.dart`, `lib/core/feedback/feedback_scope.dart`
- Test: `test/core/feedback/feedback_scope_test.dart`

**Interfaces:**
- Produces: `enum FeedbackKind { press, release, toggleOn, toggleOff, tick, detent, power, confirm, reject }`; `abstract interface class FeedbackService { bool get enabled; Future<void> setEnabled(bool value); void play(FeedbackKind kind); }`; `class NoopFeedbackService implements FeedbackService`; `class RecordingFeedbackService implements FeedbackService { final List<FeedbackKind> played; }`; `class FeedbackScope extends InheritedWidget { final FeedbackService service; static FeedbackService of(BuildContext) }` (falls back to a shared `NoopFeedbackService` when absent); `extension FeedbackContext on BuildContext { FeedbackService get feedback; }`. Task 25 adds the real synthesized service.

- [ ] **Step 1: Write the failing test**

`test/core/feedback/feedback_scope_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_scope.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';

void main() {
  testWidgets('the scope hands out its service', (tester) async {
    var recording = RecordingFeedbackService();
    late FeedbackService found;
    await tester.pumpWidget(FeedbackScope(
      service: recording,
      child: Builder(builder: (context) {
        found = context.feedback;
        return const SizedBox();
      }),
    ));
    expect(found, same(recording));
    found.play(FeedbackKind.detent);
    expect(recording.played, [FeedbackKind.detent]);
  });

  testWidgets('without a scope, feedback is a silent no-op', (tester) async {
    late FeedbackService found;
    await tester.pumpWidget(Builder(builder: (context) {
      found = context.feedback;
      return const SizedBox();
    }));
    expect(found, isA<NoopFeedbackService>());
    found.play(FeedbackKind.power);
  });

  test('a disabled recorder records nothing', () async {
    var recording = RecordingFeedbackService();
    await recording.setEnabled(false);
    recording.play(FeedbackKind.press);
    expect(recording.played, isEmpty);
    expect(recording.enabled, isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/feedback`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/feedback/feedback_kind.dart`:

```dart
/// The nine tactile events, mapped to the hardware metaphor (spec §13).
enum FeedbackKind {
  /// Any labelled or icon key going down.
  press,

  /// A key coming back up: quieter, brighter.
  release,

  /// A switch closing.
  toggleOn,

  /// A switch opening.
  toggleOff,

  /// Moving between tabs, segments or rail items.
  tick,

  /// A dial, rail or wheel crossing a notch: the smallest sound.
  detent,

  /// The power key engaging a light: the heaviest.
  power,

  /// Save or apply succeeded.
  confirm,

  /// Something failed, is unreachable, or a disabled key was pressed.
  reject,
}
```

`lib/core/feedback/feedback_service.dart`:

```dart
import 'feedback_kind.dart';

/// Sound plus haptics for every control. Safe to call on every pointer down.
abstract interface class FeedbackService {
  bool get enabled;
  Future<void> setEnabled(bool value);
  void play(FeedbackKind kind);
}

/// Does nothing. Used before the audio engine is ready and in widget tests
/// that do not care about feedback.
class NoopFeedbackService implements FeedbackService {
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async => _enabled = value;

  @override
  void play(FeedbackKind kind) {}
}

/// Records what was played, for tests.
class RecordingFeedbackService implements FeedbackService {
  final List<FeedbackKind> played = [];
  bool _enabled = true;

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async => _enabled = value;

  @override
  void play(FeedbackKind kind) {
    if (_enabled) played.add(kind);
  }
}
```

`lib/core/feedback/feedback_scope.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'feedback_service.dart';

/// Makes a [FeedbackService] available to every control below it.
class FeedbackScope extends InheritedWidget {
  final FeedbackService service;

  const FeedbackScope({super.key, required this.service, required super.child});

  static final FeedbackService _silent = NoopFeedbackService();

  static FeedbackService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FeedbackScope>()?.service ?? _silent;

  @override
  bool updateShouldNotify(FeedbackScope oldWidget) => service != oldWidget.service;
}

extension FeedbackContext on BuildContext {
  FeedbackService get feedback => FeedbackScope.of(this);
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/feedback && dart format lib test && flutter analyze --fatal-infos
git add lib/core/feedback test/core/feedback
git commit -m "feat(feedback): feedback kinds, service interface and scope"
```

---

### Task 8: Bundle the fonts

**Files:**
- Create: `assets/fonts/NeumaticCompressed-{Light,Regular,Medium,SemiBold,Bold,ExtraBold,Black}.otf`, `assets/fonts/HankenGrotesk-{Regular,SemiBold,Bold}.ttf`, `assets/fonts/JetBrainsMono-{Regular,Medium,Bold}.ttf`, `assets/fonts/OFL-HankenGrotesk.txt`, `assets/fonts/OFL-JetBrainsMono.txt`
- Modify: `pubspec.yaml` (`flutter: fonts:`)
- Test: `test/assets/fonts_test.dart`

**Interfaces:**
- Produces: the three font families declared under the names `WizType.familyDisplay`, `familyUi`, `familyMono` with the weights the type tokens use.

- [ ] **Step 1: Write the failing test**

`test/assets/fonts_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const files = [
    'NeumaticCompressed-Light.otf',
    'NeumaticCompressed-Regular.otf',
    'NeumaticCompressed-Medium.otf',
    'NeumaticCompressed-SemiBold.otf',
    'NeumaticCompressed-Bold.otf',
    'NeumaticCompressed-ExtraBold.otf',
    'NeumaticCompressed-Black.otf',
    'HankenGrotesk-Regular.ttf',
    'HankenGrotesk-SemiBold.ttf',
    'HankenGrotesk-Bold.ttf',
    'JetBrainsMono-Regular.ttf',
    'JetBrainsMono-Medium.ttf',
    'JetBrainsMono-Bold.ttf',
  ];

  test('every font file is bundled and declared', () {
    var pubspec = File('pubspec.yaml').readAsStringSync();
    for (var file in files) {
      var f = File('assets/fonts/$file');
      expect(f.existsSync(), isTrue, reason: '$file missing');
      expect(f.lengthSync(), greaterThan(10 * 1024), reason: '$file too small');
      expect(pubspec, contains('assets/fonts/$file'), reason: '$file not declared');
    }
    for (var family in ['NeumaticCompressed', 'HankenGrotesk', 'JetBrainsMono']) {
      expect(pubspec, contains('family: $family'));
    }
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/assets`
Expected: FAIL, files missing.

- [ ] **Step 3: Fetch the Neumatic OTFs from the design project**

Dispatch a subagent with this instruction (its context absorbs the base64; the main session's does not):

> Using the `DesignSync` tool with `method: get_file` and `projectId: 9e13200d-ef9c-452f-8e84-0b76ccab6bc2`, fetch each of these seven paths: `_ds/wizctl-design-system-2a6b25ea-1d34-4ebe-9a5a-0369560afd23/assets/fonts/NeumaticCompressed-Light.otf`, `...-Regular.otf`, `...-Medium.otf`, `...-SemiBold.otf`, `...-Bold.otf`, `...-ExtraBold.otf`, `...-Black.otf`. Each result is JSON with `isBase64: true` and `content`. Decode the base64 and write the bytes to `/Users/bharat/Bharat/github/wizctl_app/assets/fonts/<same file name>`. Verify each file starts with the bytes `OTTO` and is larger than 10 KB. Report the seven file sizes.

If `DesignSync` is unavailable to the subagent, stop and ask the user to copy the seven OTF files into `assets/fonts/` before continuing.

- [ ] **Step 4: Fetch Hanken Grotesk and JetBrains Mono**

```bash
cd /Users/bharat/Bharat/github/wizctl_app
mkdir -p /tmp/wizfonts && cd /tmp/wizfonts
curl -L -o hanken.zip 'https://fonts.google.com/download?family=Hanken%20Grotesk'
curl -L -o jbm.zip 'https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip'
unzip -o -q hanken.zip -d hanken && unzip -o -q jbm.zip -d jbm
find hanken -iname 'HankenGrotesk-Regular.ttf' -o -iname 'HankenGrotesk-SemiBold.ttf' -o -iname 'HankenGrotesk-Bold.ttf' | head
find jbm -path '*fonts/ttf/JetBrainsMono-Regular.ttf' -o -path '*fonts/ttf/JetBrainsMono-Medium.ttf' -o -path '*fonts/ttf/JetBrainsMono-Bold.ttf'
```

Copy the six static files into `assets/fonts/` with exactly the names the test expects, and the OFL licence files as `OFL-HankenGrotesk.txt` and `OFL-JetBrainsMono.txt`. If the Google Fonts zip has no `static/` files (only `HankenGrotesk[wght].ttf`), download the static instances from `https://github.com/marcologous/hanken-grotesk/tree/master/fonts/ttf` instead (raw URLs of the form `https://raw.githubusercontent.com/marcologous/hanken-grotesk/master/fonts/ttf/HankenGrotesk-Regular.ttf`).

- [ ] **Step 5: Declare the fonts**

Add to `pubspec.yaml` under `flutter:`:

```yaml
  fonts:
    - family: NeumaticCompressed
      fonts:
        - asset: assets/fonts/NeumaticCompressed-Light.otf
          weight: 300
        - asset: assets/fonts/NeumaticCompressed-Regular.otf
          weight: 400
        - asset: assets/fonts/NeumaticCompressed-Medium.otf
          weight: 500
        - asset: assets/fonts/NeumaticCompressed-SemiBold.otf
          weight: 600
        - asset: assets/fonts/NeumaticCompressed-Bold.otf
          weight: 700
        - asset: assets/fonts/NeumaticCompressed-ExtraBold.otf
          weight: 800
        - asset: assets/fonts/NeumaticCompressed-Black.otf
          weight: 900
    - family: HankenGrotesk
      fonts:
        - asset: assets/fonts/HankenGrotesk-Regular.ttf
          weight: 400
        - asset: assets/fonts/HankenGrotesk-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/HankenGrotesk-Bold.ttf
          weight: 700
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
```

- [ ] **Step 6: Run, commit**

```bash
flutter pub get && flutter test test/assets && flutter analyze --fatal-infos
git add assets pubspec.yaml test/assets
git commit -m "feat(theme): bundle Neumatic Compressed, Hanken Grotesk and JetBrains Mono"
```

---

### Task 9: Textures, WizSurface and WizPanel

**Files:**
- Create: `lib/core/theme/wiz_textures.dart`, `lib/core/widgets/wiz_surface.dart`, `lib/core/widgets/wiz_grain.dart`, `lib/core/widgets/wiz_panel.dart`, `lib/core/widgets/wiz_app_background.dart`
- Test: `test/core/widgets/wiz_surface_test.dart`

**Interfaces:**
- Produces: `class WizTextures { static Future<void> load({double devicePixelRatio = 1}); static bool get hasGrain; static Paint? grainPaint({double opacity = 1}); static Paint knurlPaint(WizElevation e); }`; `class WizGrain extends StatelessWidget { opacity }` (a `Positioned.fill`-able overlay); `void paintInsets(Canvas canvas, RRect rrect, List<WizInset> insets)` (public helper); `class WizSurface extends StatelessWidget { spec, radius, gradient, color, grain, grainOpacity, glow, child, padding, width, height, alignment, clipChild }`; `enum WizPanelVariant { raised, inset, flat }`; `class WizPanel extends StatelessWidget { variant, radius, padding, grain, glow, child }`; `class WizGlow extends StatelessWidget { on, shadows, radius }` (an animated outer glow layer, 420 ms); `class WizAppBackground extends StatelessWidget { child }` (surface app + vignette + grain). Also gradient helpers in `wiz_textures.dart`: `LinearGradient wizVertical(Color top, Color bottom)`.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_surface_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';
import 'package:wizctl_app/core/widgets/wiz_panel.dart';
import 'package:wizctl_app/core/widgets/wiz_surface.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('WizSurface paints outer shadows and sizes to its child', (tester) async {
    await tester.pumpWidget(wizTestApp(Builder(builder: (context) {
      var wiz = context.wiz;
      return WizSurface(
        spec: wiz.elevation.raised,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: LinearGradient(colors: [wiz.colors.surfaceKey, wiz.colors.surfaceRaised]),
        child: const SizedBox(width: 120, height: 40),
      );
    })));
    expect(tester.getSize(find.byType(WizSurface)), const Size(120, 40));
    var box = tester.widget<DecoratedBox>(find.descendant(
      of: find.byType(WizSurface), matching: find.byType(DecoratedBox)).first);
    var decoration = box.decoration as BoxDecoration;
    expect(decoration.boxShadow, hasLength(2));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('WizPanel inset variant uses the well recipe and default padding', (tester) async {
    await tester.pumpWidget(wizTestApp(const WizPanel(
      variant: WizPanelVariant.inset,
      child: SizedBox(width: 50, height: 20),
    )));
    expect(tester.getSize(find.byType(WizPanel)), const Size(50 + 32, 20 + 32));
  });

  testWidgets('WizPanel glow fades with the on flag', (tester) async {
    await tester.pumpWidget(wizTestApp(const WizPanel(glow: true, child: SizedBox(width: 10, height: 10))));
    expect(find.byType(WizGlow), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_surface_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement textures**

`lib/core/theme/wiz_textures.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'wiz_elevation.dart';

/// Vertical top-to-bottom gradient, the kit's default surface fill.
LinearGradient wizVertical(Color top, Color bottom) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [top, bottom],
);

/// The three textures, spec §11.1: grain (a 0.5 px dot every 3 px so
/// charcoal reads as machined metal), knurl (vertical stripes on grips and
/// knob rims) and the vignette painted by [WizAppBackground].
class WizTextures {
  WizTextures._();

  static ui.Image? _grain;
  static double _grainScale = 1;

  static bool get hasGrain => _grain != null;

  /// Renders the grain tile once at the device pixel ratio so the dot stays
  /// crisp. Call from bootstrap; widgets paint no grain until it is ready.
  static Future<void> load({double devicePixelRatio = 1}) async {
    if (_grain != null) return;
    const e = WizElevation.standard;
    var px = (e.grainTile * devicePixelRatio).round();
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio);
    canvas.drawCircle(
      Offset(e.grainTile / 2, e.grainTile / 2),
      e.grainDot,
      Paint()..color = Colors.white.withValues(alpha: e.grainAlpha),
    );
    _grain = await recorder.endRecording().toImage(px, px);
    _grainScale = 1 / devicePixelRatio;
  }

  static Paint? grainPaint({double opacity = 1}) {
    var image = _grain;
    if (image == null) return null;
    var matrix = Matrix4.diagonal3Values(_grainScale, _grainScale, 1);
    return Paint()
      ..shader = ImageShader(image, TileMode.repeated, TileMode.repeated, matrix.storage)
      ..color = Colors.white.withValues(alpha: opacity);
  }

  /// Repeating 1 px light, 2 px dark stripes.
  static Paint knurlPaint(WizElevation e, {Offset origin = Offset.zero}) {
    var hi = Colors.white.withValues(alpha: e.knurlHiAlpha);
    var lo = Colors.black.withValues(alpha: e.knurlLoAlpha);
    return Paint()
      ..shader = ui.Gradient.linear(
        origin,
        origin + Offset(e.grainTile, 0),
        [hi, hi, lo, lo],
        [0, 1 / 3, 1 / 3, 1],
        TileMode.repeated,
      );
  }
}
```

- [ ] **Step 4: Implement the grain overlay and the surface**

`lib/core/widgets/wiz_grain.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../theme/wiz_textures.dart';

/// Paints the machined grain over whatever it is stacked on. Ignores pointers.
class WizGrain extends StatelessWidget {
  final double opacity;

  const WizGrain({super.key, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GrainPainter(opacity)));
  }
}

class _GrainPainter extends CustomPainter {
  final double opacity;

  _GrainPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = WizTextures.grainPaint(opacity: opacity);
    if (paint == null) return;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.opacity != opacity;
}
```

`lib/core/widgets/wiz_surface.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_elevation.dart';
import '../theme/wiz_theme.dart';
import 'wiz_grain.dart';

/// Paints CSS-style inset shadows inside [rrect]: the shadow cast by the
/// area outside the shape, shifted by the inset's offset, blurred, clipped
/// to the shape. A blur of zero with a 1 px offset is the hard highlight or
/// groove line every raised or recessed part carries.
void paintInsets(Canvas canvas, RRect rrect, List<WizInset> insets) {
  if (insets.isEmpty) return;
  var outer = rrect.outerRect.inflate(64);
  canvas.save();
  canvas.clipRRect(rrect);
  for (var inset in insets) {
    var hole = Path()..addRRect(rrect.shift(Offset(0, inset.offsetY)));
    var shadow = Path.combine(
      PathOperation.difference,
      Path()..addRect(outer),
      hole,
    );
    var paint = Paint()..color = inset.color;
    if (inset.blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, inset.blur / 2);
    }
    canvas.drawPath(shadow, paint);
  }
  canvas.restore();
}

/// A chassis surface: fill, outer cast shadows, inner highlight and groove,
/// optional grain and optional emission glow. Every panel, key, well and
/// knob in the kit is a [WizSurface] with a different [spec].
class WizSurface extends StatelessWidget {
  final WizShadowSpec spec;
  final BorderRadius radius;
  final Gradient? gradient;
  final Color? color;
  final bool grain;
  final double grainOpacity;
  final List<BoxShadow> glow;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const WizSurface({
    super.key,
    required this.spec,
    required this.radius,
    this.gradient,
    this.color,
    this.grain = false,
    this.grainOpacity = 1,
    this.glow = const [],
    this.child,
    this.padding,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (alignment != null) content = Align(alignment: alignment!, child: content);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color : null,
        borderRadius: radius,
        boxShadow: [...spec.outer, ...glow],
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: radius,
          child: CustomPaint(
            foregroundPainter: _InsetPainter(spec.insets, radius),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                if (grain) Positioned.fill(child: WizGrain(opacity: grainOpacity)),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsetPainter extends CustomPainter {
  final List<WizInset> insets;
  final BorderRadius radius;

  _InsetPainter(this.insets, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    paintInsets(canvas, radius.toRRect(Offset.zero & size), insets);
  }

  @override
  bool shouldRepaint(_InsetPainter old) => old.insets != insets || old.radius != radius;
}

/// An outer emission glow that fades in and out over the light duration.
/// Stack it behind a surface of the same shape.
class WizGlow extends StatelessWidget {
  final bool on;
  final List<BoxShadow> shadows;
  final BorderRadius radius;

  const WizGlow({super.key, required this.on, required this.shadows, required this.radius});

  @override
  Widget build(BuildContext context) {
    var motion = context.wiz.motion;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: motion.light,
        curve: motion.tactile,
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement WizPanel and the app background**

`lib/core/widgets/wiz_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

enum WizPanelVariant {
  /// A card sitting on the app surface.
  raised,

  /// A well that holds controls.
  inset,

  /// Hairline only; for device fact panels.
  flat,
}

/// The chassis panel. Raised for cards, inset for wells, flat for facts.
/// Radius 20, padding 16, grain on. Gains the amber emission ring when the
/// light it represents is on.
class WizPanel extends StatelessWidget {
  final WizPanelVariant variant;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final bool grain;
  final bool glow;
  final Widget child;

  const WizPanel({
    super.key,
    this.variant = WizPanelVariant.raised,
    this.radius,
    this.padding,
    this.grain = true,
    this.glow = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var border = BorderRadius.circular(radius ?? wiz.space.r4);
    var (spec, gradient) = switch (variant) {
      WizPanelVariant.raised => (wiz.elevation.panel, wizVertical(c.surfaceRaised, c.surfacePanel)),
      WizPanelVariant.inset => (wiz.elevation.well, wizVertical(c.char900, c.char950)),
      WizPanelVariant.flat => (wiz.elevation.flat, wizVertical(c.surfaceRaised, c.surfacePanel)),
    };
    var surface = WizSurface(
      spec: spec,
      radius: border,
      gradient: gradient,
      grain: grain,
      padding: padding ?? EdgeInsets.all(wiz.space.panelPad),
      child: child,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: WizGlow(on: glow, shadows: wiz.elevation.glowAmber, radius: border)),
        surface,
      ],
    );
  }
}
```

`lib/core/widgets/wiz_app_background.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_grain.dart';

/// The screen background: app surface, a soft top vignette as if room light
/// falls from above, and the grain. Equivalent to the design system's `.wz-app`.
class WizAppBackground extends StatelessWidget {
  final Widget child;

  const WizAppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return ColoredBox(
      color: wiz.colors.surfaceApp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _VignettePainter(wiz.elevation.vignetteAlpha)),
          const WizGrain(),
          child,
        ],
      ),
    );
  }
}

/// `radial-gradient(115% 85% at 50% -8%, white .055, transparent 58%)`.
class _VignettePainter extends CustomPainter {
  final double alpha;

  _VignettePainter(this.alpha);

  static const double _rx = 1.15, _ry = 0.85, _cy = -0.08, _end = 0.58;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height * _cy);
    canvas.scale(size.width * _rx, size.height * _ry);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: alpha), Colors.white.withValues(alpha: 0)],
          stops: const [0, _end],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.alpha != alpha;
}
```

- [ ] **Step 6: Run, format, analyze, commit**

```bash
flutter test test/core/widgets && dart format lib test && flutter analyze --fatal-infos
git add lib/core/theme/wiz_textures.dart lib/core/widgets test/core/widgets
git commit -m "feat(kit): textures, inset shadows, WizSurface, WizPanel, app background"
```

---

### Task 10: WizPressable, WizButton, WizIconKey, WizChip, WizTextField

**Files:**
- Create: `lib/core/widgets/wiz_pressable.dart`, `lib/core/widgets/wiz_button.dart`, `lib/core/widgets/wiz_icon_key.dart`, `lib/core/widgets/wiz_chip.dart`, `lib/core/widgets/wiz_text_field.dart`
- Test: `test/core/widgets/wiz_pressable_test.dart`, `test/core/widgets/wiz_button_test.dart`

**Interfaces:**
- Produces: `class WizPressState { bool pressed, hovered, focused; }`; `typedef WizPressBuilder = Widget Function(BuildContext, WizPressState)`; `class WizPressable extends StatefulWidget { builder, onTap, onLongPress, feedback (FeedbackKind, default press), scale (double?, default motion.pressScale), travel (double?, default motion.pressTravel), enabled, semanticsLabel, hover (bool, default true), cursor, hitPadding (EdgeInsets?) }`; `enum WizButtonVariant { primary, secondary, ghost, danger }`; `enum WizButtonSize { sm, md, lg }`; `class WizButton { label, variant, size, icon (WizIconData?), iconAfter, fullWidth, enabled, onPressed }`; `enum WizKeySize { sm, md, lg }`; `enum WizKeyShape { circle, squircle }`; `class WizIconKey { icon, size, shape, active, enabled, onPressed, semanticsLabel }`; `class WizChip { label, selected, onTap, icon, height (default controlSm 36), enabled }`; `class WizTextField { controller, placeholder, height (default controlMd 48), autofocus, onChanged, onSubmitted, textInputAction, enabled, style (TextStyle?) }`.

- [ ] **Step 1: Write the failing tests**

`test/core/widgets/wiz_pressable_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_pressable.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a press sinks the child, fires feedback and taps', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    late WizPressState seen;
    await tester.pumpWidget(wizTestApp(
      WizPressable(
        feedback: FeedbackKind.tick,
        onTap: () => taps++,
        builder: (context, state) {
          seen = state;
          return const SizedBox(width: 60, height: 44, key: Key('k'));
        },
      ),
      feedback: feedback,
    ));
    var before = tester.getTopLeft(find.byKey(const Key('k')));
    var gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('k'))));
    await tester.pump(const Duration(milliseconds: 80));
    expect(seen.pressed, isTrue);
    expect(feedback.played, [FeedbackKind.tick]);
    var during = tester.getTopLeft(find.byKey(const Key('k')));
    expect(during.dy, greaterThan(before.dy));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(seen.pressed, isFalse);
    expect(taps, 1);
  });

  testWidgets('disabled pressables neither sink nor tap', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(wizTestApp(
      WizPressable(
        enabled: false,
        onTap: () => taps++,
        builder: (_, __) => const SizedBox(width: 60, height: 44),
      ),
      feedback: feedback,
    ));
    await tester.tap(find.byType(WizPressable));
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(feedback.played, isEmpty);
  });

  testWidgets('keyboard activation taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wizTestApp(
      WizPressable(
        onTap: () => taps++,
        semanticsLabel: 'Go',
        builder: (_, __) => const SizedBox(width: 60, height: 44),
      ),
    ));
    await tester.tap(find.byType(WizPressable));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
```

`test/core/widgets/wiz_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/wiz_button.dart';
import 'package:wizctl_app/core/widgets/wiz_chip.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('buttons take their height from the size and uppercase the label', (tester) async {
    await tester.pumpWidget(wizTestApp(Column(mainAxisSize: MainAxisSize.min, children: [
      WizButton(label: 'Create home', onPressed: () {}, size: WizButtonSize.sm),
      WizButton(label: 'Create home', onPressed: () {}),
      WizButton(label: 'Create home', onPressed: () {}, size: WizButtonSize.lg),
    ])));
    var heights = tester.widgetList(find.byType(WizButton)).map((w) => tester.getSize(find.byWidget(w)).height).toList();
    expect(heights, [36, 48, 56]);
    expect(find.text('CREATE HOME'), findsNWidgets(3));
  });

  testWidgets('primary fires confirm, danger fires reject, ghost fires press', (tester) async {
    var feedback = RecordingFeedbackService();
    await tester.pumpWidget(wizTestApp(Column(mainAxisSize: MainAxisSize.min, children: [
      WizButton(label: 'A', variant: WizButtonVariant.primary, onPressed: () {}),
      WizButton(label: 'B', variant: WizButtonVariant.danger, onPressed: () {}),
      WizButton(label: 'C', variant: WizButtonVariant.ghost, onPressed: () {}),
    ]), feedback: feedback));
    await tester.tap(find.text('A'));
    await tester.tap(find.text('B'));
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(feedback.played, [FeedbackKind.confirm, FeedbackKind.reject, FeedbackKind.press]);
  });

  testWidgets('a full-width button fills its parent', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 300,
      child: WizButton(label: 'Go', fullWidth: true, onPressed: () {}),
    )));
    expect(tester.getSize(find.byType(WizButton)).width, 300);
  });

  testWidgets('icon keys are square and chips are pills', (tester) async {
    await tester.pumpWidget(wizTestApp(Row(mainAxisSize: MainAxisSize.min, children: [
      WizIconKey(icon: WizIcons.house, onPressed: () {}, semanticsLabel: 'Homes'),
      WizChip(label: 'Living Room', selected: true, onTap: () {}),
    ])));
    expect(tester.getSize(find.byType(WizIconKey)), const Size(44, 44));
    expect(tester.getSize(find.byType(WizChip)).height, 36);
    expect(find.bySemanticsLabel('Homes'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/widgets`
Expected: compile errors.

- [ ] **Step 3: Implement WizPressable**

`lib/core/widgets/wiz_pressable.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_theme.dart';

/// What the builder can react to.
@immutable
class WizPressState {
  final bool pressed;
  final bool hovered;
  final bool focused;

  const WizPressState({this.pressed = false, this.hovered = false, this.focused = false});
}

typedef WizPressBuilder = Widget Function(BuildContext context, WizPressState state);

/// The one press recipe for every clickable thing: on pointer down the part
/// sinks [travel] and scales to [scale] in 80 ms and fires [feedback]; on
/// release it springs back on the settle curve in 140 ms. Hover brightens
/// raised parts on desktop; focus draws the amber ring. Selection itself
/// never animates, the press does.
class WizPressable extends StatefulWidget {
  final WizPressBuilder builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FeedbackKind feedback;
  final double? scale;
  final double? travel;
  final bool enabled;
  final String? semanticsLabel;
  final bool hover;
  final MouseCursor? cursor;

  /// Extra transparent hit area around the visual, for controls drawn
  /// smaller than the 44 minimum.
  final EdgeInsets? hitPadding;

  const WizPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.feedback = FeedbackKind.press,
    this.scale,
    this.travel,
    this.enabled = true,
    this.semanticsLabel,
    this.hover = true,
    this.cursor,
    this.hitPadding,
  });

  @override
  State<WizPressable> createState() => _WizPressableState();
}

class _WizPressableState extends State<WizPressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  /// CSS `filter: brightness(1.08)` as a colour matrix.
  static List<double> _brightness(double b) => [
    b, 0, 0, 0, 0,
    0, b, 0, 0, 0,
    0, 0, b, 0, 0,
    0, 0, 0, 1, 0,
  ];

  void _down() {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    context.feedback.play(widget.feedback);
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  void _activate() {
    if (!widget.enabled) return;
    context.feedback.play(widget.feedback);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    var motion = context.wiz.motion;
    var colors = context.wiz.colors;
    var scale = widget.scale ?? motion.pressScale;
    var travel = widget.travel ?? motion.pressTravel;
    var state = WizPressState(pressed: _pressed, hovered: _hovered, focused: _focused);

    Widget visual = widget.builder(context, state);
    if (widget.hover && _hovered && !_pressed && widget.enabled) {
      visual = ColorFiltered(
        colorFilter: ColorFilter.matrix(_brightness(motion.hoverBrightness)),
        child: visual,
      );
    }
    if (_focused) {
      visual = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.wiz.space.r3),
          border: Border.all(color: colors.focusRing, width: 2),
        ),
        child: visual,
      );
    }
    visual = TweenAnimationBuilder<double>(
      tween: Tween(end: _pressed ? 1 : 0),
      duration: _pressed ? motion.press : motion.release,
      curve: _pressed ? motion.pressCurve : motion.settle,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, travel * t),
        child: Transform.scale(scale: 1 - (1 - scale) * t, child: child),
      ),
      child: visual,
    );
    if (!widget.enabled) visual = Opacity(opacity: 0.42, child: visual);
    if (widget.hitPadding != null) {
      visual = Padding(padding: widget.hitPadding!, child: visual);
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      onTap: widget.enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.cursor ??
            (widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _activate();
            return null;
          }),
        },
        child: Listener(
          onPointerDown: (_) => _down(),
          onPointerUp: (_) => _up(),
          onPointerCancel: (_) => _up(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? widget.onTap : null,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            child: visual,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement WizButton and WizIconKey**

`lib/core/widgets/wiz_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizButtonVariant { primary, secondary, ghost, danger }

enum WizButtonSize { sm, md, lg }

/// Tactile key. Label is uppercase with wide tracking; the press sinks it
/// into the chassis. Every variant carries a raised cap, including ghost, so
/// siblings read as the same size.
class WizButton extends StatelessWidget {
  final String label;
  final WizButtonVariant variant;
  final WizButtonSize size;
  final WizIconData? icon;
  final WizIconData? iconAfter;
  final bool fullWidth;
  final bool enabled;
  final VoidCallback? onPressed;

  const WizButton({
    super.key,
    required this.label,
    this.variant = WizButtonVariant.secondary,
    this.size = WizButtonSize.md,
    this.icon,
    this.iconAfter,
    this.fullWidth = false,
    this.enabled = true,
    this.onPressed,
  });

  // Design system Button.jsx BUTTON_SIZES: height / horizontal padding /
  // font size / gap / radius / icon.
  static const _sizes = {
    WizButtonSize.sm: (px: 14.0, fs: 12.0, gap: 6.0, icon: 14.0),
    WizButtonSize.md: (px: 20.0, fs: 13.5, gap: 8.0, icon: 16.0),
    WizButtonSize.lg: (px: 26.0, fs: 15.0, gap: 10.0, icon: 18.0),
  };

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var s = _sizes[size]!;
    var height = switch (size) {
      WizButtonSize.sm => wiz.space.controlSm,
      WizButtonSize.md => wiz.space.controlMd,
      WizButtonSize.lg => wiz.space.controlLg,
    };
    var radius = BorderRadius.circular(switch (size) {
      WizButtonSize.sm => wiz.space.r2,
      WizButtonSize.md => wiz.space.r3,
      WizButtonSize.lg => wiz.space.r4,
    });
    var (gradient, ink, spec, feedback) = switch (variant) {
      WizButtonVariant.primary => (
          wizVertical(c.amber400, c.amber600), c.textOnAccent, wiz.elevation.key, FeedbackKind.confirm),
      WizButtonVariant.secondary => (
          wizVertical(c.surfaceKey, c.surfaceRaised), c.textPrimary, wiz.elevation.raised, FeedbackKind.press),
      WizButtonVariant.ghost => (
          wizVertical(c.char800, c.char850), c.textSecondary, wiz.elevation.raised, FeedbackKind.press),
      WizButtonVariant.danger => (
          wizVertical(c.dangerKeyTop, c.dangerKeyBottom), c.dangerKeyInk, wiz.elevation.raised, FeedbackKind.reject),
    };
    var textStyle = wiz.type.body.copyWith(
      fontSize: s.fs,
      fontWeight: FontWeight.w700,
      letterSpacing: s.fs * WizTypeTracking.label,
      color: ink,
      height: 1,
    );

    return WizPressable(
      onTap: onPressed,
      enabled: enabled && onPressed != null,
      feedback: feedback,
      scale: wiz.motion.keyScale,
      semanticsLabel: label,
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : spec,
        radius: radius,
        gradient: gradient,
        height: height,
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: s.px),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              WizIcon(icon!, size: s.icon, color: ink),
              SizedBox(width: s.gap),
            ],
            Text(label.toUpperCase(), style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (iconAfter != null) ...[
              SizedBox(width: s.gap),
              WizIcon(iconAfter!, size: s.icon, color: ink),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tracking multipliers shared by labels (em units from typography.css).
class WizTypeTracking {
  WizTypeTracking._();
  static const double label = 0.10;
  static const double segment = 0.08;
  static const double sceneLabel = 0.02;
}
```

`lib/core/widgets/wiz_icon_key.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizKeySize { sm, md, lg }

enum WizKeyShape { circle, squircle }

/// Round or squircle icon key: the default control for anything without a
/// text label. Active keys are amber.
class WizIconKey extends StatelessWidget {
  final WizIconData icon;
  final WizKeySize size;
  final WizKeyShape shape;
  final bool active;
  final bool enabled;
  final VoidCallback? onPressed;
  final String semanticsLabel;

  const WizIconKey({
    super.key,
    required this.icon,
    this.size = WizKeySize.md,
    this.shape = WizKeyShape.circle,
    this.active = false,
    this.enabled = true,
    this.onPressed,
    required this.semanticsLabel,
  });

  // Design system IconButton.jsx: diameter and glyph size per size.
  static const _diameter = {WizKeySize.sm: 36.0, WizKeySize.md: 44.0, WizKeySize.lg: 56.0};
  static const _glyph = {WizKeySize.sm: 16.0, WizKeySize.md: 20.0, WizKeySize.lg: 24.0};

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var d = _diameter[size]!;
    var radius = BorderRadius.circular(shape == WizKeyShape.circle ? d / 2 : wiz.space.r3);
    return WizPressable(
      onTap: onPressed,
      enabled: enabled && onPressed != null,
      scale: wiz.motion.smallKeyScale,
      semanticsLabel: semanticsLabel,
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: radius,
        gradient: active ? wizVertical(c.amber400, c.amber600) : wizVertical(c.surfaceKey, c.surfaceRaised),
        width: d,
        height: d,
        alignment: Alignment.center,
        child: WizIcon(icon, size: _glyph[size]!, color: active ? c.textOnAccent : c.textSecondary),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement WizChip and WizTextField**

`lib/core/widgets/wiz_chip.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

/// Pill chip for room and option picking. Amber when selected.
class WizChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final WizIconData? icon;
  final double? height;
  final bool enabled;

  /// Amber text on a charcoal cap, for "New room" style actions.
  final bool accentText;

  const WizChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.height,
    this.enabled = true,
    this.accentText = false,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var h = height ?? wiz.space.controlSm;
    var ink = selected ? c.textOnAccent : (accentText ? c.amber400 : c.textSecondary);
    return WizPressable(
      onTap: onTap,
      enabled: enabled && onTap != null,
      feedback: FeedbackKind.tick,
      scale: wiz.motion.keyScale,
      semanticsLabel: label,
      hitPadding: EdgeInsets.symmetric(vertical: (wiz.space.hitMin - h).clamp(0, wiz.space.hitMin) / 2),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: BorderRadius.circular(wiz.space.pill),
        gradient: selected ? wizVertical(c.amber400, c.amber600) : wizVertical(c.surfaceKey, c.surfaceRaised),
        height: h,
        padding: EdgeInsets.symmetric(horizontal: wiz.space.s3 + wiz.space.s4),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              WizIcon(icon!, size: wiz.type.body.fontSize!, color: ink),
              SizedBox(width: wiz.space.s3),
            ],
            Text(label, style: wiz.type.bodySm.copyWith(fontWeight: FontWeight.w600, color: ink, height: 1)),
          ],
        ),
      ),
    );
  }
}
```

`lib/core/widgets/wiz_text_field.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// A recessed well the user types into. No border; the well shadow is the
/// edge. Focus draws the amber ring.
class WizTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final double? height;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final TextStyle? style;

  const WizTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.height,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.style,
  });

  @override
  State<WizTextField> createState() => _WizTextFieldState();
}

class _WizTextFieldState extends State<WizTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var style = widget.style ?? wiz.type.bodyLg.copyWith(color: c.textPrimary);
    return WizSurface(
      spec: wiz.elevation.well,
      radius: BorderRadius.circular(wiz.space.r3),
      color: c.char1000,
      height: widget.height ?? wiz.space.controlMd,
      glow: _focus.hasFocus
          ? [BoxShadow(color: c.focusRing, spreadRadius: 2)]
          : const [],
      padding: EdgeInsets.symmetric(horizontal: wiz.space.s6),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: widget.textInputAction,
        style: style,
        cursorColor: c.amber400,
        scrollPadding: EdgeInsets.all(wiz.space.s12),
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: style.copyWith(color: c.textTertiary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run, format, analyze, commit**

```bash
flutter test test/core/widgets && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets test/core/widgets
git commit -m "feat(kit): the press recipe, buttons, icon keys, chips and text fields"
```

---

### Task 11: WizToggle

**Files:**
- Create: `lib/core/widgets/wiz_toggle.dart`
- Test: `test/core/widgets/wiz_toggle_test.dart`

**Interfaces:**
- Produces: `enum WizToggleSize { sm, md }`; `class WizToggle extends StatefulWidget { value, onChanged (ValueChanged<bool>?), size, enabled, semanticsLabel }`. Tap toggles; horizontal drag or flick toggles; fires `toggleOn`/`toggleOff` on commit.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_toggle_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('sizes match the rocker geometry', (tester) async {
    await tester.pumpWidget(wizTestApp(Column(mainAxisSize: MainAxisSize.min, children: [
      WizToggle(value: false, onChanged: (_) {}, size: WizToggleSize.sm, semanticsLabel: 'a'),
      WizToggle(value: false, onChanged: (_) {}, semanticsLabel: 'b'),
    ])));
    var sizes = tester.widgetList(find.byType(WizToggle)).map((w) => tester.getSize(find.byWidget(w))).toList();
    expect(sizes[0], const Size(46, 27));
    expect(sizes[1], const Size(60, 33));
  });

  testWidgets('tap toggles and plays toggleOn then toggleOff', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = false;
    await tester.pumpWidget(wizTestApp(StatefulBuilder(builder: (context, setState) {
      return WizToggle(value: value, onChanged: (v) => setState(() => value = v), semanticsLabel: 'Power');
    }), feedback: feedback));
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(feedback.played, [FeedbackKind.toggleOn, FeedbackKind.toggleOff]);
  });

  testWidgets('a flick to the right turns it on', (tester) async {
    var value = false;
    await tester.pumpWidget(wizTestApp(StatefulBuilder(builder: (context, setState) {
      return WizToggle(value: value, onChanged: (v) => setState(() => value = v), semanticsLabel: 'Power');
    })));
    await tester.fling(find.byType(WizToggle), const Offset(40, 0), 800);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('disabled toggles ignore taps', (tester) async {
    var changed = false;
    await tester.pumpWidget(wizTestApp(WizToggle(value: false, enabled: false, onChanged: (_) => changed = true, semanticsLabel: 'x')));
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(changed, isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_toggle_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/widgets/wiz_toggle.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

enum WizToggleSize { sm, md }

/// Physical rocker switch: recessed well, glossy ivory cap, amber filament
/// glow when live. The cap slides on the settle curve; it can also be
/// dragged or flicked.
class WizToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final WizToggleSize size;
  final bool enabled;
  final String semanticsLabel;

  const WizToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = WizToggleSize.md,
    this.enabled = true,
    required this.semanticsLabel,
  });

  // Design system Toggle.jsx TOGGLE_S: track width, height, cap diameter.
  static const _geometry = {
    WizToggleSize.sm: (w: 46.0, h: 27.0, k: 21.0),
    WizToggleSize.md: (w: 60.0, h: 33.0, k: 27.0),
  };

  /// Flick faster than this commits regardless of where the cap is.
  static const double flickVelocity = 200;

  @override
  State<WizToggle> createState() => _WizToggleState();
}

class _WizToggleState extends State<WizToggle> {
  bool _down = false;
  double? _dragLeft;

  ({double w, double h, double k}) get _g => WizToggle._geometry[widget.size]!;
  double get _pad => (_g.h - _g.k) / 2;
  double get _leftOn => _g.w - _g.k - _pad;

  void _commit(bool next) {
    if (!widget.enabled || widget.onChanged == null || next == widget.value) return;
    context.feedback.play(next ? FeedbackKind.toggleOn : FeedbackKind.toggleOff);
    widget.onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var g = _g;
    var on = widget.value;
    var restLeft = on ? _leftOn : _pad;
    var left = _dragLeft ?? restLeft;
    var radius = BorderRadius.circular(wiz.space.pill);

    var trackSpec = on
        ? WizShadowSpec(
            insets: const [
              WizInset(offsetY: 2, blur: 5, color: Color(0x8C783C00)),
              WizInset(offsetY: -1, blur: 0, color: Color(0x59FFFFFF)),
            ],
            outer: [BoxShadow(color: c.amber500.withValues(alpha: .65), blurRadius: 16, spreadRadius: -3)],
          )
        : const WizShadowSpec(
            insets: [
              WizInset(offsetY: 2, blur: 5, color: Color(0xB3000000)),
              WizInset(offsetY: -1, blur: 0, color: Color(0x12FFFFFF)),
            ],
          );
    var trackGradient = on
        ? LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [c.amber600, c.amber400, c.amber500], stops: const [0, .62, 1])
        : LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [c.char1000, c.char800]);

    var cap = AnimatedScale(
      scale: _down ? 0.93 : 1,
      duration: m.release,
      curve: m.settle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.24, -0.48),
            colors: [Color(0xFFFFFFFF), Color(0xFFF1EEE8), Color(0xFFC8C4BB), Color(0xFFA8A49B)],
            stops: [0, .42, .78, 1],
          ),
          boxShadow: const [BoxShadow(color: Color(0x8C000000), offset: Offset(0, 3), blurRadius: 6)],
        ),
        child: SizedBox(width: g.k, height: g.k),
      ),
    );

    return Semantics(
      label: widget.semanticsLabel,
      toggled: on,
      enabled: widget.enabled,
      onTap: widget.enabled ? () => _commit(!on) : null,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.enabled ? () => _commit(!on) : null,
          onHorizontalDragStart: widget.enabled
              ? (_) => setState(() {
                  _down = true;
                  _dragLeft = restLeft;
                })
              : null,
          onHorizontalDragUpdate: (d) => setState(() {
            _dragLeft = ((_dragLeft ?? restLeft) + d.delta.dx).clamp(_pad, _leftOn);
          }),
          onHorizontalDragEnd: (d) {
            var v = d.primaryVelocity ?? 0;
            var next = v.abs() > WizToggle.flickVelocity
                ? v > 0
                : (_dragLeft ?? restLeft) + g.k / 2 > g.w / 2;
            setState(() {
              _down = false;
              _dragLeft = null;
            });
            _commit(next);
          },
          onHorizontalDragCancel: () => setState(() {
            _down = false;
            _dragLeft = null;
          }),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: AnimatedScale(
              scale: _down ? 0.96 : 1,
              duration: m.release,
              curve: m.settle,
              child: SizedBox(
                width: g.w,
                height: g.h,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: m.ui,
                        child: WizSurface(
                          key: ValueKey(on),
                          spec: trackSpec,
                          radius: radius,
                          gradient: trackGradient,
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: _dragLeft == null ? m.panel : Duration.zero,
                      curve: m.settle,
                      left: left,
                      top: _pad,
                      child: cap,
                    ),
                  ],
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

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_toggle_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/wiz_toggle.dart test/core/widgets/wiz_toggle_test.dart
git commit -m "feat(kit): WizToggle rocker with drag and flick"
```

---

### Task 12: WizPowerKey

**Files:**
- Create: `lib/core/widgets/wiz_power_key.dart`
- Test: `test/core/widgets/wiz_power_key_test.dart`

**Interfaces:**
- Produces: `enum WizPowerKeySize { md, lg }` (96, 132); `class WizPowerKey extends StatelessWidget { on, onChanged (ValueChanged<bool>?), size, enabled }`. Fires `power` when turning on and `toggleOff` when turning off; sinks 2 px; the amber glow ramps over the light duration.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_power_key_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_power_key.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('sizes and feedback', (tester) async {
    var feedback = RecordingFeedbackService();
    var on = false;
    await tester.pumpWidget(wizTestApp(StatefulBuilder(builder: (context, setState) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        WizPowerKey(on: on, onChanged: (v) => setState(() => on = v)),
        WizPowerKey(on: on, onChanged: (v) => setState(() => on = v), size: WizPowerKeySize.md),
      ]);
    }), feedback: feedback));
    var sizes = tester.widgetList(find.byType(WizPowerKey)).map((w) => tester.getSize(find.byWidget(w))).toList();
    expect(sizes[0], const Size(132, 132));
    expect(sizes[1], const Size(96, 96));
    await tester.tap(find.byType(WizPowerKey).first);
    await tester.pumpAndSettle();
    expect(on, isTrue);
    await tester.tap(find.byType(WizPowerKey).first);
    await tester.pumpAndSettle();
    expect(on, isFalse);
    expect(feedback.played, [FeedbackKind.power, FeedbackKind.toggleOff]);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_power_key_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/widgets/wiz_power_key.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizPowerKeySize { md, lg }

/// Hero power control. Off is dead charcoal; on is tungsten glow that ramps
/// in over the light duration, the bulb physically warming.
class WizPowerKey extends StatelessWidget {
  final bool on;
  final ValueChanged<bool>? onChanged;
  final WizPowerKeySize size;
  final bool enabled;

  const WizPowerKey({
    super.key,
    required this.on,
    required this.onChanged,
    this.size = WizPowerKeySize.lg,
    this.enabled = true,
  });

  // Design system PowerKey.jsx: diameters, glyph ratio, press travel.
  static const _diameter = {WizPowerKeySize.md: 96.0, WizPowerKeySize.lg: 132.0};
  static const double glyphRatio = 0.34;
  static const double travel = 2;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var d = _diameter[size]!;
    var radius = BorderRadius.circular(d / 2);
    var offGradient = wizVertical(c.surfaceKey, c.char900);
    var onGradient = RadialGradient(
      center: const Alignment(0, -0.36),
      colors: [c.amber300, c.amber500, c.amber700],
      stops: const [0, .58, 1],
    );
    return WizPressable(
      onTap: onChanged == null ? null : () => onChanged!(!on),
      enabled: enabled && onChanged != null,
      feedback: on ? FeedbackKind.toggleOff : FeedbackKind.power,
      scale: m.pressScale,
      travel: travel,
      semanticsLabel: 'Power',
      builder: (context, state) => SizedBox(
        width: d,
        height: d,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WizGlow(on: on && !state.pressed, shadows: wiz.elevation.glowAmberStrong, radius: radius),
            WizSurface(
              spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.knob,
              radius: radius,
              gradient: offGradient,
            ),
            AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: m.light,
              curve: m.tactile,
              child: WizSurface(
                spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.knob,
                radius: radius,
                gradient: onGradient,
              ),
            ),
            Center(
              child: AnimatedDefaultTextStyle(
                duration: m.light,
                style: TextStyle(color: on ? c.textOnAccent : c.textTertiary),
                child: WizIcon(WizIcons.power, size: d * glyphRatio),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_power_key_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/wiz_power_key.dart test/core/widgets/wiz_power_key_test.dart
git commit -m "feat(kit): WizPowerKey with ramping emission"
```

---
### Task 13: WizDial

**Files:**
- Create: `lib/core/widgets/wiz_dial.dart`, `lib/core/widgets/wiz_dial_painter.dart`
- Test: `test/core/widgets/wiz_dial_test.dart`

**Interfaces:**
- Consumes: `paintInsets`, `WizSurface`, `WizTextures.knurlPaint`, `FeedbackKind.detent/press`.
- Produces: `class WizDial extends StatefulWidget { value (double), min, max, step (default 1), onChanged (ValueChanged<double>), onChangeEnd (ValueChanged<double>?), label (String?), unit (String, default '%'), size (double, required), enabled }`. Vertical drag of 160 px covers the full range; arrow keys step ×5; a detent fires every 1/40 of the range; the readout snaps.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_dial_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_dial.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('dragging up raises the value and fires detents', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 50.0;
    var ended = <double>[];
    await tester.pumpWidget(wizTestApp(StatefulBuilder(builder: (context, setState) {
      return WizDial(
        value: value, min: 10, max: 100, size: 132, label: 'Brightness',
        onChanged: (v) => setState(() => value = v),
        onChangeEnd: ended.add,
      );
    }), feedback: feedback));
    expect(find.text('50'), findsOneWidget);
    var center = tester.getCenter(find.byType(WizDial));
    await tester.timedDrag(find.byType(WizDial), const Offset(0, -80), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // 80 px of 160 px travel is half the 90-unit range: 50 + 45.
    expect(value, closeTo(95, 1));
    expect(find.text('95'), findsOneWidget);
    expect(feedback.played.first, FeedbackKind.press);
    expect(feedback.played.where((k) => k == FeedbackKind.detent).length, greaterThan(5));
    expect(ended, [value]);
    expect(center, isNotNull);
  });

  testWidgets('values clamp to the range and snap to step', (tester) async {
    var value = 2700.0;
    await tester.pumpWidget(wizTestApp(StatefulBuilder(builder: (context, setState) {
      return WizDial(
        value: value, min: 2200, max: 6500, step: 50, size: 132, unit: 'K',
        onChanged: (v) => setState(() => value = v),
      );
    })));
    await tester.timedDrag(find.byType(WizDial), const Offset(0, 400), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(value, 2200);
    await tester.timedDrag(find.byType(WizDial), const Offset(0, -33), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(value % 50, 0);
    expect(find.textContaining('K'), findsWidgets);
  });

  testWidgets('the dial is as wide as it is told and shows its label', (tester) async {
    await tester.pumpWidget(wizTestApp(WizDial(value: 30, min: 10, max: 100, size: 118, label: 'Brightness', onChanged: (_) {})));
    expect(tester.getSize(find.byType(WizDial)).width, 118);
    expect(find.text('BRIGHTNESS'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_dial_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the painter**

`lib/core/widgets/wiz_dial_painter.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import 'wiz_surface.dart';

/// Geometry shared by the dial's layers (Dial.jsx).
class WizDialGeometry {
  WizDialGeometry._();

  /// Degrees of travel and where it starts (measured clockwise from 12).
  static const double sweep = 280;
  static const double start = -140;

  /// Pixels of vertical drag that cover the full range.
  static const double dragTravel = 160;

  /// Notches across the range; each crossing fires a detent.
  static const int detents = 40;

  /// Arrow keys move this many steps.
  static const int keySteps = 5;

  /// Ratios of the diameter (knob inset, readout well inset, value font,
  /// unit font, index mark height and top offset).
  static const double knobInset = 0.085;
  static const double wellInset = 0.235;
  static const double valueFont = 0.24;
  static const double unitFont = 0.11;
  static const double markHeight = 0.125;
  static const double markTop = 0.05;
  static const double markWidth = 3;

  static double angleFor(double pct) => start + pct * sweep;
}

/// The recessed disc with the amber sweep arc and the dead wedge at the
/// bottom. CSS conic angles are from 12 o'clock; Flutter sweeps from 3, so
/// every angle is shifted by a quarter turn.
class WizDialArcPainter extends CustomPainter {
  final double pct;
  final Color amber600, amber400, amber500, dead;
  final List<WizInset> insets;

  WizDialArcPainter({
    required this.pct,
    required this.amber600,
    required this.amber400,
    required this.amber500,
    required this.dead,
    required this.insets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    var filled = pct * WizDialGeometry.sweep / 360;
    var sweepEnd = WizDialGeometry.sweep / 360;
    var startRad = (WizDialGeometry.start - 90) * math.pi / 180;
    var gradient = SweepGradient(
      startAngle: startRad,
      endAngle: startRad + 2 * math.pi,
      colors: [amber600, amber400, amber500, dead, dead, Colors.transparent, Colors.transparent],
      stops: [0, filled * 0.65, filled, filled, sweepEnd, sweepEnd, 1],
    );
    canvas.drawOval(rect, Paint()..shader = gradient.createShader(rect));
    paintInsets(canvas, RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2)), insets);
  }

  @override
  bool shouldRepaint(WizDialArcPainter old) => old.pct != pct;
}

/// The knurled knob face: knurl stripes over a charcoal gradient with a
/// top-left highlight.
class WizKnobFacePainter extends CustomPainter {
  final WizElevation elevation;
  final Color top, bottom;

  WizKnobFacePainter({required this.elevation, required this.top, required this.bottom});

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(rect));
    canvas.drawRect(rect, WizTextures.knurlPaint(elevation)..blendMode = BlendMode.softLight);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.36, -0.56),
          colors: [Colors.white.withValues(alpha: .14), Colors.white.withValues(alpha: 0)],
          stops: const [0, .58],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(WizKnobFacePainter old) => old.top != top || old.bottom != bottom;
}
```

- [ ] **Step 4: Implement the dial**

`lib/core/widgets/wiz_dial.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_dial_painter.dart';
import 'wiz_surface.dart';

/// Rotary knob. Drag vertically (or use arrow keys) to change the value.
/// Machined bezel, knurled rim, engraved index mark, amber sweep arc. The
/// readout snaps; only the knob and the arc glow ease.
class WizDial extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final String unit;
  final double size;
  final bool enabled;

  const WizDial({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    this.onChangeEnd,
    this.label,
    this.unit = '%',
    required this.size,
    this.enabled = true,
  });

  @override
  State<WizDial> createState() => _WizDialState();
}

class _WizDialState extends State<WizDial> {
  double? _dragStartY;
  double _dragStartValue = 0;
  int? _notch;
  bool _down = false;

  double get _pct => ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0, 1);

  void _commit(double raw) {
    var clamped = raw.clamp(widget.min, widget.max);
    var next = ((clamped - widget.min) / widget.step).round() * widget.step + widget.min;
    var notch = ((next - widget.min) / (widget.max - widget.min) * WizDialGeometry.detents).round();
    if (notch != _notch) {
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    if (next != widget.value) widget.onChanged(next);
  }

  void _start(DragStartDetails d) {
    if (!widget.enabled) return;
    _dragStartY = d.localPosition.dy;
    _dragStartValue = widget.value;
    _notch = (_pct * WizDialGeometry.detents).round();
    setState(() => _down = true);
    context.feedback.play(FeedbackKind.press);
  }

  void _update(DragUpdateDetails d) {
    var startY = _dragStartY;
    if (startY == null) return;
    var range = widget.max - widget.min;
    _commit(_dragStartValue + (startY - d.localPosition.dy) / WizDialGeometry.dragTravel * range);
  }

  void _end() {
    if (_dragStartY == null) return;
    _dragStartY = null;
    setState(() => _down = false);
    widget.onChangeEnd?.call(widget.value);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) return KeyEventResult.ignored;
    var delta = widget.step * WizDialGeometry.keySteps;
    var k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
      _commit(widget.value + delta);
      widget.onChangeEnd?.call(widget.value);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
      _commit(widget.value - delta);
      widget.onChangeEnd?.call(widget.value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var d = widget.size;
    var pct = _pct;
    var angle = WizDialGeometry.angleFor(pct);
    var knobInset = d * WizDialGeometry.knobInset;
    var wellInset = d * WizDialGeometry.wellInset;
    var knobSize = d - knobInset * 2;
    var circle = BorderRadius.circular(d);

    var disc = SizedBox(
      width: d,
      height: d,
      child: Stack(
        children: [
          // Sweep arc and its glow
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: pct > 0 ? 1 : 0,
              duration: m.ui,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: c.amber500.withValues(alpha: .28), blurRadius: 12)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WizDialArcPainter(
                pct: pct,
                amber600: c.amber600,
                amber400: c.amber400,
                amber500: c.amber500,
                dead: c.char1000,
                insets: wiz.elevation.well.insets,
              ),
            ),
          ),
          // Knob
          Positioned(
            left: knobInset,
            top: knobInset,
            width: knobSize,
            height: knobSize,
            child: AnimatedRotation(
              turns: angle / 360,
              duration: _dragStartY == null ? m.release : Duration.zero,
              curve: m.settle,
              child: WizSurface(
                spec: wiz.elevation.knob,
                radius: circle,
                color: c.char850,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: WizKnobFacePainter(elevation: wiz.elevation, top: c.surfaceKey, bottom: c.char950),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: d * WizDialGeometry.markTop),
                        child: Container(
                          width: WizDialGeometry.markWidth,
                          height: d * WizDialGeometry.markHeight,
                          decoration: BoxDecoration(
                            color: c.amber300,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: c.amber400.withValues(alpha: .9), blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Readout well
          Positioned(
            left: wellInset,
            top: wellInset,
            right: wellInset,
            bottom: wellInset,
            child: IgnorePointer(
              child: WizSurface(
                spec: wiz.elevation.wellDeep,
                radius: circle,
                gradient: wizVertical(c.char850, c.char1000),
                alignment: Alignment.center,
                child: Text.rich(
                  TextSpan(
                    text: '${widget.value.round()}',
                    style: wiz.type.readout.copyWith(fontSize: d * WizDialGeometry.valueFont, fontWeight: FontWeight.w800, letterSpacing: d * WizDialGeometry.valueFont * 0.01, color: c.textPrimary),
                    children: [
                      TextSpan(
                        text: widget.unit,
                        style: TextStyle(fontSize: d * WizDialGeometry.unitFont, color: c.textTertiary),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          slider: true,
          label: widget.label,
          value: '${widget.value.round()}${widget.unit}',
          enabled: widget.enabled,
          onIncrease: widget.enabled ? () => _commit(widget.value + widget.step * WizDialGeometry.keySteps) : null,
          onDecrease: widget.enabled ? () => _commit(widget.value - widget.step * WizDialGeometry.keySteps) : null,
          child: Focus(
            onKeyEvent: _key,
            child: MouseRegion(
              cursor: widget.enabled ? SystemMouseCursors.resizeUpDown : SystemMouseCursors.forbidden,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _start,
                onVerticalDragUpdate: _update,
                onVerticalDragEnd: (_) => _end(),
                onVerticalDragCancel: _end,
                child: Opacity(
                  opacity: widget.enabled ? 1 : 0.45,
                  child: AnimatedScale(
                    scale: _down ? m.pressScale : 1,
                    duration: m.release,
                    curve: m.settle,
                    child: disc,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          SizedBox(height: wiz.space.s2 + wiz.space.s3),
          Text(widget.label!.toUpperCase(), style: wiz.type.label.copyWith(color: c.textTertiary)),
        ],
      ],
    );
  }
}
```

Note the arc's `SweepGradient` stops must be non-decreasing; when `pct` is 0 the stops `[0, 0, 0, 0, sweepEnd, sweepEnd, 1]` are valid. `math` is imported for future use by the painter file; remove it from `wiz_dial.dart` if the analyzer flags it unused.

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_dial_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/wiz_dial.dart lib/core/widgets/wiz_dial_painter.dart test/core/widgets/wiz_dial_test.dart
git commit -m "feat(kit): WizDial rotary knob with detents"
```

---

### Task 14: WizSlider

**Files:**
- Create: `lib/core/widgets/wiz_slider.dart`
- Modify: `lib/core/theme/wiz_colors.dart` (add `railDark 0xFF3A3A42`, `railMid 0xFF8C8C96`)
- Test: `test/core/widgets/wiz_slider_test.dart`

**Interfaces:**
- Produces: `class WizSliderFill { static final brightness, kelvin, speed, neutral; factory colour(Color); List<Color> colors(WizColors); bool glows; }`; `class WizSlider extends StatefulWidget { value, min, max, step (default 1), onChanged, onChangeEnd, fill (default brightness), label, readout (String?), enabled }`. Fills the width it is given; detent every 1/20; keyboard arrows step by `step`.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_slider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('tapping the rail sets the value proportionally', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 10.0;
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 300,
      child: StatefulBuilder(builder: (context, setState) {
        return WizSlider(value: value, min: 10, max: 100, label: 'Speed', readout: '$value',
            onChanged: (v) => setState(() => value = v));
      }),
    ), feedback: feedback));
    var rail = find.byKey(const Key('wiz-slider-track'));
    var rect = tester.getRect(rail);
    await tester.tapAt(Offset(rect.left + rect.width * 0.5, rect.center.dy));
    await tester.pumpAndSettle();
    expect(value, closeTo(55, 1));
    expect(feedback.played.first, FeedbackKind.press);
  });

  testWidgets('dragging fires detents and reports the end value', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 10.0;
    double? ended;
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 300,
      child: StatefulBuilder(builder: (context, setState) {
        return WizSlider(value: value, min: 10, max: 200, fill: WizSliderFill.speed,
            onChanged: (v) => setState(() => value = v), onChangeEnd: (v) => ended = v);
      }),
    ), feedback: feedback));
    var rect = tester.getRect(find.byKey(const Key('wiz-slider-track')));
    await tester.timedDrag(find.byKey(const Key('wiz-slider-track')), Offset(rect.width, 0), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(value, 200);
    expect(ended, 200);
    expect(feedback.played.where((k) => k == FeedbackKind.detent).length, greaterThan(3));
  });

  testWidgets('label is uppercase and readout shows', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(width: 200, child: WizSlider(value: 50, min: 10, max: 100, label: 'Brightness', readout: '50%', onChanged: (_) {}))));
    expect(find.text('BRIGHTNESS'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_slider_test.dart`
Expected: compile error.

- [ ] **Step 3: Add the rail colours and implement**

In `lib/core/theme/wiz_colors.dart` add after the ivory colours:

```dart
  // Slider fill ends (SLIDER_FILLS in Slider.jsx)
  final Color railDark = const Color(0xFF3A3A42);
  final Color railMid = const Color(0xFF8C8C96);
```

`lib/core/widgets/wiz_slider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// The fill gradient differs per purpose (Slider.jsx SLIDER_FILLS), plus a
/// live-colour fill for brightness in colour mode (handoff proposal).
class WizSliderFill {
  final List<Color> Function(WizColors c) colors;

  /// Brightness and kelvin fills carry the amber glow.
  final bool glows;

  const WizSliderFill._(this.colors, this.glows);

  static final brightness = WizSliderFill._((c) => [c.railDark, c.amber300], true);
  static final kelvin = WizSliderFill._(
    (c) => [c.kelvinStops[2200]!, c.kelvinStops[3500]!, c.kelvinStops[4500]!, c.kelvinStops[6500]!],
    true,
  );
  static final speed = WizSliderFill._((c) => [c.railDark, c.hueCyan], false);
  static final neutral = WizSliderFill._((c) => [c.railDark, c.railMid], false);

  factory WizSliderFill.colour(Color color) => WizSliderFill._((_) => [color, color], false);
}

/// Recessed rail with a raised ivory handle. Drag or tap anywhere on the
/// track; a detent fires every twentieth of the range.
class WizSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final WizSliderFill? fill;
  final String? label;
  final String? readout;
  final bool enabled;

  const WizSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    this.onChangeEnd,
    this.fill,
    this.label,
    this.readout,
    this.enabled = true,
  });

  // Slider.jsx: handle diameter, fill inset, minimum fill width, detents.
  static const double handleSize = 26;
  static const double fillInset = 2;
  static const double fillMin = 6;
  static const int detents = 20;

  @override
  State<WizSlider> createState() => _WizSliderState();
}

class _WizSliderState extends State<WizSlider> {
  bool _dragging = false;
  int? _notch;

  double get _pct => ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0, 1);

  void _from(double dx, double width) {
    var p = (dx / width).clamp(0.0, 1.0);
    var v = widget.min + p * (widget.max - widget.min);
    var notch = (p * WizSlider.detents).round();
    if (notch != _notch) {
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    var next = (v / widget.step).round() * widget.step;
    if (next != widget.value) widget.onChanged(next.clamp(widget.min, widget.max));
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onChanged((widget.value + widget.step).clamp(widget.min, widget.max));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onChanged((widget.value - widget.step).clamp(widget.min, widget.max));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var fill = widget.fill ?? WizSliderFill.brightness;
    var pill = BorderRadius.circular(wiz.space.pill);
    var trackH = wiz.space.track;
    var boxH = WizSlider.handleSize > trackH ? WizSlider.handleSize : trackH;

    var header = (widget.label != null || widget.readout != null)
        ? Padding(
            padding: EdgeInsets.only(bottom: wiz.space.s2 + wiz.space.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (widget.label != null)
                  Text(widget.label!.toUpperCase(), style: wiz.type.label.copyWith(color: c.textTertiary)),
                const Spacer(),
                if (widget.readout != null)
                  Text(widget.readout!, style: wiz.type.readoutSm.copyWith(fontSize: 20, color: c.textPrimary)),
              ],
            ),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Semantics(
          slider: true,
          label: widget.label,
          value: widget.readout ?? '${widget.value.round()}',
          enabled: widget.enabled,
          child: Focus(
            onKeyEvent: _key,
            child: LayoutBuilder(
              builder: (context, constraints) {
                var w = constraints.maxWidth;
                var pct = _pct;
                var fillW = ((w - WizSlider.fillInset * 2) * pct).clamp(WizSlider.fillMin, w);
                return MouseRegion(
                  cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                  child: GestureDetector(
                    key: const Key('wiz-slider-track'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: widget.enabled
                        ? (d) {
                            _notch = null;
                            context.feedback.play(FeedbackKind.press);
                            _from(d.localPosition.dx, w);
                          }
                        : null,
                    onTapUp: (_) => widget.onChangeEnd?.call(widget.value),
                    onHorizontalDragStart: widget.enabled
                        ? (d) {
                            _notch = null;
                            setState(() => _dragging = true);
                            context.feedback.play(FeedbackKind.press);
                            _from(d.localPosition.dx, w);
                          }
                        : null,
                    onHorizontalDragUpdate: (d) => _from(d.localPosition.dx, w),
                    onHorizontalDragEnd: (_) {
                      setState(() => _dragging = false);
                      widget.onChangeEnd?.call(widget.value);
                    },
                    onHorizontalDragCancel: () => setState(() => _dragging = false),
                    child: Opacity(
                      opacity: widget.enabled ? 1 : 0.45,
                      child: SizedBox(
                        height: boxH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: (boxH - trackH) / 2,
                              height: trackH,
                              child: WizSurface(
                                spec: wiz.elevation.well,
                                radius: pill,
                                gradient: wizVertical(c.char1000, c.char900),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: _dragging ? Duration.zero : m.release,
                              curve: m.tactile,
                              left: WizSlider.fillInset,
                              top: (boxH - trackH) / 2 + WizSlider.fillInset,
                              height: trackH - WizSlider.fillInset * 2,
                              width: fillW,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: pill,
                                  gradient: LinearGradient(colors: fill.colors(c)),
                                  boxShadow: fill.glows
                                      ? [BoxShadow(color: c.amber500.withValues(alpha: .45), blurRadius: 14, spreadRadius: -2)]
                                      : null,
                                ),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: _dragging ? Duration.zero : m.release,
                              curve: m.tactile,
                              left: pct * w - WizSlider.handleSize / 2,
                              top: (boxH - WizSlider.handleSize) / 2,
                              child: WizSurface(
                                spec: const WizShadowSpec(
                                  outer: [BoxShadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 6)],
                                  insets: [WizInset(offsetY: 1, blur: 0, color: Color(0xF2FFFFFF))],
                                ),
                                radius: BorderRadius.circular(WizSlider.handleSize / 2),
                                gradient: wizVertical(c.ivoryHi, c.ivoryLo),
                                width: WizSlider.handleSize,
                                height: WizSlider.handleSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_slider_test.dart test/core/theme && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/wiz_slider.dart lib/core/theme/wiz_colors.dart test/core/widgets/wiz_slider_test.dart
git commit -m "feat(kit): WizSlider rail with purpose fills"
```

---

### Task 15: WizColorWheel

**Files:**
- Create: `lib/core/widgets/wiz_color_wheel.dart`
- Test: `test/core/widgets/wiz_color_wheel_test.dart`

**Interfaces:**
- Produces: `class WizHsv { final double hue; final double saturation; Color get color; const WizHsv(this.hue, this.saturation); }`; `class WizColorWheel extends StatefulWidget { hue, saturation, onChanged (ValueChanged<WizHsv>), onChangeEnd (ValueChanged<WizHsv>?), size (required), enabled }`. Hue 0 is at 12 o'clock going clockwise; saturation is distance from the centre; a detent fires every 15° of hue.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_color_wheel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_color_wheel.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('tapping to the right of centre gives hue 90 at full saturation', (tester) async {
    var feedback = RecordingFeedbackService();
    WizHsv? got;
    await tester.pumpWidget(wizTestApp(
      WizColorWheel(hue: 30, saturation: 0, size: 200, onChanged: (v) => got = v),
      feedback: feedback,
    ));
    var center = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(center + const Offset(90, 0));
    await tester.pump();
    expect(got, isNotNull);
    expect(got!.hue, closeTo(90, 1));
    expect(got!.saturation, closeTo(1, 0.02));
    expect(feedback.played.first, FeedbackKind.press);
  });

  testWidgets('the centre is white and dragging around fires detents', (tester) async {
    var feedback = RecordingFeedbackService();
    WizHsv? got;
    await tester.pumpWidget(wizTestApp(
      WizColorWheel(hue: 0, saturation: 1, size: 200, onChanged: (v) => got = v),
      feedback: feedback,
    ));
    var center = tester.getCenter(find.byType(WizColorWheel));
    await tester.tapAt(center);
    await tester.pump();
    expect(got!.saturation, closeTo(0, 0.02));
    expect(got!.color, const Color(0xFFFFFFFF));
    await tester.timedDrag(find.byType(WizColorWheel), const Offset(0, 80), const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(feedback.played.where((k) => k == FeedbackKind.detent).length, greaterThan(0));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_color_wheel_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/widgets/wiz_color_wheel.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_theme.dart';
import '../util/color_maths.dart';
import 'wiz_surface.dart';

/// Hue in degrees (0 at the top, clockwise) and saturation in [0, 1].
@immutable
class WizHsv {
  final double hue;
  final double saturation;

  const WizHsv(this.hue, this.saturation);

  Color get color => hsvToColor(hue, saturation);
}

/// HSV colour wheel with a raised puck. Drag anywhere inside the disc.
class WizColorWheel extends StatefulWidget {
  final double hue;
  final double saturation;
  final ValueChanged<WizHsv> onChanged;
  final ValueChanged<WizHsv>? onChangeEnd;
  final double size;
  final bool enabled;

  const WizColorWheel({
    super.key,
    required this.hue,
    required this.saturation,
    required this.onChanged,
    this.onChangeEnd,
    required this.size,
    this.enabled = true,
  });

  // ColorWheel.jsx: ring inset, puck, ring width, usable radius margin, detent.
  static const double ringInset = 8;
  static const double puckSize = 34;
  static const double puckRing = 4;
  static const double radiusMargin = 18;
  static const double detentDegrees = 15;
  static const double whiteStop = 0.62;

  @override
  State<WizColorWheel> createState() => _WizColorWheelState();
}

class _WizColorWheelState extends State<WizColorWheel> {
  bool _dragging = false;
  int? _notch;

  double get _r => widget.size / 2;
  double get _usable => _r - WizColorWheel.radiusMargin;

  void _from(Offset local) {
    var x = local.dx - _r, y = local.dy - _r;
    var dist = math.min(1.0, math.sqrt(x * x + y * y) / _usable);
    var h = math.atan2(y, x) * 180 / math.pi + 90;
    if (h < 0) h += 360;
    var notch = (h / WizColorWheel.detentDegrees).round();
    if (notch != _notch) {
      if (_notch != null) context.feedback.play(FeedbackKind.detent);
      _notch = notch;
    }
    widget.onChanged(WizHsv(h.roundToDouble() % 360, double.parse(dist.toStringAsFixed(3))));
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var d = widget.size;
    var rad = (widget.hue - 90) * math.pi / 180;
    var px = _r + math.cos(rad) * widget.saturation * _usable;
    var py = _r + math.sin(rad) * widget.saturation * _usable;
    var current = WizHsv(widget.hue, widget.saturation).color;
    // conic-gradient(from -90deg, red, yellow, green, teal, cyan, indigo, violet, magenta, red)
    var wheelColors = [c.hueRed, c.hueYellow, c.hueGreen, c.hueTeal, c.hueCyan, c.hueIndigo, c.hueViolet, c.hueMagenta, c.hueRed];

    return Semantics(
      label: 'Colour wheel',
      enabled: widget.enabled,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.precise : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: widget.enabled
              ? (e) {
                  _notch = null;
                  setState(() => _dragging = true);
                  context.feedback.play(FeedbackKind.press);
                  _from(e.localPosition);
                }
              : null,
          onPanUpdate: (e) => _from(e.localPosition),
          onPanEnd: (_) {
            setState(() => _dragging = false);
            widget.onChangeEnd?.call(WizHsv(widget.hue, widget.saturation));
          },
          onPanCancel: () => setState(() => _dragging = false),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.4,
            child: SizedBox(
              width: d,
              height: d,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(startAngle: -math.pi, endAngle: math.pi, colors: wheelColors),
                        boxShadow: wiz.elevation.knob.outer,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.char900, width: WizColorWheel.ringInset),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(WizColorWheel.ringInset),
                      child: WizSurface(
                        spec: const WizShadowSpec(insets: [WizInset(offsetY: 2, blur: 10, color: Color(0x73000000))]),
                        radius: BorderRadius.circular(d),
                        gradient: RadialGradient(
                          colors: [Colors.white.withValues(alpha: .95), Colors.white.withValues(alpha: 0)],
                          stops: const [0, WizColorWheel.whiteStop],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dragging ? Duration.zero : m.release,
                    curve: m.tactile,
                    left: px - WizColorWheel.puckSize / 2,
                    top: py - WizColorWheel.puckSize / 2,
                    child: IgnorePointer(
                      child: Container(
                        width: WizColorWheel.puckSize,
                        height: WizColorWheel.puckSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: current,
                          boxShadow: [
                            BoxShadow(color: c.ivoryHi.withValues(alpha: .92), spreadRadius: WizColorWheel.puckRing),
                            const BoxShadow(color: Color(0x99000000), offset: Offset(0, 4), blurRadius: 10),
                            BoxShadow(color: current.withValues(alpha: .8), blurRadius: 26, spreadRadius: -2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_color_wheel_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/wiz_color_wheel.dart test/core/widgets/wiz_color_wheel_test.dart
git commit -m "feat(kit): WizColorWheel with hue detents"
```

---

### Task 16: Scene gradients, WizSceneArt and WizSceneTile

**Files:**
- Create: `lib/core/widgets/scene_gradients.dart`, `lib/core/widgets/wiz_scene_art.dart`, `lib/core/widgets/wiz_scene_tile.dart`
- Test: `test/core/widgets/scene_gradients_test.dart`, `test/core/widgets/wiz_scene_tile_test.dart`

**Interfaces:**
- Produces: `class SceneGradient { int id; String name; bool isDynamic; Color from; Color to; }`; `const Map<int, SceneGradient> sceneGradients` (36 entries keyed by WiZ scene id); `List<SceneGradient> get staticScenes`, `dynamicScenes` (in id order); `class WizSceneArt extends StatelessWidget { from, to, radius (BorderRadius), sheen (bool), grainOpacity (0.85), child? }` with `WizSceneArt.scene(int id, {radius, sheen, child})`; `class WizSceneTile extends StatelessWidget { sceneId, selected, onTap, radius, labelSize, sheen, height? }`.

- [ ] **Step 1: Write the failing tests**

`test/core/widgets/scene_gradients_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';

void main() {
  test('all 36 WiZ scenes, 21 dynamic and 15 static, keyed by id', () {
    expect(sceneGradients, hasLength(36));
    expect(dynamicScenes, hasLength(21));
    expect(staticScenes, hasLength(15));
    expect(sceneGradients[1]!.name, 'Ocean');
    expect(sceneGradients[1]!.isDynamic, isTrue);
    expect(sceneGradients[6]!.name, 'Cozy');
    expect(sceneGradients[6]!.isDynamic, isFalse);
    expect(sceneGradients[1000]!.name, 'Rhythm');
    expect(sceneGradients[29]!.from, const Color(0xFF7A3A05));
    expect(sceneGradients[29]!.to, const Color(0xFFFFC24D));
  });
}
```

`test/core/widgets/wiz_scene_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_tile.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('shows the scene name, a pip for dynamic scenes, and taps', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0;
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 160,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        WizSceneTile(sceneId: 1, selected: false, height: 82, onTap: () => taps++),
        WizSceneTile(sceneId: 6, selected: true, height: 82, onTap: () {}),
      ]),
    ), feedback: feedback));
    expect(find.text('Ocean'), findsOneWidget);
    expect(find.text('Cozy'), findsOneWidget);
    expect(find.byKey(const Key('scene-pip-1')), findsOneWidget);
    expect(find.byKey(const Key('scene-pip-6')), findsNothing);
    await tester.tap(find.text('Ocean'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(feedback.played, [FeedbackKind.tick]);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/widgets/scene_gradients_test.dart test/core/widgets/wiz_scene_tile_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the gradient table**

`lib/core/widgets/scene_gradients.dart` (values from `SCENE_GRADIENTS` in SceneTile.jsx; ids, names and dynamic flags mirror `WizScene`):

```dart
import 'package:flutter/material.dart';

/// Two colours per built-in WiZ scene, authored by the design system since
/// the library has no colour data for scenes. Keyed by `WizScene.id`.
@immutable
class SceneGradient {
  final int id;
  final String name;
  final bool isDynamic;
  final Color from;
  final Color to;

  const SceneGradient(this.id, this.name, this.isDynamic, this.from, this.to);
}

const Map<int, SceneGradient> sceneGradients = {
  1: SceneGradient(1, 'Ocean', true, Color(0xFF0B6FD8), Color(0xFF25D8C0)),
  2: SceneGradient(2, 'Romance', true, Color(0xFFC2185B), Color(0xFFFF8A2B)),
  3: SceneGradient(3, 'Sunset', true, Color(0xFFFF4A3D), Color(0xFFFFD52B)),
  4: SceneGradient(4, 'Party', true, Color(0xFFA45BFF), Color(0xFFFF3FC0)),
  5: SceneGradient(5, 'Fireplace', true, Color(0xFF8A1E05), Color(0xFFFF8A2B)),
  6: SceneGradient(6, 'Cozy', false, Color(0xFFB4600F), Color(0xFFFFC24D)),
  7: SceneGradient(7, 'Forest', true, Color(0xFF0E5B2A), Color(0xFFB7F03C)),
  8: SceneGradient(8, 'Pastel Colors', true, Color(0xFFFFB6C1), Color(0xFFB8E1FF)),
  9: SceneGradient(9, 'Wake Up', true, Color(0xFF3A2A5C), Color(0xFFFFD98A)),
  10: SceneGradient(10, 'Bedtime', true, Color(0xFF241634), Color(0xFFFF8A2B)),
  11: SceneGradient(11, 'Warm White', false, Color(0xFFB4772A), Color(0xFFFFE0BC)),
  12: SceneGradient(12, 'Daylight', false, Color(0xFFC9D8F0), Color(0xFFFFF4E6)),
  13: SceneGradient(13, 'Cool White', false, Color(0xFF7FA8D9), Color(0xFFDCE9FF)),
  14: SceneGradient(14, 'Night Light', false, Color(0xFF2A1E10), Color(0xFF8A5A1E)),
  15: SceneGradient(15, 'Focus', false, Color(0xFF9FC6FF), Color(0xFFFFFFFF)),
  16: SceneGradient(16, 'Relax', false, Color(0xFF1E5B3A), Color(0xFF9FE6B8)),
  17: SceneGradient(17, 'True Colors', false, Color(0xFFFF4A3D), Color(0xFF2E7BFF)),
  18: SceneGradient(18, 'TV Time', false, Color(0xFF122A4A), Color(0xFF2ECBFF)),
  19: SceneGradient(19, 'Plant Growth', false, Color(0xFF5B1E8A), Color(0xFF38D06B)),
  20: SceneGradient(20, 'Spring', true, Color(0xFF7CFF9E), Color(0xFFFFD52B)),
  21: SceneGradient(21, 'Summer', true, Color(0xFFFF8A2B), Color(0xFFFFD52B)),
  22: SceneGradient(22, 'Fall', true, Color(0xFF8A3A05), Color(0xFFFFB25C)),
  23: SceneGradient(23, 'Deep Dive', true, Color(0xFF04234A), Color(0xFF2ECBFF)),
  24: SceneGradient(24, 'Jungle', true, Color(0xFF04361E), Color(0xFFB7F03C)),
  25: SceneGradient(25, 'Mojito', true, Color(0xFF0E6B3A), Color(0xFFD6FF6E)),
  26: SceneGradient(26, 'Club', true, Color(0xFF5B5BFF), Color(0xFFFF3FC0)),
  27: SceneGradient(27, 'Christmas', true, Color(0xFFC81E1E), Color(0xFF38D06B)),
  28: SceneGradient(28, 'Halloween', true, Color(0xFF4A1E6B), Color(0xFFFF8A2B)),
  29: SceneGradient(29, 'Candlelight', true, Color(0xFF7A3A05), Color(0xFFFFC24D)),
  30: SceneGradient(30, 'Golden White', false, Color(0xFFC08A1E), Color(0xFFFFF0C9)),
  31: SceneGradient(31, 'Pulse', true, Color(0xFF1B1B22), Color(0xFFFF4A3D)),
  32: SceneGradient(32, 'Steampunk', false, Color(0xFF5C4326), Color(0xFFD9A85C)),
  33: SceneGradient(33, 'Diwali', true, Color(0xFF8A0F5B), Color(0xFFFFD52B)),
  34: SceneGradient(34, 'White', false, Color(0xFFE8ECF5), Color(0xFFFFFFFF)),
  35: SceneGradient(35, 'Alarm', true, Color(0xFF8A0505), Color(0xFFFF4A3D)),
  1000: SceneGradient(1000, 'Rhythm', true, Color(0xFF2E7BFF), Color(0xFFA45BFF)),
};

List<SceneGradient> get staticScenes =>
    sceneGradients.values.where((s) => !s.isDynamic).toList();

List<SceneGradient> get dynamicScenes =>
    sceneGradients.values.where((s) => s.isDynamic).toList();
```

- [ ] **Step 4: Implement the art and the tile**

`lib/core/widgets/wiz_scene_art.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'scene_gradients.dart';
import 'wiz_grain.dart';

/// Procedural scene art from two colours: a top-left highlight, a
/// bottom-right bloom, a diagonal blend and the grain. Every tile is a slot
/// keyed `scene-<id>` so real artwork can replace it later.
class WizSceneArt extends StatelessWidget {
  final Color from;
  final Color to;
  final BorderRadius radius;
  final bool sheen;
  final double grainOpacity;
  final Widget? child;

  const WizSceneArt({
    super.key,
    required this.from,
    required this.to,
    required this.radius,
    this.sheen = false,
    this.grainOpacity = 0.85,
    this.child,
  });

  WizSceneArt.scene(int id, {super.key, required this.radius, this.sheen = false, this.grainOpacity = 0.85, this.child})
      : from = sceneGradients[id]!.from,
        to = sceneGradients[id]!.to;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: CustomPaint(painter: _SceneArtPainter(from, to, sheen))),
          Positioned.fill(child: WizGrain(opacity: grainOpacity)),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _SceneArtPainter extends CustomPainter {
  final Color from, to;
  final bool sheen;

  _SceneArtPainter(this.from, this.to, this.sheen);

  // CSS: radial 72%×58% at (26%,14%) from→0 at 68%; radial 84%×70% at
  // (82%,96%) to→0 at 72%; linear 158° from→to; sheen 58%×44% at (28%,18%).
  void _ellipse(Canvas canvas, Size s, double cx, double cy, double rx, double ry, Color color, double end) {
    canvas.save();
    canvas.translate(s.width * cx, s.height * cy);
    canvas.scale(s.width * rx, s.height * ry);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)], stops: [0, end])
            .createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    // 158° in CSS is a direction; converted to begin/end alignments.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.375, -0.927),
          end: const Alignment(0.375, 0.927),
          colors: [from, to],
        ).createShader(rect),
    );
    _ellipse(canvas, size, 0.82, 0.96, 0.84, 0.70, to, 0.72);
    _ellipse(canvas, size, 0.26, 0.14, 0.72, 0.58, from, 0.68);
    if (sheen) _ellipse(canvas, size, 0.28, 0.18, 0.58, 0.44, Colors.white.withValues(alpha: .30), 0.68);
  }

  @override
  bool shouldRepaint(_SceneArtPainter old) => old.from != from || old.to != to || old.sheen != sheen;
}
```

`lib/core/widgets/wiz_scene_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../theme/wiz_theme.dart';
import 'scene_gradients.dart';
import 'wiz_button.dart';
import 'wiz_pressable.dart';
import 'wiz_scene_art.dart';

/// A scene as an art tile: procedural art, the name in the display face over
/// a bottom gradient, a cyan pip when the scene is dynamic, and a 1.5 amber
/// ring when selected. One tap applies.
class WizSceneTile extends StatelessWidget {
  final int sceneId;
  final bool selected;
  final VoidCallback? onTap;
  final double? radius;
  final double? labelSize;
  final bool sheen;
  final double? height;

  const WizSceneTile({
    super.key,
    required this.sceneId,
    required this.selected,
    required this.onTap,
    this.radius,
    this.labelSize,
    this.sheen = false,
    this.height,
  });

  static const double pipSize = 5;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var scene = sceneGradients[sceneId]!;
    var border = BorderRadius.circular(radius ?? wiz.space.r4);
    var label = wiz.type.heading.copyWith(
      fontSize: labelSize ?? 20,
      fontWeight: FontWeight.w700,
      letterSpacing: (labelSize ?? 20) * WizTypeTracking.sceneLabel,
      color: c.ink1000,
      height: 1.1,
    );
    var tile = Stack(
      fit: StackFit.expand,
      children: [
        WizSceneArt(from: scene.from, to: scene.to, radius: border, sheen: sheen),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: wiz.space.s5, vertical: wiz.space.s4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.char1000.withValues(alpha: 0), c.char1000.withValues(alpha: .86)],
              ),
            ),
            child: Text(scene.name, style: label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        if (scene.isDynamic)
          Positioned(
            top: wiz.space.s4,
            right: wiz.space.s4,
            child: Container(
              key: Key('scene-pip-$sceneId'),
              width: pipSize,
              height: pipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.hueCyan,
                boxShadow: [BoxShadow(color: c.hueCyan, blurRadius: 8)],
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: m.ui,
              curve: m.tactile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: border,
                  border: Border.all(color: c.amber500, width: wiz.space.keyBorder),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return WizPressable(
      onTap: onTap,
      enabled: onTap != null,
      feedback: selected ? FeedbackKind.press : FeedbackKind.tick,
      scale: m.pressScale,
      semanticsLabel: scene.name,
      builder: (context, state) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: border, boxShadow: wiz.elevation.raised.outer),
        child: ClipRRect(
          borderRadius: border,
          child: height != null ? SizedBox(height: height, child: tile) : AspectRatio(aspectRatio: 1, child: tile),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/widgets && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets test/core/widgets
git commit -m "feat(kit): scene gradients, procedural scene art and tiles"
```

---
### Task 17: Travelling caps: WizSegmentedControl, WizTabBar, WizRail

**Files:**
- Create: `lib/core/widgets/wiz_cap_tracker.dart`, `lib/core/widgets/wiz_segmented_control.dart`, `lib/core/widgets/wiz_tab_bar.dart`, `lib/core/widgets/wiz_rail.dart`
- Test: `test/core/widgets/wiz_caps_test.dart`

**Interfaces:**
- Produces: `mixin WizCapTracker<T extends StatefulWidget> on State<T> { GlobalKey containerKey; GlobalKey keyFor(Object value); Rect? capRect; void measureCap(Object? active); }`; `class WizSegment<T> { T value; String label; WizIconData? icon; }`; `enum WizSegmentSize { sm, md }`; `class WizSegmentedControl<T> extends StatefulWidget { segments, value, onChanged, fullWidth (true), size }`; `class WizTab<T> { T value; WizIconData icon; String label; }`; `class WizTabBar<T> extends StatefulWidget { tabs, value, onChanged }`; `class WizRailItem<T> { T value; String label; WizIconData icon; String? meta; }`; `class WizRailSection<T> { String title; List<WizRailItem<T>> items; }`; `class WizRail<T> extends StatefulWidget { brand (Widget?), collapsedBrand (Widget?), sections, value (T?), onChanged, footer (Widget?), collapsed (bool), width (double?) }`. All three fire `tick` on a change and move one cap with `panel` duration on the `settle` curve. The cap carries `Key('wiz-cap')`.

- [ ] **Step 1: Write the failing tests**

`test/core/widgets/wiz_caps_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/wiz_rail.dart';
import 'package:wizctl_app/core/widgets/wiz_segmented_control.dart';
import 'package:wizctl_app/core/widgets/wiz_tab_bar.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('the segmented cap sits under the selected segment and travels', (tester) async {
    var feedback = RecordingFeedbackService();
    var value = 'colour';
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 330,
      child: StatefulBuilder(builder: (context, setState) {
        return WizSegmentedControl<String>(
          segments: const [
            WizSegment(value: 'colour', label: 'Colour'),
            WizSegment(value: 'static', label: 'Static'),
            WizSegment(value: 'dynamic', label: 'Dynamic'),
          ],
          value: value,
          onChanged: (v) => setState(() => value = v),
        );
      }),
    ), feedback: feedback));
    await tester.pumpAndSettle();
    var cap = tester.getRect(find.byKey(const Key('wiz-cap')));
    var first = tester.getRect(find.text('COLOUR'));
    expect(cap.center.dx, closeTo(first.center.dx, 1));
    await tester.tap(find.text('DYNAMIC'));
    await tester.pumpAndSettle();
    expect(value, 'dynamic');
    var moved = tester.getRect(find.byKey(const Key('wiz-cap')));
    expect(moved.center.dx, closeTo(tester.getRect(find.text('DYNAMIC')).center.dx, 1));
    expect(feedback.played, [FeedbackKind.tick]);
    expect(tester.getSize(find.byType(WizSegmentedControl<String>)).height, 44 + 8);
  });

  testWidgets('the tab bar is 72 tall and its amber cap follows the tab', (tester) async {
    var value = 'home';
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: StatefulBuilder(builder: (context, setState) {
        return WizTabBar<String>(
          tabs: const [
            WizTab(value: 'home', icon: WizIcons.house, label: 'Home'),
            WizTab(value: 'rooms', icon: WizIcons.layoutGrid, label: 'Rooms'),
            WizTab(value: 'scenes', icon: WizIcons.sparkles, label: 'Scenes'),
            WizTab(value: 'settings', icon: WizIcons.slidersHorizontal, label: 'Settings'),
          ],
          value: value,
          onChanged: (v) => setState(() => value = v),
        );
      }),
    )));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WizTabBar<String>)).height, 72);
    await tester.tap(find.bySemanticsLabel('Scenes'));
    await tester.pumpAndSettle();
    expect(value, 'scenes');
    var cap = tester.getRect(find.byKey(const Key('wiz-cap')));
    expect(cap.center.dx, closeTo(tester.getCenter(find.bySemanticsLabel('Scenes')).dx, 1));
  });

  testWidgets('the rail is 264 wide, 72 collapsed, and selects on tap', (tester) async {
    var value = 'living';
    Widget rail(bool collapsed) => StatefulBuilder(builder: (context, setState) {
      return WizRail<String>(
        collapsed: collapsed,
        brand: const Text('WIZCTL'),
        sections: const [
          WizRailSection(title: 'Rooms', items: [
            WizRailItem(value: 'living', label: 'Living Room', icon: WizIcons.sofa, meta: '3'),
            WizRailItem(value: 'bedroom', label: 'Bedroom', icon: WizIcons.bed, meta: '2'),
          ]),
          WizRailSection(title: 'House', items: [
            WizRailItem(value: 'settings', label: 'Settings', icon: WizIcons.slidersHorizontal),
          ]),
        ],
        value: value,
        onChanged: (v) => setState(() => value = v),
      );
    });
    await tester.pumpWidget(wizTestApp(SizedBox(height: 600, child: rail(false)), size: const Size(1280, 800)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WizRail<String>)).width, 264);
    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    expect(value, 'bedroom');
    await tester.pumpWidget(wizTestApp(SizedBox(height: 600, child: rail(true)), size: const Size(900, 800)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(WizRail<String>)).width, 72);
    expect(find.text('Bedroom'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/widgets/wiz_caps_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the cap tracker**

`lib/core/widgets/wiz_cap_tracker.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Measures keyed items after layout so a single raised cap can travel to
/// the active one. The cap is one element that moves; nothing cross-fades.
mixin WizCapTracker<T extends StatefulWidget> on State<T> {
  final GlobalKey containerKey = GlobalKey();
  final Map<Object, GlobalKey> _itemKeys = {};
  Rect? capRect;

  GlobalKey keyFor(Object value) => _itemKeys.putIfAbsent(value, GlobalKey.new);

  /// Schedule a measurement for after this frame. Safe to call from build:
  /// it only calls setState when the rect actually changed.
  void measureCap(Object? active) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var container = containerKey.currentContext?.findRenderObject();
      var item = active == null ? null : _itemKeys[active]?.currentContext?.findRenderObject();
      if (container is! RenderBox || item is! RenderBox || !item.hasSize || !container.hasSize) {
        if (capRect != null) setState(() => capRect = null);
        return;
      }
      var offset = item.localToGlobal(Offset.zero, ancestor: container);
      var rect = offset & item.size;
      if (rect != capRect) setState(() => capRect = rect);
    });
  }
}
```

- [ ] **Step 4: Implement the segmented control**

`lib/core/widgets/wiz_segmented_control.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_button.dart';
import 'wiz_cap_tracker.dart';
import 'wiz_surface.dart';

class WizSegment<T> {
  final T value;
  final String label;
  final WizIconData? icon;

  const WizSegment({required this.value, required this.label, this.icon});
}

enum WizSegmentSize { sm, md }

/// Recessed track holding one raised selector that slides between items.
class WizSegmentedControl<T> extends StatefulWidget {
  final List<WizSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool fullWidth;
  final WizSegmentSize size;

  const WizSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.fullWidth = true,
    this.size = WizSegmentSize.md,
  });

  // SegmentedControl.jsx: item height per size, track padding and gap.
  static const _height = {WizSegmentSize.sm: 36.0, WizSegmentSize.md: 44.0};
  static const double trackPad = 4;
  static const double gap = 4;

  @override
  State<WizSegmentedControl<T>> createState() => _WizSegmentedControlState<T>();
}

class _WizSegmentedControlState<T> extends State<WizSegmentedControl<T>> with WizCapTracker<WizSegmentedControl<T>> {
  @override
  Widget build(BuildContext context) {
    measureCap(widget.value);
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var h = WizSegmentedControl._height[widget.size]!;
    var fs = widget.size == WizSegmentSize.sm ? 12.0 : 13.0;
    var pill = BorderRadius.circular(wiz.space.pill);

    var items = widget.segments.map((seg) {
      var on = seg.value == widget.value;
      var ink = on ? c.textPrimary : c.textTertiary;
      var item = Semantics(
        selected: on,
        button: true,
        label: seg.label,
        child: GestureDetector(
          key: keyFor(seg.value as Object),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (on) return;
            context.feedback.play(FeedbackKind.tick);
            widget.onChanged(seg.value);
          },
          child: AnimatedScale(
            scale: on ? 1 : 0.98,
            duration: m.release,
            curve: m.settle,
            child: SizedBox(
              height: h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wiz.space.s6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (seg.icon != null) ...[
                      WizIcon(seg.icon!, size: fs + 2, color: ink),
                      SizedBox(width: wiz.space.s3),
                    ],
                    AnimatedDefaultTextStyle(
                      duration: m.ui,
                      style: wiz.type.body.copyWith(
                        fontSize: fs,
                        fontWeight: FontWeight.w700,
                        letterSpacing: fs * WizTypeTracking.segment,
                        color: ink,
                        height: 1,
                      ),
                      child: Text(seg.label.toUpperCase(), maxLines: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return widget.fullWidth ? Expanded(child: item) : item;
    }).toList();

    return WizSurface(
      spec: wiz.elevation.well,
      radius: pill,
      gradient: wizVertical(c.char1000, c.char900),
      padding: const EdgeInsets.all(WizSegmentedControl.trackPad),
      child: Stack(
        key: containerKey,
        children: [
          if (capRect != null)
            AnimatedPositioned.fromRect(
              key: const Key('wiz-cap'),
              rect: capRect!,
              duration: m.panel,
              curve: m.settle,
              child: IgnorePointer(
                child: WizSurface(
                  spec: wiz.elevation.raised,
                  radius: pill,
                  gradient: wizVertical(c.surfaceKey, c.surfaceRaised),
                ),
              ),
            ),
          Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: WizSegmentedControl.gap),
                items[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Implement the tab bar and the rail**

`lib/core/widgets/wiz_tab_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_cap_tracker.dart';
import 'wiz_surface.dart';

class WizTab<T> {
  final T value;
  final WizIconData icon;
  final String label;

  const WizTab({required this.value, required this.icon, required this.label});
}

/// Floating bottom nav on the phone: the amber cap slides to the tab you pick.
class WizTabBar<T> extends StatefulWidget {
  final List<WizTab<T>> tabs;
  final T value;
  final ValueChanged<T> onChanged;

  const WizTabBar({super.key, required this.tabs, required this.value, required this.onChanged});

  // TabBar.jsx: item square, horizontal padding, glyph size, selected scale.
  static const double itemSize = 52;
  static const double padX = 10;
  static const double glyph = 22;
  static const double selectedScale = 1.06;

  @override
  State<WizTabBar<T>> createState() => _WizTabBarState<T>();
}

class _WizTabBarState<T> extends State<WizTabBar<T>> with WizCapTracker<WizTabBar<T>> {
  @override
  Widget build(BuildContext context) {
    measureCap(widget.value);
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    return WizSurface(
      spec: wiz.elevation.key,
      radius: BorderRadius.circular(wiz.space.r5),
      gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
      height: wiz.space.tabBar,
      padding: const EdgeInsets.symmetric(horizontal: WizTabBar.padX),
      child: Stack(
        key: containerKey,
        children: [
          if (capRect != null)
            AnimatedPositioned.fromRect(
              key: const Key('wiz-cap'),
              rect: capRect!,
              duration: m.panel,
              curve: m.settle,
              child: IgnorePointer(
                child: WizSurface(
                  spec: wiz.elevation.raised,
                  radius: BorderRadius.circular(wiz.space.r3),
                  gradient: wizVertical(c.amber400, c.amber600),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var tab in widget.tabs)
                Builder(builder: (context) {
                  var on = tab.value == widget.value;
                  return Semantics(
                    label: tab.label,
                    selected: on,
                    button: true,
                    child: GestureDetector(
                      key: keyFor(tab.value as Object),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (on) return;
                        context.feedback.play(FeedbackKind.tick);
                        widget.onChanged(tab.value);
                      },
                      child: SizedBox(
                        width: WizTabBar.itemSize,
                        height: WizTabBar.itemSize,
                        child: Center(
                          child: AnimatedScale(
                            scale: on ? WizTabBar.selectedScale : 1,
                            duration: m.panel,
                            curve: m.settle,
                            child: AnimatedDefaultTextStyle(
                              duration: m.ui,
                              style: TextStyle(color: on ? c.textOnAccent : c.textTertiary),
                              child: WizIcon(tab.icon, size: WizTabBar.glyph),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}
```

`lib/core/widgets/wiz_rail.dart`:

```dart
import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_scope.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../layout/wiz_breakpoints.dart';
import '../layout/wiz_layout.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_cap_tracker.dart';
import 'wiz_surface.dart';

class WizRailItem<T> {
  final T value;
  final String label;
  final WizIconData icon;
  final String? meta;

  const WizRailItem({required this.value, required this.label, required this.icon, this.meta});
}

class WizRailSection<T> {
  final String title;
  final List<WizRailItem<T>> items;

  const WizRailSection({required this.title, required this.items});
}

/// Desktop rail: brand block, room and house navigation with a sliding
/// raised cap, footer slot. Collapses to icons with tooltips on medium
/// windows.
class WizRail<T> extends StatefulWidget {
  final Widget? brand;
  final Widget? collapsedBrand;
  final List<WizRailSection<T>> sections;
  final T? value;
  final ValueChanged<T> onChanged;
  final Widget? footer;
  final bool collapsed;
  final double? width;

  const WizRail({
    super.key,
    this.brand,
    this.collapsedBrand,
    required this.sections,
    required this.value,
    required this.onChanged,
    this.footer,
    this.collapsed = false,
    this.width,
  });

  // Sidebar.jsx: item height, glyph size, item padding.
  static const double itemHeight = 42;
  static const double glyph = 18;
  static const double itemPadX = 12;
  static const double pressedScale = 0.98;

  @override
  State<WizRail<T>> createState() => _WizRailState<T>();
}

class _WizRailState<T> extends State<WizRail<T>> with WizCapTracker<WizRail<T>> {
  Object? _down;

  @override
  Widget build(BuildContext context) {
    measureCap(widget.value);
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var s = wiz.space;
    WidthClass? cls;
    try {
      cls = context.layout.widthClass;
    } catch (_) {
      cls = null;
    }
    var width = widget.width ??
        (widget.collapsed ? s.railIcon : (cls == WidthClass.wide ? s.railWide : s.rail));
    var radius = BorderRadius.circular(s.r2);

    Widget item(WizRailItem<T> it) {
      var on = it.value == widget.value;
      var row = Row(
        mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: m.ui,
            style: TextStyle(color: on ? c.amber400 : c.textTertiary),
            child: WizIcon(it.icon, size: WizRail.glyph),
          ),
          if (!widget.collapsed) ...[
            SizedBox(width: s.s5 - 1),
            Expanded(
              child: Text(
                it.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: wiz.type.body.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.075,
                  color: on ? c.textPrimary : c.textSecondary,
                  height: 1,
                ),
              ),
            ),
            if (it.meta != null)
              Text(it.meta!, style: wiz.type.mono.copyWith(fontSize: 11, color: c.textTertiary, height: 1)),
          ],
        ],
      );
      Widget body = Semantics(
        selected: on,
        button: true,
        label: it.label,
        child: GestureDetector(
          key: keyFor(it.value as Object),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = it.value),
          onTapUp: (_) => setState(() => _down = null),
          onTapCancel: () => setState(() => _down = null),
          onTap: () {
            if (on) return;
            context.feedback.play(FeedbackKind.tick);
            widget.onChanged(it.value);
          },
          child: AnimatedScale(
            scale: _down == it.value ? WizRail.pressedScale : 1,
            duration: m.release,
            curve: m.settle,
            child: SizedBox(
              height: WizRail.itemHeight,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: WizRail.itemPadX), child: row),
            ),
          ),
        ),
      );
      if (widget.collapsed) body = Tooltip(message: it.label, child: body);
      return body;
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: wizVertical(c.char900, c.char950),
        border: Border(right: BorderSide(color: c.edgeHairline, width: s.hairline)),
      ),
      padding: EdgeInsets.all(widget.collapsed ? s.s4 : s.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.collapsed ? widget.collapsedBrand != null : widget.brand != null) ...[
            widget.collapsed ? widget.collapsedBrand! : widget.brand!,
            SizedBox(height: s.s8),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                key: containerKey,
                children: [
                  if (capRect != null)
                    AnimatedPositioned.fromRect(
                      key: const Key('wiz-cap'),
                      rect: capRect!,
                      duration: m.panel,
                      curve: m.settle,
                      child: IgnorePointer(
                        child: WizSurface(
                          spec: wiz.elevation.raised,
                          radius: radius,
                          gradient: wizVertical(c.surfaceKey, c.surfaceRaised),
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < widget.sections.length; i++) ...[
                        if (i > 0) SizedBox(height: s.s8),
                        if (!widget.collapsed)
                          Padding(
                            padding: EdgeInsets.only(left: s.s3, bottom: s.s3),
                            child: Text(widget.sections[i].title.toUpperCase(), style: wiz.type.label.copyWith(color: c.textTertiary)),
                          ),
                        for (var it in widget.sections[i].items) ...[item(it), SizedBox(height: s.s3)],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.footer != null && !widget.collapsed) ...[SizedBox(height: s.s8), widget.footer!],
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_caps_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets test/core/widgets
git commit -m "feat(kit): segmented control, tab bar and rail with one travelling cap"
```

---

### Task 18: WizTopBar, WizListRow, WizBadge, WizStatTile, WizReadout, WizEmptyState

**Files:**
- Create: `lib/core/widgets/wiz_top_bar.dart`, `lib/core/widgets/wiz_list_row.dart`, `lib/core/widgets/wiz_badge.dart`, `lib/core/widgets/wiz_stat_tile.dart`, `lib/core/widgets/wiz_readout.dart`, `lib/core/widgets/wiz_empty_state.dart`
- Test: `test/core/widgets/wiz_rows_test.dart`

**Interfaces:**
- Produces: `class WizTopBar { title, subtitle, leading, trailing }`; `class WizListRow { icon (WizIconData?), iconWidget (Widget?), title, meta, trailing, active, onTap, onLongPress }`; `enum WizBadgeTone { neutral, accent, online, danger }`; `class WizBadge { label, tone, dot }`; `class WizStatTile { icon (WizIconData), label, value, unit, accent }`; `enum WizReadoutSize { sm, md, lg }`; `enum WizReadoutTone { normal, accent, muted }`; `class WizReadout { value, unit, label, size, tone, mono, center }`; `class WizEmptyState { icon, title, body, action }`.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_rows_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/wiz_badge.dart';
import 'package:wizctl_app/core/widgets/wiz_empty_state.dart';
import 'package:wizctl_app/core/widgets/wiz_list_row.dart';
import 'package:wizctl_app/core/widgets/wiz_stat_tile.dart';
import 'package:wizctl_app/core/widgets/wiz_top_bar.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('top bar shows title and subtitle with slots', (tester) async {
    await tester.pumpWidget(wizTestApp(const SizedBox(
      width: 350,
      child: WizTopBar(title: 'Living Room', subtitle: '3 lights', trailing: Text('T')),
    )));
    expect(find.text('Living Room'), findsOneWidget);
    expect(find.text('3 lights'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(tester.getSize(find.byType(WizTopBar)).height, greaterThanOrEqualTo(56));
  });

  testWidgets('list rows tap and long-press with feedback', (tester) async {
    var feedback = RecordingFeedbackService();
    var taps = 0, longs = 0;
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: WizListRow(icon: WizIcons.sofa, title: 'Living Room', meta: '3 lights · 1 on',
          onTap: () => taps++, onLongPress: () => longs++),
    ), feedback: feedback));
    await tester.tap(find.text('Living Room'));
    await tester.longPress(find.text('Living Room'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(longs, 1);
    expect(feedback.played.first, FeedbackKind.press);
  });

  testWidgets('badge, stat tile and empty state render their copy', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const WizBadge(label: 'Live', tone: WizBadgeTone.online, dot: true),
        const WizStatTile(icon: WizIcons.thermometer, label: 'Colour temp', value: '2700', unit: 'K'),
        WizEmptyState(icon: WizIcons.radio, title: 'Nothing found yet', body: 'Lights answer on your local network.', action: const Text('A')),
      ]),
    )));
    expect(find.text('LIVE'), findsOneWidget);
    expect(tester.getSize(find.byType(WizBadge)).height, 22);
    expect(find.text('COLOUR TEMP'), findsOneWidget);
    expect(find.text('2700'), findsOneWidget);
    expect(find.text('Nothing found yet'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_rows_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the top bar and list row**

`lib/core/widgets/wiz_top_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';

/// Screen header: optional leading key, display-face title with sub-line,
/// trailing slot.
class WizTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const WizTopBar({super.key, required this.title, this.subtitle, this.leading, this.trailing});

  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Row(
        children: [
          if (leading != null) ...[leading!, SizedBox(width: wiz.space.s5 + wiz.space.s1)],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: wiz.type.title.copyWith(color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Padding(
                    padding: EdgeInsets.only(top: wiz.space.s1),
                    child: Text(subtitle!, style: wiz.type.bodySm.copyWith(color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: wiz.space.s5 + wiz.space.s1), trailing!],
        ],
      ),
    );
  }
}
```

`lib/core/widgets/wiz_list_row.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

/// One line in a list of rooms, lights or settings: leading icon well,
/// title, meta, trailing slot. Rows have no dividers; lists use gaps.
class WizListRow extends StatelessWidget {
  final WizIconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? meta;
  final Widget? trailing;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WizListRow({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.meta,
    this.trailing,
    this.active = false,
    this.onTap,
    this.onLongPress,
  });

  // ListRow.jsx: icon well size and glyph.
  static const double well = 40;
  static const double glyph = 20;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var interactive = onTap != null || onLongPress != null;

    Widget body(bool pressed) => WizSurface(
      spec: pressed ? wiz.elevation.pressed : (active ? wiz.elevation.raised : wiz.elevation.panel),
      radius: BorderRadius.circular(wiz.space.r3),
      gradient: active ? wizVertical(c.surfaceKey, c.surfaceRaised) : wizVertical(c.surfaceRaised, c.surfacePanel),
      glow: active ? [BoxShadow(color: c.amber500.withValues(alpha: .28), spreadRadius: 1)] : const [],
      padding: EdgeInsets.symmetric(vertical: wiz.space.s5, horizontal: wiz.space.s5 + wiz.space.s1),
      child: Row(
        children: [
          if (icon != null || iconWidget != null) ...[
            WizSurface(
              spec: wiz.elevation.well,
              radius: BorderRadius.circular(wiz.space.r2),
              color: c.char1000,
              width: well,
              height: well,
              alignment: Alignment.center,
              child: iconWidget ?? WizIcon(icon!, size: glyph, color: active ? c.amber400 : c.textTertiary),
            ),
            SizedBox(width: wiz.space.s5 + wiz.space.s1),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: wiz.type.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.08, color: c.textPrimary, height: 1.25)),
                if (meta != null)
                  Padding(
                    padding: EdgeInsets.only(top: wiz.space.s1 / 2),
                    child: Text(meta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: wiz.type.bodySm.copyWith(color: c.textTertiary)),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: wiz.space.s5), trailing!],
        ],
      ),
    );

    if (!interactive) return body(false);
    return WizPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: wiz.motion.pressScale,
      semanticsLabel: title,
      arenaResolved: true,
      builder: (context, state) => body(state.pressed),
    );
  }
}
```

`WizListRow` uses `arenaResolved: true` so a toggle in its trailing slot does not sink the whole row. Add that parameter to `WizPressable` now (`lib/core/widgets/wiz_pressable.dart`): a `final bool arenaResolved;` (default `false`) constructor parameter; in `build`, when `arenaResolved` is true, drop the `Listener` and instead pass `onTapDown: (_) => _down()`, `onTapUp: (_) => _up()`, `onTapCancel: _up` to the `GestureDetector`, so the sink only happens once the tap recognizer has won the arena.

- [ ] **Step 4: Implement badge, stat tile, readout, empty state**

`lib/core/widgets/wiz_badge.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

enum WizBadgeTone { neutral, accent, online, danger }

/// Small engraved status pill: reachability, bulb class, scene state. The
/// dot breathes for live tones only; it is the only looping animation apart
/// from a powered light's emission.
class WizBadge extends StatelessWidget {
  final String label;
  final WizBadgeTone tone;
  final bool dot;

  const WizBadge({super.key, required this.label, this.tone = WizBadgeTone.neutral, this.dot = false});

  static const double height = 22;
  static const double dotSize = 6;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var (fg, dotColor) = switch (tone) {
      WizBadgeTone.neutral => (c.textTertiary, c.signalOffline),
      WizBadgeTone.accent => (c.amber400, c.amber500),
      WizBadgeTone.online => (c.signalOnline, c.signalOnline),
      WizBadgeTone.danger => (c.signalDanger, c.signalDanger),
    };
    var live = dot && tone != WizBadgeTone.neutral;
    return WizSurface(
      spec: wiz.elevation.well,
      radius: BorderRadius.circular(wiz.space.pill),
      color: Colors.black.withValues(alpha: .35),
      height: height,
      padding: EdgeInsets.symmetric(horizontal: wiz.space.s4 + wiz.space.s1 / 2),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            _Dot(color: dotColor, live: live),
            SizedBox(width: wiz.space.s3),
          ],
          Text(label.toUpperCase(), style: wiz.type.caption.copyWith(fontWeight: FontWeight.w600, color: fg, height: 1)),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final bool live;

  const _Dot({required this.color, required this.live});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: context.wiz.motion.ping);

  @override
  void initState() {
    super.initState();
    if (widget.live) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.live && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!widget.live) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        var t = (widget.live && !reduced) ? _pulse.value : 0.0;
        return Opacity(
          opacity: 1 - 0.6 * t,
          child: Transform.scale(
            scale: 1 - 0.28 * t,
            child: Container(
              width: WizBadge.dotSize,
              height: WizBadge.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: widget.live ? [BoxShadow(color: widget.color, blurRadius: 8)] : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

`lib/core/widgets/wiz_stat_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// Small instrument tile: caps label with glyph, then a display-face value.
class WizStatTile extends StatelessWidget {
  final WizIconData icon;
  final String label;
  final String value;
  final String? unit;
  final bool accent;

  const WizStatTile({super.key, required this.icon, required this.label, required this.value, this.unit, this.accent = false});

  // StatTile.jsx: value size, unit size, glyph size.
  static const double valueSize = 28;
  static const double unitSize = 13;
  static const double glyph = 14;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    return WizSurface(
      spec: wiz.elevation.panel,
      radius: BorderRadius.circular(wiz.space.r3),
      gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
      padding: EdgeInsets.symmetric(vertical: wiz.space.s5 + wiz.space.s1, horizontal: wiz.space.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            WizIcon(icon, size: glyph, color: c.textTertiary),
            SizedBox(width: wiz.space.s3 + wiz.space.s1 / 2),
            Expanded(child: Text(label.toUpperCase(), style: wiz.type.caption.copyWith(color: c.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          SizedBox(height: wiz.space.s5),
          Text.rich(
            TextSpan(
              text: value,
              style: wiz.type.readout.copyWith(fontSize: valueSize, fontWeight: FontWeight.w800, color: accent ? c.amber400 : c.textPrimary),
              children: [
                if (unit != null)
                  TextSpan(text: unit, style: wiz.type.body.copyWith(fontSize: unitSize, fontWeight: FontWeight.w600, color: c.textTertiary)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

`lib/core/widgets/wiz_readout.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';

enum WizReadoutSize { sm, md, lg }

enum WizReadoutTone { normal, accent, muted }

/// Instrument readout: large display numeral with a small unit, optional
/// caps label above. Numeric readouts never animate; values snap.
class WizReadout extends StatelessWidget {
  final String value;
  final String? unit;
  final String? label;
  final WizReadoutSize size;
  final WizReadoutTone tone;
  final bool mono;
  final bool center;

  const WizReadout({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.size = WizReadoutSize.md,
    this.tone = WizReadoutTone.normal,
    this.mono = false,
    this.center = false,
  });

  static const double lgSize = 48;
  static const double unitRatio = 0.44;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var fs = switch (size) {
      WizReadoutSize.sm => wiz.type.readoutSm.fontSize!,
      WizReadoutSize.md => wiz.type.readout.fontSize!,
      WizReadoutSize.lg => lgSize,
    };
    var color = switch (tone) {
      WizReadoutTone.accent => c.amber400,
      WizReadoutTone.muted => c.textTertiary,
      WizReadoutTone.normal => c.textPrimary,
    };
    var style = (mono ? wiz.type.code : wiz.type.readout).copyWith(fontSize: fs, fontWeight: mono ? FontWeight.w500 : FontWeight.w800, height: 1, color: color);
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: wiz.type.caption.copyWith(color: c.textTertiary)),
          SizedBox(height: wiz.space.s2),
        ],
        Text.rich(TextSpan(text: value, style: style, children: [
          if (unit != null) TextSpan(text: unit, style: style.copyWith(fontSize: fs * unitRatio, fontWeight: FontWeight.w600, color: c.textTertiary)),
        ])),
      ],
    );
  }
}
```

`lib/core/widgets/wiz_empty_state.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// Zero state: recessed glyph well, one line of plain explanation, one action.
class WizEmptyState extends StatelessWidget {
  final WizIconData icon;
  final String title;
  final String? body;
  final Widget? action;

  const WizEmptyState({super.key, required this.icon, required this.title, this.body, this.action});

  // EmptyState.jsx: well diameter, glyph, body max width.
  static const double well = 76;
  static const double glyph = 30;
  static const double bodyMaxWidth = 320;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: wiz.space.s10, horizontal: wiz.space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WizSurface(
            spec: wiz.elevation.wellDeep,
            radius: BorderRadius.circular(well / 2),
            gradient: wizVertical(c.char1000, c.char900),
            width: well,
            height: well,
            alignment: Alignment.center,
            child: WizIcon(icon, size: glyph, color: c.textTertiary),
          ),
          SizedBox(height: wiz.space.s6),
          Text(title, textAlign: TextAlign.center, style: wiz.type.heading.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary)),
          if (body != null) ...[
            SizedBox(height: wiz.space.s3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: bodyMaxWidth),
              child: Text(body!, textAlign: TextAlign.center, style: wiz.type.body.copyWith(color: c.textTertiary)),
            ),
          ],
          if (action != null) ...[SizedBox(height: wiz.space.s6), action!],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/widgets && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets test/core/widgets
git commit -m "feat(kit): top bar, list row, badge, stat tile, readout, empty state"
```

---

### Task 19: WizFilamentBar, WizSkeleton, WizSpinner

**Files:**
- Create: `lib/core/widgets/wiz_filament_bar.dart`, `lib/core/widgets/wiz_skeleton.dart`, `lib/core/widgets/wiz_spinner.dart`
- Test: `test/core/widgets/wiz_loaders_test.dart`

**Interfaces:**
- Produces: `class WizFilamentBar { value (double? in 0..1; null = indeterminate), label, thickness (6) }`; `class WizSkeleton { width (double?), height (16), circle (bool) }`; `class WizSpinner { size (22), accent (bool) }`.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_loaders_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_skeleton.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('determinate filament fills proportionally and prints the percentage', (tester) async {
    await tester.pumpWidget(wizTestApp(const SizedBox(width: 300, child: WizFilamentBar(value: 0.5, label: 'Sweeping subnet'))));
    await tester.pumpAndSettle();
    expect(find.text('SWEEPING SUBNET'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    var track = tester.getRect(find.byKey(const Key('wiz-filament-track')));
    var fill = tester.getRect(find.byKey(const Key('wiz-filament-fill')));
    expect(fill.width, closeTo(track.width * 0.5, 1));
  });

  testWidgets('indeterminate filament keeps moving', (tester) async {
    await tester.pumpWidget(wizTestApp(const SizedBox(width: 300, child: WizFilamentBar(label: 'Discovering'))));
    await tester.pump();
    var a = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    await tester.pump(const Duration(milliseconds: 400));
    var b = tester.getRect(find.byKey(const Key('wiz-filament-hot')));
    expect(a.left, isNot(closeTo(b.left, 0.5)));
    expect(find.text('%'), findsNothing);
  });

  testWidgets('skeleton and spinner sizes', (tester) async {
    await tester.pumpWidget(wizTestApp(const Row(mainAxisSize: MainAxisSize.min, children: [
      WizSkeleton(height: 40, circle: true),
      WizSkeleton(width: 120, height: 14),
      WizSpinner(),
    ])));
    var sizes = tester.widgetList(find.byType(WizSkeleton)).map((w) => tester.getSize(find.byWidget(w))).toList();
    expect(sizes[0], const Size(40, 40));
    expect(sizes[1], const Size(120, 14));
    expect(tester.getSize(find.byType(WizSpinner)), const Size(22, 22));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_loaders_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/widgets/wiz_filament_bar.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// The house loader: a tungsten filament heating along a recessed wire.
/// Indeterminate by default, a hot spot travels the wire; pass [value] for a
/// determinate fill. Current flowing, not a web spinner.
class WizFilamentBar extends StatefulWidget {
  final double? value;
  final String? label;
  final double thickness;

  const WizFilamentBar({super.key, this.value, this.label, this.thickness = 6});

  // FilamentBar.jsx: hot spot width fraction, travel range, tick spacing.
  static const double hotWidth = 0.38;
  static const double travelFrom = -1.05;
  static const double travelTo = 2.05;
  static const double tickSpacing = 4;

  @override
  State<WizFilamentBar> createState() => _WizFilamentBarState();
}

class _WizFilamentBarState extends State<WizFilamentBar> with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(vsync: this, duration: context.wiz.motion.filament);

  @override
  void initState() {
    super.initState();
    if (widget.value == null) _run.repeat();
  }

  @override
  void didUpdateWidget(WizFilamentBar old) {
    super.didUpdateWidget(old);
    if (widget.value == null && !_run.isAnimating) _run.repeat();
    if (widget.value != null) _run.stop();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var value = widget.value;
    var reduced = MediaQuery.disableAnimationsOf(context);
    var pill = BorderRadius.circular(wiz.space.pill);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: EdgeInsets.only(bottom: wiz.space.s4),
            child: Row(children: [
              Expanded(child: Text(widget.label!.toUpperCase(), style: wiz.type.label.copyWith(color: c.textTertiary))),
              if (value != null) Text('${(value * 100).round()}%', style: wiz.type.mono.copyWith(color: c.textTertiary)),
            ]),
          ),
        Semantics(
          label: widget.label,
          value: value == null ? null : '${(value * 100).round()}%',
          child: LayoutBuilder(
            builder: (context, constraints) {
              var w = constraints.maxWidth;
              return SizedBox(
                key: const Key('wiz-filament-track'),
                height: widget.thickness,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: WizSurface(
                        spec: wiz.elevation.well,
                        radius: pill,
                        gradient: wizVertical(c.char1000, c.char900),
                        child: CustomPaint(painter: _TickPainter(c.edgeHairline)),
                      ),
                    ),
                    if (value != null)
                      AnimatedPositioned(
                        key: const Key('wiz-filament-fill'),
                        duration: m.light,
                        curve: m.tactile,
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: (value.clamp(0, 1)) * w,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: pill,
                            gradient: LinearGradient(colors: [c.amber700, c.amber300]),
                            boxShadow: [BoxShadow(color: c.amber500.withValues(alpha: .7), blurRadius: 14, spreadRadius: -1)],
                          ),
                        ),
                      )
                    else
                      AnimatedBuilder(
                        animation: _run,
                        builder: (context, _) {
                          var t = reduced ? 0.5 : _run.value;
                          var hotW = w * WizFilamentBar.hotWidth;
                          var x = hotW * (WizFilamentBar.travelFrom + (WizFilamentBar.travelTo - WizFilamentBar.travelFrom) * t);
                          var heat = 0.62 + 0.38 * (0.5 - 0.5 * math.cos(2 * math.pi * t));
                          return Positioned(
                            key: const Key('wiz-filament-hot'),
                            left: x,
                            top: 0,
                            bottom: 0,
                            width: hotW,
                            child: Opacity(
                              opacity: heat,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: pill,
                                  gradient: LinearGradient(colors: [c.amber500.withValues(alpha: 0), c.amber300, c.amber500.withValues(alpha: 0)]),
                                  boxShadow: [BoxShadow(color: c.amber500.withValues(alpha: .55), blurRadius: 16)],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;

  _TickPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += WizFilamentBar.tickSpacing) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}
```

`lib/core/widgets/wiz_skeleton.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// Empty machined well standing in for content that has not arrived. A faint
/// sheen crosses it. First loads use skeletons in the geometry of the real
/// row so the layout never collapses.
class WizSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final bool circle;

  const WizSkeleton({super.key, this.width, this.height = 16, this.circle = false});

  @override
  State<WizSkeleton> createState() => _WizSkeletonState();
}

class _WizSkeletonState extends State<WizSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: context.wiz.motion.sheen)..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var reduced = MediaQuery.disableAnimationsOf(context);
    var radius = BorderRadius.circular(widget.circle ? widget.height / 2 : wiz.space.r2);
    return WizSurface(
      spec: wiz.elevation.well,
      radius: radius,
      gradient: wizVertical(c.char1000, c.char900),
      width: widget.circle ? widget.height : widget.width,
      height: widget.height,
      child: widget.width == null && !widget.circle
          ? const SizedBox(width: double.infinity)
          : AnimatedBuilder(
              animation: _sheen,
              builder: (context, _) => FractionalTranslation(
                translation: Offset(reduced ? 0 : -1 + 2 * _sheen.value, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: .055),
                      Colors.white.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}
```

If the width is null the skeleton must still show the sheen: replace the `SizedBox` branch with the same `AnimatedBuilder` wrapped in `SizedBox(width: double.infinity)`.

`lib/core/widgets/wiz_spinner.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// A needle sweeping a recessed ring: the inline loader, only ever inside a
/// key, banner or toast.
class WizSpinner extends StatefulWidget {
  final double size;
  final bool accent;

  const WizSpinner({super.key, this.size = 22, this.accent = true});

  // Spinner.jsx: ring inset and thickness ratios, arc start.
  static const double insetRatio = 0.09;
  static const double thicknessRatio = 0.11;
  static const double arcStartDeg = 210;

  @override
  State<WizSpinner> createState() => _WizSpinnerState();
}

class _WizSpinnerState extends State<WizSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: context.wiz.motion.spin)..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var color = widget.accent ? c.amber400 : c.textSecondary;
    var reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Loading',
      child: WizSurface(
        spec: wiz.elevation.well,
        radius: BorderRadius.circular(widget.size / 2),
        gradient: wizVertical(c.char1000, c.char900),
        width: widget.size,
        height: widget.size,
        child: RotationTransition(
          turns: reduced ? const AlwaysStoppedAnimation(0) : _spin,
          child: CustomPaint(painter: _NeedlePainter(color, widget.size)),
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final Color color;
  final double size;

  _NeedlePainter(this.color, this.size);

  @override
  void paint(Canvas canvas, Size s) {
    var inset = math.max(1.0, size * WizSpinner.insetRatio);
    var thickness = math.max(1.5, size * WizSpinner.thicknessRatio);
    var rect = (Offset.zero & s).deflate(inset + thickness / 2);
    var start = WizSpinner.arcStartDeg * math.pi / 180;
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: 2 * math.pi,
        colors: [color.withValues(alpha: 0), color],
      ).createShader(rect);
    canvas.drawArc(rect, start, 2 * math.pi - start, false, paint);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.color != color || old.size != size;
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_loaders_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets test/core/widgets
git commit -m "feat(kit): filament bar, skeleton and spinner"
```

---

### Task 20: WizStatusBanner, toasts

**Files:**
- Create: `lib/core/widgets/wiz_status_banner.dart`, `lib/core/widgets/toast_controller.dart`, `lib/core/widgets/wiz_toast.dart`, `lib/core/widgets/wiz_toast_layer.dart`
- Modify: `pubspec.yaml` (`dev:fake_async`)
- Test: `test/core/widgets/wiz_status_banner_test.dart`, `test/core/widgets/toast_controller_test.dart`, `test/core/widgets/wiz_toast_layer_test.dart`

**Interfaces:**
- Produces: `enum WizStatus { loading, success, error, warn, info }`; `class WizStatusBanner { status, title, body, action }`; `enum WizToastTone { success, error, loading, info }`; `class WizToastData { id, tone, title, body, actionLabel, onAction }`; `class ToastController extends ChangeNotifier { ToastController({Duration duration = 3200 ms, int max = 3, FeedbackService? feedback}); List<WizToastData> get toasts; String push({required WizToastTone tone, required String title, String? body, String? actionLabel, VoidCallback? onAction}); String pushAfter(Duration delay, {...same}); void update(String id, {WizToastTone? tone, String? title, String? body, String? actionLabel, VoidCallback? onAction}); void dismiss(String id); }`; `enum WizToastPlacement { aboveTabBar, bottomRight }`; `class WizToastLayer { controller, placement, bottomInset }`; `class WizToast { data, onDismiss }`.
- Behaviour: `push` plays `confirm`/`reject`/`tick` for success/error/info, nothing for loading; non-loading toasts auto-dismiss after `duration`; at most `max` toasts (oldest dropped); `update` with a new tone plays that tone's sound and re-arms the timer; `pushAfter` shows nothing until `delay` elapses unless `update` or `dismiss` arrives first (an `update` shows it immediately with the new fields).

- [ ] **Step 1: Write the failing tests**

`test/core/widgets/toast_controller_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';

void main() {
  test('pushes, caps at three, and expires after 3.2 s', () {
    fakeAsync((async) {
      var feedback = RecordingFeedbackService();
      var c = ToastController(feedback: feedback);
      c.push(tone: WizToastTone.success, title: 'A');
      c.push(tone: WizToastTone.info, title: 'B');
      c.push(tone: WizToastTone.error, title: 'C');
      c.push(tone: WizToastTone.success, title: 'D');
      expect(c.toasts.map((t) => t.title), ['B', 'C', 'D']);
      expect(feedback.played, [FeedbackKind.confirm, FeedbackKind.tick, FeedbackKind.reject, FeedbackKind.confirm]);
      async.elapse(const Duration(milliseconds: 3300));
      expect(c.toasts, isEmpty);
    });
  });

  test('loading toasts stay until updated, then expire', () {
    fakeAsync((async) {
      var feedback = RecordingFeedbackService();
      var c = ToastController(feedback: feedback);
      var id = c.push(tone: WizToastTone.loading, title: 'Sending to Hallway');
      async.elapse(const Duration(seconds: 10));
      expect(c.toasts, hasLength(1));
      expect(feedback.played, isEmpty);
      c.update(id, tone: WizToastTone.error, title: 'No response after 3 tries', actionLabel: 'Retry', onAction: () {});
      expect(c.toasts.single.title, 'No response after 3 tries');
      expect(feedback.played, [FeedbackKind.reject]);
      async.elapse(const Duration(milliseconds: 3300));
      expect(c.toasts, isEmpty);
    });
  });

  test('pushAfter shows only if still pending after the delay', () {
    fakeAsync((async) {
      var c = ToastController();
      var early = c.pushAfter(const Duration(milliseconds: 600), tone: WizToastTone.loading, title: 'Sending');
      c.dismiss(early);
      async.elapse(const Duration(milliseconds: 700));
      expect(c.toasts, isEmpty);

      var late = c.pushAfter(const Duration(milliseconds: 600), tone: WizToastTone.loading, title: 'Sending');
      async.elapse(const Duration(milliseconds: 700));
      expect(c.toasts.single.title, 'Sending');

      var resolved = c.pushAfter(const Duration(milliseconds: 600), tone: WizToastTone.loading, title: 'Sending');
      c.update(resolved, tone: WizToastTone.success, title: 'Saved');
      expect(c.toasts.map((t) => t.title), contains('Saved'));
      expect(late, isNot(resolved));
    });
  });
}
```

`test/core/widgets/wiz_status_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_spinner.dart';
import 'package:wizctl_app/core/widgets/wiz_status_banner.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('banner shows copy, an action, and a spinner when loading', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const WizStatusBanner(status: WizStatus.error, title: 'Not on the home network', body: 'Join the home network.', action: Text('Retry')),
        const WizStatusBanner(status: WizStatus.loading, title: 'Sweeping 192.168.1.0/24', body: '12 of 254 addresses'),
      ]),
    )));
    expect(find.text('Not on the home network'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(WizSpinner), findsOneWidget);
  });
}
```

`test/core/widgets/wiz_toast_layer_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/core/widgets/wiz_toast.dart';
import 'package:wizctl_app/core/widgets/wiz_toast_layer.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('the layer renders the controller queue and dismisses', (tester) async {
    var c = ToastController();
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 390,
      height: 600,
      child: Stack(children: [WizToastLayer(controller: c, placement: WizToastPlacement.aboveTabBar)]),
    )));
    c.push(tone: WizToastTone.success, title: 'Cozy applied', body: 'to the whole home');
    await tester.pumpAndSettle();
    expect(find.text('Cozy applied'), findsOneWidget);
    expect(find.byType(WizToast), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.byType(WizToast), findsNothing);
    c.dispose();
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter pub add dev:fake_async && flutter test test/core/widgets/toast_controller_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement the banner**

`lib/core/widgets/wiz_status_banner.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_spinner.dart';
import 'wiz_surface.dart';

enum WizStatus { loading, success, error, warn, info }

/// Inline state band: what is happening, and what to do about it. A banner
/// is a condition; if the user can fix it, it is a banner, not a toast.
class WizStatusBanner extends StatelessWidget {
  final WizStatus status;
  final String title;
  final String? body;
  final Widget? action;

  const WizStatusBanner({super.key, required this.status, required this.title, this.body, this.action});

  // StatusBanner.jsx: icon well and glyph.
  static const double well = 30;
  static const double glyph = 16;
  static const double spinner = 18;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var (icon, color) = switch (status) {
      WizStatus.loading => (null, c.textSecondary),
      WizStatus.success => (WizIcons.check, c.signalOnline),
      WizStatus.error => (WizIcons.x, c.signalDanger),
      WizStatus.warn => (WizIcons.wifi, c.signalWarn),
      WizStatus.info => (WizIcons.terminal, c.textSecondary),
    };
    return Semantics(
      liveRegion: status == WizStatus.error,
      child: WizSurface(
        spec: wiz.elevation.well,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(c.char900, c.char950),
        padding: EdgeInsets.symmetric(vertical: wiz.space.s5, horizontal: wiz.space.s5 + wiz.space.s1),
        child: Row(
          children: [
            WizSurface(
              spec: wiz.elevation.well,
              radius: BorderRadius.circular(wiz.space.r2),
              color: c.char1000,
              width: well,
              height: well,
              alignment: Alignment.center,
              child: icon == null ? const WizSpinner(size: spinner) : WizIcon(icon, size: glyph, color: color),
            ),
            SizedBox(width: wiz.space.s5 + wiz.space.s1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: wiz.type.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.07, color: c.textPrimary)),
                  if (body != null)
                    Padding(
                      padding: EdgeInsets.only(top: wiz.space.s1 / 2),
                      child: Text(body!, style: wiz.type.bodySm.copyWith(color: c.textTertiary)),
                    ),
                ],
              ),
            ),
            if (action != null) ...[SizedBox(width: wiz.space.s5), action!],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement the toast controller**

`lib/core/widgets/toast_controller.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../feedback/feedback_kind.dart';
import '../feedback/feedback_service.dart';

enum WizToastTone { success, error, loading, info }

@immutable
class WizToastData {
  final String id;
  final WizToastTone tone;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WizToastData({
    required this.id,
    required this.tone,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  WizToastData copyWith({WizToastTone? tone, String? title, String? body, String? actionLabel, VoidCallback? onAction}) =>
      WizToastData(
        id: id,
        tone: tone ?? this.tone,
        title: title ?? this.title,
        body: body ?? this.body,
        actionLabel: actionLabel ?? this.actionLabel,
        onAction: onAction ?? this.onAction,
      );
}

/// The toast queue. Max three, 3.2 s each; loading toasts stay until updated
/// to a resolved tone, which is how a long action reports back. Success
/// plays confirm, error plays reject, info plays tick, loading is silent.
class ToastController extends ChangeNotifier {
  final Duration duration;
  final int max;
  final FeedbackService? feedback;

  final List<WizToastData> _toasts = [];
  final Map<String, Timer> _expiry = {};
  final Map<String, (Timer, WizToastData)> _pending = {};
  int _seq = 0;

  ToastController({this.duration = const Duration(milliseconds: 3200), this.max = 3, this.feedback});

  List<WizToastData> get toasts => List.unmodifiable(_toasts);

  static FeedbackKind? soundFor(WizToastTone tone) => switch (tone) {
    WizToastTone.success => FeedbackKind.confirm,
    WizToastTone.error => FeedbackKind.reject,
    WizToastTone.info => FeedbackKind.tick,
    WizToastTone.loading => null,
  };

  String _nextId() => 't${_seq++}';

  void _show(WizToastData toast) {
    var sound = soundFor(toast.tone);
    if (sound != null) feedback?.play(sound);
    _toasts.add(toast);
    while (_toasts.length > max) {
      var dropped = _toasts.removeAt(0);
      _expiry.remove(dropped.id)?.cancel();
    }
    _arm(toast);
    notifyListeners();
  }

  void _arm(WizToastData toast) {
    _expiry.remove(toast.id)?.cancel();
    if (toast.tone == WizToastTone.loading) return;
    _expiry[toast.id] = Timer(duration, () => dismiss(toast.id));
  }

  String push({required WizToastTone tone, required String title, String? body, String? actionLabel, VoidCallback? onAction}) {
    var toast = WizToastData(id: _nextId(), tone: tone, title: title, body: body, actionLabel: actionLabel, onAction: onAction);
    _show(toast);
    return toast.id;
  }

  /// Show only if still unresolved after [delay]. A write that completes
  /// quickly never surfaces a toast; one still in flight after 600 ms does.
  String pushAfter(Duration delay, {required WizToastTone tone, required String title, String? body, String? actionLabel, VoidCallback? onAction}) {
    var toast = WizToastData(id: _nextId(), tone: tone, title: title, body: body, actionLabel: actionLabel, onAction: onAction);
    _pending[toast.id] = (
      Timer(delay, () {
        var entry = _pending.remove(toast.id);
        if (entry != null) _show(entry.$2);
      }),
      toast,
    );
    return toast.id;
  }

  void update(String id, {WizToastTone? tone, String? title, String? body, String? actionLabel, VoidCallback? onAction}) {
    var pending = _pending.remove(id);
    if (pending != null) {
      pending.$1.cancel();
      _show(pending.$2.copyWith(tone: tone, title: title, body: body, actionLabel: actionLabel, onAction: onAction));
      return;
    }
    var index = _toasts.indexWhere((t) => t.id == id);
    if (index < 0) return;
    var next = _toasts[index].copyWith(tone: tone, title: title, body: body, actionLabel: actionLabel, onAction: onAction);
    _toasts[index] = next;
    if (tone != null) {
      var sound = soundFor(tone);
      if (sound != null) feedback?.play(sound);
      _arm(next);
    }
    notifyListeners();
  }

  void dismiss(String id) {
    var pending = _pending.remove(id);
    pending?.$1.cancel();
    _expiry.remove(id)?.cancel();
    var before = _toasts.length;
    _toasts.removeWhere((t) => t.id == id);
    if (_toasts.length != before) notifyListeners();
  }

  @override
  void dispose() {
    for (var t in _expiry.values) {
      t.cancel();
    }
    for (var p in _pending.values) {
      p.$1.cancel();
    }
    super.dispose();
  }
}
```

- [ ] **Step 5: Implement the toast widget and the layer**

`lib/core/widgets/wiz_toast.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'toast_controller.dart';
import 'wiz_button.dart';
import 'wiz_spinner.dart';
import 'wiz_surface.dart';

/// One toast: an event, never a condition. Rendered by [WizToastLayer].
class WizToast extends StatelessWidget {
  final WizToastData data;
  final VoidCallback? onDismiss;

  const WizToast({super.key, required this.data, this.onDismiss});

  // Toast.jsx: icon well, glyph, spinner, dismiss key.
  static const double well = 26;
  static const double glyph = 14;
  static const double spinner = 16;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var (icon, color) = switch (data.tone) {
      WizToastTone.success => (WizIcons.check, c.signalOnline),
      WizToastTone.error => (WizIcons.x, c.signalDanger),
      WizToastTone.loading => (null, c.amber400),
      WizToastTone.info => (WizIcons.zap, c.textSecondary),
    };
    return Semantics(
      liveRegion: true,
      child: WizSurface(
        spec: WizShadowSpec(
          insets: wiz.elevation.key.insets,
          outer: [...wiz.elevation.key.outer, const BoxShadow(color: Color(0xCC000000), offset: Offset(0, 18), blurRadius: 40, spreadRadius: -18)],
        ),
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
        padding: EdgeInsets.symmetric(vertical: wiz.space.s5 - wiz.space.s1 / 2, horizontal: wiz.space.s5 + wiz.space.s1 / 2),
        child: Row(
          children: [
            WizSurface(
              spec: wiz.elevation.well,
              radius: BorderRadius.circular(wiz.space.r1),
              color: c.char1000,
              width: well,
              height: well,
              alignment: Alignment.center,
              child: icon == null ? const WizSpinner(size: spinner) : WizIcon(icon, size: glyph, color: color),
            ),
            SizedBox(width: wiz.space.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.title, style: wiz.type.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: -0.07, color: c.textPrimary)),
                  if (data.body != null)
                    Padding(
                      padding: EdgeInsets.only(top: wiz.space.s1 / 2),
                      child: Text(data.body!, style: wiz.type.bodySm.copyWith(fontSize: 12, color: c.textTertiary)),
                    ),
                ],
              ),
            ),
            if (data.actionLabel != null) ...[
              SizedBox(width: wiz.space.s4),
              WizButton(label: data.actionLabel!, variant: WizButtonVariant.ghost, size: WizButtonSize.sm, onPressed: data.onAction),
            ],
            if (onDismiss != null) ...[
              SizedBox(width: wiz.space.s2),
              Semantics(
                button: true,
                label: 'Dismiss',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: SizedBox(width: wiz.space.hitMin, height: wiz.space.hitMin, child: Center(child: WizIcon(WizIcons.x, size: glyph, color: c.textTertiary))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

`lib/core/widgets/wiz_toast_layer.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'toast_controller.dart';
import 'wiz_toast.dart';

enum WizToastPlacement { aboveTabBar, bottomRight }

/// Stacks the controller's toasts at the bottom of the screen: above the tab
/// bar on the phone, bottom-right on desktop. Toasts rise in on the settle
/// curve and fade out.
class WizToastLayer extends StatefulWidget {
  final ToastController controller;
  final WizToastPlacement placement;

  /// Space to leave for the floating tab bar (its height plus float).
  final double bottomInset;

  const WizToastLayer({super.key, required this.controller, required this.placement, this.bottomInset = 0});

  static const double desktopWidth = 340;

  @override
  State<WizToastLayer> createState() => _WizToastLayerState();
}

class _WizToastLayerState extends State<WizToastLayer> {
  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var m = wiz.motion;
    var desktop = widget.placement == WizToastPlacement.bottomRight;
    return Positioned(
      left: desktop ? null : wiz.space.s6,
      right: desktop ? wiz.space.s8 : wiz.space.s6,
      bottom: (desktop ? wiz.space.s8 : wiz.space.s6) + widget.bottomInset,
      width: desktop ? WizToastLayer.desktopWidth : null,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          var toasts = widget.controller.toasts;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var toast in toasts)
                Padding(
                  padding: EdgeInsets.only(top: wiz.space.s4),
                  child: _Enter(
                    key: ValueKey(toast.id),
                    duration: m.panel,
                    curve: m.settle,
                    child: WizToast(data: toast, onDismiss: () => widget.controller.dismiss(toast.id)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Rise 10 px, scale from .97 and fade in once on mount.
class _Enter extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;

  const _Enter({super.key, required this.duration, required this.curve, required this.child});

  @override
  Widget build(BuildContext context) {
    var reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
        ),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 6: Run, format, analyze, commit**

```bash
flutter test test/core/widgets && dart format lib test && flutter analyze --fatal-infos
git add pubspec.yaml pubspec.lock lib/core/widgets test/core/widgets
git commit -m "feat(kit): status banner, toast queue and toast layer"
```

---

### Task 21: showWizSheet

**Files:**
- Create: `lib/core/widgets/wiz_sheet.dart`
- Test: `test/core/widgets/wiz_sheet_test.dart`

**Interfaces:**
- Produces: `Future<T?> showWizSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder, List<Widget>? footer, double? maxWidth})`. Bottom sheet on compact widths (grab handle, drag to dismiss, max height 86 %), centred dialog otherwise (width capped at `maxWidth` or 520). Scrim 72 % with a 6 px blur; 260 ms rise of 14 px plus fade on the settle curve; Escape and scrim tap close.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/wiz_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_sheet.dart';

import '../../support/wiz_test_app.dart';

void main() {
  Widget opener() => Builder(builder: (context) {
    return TextButton(
      onPressed: () => showWizSheet<void>(context, title: 'Add a room', builder: (_) => const Text('Body'), footer: const [Text('Cancel')]),
      child: const Text('open'),
    );
  });

  testWidgets('compact widths get a bottom sheet with a grab handle', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsOneWidget);
    expect(find.byKey(const Key('wiz-sheet-handle')), findsOneWidget);
    var sheet = tester.getRect(find.byKey(const Key('wiz-sheet')));
    expect(sheet.bottom, 844);
    expect(sheet.width, 390);
  });

  testWidgets('expanded widths get a centred dialog', (tester) async {
    await setSurface(tester, const Size(1280, 800));
    await tester.pumpWidget(wizTestApp(opener(), size: const Size(1280, 800)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiz-sheet-handle')), findsNothing);
    var sheet = tester.getRect(find.byKey(const Key('wiz-sheet')));
    expect(sheet.width, 520);
    expect(sheet.center.dx, closeTo(640, 1));
  });

  testWidgets('tapping the scrim closes', (tester) async {
    await setSurface(tester, const Size(390, 844));
    await tester.pumpWidget(wizTestApp(opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(find.text('Add a room'), findsNothing);
  });
}
```

`wizTestApp` sets a `MediaQuery` size but the route overlay measures the real test surface, so add this helper to `test/support/wiz_test_app.dart` (import `package:flutter_test/flutter_test.dart` there):

```dart
/// Sizes the test surface itself, for widgets that measure the window
/// (routes, overlays). Resets after the test.
Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/wiz_sheet_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/widgets/wiz_sheet.dart`:

```dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../layout/wiz_breakpoints.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// Bottom sheet on the phone, centred dialog on desktop. Grab handle, scrim
/// with blur, escape and scrim tap to close, drag to dismiss on the phone.
Future<T?> showWizSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  List<Widget>? footer,
  double? maxWidth,
}) {
  var wiz = context.wiz;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: wiz.motion.panel,
    pageBuilder: (context, animation, secondary) => _WizSheetRoute(
      title: title,
      body: builder(context),
      footer: footer,
      maxWidth: maxWidth,
      animation: animation,
    ),
    transitionBuilder: (context, animation, secondary, child) => child,
  );
}

class _WizSheetRoute extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? footer;
  final double? maxWidth;
  final Animation<double> animation;

  const _WizSheetRoute({required this.title, required this.body, this.footer, this.maxWidth, required this.animation});

  // Sheet.jsx: grab handle, rise distance, max height, dialog width, blur.
  static const double handleWidth = 44;
  static const double handleHeight = 4;
  static const double rise = 14;
  static const double maxHeightFraction = 0.86;
  static const double dialogWidth = 520;
  static const double blur = 6;
  static const double dismissFraction = 0.3;
  static const double dismissVelocity = 700;

  @override
  State<_WizSheetRoute> createState() => _WizSheetRouteState();
}

class _WizSheetRouteState extends State<_WizSheetRoute> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var size = MediaQuery.sizeOf(context);
    var compact = WizBreakpoints.classify(size.width).isCompact;
    var maxHeight = size.height * _WizSheetRoute.maxHeightFraction;
    var curved = CurvedAnimation(parent: widget.animation, curve: m.settle);
    var dragFraction = compact && maxHeight > 0 ? (_drag / maxHeight).clamp(0.0, 1.0) : 0.0;

    var content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact)
          Center(
            child: Container(
              key: const Key('wiz-sheet-handle'),
              width: _WizSheetRoute.handleWidth,
              height: _WizSheetRoute.handleHeight,
              margin: EdgeInsets.only(bottom: wiz.space.s5 + wiz.space.s1),
              decoration: BoxDecoration(color: c.char700, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: wiz.space.s5 + wiz.space.s1),
          child: Text(widget.title, style: wiz.type.heading.copyWith(fontWeight: FontWeight.w600, color: c.textPrimary)),
        ),
        Flexible(child: SingleChildScrollView(child: widget.body)),
        if (widget.footer != null)
          Padding(
            padding: EdgeInsets.only(top: wiz.space.s7),
            child: Row(children: [
              for (var i = 0; i < widget.footer!.length; i++) ...[
                if (i > 0) SizedBox(width: wiz.space.s4),
                i == widget.footer!.length - 1 ? Expanded(child: widget.footer![i]) : widget.footer![i],
              ],
            ]),
          ),
      ],
    );

    var radius = compact
        ? BorderRadius.vertical(top: Radius.circular(wiz.space.r5))
        : BorderRadius.circular(wiz.space.r5);
    Widget sheet = WizSurface(
      key: const Key('wiz-sheet'),
      spec: wiz.elevation.overlay,
      radius: radius,
      gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
      padding: EdgeInsets.all(wiz.space.panelPadLg),
      child: ConstrainedBox(constraints: BoxConstraints(maxHeight: maxHeight), child: content),
    );
    if (compact) {
      sheet = GestureDetector(
        onVerticalDragUpdate: (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, maxHeight)),
        onVerticalDragEnd: (d) {
          var fast = (d.primaryVelocity ?? 0) > _WizSheetRoute.dismissVelocity;
          if (fast || dragFraction > _WizSheetRoute.dismissFraction) {
            Navigator.of(context).pop();
          } else {
            setState(() => _drag = 0);
          }
        },
        child: AnimatedContainer(
          duration: _drag == 0 ? m.release : Duration.zero,
          curve: m.settle,
          transform: Matrix4.translationValues(0, _drag, 0),
          child: SizedBox(width: double.infinity, child: sheet),
        ),
      );
    } else {
      sheet = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (widget.maxWidth ?? _WizSheetRoute.dialogWidth).clamp(0, size.width - wiz.space.s8 * 2)),
        child: sheet,
      );
    }

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        var t = curved.value;
        var scrim = (1 - dragFraction) * t;
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: _WizSheetRoute.blur * scrim, sigmaY: _WizSheetRoute.blur * scrim),
                child: ColoredBox(color: c.surfaceScrim.withValues(alpha: c.surfaceScrim.a * scrim)),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: compact ? Alignment.bottomCenter : Alignment.center,
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, _WizSheetRoute.rise * (1 - t)),
                    child: Material(type: MaterialType.transparency, child: sheet),
                  ),
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

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/wiz_sheet_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/wiz_sheet.dart test/core/widgets/wiz_sheet_test.dart test/support
git commit -m "feat(kit): showWizSheet as bottom sheet or centred dialog"
```

---
### Task 22: Motion helpers: RiseIn, Breathe, fade page, reduced motion

**Files:**
- Create: `lib/core/motion/reduced_motion.dart`, `lib/core/motion/rise_in.dart`, `lib/core/motion/breathe.dart`, `lib/core/motion/wiz_fade_page.dart`
- Test: `test/core/motion/motion_test.dart`

**Interfaces:**
- Produces: `bool wizReducedMotion(BuildContext context)`; `class RiseIn extends StatefulWidget { index (int, default 0), child, enabled (true) }` (rises 12 px and fades in once on mount after `index × stagger`, skipped under reduced motion); `class Breathe extends StatefulWidget { active, child }` (opacity 0.88 to 1 over 5.5 s while active); `CustomTransitionPage<T> wizFadePage<T>({required LocalKey key, required Widget child, required WizMotion motion})` (opacity-only 300 ms enter).

- [ ] **Step 1: Write the failing test**

`test/core/motion/motion_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/motion/breathe.dart';
import 'package:wizctl_app/core/motion/rise_in.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('RiseIn starts invisible, staggers, and settles opaque', (tester) async {
    await tester.pumpWidget(wizTestApp(const Column(children: [
      RiseIn(index: 0, child: SizedBox(key: Key('a'), height: 10)),
      RiseIn(index: 2, child: SizedBox(key: Key('b'), height: 10)),
    ])));
    double opacityOf(Key key) => tester.widget<Opacity>(find.ancestor(of: find.byKey(key), matching: find.byType(Opacity)).first).opacity;
    expect(opacityOf(const Key('a')), 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(const Key('a')), greaterThan(0.3));
    expect(opacityOf(const Key('b')), lessThan(opacityOf(const Key('a'))));
    await tester.pumpAndSettle();
    expect(opacityOf(const Key('a')), 1);
    expect(opacityOf(const Key('b')), 1);
  });

  testWidgets('Breathe oscillates only while active', (tester) async {
    await tester.pumpWidget(wizTestApp(const Breathe(active: true, child: SizedBox(key: Key('x'), height: 10))));
    double opacity() => tester.widget<Opacity>(find.ancestor(of: find.byKey(const Key('x')), matching: find.byType(Opacity)).first).opacity;
    var a = opacity();
    await tester.pump(const Duration(milliseconds: 2750));
    var b = opacity();
    expect(a, isNot(closeTo(b, 0.01)));
    expect(b, inInclusiveRange(0.88, 1));
    await tester.pumpWidget(wizTestApp(const Breathe(active: false, child: SizedBox(key: Key('x'), height: 10))));
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(), 1);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/motion`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/motion/reduced_motion.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Honour the system "reduce motion" setting: staggers, breathe and other
/// decorative motion are skipped; state changes still snap.
bool wizReducedMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);
```

`lib/core/motion/rise_in.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'reduced_motion.dart';

/// Content load-in: rise 12 px and fade over 360 ms, staggered 55 ms per
/// item. Runs once on first build only; rebuilds never replay it.
class RiseIn extends StatefulWidget {
  final int index;
  final Widget child;
  final bool enabled;

  const RiseIn({super.key, this.index = 0, required this.child, this.enabled = true});

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: context.wiz.motion.loadIn);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: context.wiz.motion.tactile);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled || wizReducedMotion(context)) {
      _c.value = 1;
      return;
    }
    Future<void>.delayed(context.wiz.motion.stagger * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var rise = context.wiz.motion.riseDistance;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, rise * (1 - _t.value)), child: child),
      ),
      child: widget.child,
    );
  }
}
```

`lib/core/motion/breathe.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'reduced_motion.dart';

/// A powered light's slow emission breathe: opacity 0.88 to 1 over 5.5 s,
/// only while [active]. Together with the badge pulse, the only loops in
/// the product.
class Breathe extends StatefulWidget {
  final bool active;
  final Widget child;

  const Breathe({super.key, required this.active, required this.child});

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: context.wiz.motion.breathe);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Breathe old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var min = context.wiz.motion.breatheMin;
    var curve = CurvedAnimation(parent: _c, curve: context.wiz.motion.tactile);
    var reduced = wizReducedMotion(context);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: (!widget.active || reduced) ? 1 : 1 - (1 - min) * curve.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
```

`lib/core/motion/wiz_fade_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wiz_motion.dart';

/// Screen enter: opacity only, 300 ms on the tactile curve. Nothing slides.
CustomTransitionPage<T> wizFadePage<T>({required LocalKey key, required Widget child, required WizMotion motion}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: motion.screenEnter,
    reverseTransitionDuration: motion.ui,
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(opacity: CurvedAnimation(parent: animation, curve: motion.tactile), child: child),
  );
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/motion && dart format lib test && flutter analyze --fatal-infos
git add lib/core/motion test/core/motion
git commit -m "feat(motion): rise-in stagger, breathe, fade page, reduced motion"
```

---

### Task 23: LightCard and RoomCard

**Files:**
- Create: `lib/core/widgets/light_card.dart`, `lib/core/widgets/room_card.dart`
- Test: `test/core/widgets/cards_test.dart`

**Interfaces:**
- Consumes: `WizPressable(arenaResolved: true)` (Task 18), `WizToggle`, `WizSlider`, `WizGlow`, `WizSurface`, `WizIcon`, `plural`.
- Produces: `enum WizBrightnessControl { rail, meter, none }`; `class LightCard { name, meta, icon (WizIconData), on, unreachable, brightness (double), control, onToggle (ValueChanged<bool>?), onBrightness (ValueChanged<double>?), onBrightnessEnd, selected, onTap }`; `class RoomCard { name, icon, lightCount, onCount, on, onToggle, onTap }`.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/cards_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/core/widgets/wiz_slider.dart';
import 'package:wizctl_app/core/widgets/wiz_toggle.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a lit light card shows the rail; a plug shows none; unreachable shows the line', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        LightCard(name: 'Ceiling dome light', meta: 'Cozy', icon: WizIcons.lampCeiling, on: true, brightness: 70, onToggle: (_) {}, onBrightness: (_) {}),
        LightCard(name: 'Plug by the TV', meta: 'Power on', icon: WizIcons.power, on: true, brightness: 100, control: WizBrightnessControl.none, onToggle: (_) {}),
        LightCard(name: 'Hallway', meta: '192.168.1.118', icon: WizIcons.lightbulb, on: false, unreachable: true, brightness: 50, onToggle: (_) {}),
      ]),
    )));
    expect(find.byType(WizSlider), findsOneWidget);
    expect(find.text('No response on the local network'), findsOneWidget);
    expect(find.byType(WizToggle), findsNWidgets(3));
  });

  testWidgets('tapping the toggle does not open the card', (tester) async {
    var opened = 0;
    var toggled = 0;
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: LightCard(name: 'Bedside bulb', meta: '2700K white', icon: WizIcons.lightbulb, on: false, brightness: 30,
          onToggle: (_) => toggled++, onTap: () => opened++),
    )));
    await tester.tap(find.byType(WizToggle));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(opened, 0);
    await tester.tap(find.text('Bedside bulb'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('room card counts', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 170,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        RoomCard(name: 'Living Room', icon: WizIcons.sofa, lightCount: 3, onCount: 2, on: true, onToggle: (_) {}, onTap: () {}),
        RoomCard(name: 'Bedroom', icon: WizIcons.bed, lightCount: 1, onCount: 0, on: false, onToggle: (_) {}, onTap: () {}),
      ]),
    )));
    expect(find.text('3 lights · 2 on'), findsOneWidget);
    expect(find.text('1 light · all off'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/cards_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement LightCard**

`lib/core/widgets/light_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_slider.dart';
import 'wiz_surface.dart';
import 'wiz_toggle.dart';

enum WizBrightnessControl { rail, meter, none }

/// A single light: name, mode or address meta, power switch, and brightness
/// as a rail (phone) or a read-only meter (desktop grid). A plug shows
/// neither. Emits the amber ring while lit; drops to 55 % when unreachable.
class LightCard extends StatelessWidget {
  final String name;
  final String? meta;
  final WizIconData icon;
  final bool on;
  final bool unreachable;
  final double brightness;
  final WizBrightnessControl control;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<double>? onBrightness;
  final ValueChanged<double>? onBrightnessEnd;
  final bool selected;
  final VoidCallback? onTap;

  const LightCard({
    super.key,
    required this.name,
    this.meta,
    this.icon = WizIcons.lightbulb,
    required this.on,
    this.unreachable = false,
    required this.brightness,
    this.control = WizBrightnessControl.rail,
    this.onToggle,
    this.onBrightness,
    this.onBrightnessEnd,
    this.selected = false,
    this.onTap,
  });

  // LightCard.jsx: icon well, glyph, meter thickness, unreachable opacity.
  static const double well = 46;
  static const double glyph = 22;
  static const double meter = 6;
  static const double unreachableOpacity = 0.55;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var lit = on && !unreachable;
    var pct = brightness.round().clamp(0, 100);
    var showRail = lit && control == WizBrightnessControl.rail;
    var showMeter = lit && control == WizBrightnessControl.meter;
    var radius = BorderRadius.circular(wiz.space.r4);

    var header = Row(
      children: [
        AnimatedContainer(
          duration: m.light,
          curve: m.tactile,
          width: well,
          height: well,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(wiz.space.r2),
            gradient: lit
                ? RadialGradient(center: const Alignment(0, -0.4), colors: [c.amber400, c.amber700])
                : null,
            color: lit ? null : c.char1000,
            boxShadow: lit ? [BoxShadow(color: c.amber500.withValues(alpha: .7), blurRadius: 20, spreadRadius: -4)] : null,
          ),
          child: Center(child: WizIcon(icon, size: glyph, color: lit ? c.textOnAccent : c.textTertiary)),
        ),
        SizedBox(width: wiz.space.s5 + wiz.space.s1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: wiz.type.body.copyWith(fontSize: 16.5, fontWeight: FontWeight.w600, letterSpacing: -0.08, height: 1.2, color: c.textPrimary)),
              if (meta != null)
                Padding(
                  padding: EdgeInsets.only(top: wiz.space.s1),
                  child: Text(meta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: wiz.type.mono.copyWith(fontSize: 11, color: c.textTertiary)),
                ),
            ],
          ),
        ),
        SizedBox(width: wiz.space.s5),
        WizToggle(value: lit, onChanged: onToggle, enabled: !unreachable && onToggle != null, semanticsLabel: name),
      ],
    );

    Widget? second;
    if (showRail) {
      second = WizSlider(value: brightness, min: 10, max: 100, onChanged: onBrightness ?? (_) {}, onChangeEnd: onBrightnessEnd, label: 'Brightness', readout: '$pct%');
    } else if (showMeter) {
      second = Row(children: [
        Expanded(
          child: WizSurface(
            spec: wiz.elevation.well,
            radius: BorderRadius.circular(wiz.space.pill),
            gradient: wizVertical(c.char1000, c.char900),
            height: meter,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: m.light,
                curve: m.tactile,
                widthFactor: pct / 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(wiz.space.pill), gradient: LinearGradient(colors: [c.amber700, c.amber300])),
                  child: const SizedBox(height: meter),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: wiz.space.s5),
        Text.rich(TextSpan(
          text: '$pct',
          style: wiz.type.readoutSm.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.27, color: c.amber400),
          children: [TextSpan(text: '%', style: TextStyle(fontSize: 10.5, color: c.textTertiary))],
        )),
      ]);
    } else if (unreachable) {
      second = Row(children: [
        WizIcon(WizIcons.wifi, size: 15, color: c.signalDanger),
        SizedBox(width: wiz.space.s3 + wiz.space.s1 / 2),
        Expanded(child: Text('No response on the local network', style: wiz.type.bodySm.copyWith(color: c.signalDanger))),
      ]);
    }

    Widget card(bool pressed) => AnimatedOpacity(
      opacity: unreachable ? unreachableOpacity : 1,
      duration: m.ui,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: WizGlow(on: lit, shadows: wiz.elevation.glowAmber, radius: radius)),
          WizSurface(
            spec: pressed ? wiz.elevation.pressed : wiz.elevation.panel,
            radius: radius,
            gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
            glow: selected ? [BoxShadow(color: c.amber500, spreadRadius: wiz.space.keyBorder)] : const [],
            padding: EdgeInsets.all(wiz.space.panelPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                if (second != null) ...[SizedBox(height: wiz.space.s5 + wiz.space.s1), second],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card(false);
    return WizPressable(
      onTap: onTap,
      scale: m.cardScale,
      semanticsLabel: name,
      arenaResolved: true,
      builder: (context, state) => card(state.pressed),
    );
  }
}
```

- [ ] **Step 4: Implement RoomCard**

`lib/core/widgets/room_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../util/plural.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';
import 'wiz_toggle.dart';

/// Room summary tile: room glyph, light count, how many are on, master switch.
class RoomCard extends StatelessWidget {
  final String name;
  final WizIconData icon;
  final int lightCount;
  final int onCount;
  final bool on;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.name,
    required this.icon,
    required this.lightCount,
    required this.onCount,
    required this.on,
    this.onToggle,
    this.onTap,
  });

  // RoomCard.jsx: glyph well and glyph.
  static const double well = 42;
  static const double glyph = 21;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var radius = BorderRadius.circular(wiz.space.r4);
    var meta = '${plural(lightCount, 'light')} · ${onCount > 0 ? '$onCount on' : 'all off'}';

    Widget card(bool pressed) => Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: WizGlow(on: on, shadows: wiz.elevation.glowAmber, radius: radius)),
        WizSurface(
          spec: pressed ? wiz.elevation.pressed : wiz.elevation.panel,
          radius: radius,
          gradient: wizVertical(c.surfaceRaised, c.surfacePanel),
          padding: EdgeInsets.all(wiz.space.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizSurface(
                    spec: wiz.elevation.well,
                    radius: BorderRadius.circular(wiz.space.r2),
                    color: c.char1000,
                    width: well,
                    height: well,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: m.light,
                      style: TextStyle(color: on ? c.amber400 : c.textTertiary),
                      child: WizIcon(icon, size: glyph),
                    ),
                  ),
                  const Spacer(),
                  WizToggle(value: on, onChanged: onToggle, size: WizToggleSize.sm, enabled: onToggle != null, semanticsLabel: name),
                ],
              ),
              SizedBox(height: wiz.space.s6 + wiz.space.s1),
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: wiz.type.body.copyWith(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.19, height: 1.15, color: c.textPrimary)),
              SizedBox(height: wiz.space.s1 + wiz.space.s1 / 2),
              Text(meta, style: wiz.type.bodySm.copyWith(color: c.textTertiary)),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return card(false);
    return WizPressable(
      onTap: onTap,
      scale: m.cardScale,
      semanticsLabel: name,
      arenaResolved: true,
      builder: (context, state) => card(state.pressed),
    );
  }
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/cards_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets test/core/widgets
git commit -m "feat(kit): LightCard and RoomCard"
```

---

### Task 24: FixtureHero

**Files:**
- Create: `lib/core/widgets/fixture_hero.dart`, `lib/core/widgets/fixture_hero_painter.dart`
- Modify: `lib/core/theme/wiz_colors.dart` (add `shadeBottom 0xFF141418`, `neckTop 0xFF2E2E36`, `neckBottom 0xFF1C1C22`, `glass 0xF018181D`)
- Test: `test/core/widgets/fixture_hero_test.dart`

**Interfaces:**
- Produces: `enum WizFixture { bulb, dome, desk, strip, socket }`; `class WizEmission { Color color; double alpha; double bloom; double filament; static const off; factory WizEmission.lit({required Color color, required int brightness}); static WizEmission lerp(WizEmission a, WizEmission b, double t); }` (spec §5.6: alpha = 0.30 + b/100 × 0.62, bloom = 0.22 + b/100 × 0.58, filament 1 when lit, 0.06 when off); `class FixtureHero extends StatefulWidget { fixture, emission, compact (bool) }`. The hero scales uniformly to the width it is given (design box 350×236, or 350×132 when compact) and animates emission over the light duration; the emission layers breathe while lit.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/fixture_hero_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';

import '../../support/wiz_test_app.dart';

void main() {
  test('emission maths follow the spec', () {
    var lit = WizEmission.lit(color: const Color(0xFFFFB020), brightness: 100);
    expect(lit.alpha, closeTo(0.92, 0.001));
    expect(lit.bloom, closeTo(0.80, 0.001));
    var dim = WizEmission.lit(color: const Color(0xFFFFB020), brightness: 10);
    expect(dim.alpha, closeTo(0.362, 0.001));
    expect(WizEmission.off.alpha, 0);
    expect(WizEmission.off.filament, 0.06);
    var mid = WizEmission.lerp(WizEmission.off, lit, 0.5);
    expect(mid.alpha, closeTo(0.46, 0.001));
  });

  testWidgets('the hero scales to its width for every fixture', (tester) async {
    for (var fixture in WizFixture.values) {
      await tester.pumpWidget(wizTestApp(SizedBox(
        width: 350,
        child: FixtureHero(fixture: fixture, emission: WizEmission.lit(color: const Color(0xFFFFB020), brightness: 70)),
      )));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(FixtureHero)), const Size(350, 236), reason: '$fixture');
    }
    await tester.pumpWidget(wizTestApp(const SizedBox(width: 175, child: FixtureHero(fixture: WizFixture.bulb, emission: WizEmission.off))));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FixtureHero)), const Size(175, 118));
    await tester.pumpWidget(wizTestApp(const SizedBox(width: 304, child: FixtureHero(fixture: WizFixture.dome, emission: WizEmission.off, compact: true))));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FixtureHero)).height, closeTo(132 * 304 / 350, 0.5));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/fixture_hero_test.dart`
Expected: compile error.

- [ ] **Step 3: Add the colours and implement the emission model and widget**

In `lib/core/theme/wiz_colors.dart` add:

```dart
  // Fixture hero materials (prototype hero markup)
  final Color shadeBottom = const Color(0xFF141418);
  final Color neckTop = const Color(0xFF2E2E36);
  final Color neckBottom = const Color(0xFF1C1C22);
  final Color glass = const Color(0xF018181D); // rgba(24,24,29,.94)
```

`lib/core/widgets/fixture_hero.dart`:

```dart
import 'package:flutter/material.dart';

import '../motion/reduced_motion.dart';
import '../theme/wiz_theme.dart';
import 'fixture_hero_painter.dart';

enum WizFixture { bulb, dome, desk, strip, socket }

/// What a light is emitting, spec §5.6. Off is transparent with a barely
/// visible filament; on scales with brightness.
@immutable
class WizEmission {
  final Color color;
  final double alpha;
  final double bloom;
  final double filament;

  const WizEmission({required this.color, required this.alpha, required this.bloom, required this.filament});

  static const WizEmission off = WizEmission(color: Color(0xFFFFB020), alpha: 0, bloom: 0, filament: 0.06);

  factory WizEmission.lit({required Color color, required int brightness}) {
    var b = brightness.clamp(0, 100) / 100;
    return WizEmission(color: color, alpha: 0.30 + b * 0.62, bloom: 0.22 + b * 0.58, filament: 1);
  }

  Color get em => color.withValues(alpha: alpha);
  Color get emSoft => color.withValues(alpha: alpha * 0.32);

  static WizEmission lerp(WizEmission a, WizEmission b, double t) => WizEmission(
    color: Color.lerp(a.color, b.color, t)!,
    alpha: a.alpha + (b.alpha - a.alpha) * t,
    bloom: a.bloom + (b.bloom - a.bloom) * t,
    filament: a.filament + (b.filament - a.filament) * t,
  );
}

class _EmissionTween extends Tween<WizEmission> {
  _EmissionTween({required WizEmission super.begin, required WizEmission super.end});

  @override
  WizEmission lerp(double t) => WizEmission.lerp(begin!, end!, t);
}

/// The emission hero: a fixture drawn from the light's "show it as" kind,
/// its glow tracking colour and brightness. Colour changes ramp over 420 ms
/// (the bulb physically warming) and the emission breathes while on.
class FixtureHero extends StatefulWidget {
  final WizFixture fixture;
  final WizEmission emission;

  /// The desktop inspector variant: a 132-tall well with the fixture at 0.6.
  final bool compact;

  const FixtureHero({super.key, required this.fixture, required this.emission, this.compact = false});

  @override
  State<FixtureHero> createState() => _FixtureHeroState();
}

class _FixtureHeroState extends State<FixtureHero> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(vsync: this, duration: context.wiz.motion.breathe);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(FixtureHero old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.emission.alpha > 0) {
      if (!_breathe.isAnimating) _breathe.repeat(reverse: true);
    } else {
      _breathe.stop();
      _breathe.value = 0;
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var m = wiz.motion;
    var box = widget.compact ? FixtureGeometry.compactBox : FixtureGeometry.box;
    var reduced = wizReducedMotion(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var scale = constraints.maxWidth / box.width;
        return SizedBox(
          width: constraints.maxWidth,
          height: box.height * scale,
          child: TweenAnimationBuilder<WizEmission>(
            tween: _EmissionTween(begin: widget.emission, end: widget.emission),
            duration: m.light,
            curve: m.tactile,
            builder: (context, emission, _) => AnimatedBuilder(
              animation: _breathe,
              builder: (context, _) {
                var breath = reduced ? 1.0 : 1 - (1 - m.breatheMin) * _breathe.value;
                return CustomPaint(
                  painter: FixtureHeroPainter(
                    fixture: widget.fixture,
                    emission: emission,
                    breath: breath,
                    scale: scale,
                    compact: widget.compact,
                    colors: wiz.colors,
                    elevation: wiz.elevation,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Implement the painter**

`lib/core/widgets/fixture_hero_painter.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import 'fixture_hero.dart';
import 'wiz_surface.dart';

/// Geometry of the hero in its 350×236 design box (prototype GEO map and
/// hero markup). Everything scales uniformly from here.
class FixtureGeometry {
  FixtureGeometry._();

  static const Size box = Size(350, 236);
  static const Size compactBox = Size(350, 132);
  static const double compactScale = 0.6;

  /// Shade width, height, corner radii (top, bottom as x/y), vertical offset
  /// of the shade's centre from the box centre, and whether cords hang above.
  static const Map<WizFixture, ({double w, double h, Radius top, Radius bottom, double offset, bool cord})> shades = {
    WizFixture.dome: (w: 216, h: 78, top: Radius.circular(14), bottom: Radius.elliptical(108, 54), offset: 17, cord: true),
    WizFixture.desk: (w: 140, h: 76, top: Radius.elliptical(78, 62), bottom: Radius.circular(14), offset: 9, cord: false),
    WizFixture.strip: (w: 262, h: 20, top: Radius.circular(10), bottom: Radius.circular(10), offset: 0, cord: false),
    WizFixture.socket: (w: 104, h: 104, top: Radius.circular(20), bottom: Radius.circular(20), offset: 0, cord: false),
  };

  // Bulb: screw cap, neck and globe.
  static const Size cap = Size(44, 28);
  static const Size neck = Size(58, 18);
  static const double globe = 122;
  static const double bulbOffset = 4;
  static const double filamentHeight = 34;
  static const double filamentGap = 12;
  static const double filamentTop = 0.34;

  // Bloom above the fixture, floor glow below.
  static const double bloomTop = 92, bloomHeight = 190, bloomWidth = 1.55, bloomBlur = 34;
  static const double floorTop = 150, floorHeight = 26, floorWidth = 0.9, floorBlur = 14;
  static const double compactBloomTop = 58, compactBloomHeight = 110, compactBloomWidth = 1.1, compactBloomBlur = 24;
  static const double cordHeight = 74, cordGap = 64;
}

class FixtureHeroPainter extends CustomPainter {
  final WizFixture fixture;
  final WizEmission emission;
  final double breath;
  final double scale;
  final bool compact;
  final WizColors colors;
  final WizElevation elevation;

  FixtureHeroPainter({
    required this.fixture,
    required this.emission,
    required this.breath,
    required this.scale,
    required this.compact,
    required this.colors,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale, scale);
    var box = compact ? FixtureGeometry.compactBox : FixtureGeometry.box;
    var cx = box.width / 2;
    var fixtureWidth = fixture == WizFixture.bulb ? FixtureGeometry.globe : FixtureGeometry.shades[fixture]!.w;
    if (compact) fixtureWidth *= FixtureGeometry.compactScale;

    _paintBloom(canvas, cx, fixtureWidth);
    if (!compact) _paintFloor(canvas, cx, fixtureWidth);

    canvas.save();
    if (compact) {
      canvas.translate(cx, box.height / 2);
      canvas.scale(FixtureGeometry.compactScale);
      canvas.translate(-cx, -FixtureGeometry.box.height / 2);
    }
    if (fixture == WizFixture.bulb) {
      _paintBulb(canvas, cx);
    } else {
      _paintShade(canvas, cx, FixtureGeometry.shades[fixture]!, cords: !compact);
    }
    canvas.restore();
    canvas.restore();
  }

  Paint _blurred(Color color, double blur) => Paint()
    ..color = color
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2);

  void _paintBloom(Canvas canvas, double cx, double w) {
    if (emission.bloom <= 0) return;
    var top = compact ? FixtureGeometry.compactBloomTop : FixtureGeometry.bloomTop;
    var h = compact ? FixtureGeometry.compactBloomHeight : FixtureGeometry.bloomHeight;
    var wf = compact ? FixtureGeometry.compactBloomWidth : FixtureGeometry.bloomWidth;
    var blur = compact ? FixtureGeometry.compactBloomBlur : FixtureGeometry.bloomBlur;
    var rect = Rect.fromLTWH(cx - w * wf / 2, top, w * wf, h);
    var paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.04,
        colors: [emission.em, emission.color.withValues(alpha: 0)],
        stops: const [0, .74],
      ).createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2)
      ..color = Colors.white.withValues(alpha: emission.bloom * breath);
    canvas.drawOval(rect, paint);
  }

  void _paintFloor(Canvas canvas, double cx, double w) {
    if (emission.bloom <= 0) return;
    var rect = Rect.fromCenter(center: Offset(cx, FixtureGeometry.floorTop + FixtureGeometry.floorHeight / 2), width: w * FixtureGeometry.floorWidth, height: FixtureGeometry.floorHeight);
    canvas.drawOval(rect, _blurred(emission.em.withValues(alpha: emission.alpha * emission.bloom), FixtureGeometry.floorBlur));
  }

  void _castShadow(Canvas canvas, RRect shape) {
    for (var s in elevation.knob.outer) {
      canvas.drawRRect(shape.shift(s.offset).inflate(s.spreadRadius), _blurred(s.color, s.blurRadius));
    }
  }

  void _paintShade(Canvas canvas, double cx, ({double w, double h, Radius top, Radius bottom, double offset, bool cord}) g, {required bool cords}) {
    var cy = FixtureGeometry.box.height / 2 + g.offset;
    var rect = Rect.fromCenter(center: Offset(cx, cy), width: g.w, height: g.h);
    var shape = RRect.fromRectAndCorners(rect, topLeft: g.top, topRight: g.top, bottomLeft: g.bottom, bottomRight: g.bottom);

    if (cords && g.cord) {
      var cordPaint = Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: .16), Colors.white.withValues(alpha: .05)])
            .createShader(Rect.fromLTWH(0, 0, 1, FixtureGeometry.cordHeight));
      for (var x in [cx - FixtureGeometry.cordGap / 2, cx + FixtureGeometry.cordGap / 2]) {
        canvas.drawRect(Rect.fromLTWH(x, 0, 1, FixtureGeometry.cordHeight), cordPaint);
      }
    }

    _castShadow(canvas, shape);
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.railDark, colors.shadeBottom], stops: const [0, .62]).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(shape);
    // Knurl on the top third of the grip
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.34), WizTextures.knurlPaint(elevation, origin: rect.topLeft)..color = Colors.white.withValues(alpha: .5));
    // Emission at the mouth of the shade
    var mouth = Rect.fromLTWH(rect.left + rect.width * 0.06, rect.bottom - rect.height * 0.52 + rect.height * 0.06, rect.width * 0.88, rect.height * 0.52);
    var emissionPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: 1,
        colors: [emission.em, emission.emSoft, Colors.black.withValues(alpha: .9)],
        stops: const [0, .58, 1],
      ).createShader(mouth)
      ..color = Colors.white.withValues(alpha: emission.filament * breath);
    canvas.drawOval(mouth, emissionPaint);
    canvas.restore();
    paintInsets(canvas, shape, elevation.knob.insets);
  }

  void _paintBulb(Canvas canvas, double cx) {
    var total = FixtureGeometry.cap.height + FixtureGeometry.neck.height - 1 + FixtureGeometry.globe - 8;
    var top = FixtureGeometry.box.height / 2 + FixtureGeometry.bulbOffset - total / 2;

    // Cap
    var cap = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, top + FixtureGeometry.cap.height / 2), width: FixtureGeometry.cap.width, height: FixtureGeometry.cap.height),
      topLeft: const Radius.circular(5), topRight: const Radius.circular(5), bottomLeft: const Radius.circular(3), bottomRight: const Radius.circular(3),
    );
    for (var s in elevation.raised.outer) {
      canvas.drawRRect(cap.shift(s.offset).inflate(s.spreadRadius), _blurred(s.color, s.blurRadius));
    }
    canvas.drawRRect(cap, Paint()..color = colors.railDark);
    canvas.save();
    canvas.clipRRect(cap);
    canvas.drawRect(cap.outerRect, WizTextures.knurlPaint(elevation, origin: cap.outerRect.topLeft));
    canvas.restore();

    // Neck: trapezoid from 16 % to 84 % at the top, full width at the bottom
    var neckTop = top + FixtureGeometry.cap.height - 1;
    var nw = FixtureGeometry.neck.width;
    var neckRect = Rect.fromLTWH(cx - nw / 2, neckTop, nw, FixtureGeometry.neck.height);
    var neck = Path()
      ..moveTo(neckRect.left + nw * 0.16, neckRect.top)
      ..lineTo(neckRect.left + nw * 0.84, neckRect.top)
      ..lineTo(neckRect.right, neckRect.bottom)
      ..lineTo(neckRect.left, neckRect.bottom)
      ..close();
    canvas.drawPath(neck, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [colors.neckTop, colors.neckBottom]).createShader(neckRect));

    // Globe
    var globeTop = neckRect.bottom - 8;
    var globeRect = Rect.fromLTWH(cx - FixtureGeometry.globe / 2, globeTop, FixtureGeometry.globe, FixtureGeometry.globe);
    var globe = RRect.fromRectAndRadius(globeRect, Radius.circular(FixtureGeometry.globe / 2));
    _castShadow(canvas, globe);
    canvas.drawOval(
      globeRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.16),
          radius: 0.58,
          colors: [emission.em, emission.emSoft, colors.glass],
          stops: const [0, .52, 1],
        ).createShader(globeRect),
    );
    canvas.save();
    canvas.clipRRect(globe);
    // Filaments and loop
    var filamentPaint = Paint()
      ..color = emission.em.withValues(alpha: emission.alpha * emission.filament * breath)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3);
    var fTop = globeRect.top + globeRect.height * FixtureGeometry.filamentTop;
    for (var dx in [-FixtureGeometry.filamentGap / 2 - 1, FixtureGeometry.filamentGap / 2 + 1]) {
      canvas.drawLine(Offset(cx + dx, fTop), Offset(cx + dx, fTop + FixtureGeometry.filamentHeight), filamentPaint);
    }
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, fTop + FixtureGeometry.filamentHeight - 4), width: 16, height: 20), 0, math.pi, false, filamentPaint);
    // Glass highlight
    canvas.drawOval(
      Rect.fromLTWH(globeRect.left + globeRect.width * 0.18, globeRect.top + globeRect.height * 0.14, 26, 16),
      _blurred(Colors.white.withValues(alpha: .16), 6),
    );
    canvas.restore();
    paintInsets(canvas, globe, [
      const WizInset(offsetY: -10, blur: 20, color: Color(0x8C000000)),
      const WizInset(offsetY: 3, blur: 0, color: Color(0x1FFFFFFF)),
    ]);
  }

  @override
  bool shouldRepaint(FixtureHeroPainter old) =>
      old.fixture != fixture ||
      old.emission.alpha != emission.alpha ||
      old.emission.color != emission.color ||
      old.emission.bloom != emission.bloom ||
      old.emission.filament != emission.filament ||
      old.breath != breath ||
      old.scale != scale ||
      old.compact != compact;
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/fixture_hero_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/fixture_hero.dart lib/core/widgets/fixture_hero_painter.dart lib/core/theme/wiz_colors.dart test/core/widgets/fixture_hero_test.dart
git commit -m "feat(kit): FixtureHero with emission, bloom and breathe"
```

---

### Task 25: ModeRow

**Files:**
- Create: `lib/core/widgets/mode_row.dart`
- Test: `test/core/widgets/mode_row_test.dart`

**Interfaces:**
- Produces: `sealed class WizModeArt` with `SceneModeArt(int sceneId)`, `SolidModeArt(Color color)`, `FlatModeArt()`; `class ModeRow { art, name, onTap, label ('Light mode') }`. The art cross-fades over the panel duration when it changes.

- [ ] **Step 1: Write the failing test**

`test/core/widgets/mode_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/core/widgets/wiz_scene_art.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('shows the label, name and art; taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: ModeRow(art: const SceneModeArt(6), name: 'Cozy', onTap: () => taps++),
    )));
    expect(find.text('LIGHT MODE'), findsOneWidget);
    expect(find.text('Cozy'), findsOneWidget);
    expect(find.byType(WizSceneArt), findsOneWidget);
    await tester.tap(find.text('Cozy'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('solid and flat art render without a scene', (tester) async {
    await tester.pumpWidget(wizTestApp(SizedBox(
      width: 350,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ModeRow(art: const SolidModeArt(Color(0xFFFFC98D)), name: '2700K white', onTap: () {}),
        ModeRow(art: const FlatModeArt(), name: 'Mixed', onTap: () {}),
      ]),
    )));
    expect(find.byType(WizSceneArt), findsNothing);
    expect(find.text('Mixed'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/widgets/mode_row_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

`lib/core/widgets/mode_row.dart`:

```dart
import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_pressable.dart';
import 'wiz_scene_art.dart';
import 'wiz_surface.dart';

/// What the Light mode row shows in its art square.
sealed class WizModeArt {
  const WizModeArt();
}

final class SceneModeArt extends WizModeArt {
  final int sceneId;
  const SceneModeArt(this.sceneId);
}

final class SolidModeArt extends WizModeArt {
  final Color color;
  const SolidModeArt(this.color);
}

final class FlatModeArt extends WizModeArt {
  const FlatModeArt();
}

/// The Light mode row: art square, "LIGHT MODE", the current state as a
/// heading (a scene name, "Colour", "2700K white", "Mixed" or "Nothing
/// set") and a chevron well. Opens the three-tab sheet scoped to its target.
class ModeRow extends StatelessWidget {
  final WizModeArt art;
  final String name;
  final VoidCallback? onTap;
  final String label;

  const ModeRow({super.key, required this.art, required this.name, required this.onTap, this.label = 'Light mode'});

  static const double artSize = 48;
  static const double chevronWell = 32;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var artRadius = BorderRadius.circular(wiz.space.r2);
    Widget artWidget = switch (art) {
      SceneModeArt(:var sceneId) => WizSceneArt.scene(sceneId, key: ValueKey('scene-$sceneId'), radius: artRadius),
      SolidModeArt(:var color) => DecoratedBox(key: ValueKey(color), decoration: BoxDecoration(color: color, borderRadius: artRadius)),
      FlatModeArt() => DecoratedBox(key: const ValueKey('flat'), decoration: BoxDecoration(gradient: wizVertical(c.char800, c.char900), borderRadius: artRadius)),
    };
    return WizPressable(
      onTap: onTap,
      enabled: onTap != null,
      scale: m.keyScale,
      semanticsLabel: '$label: $name',
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(c.surfaceKey, c.surfaceRaised),
        padding: EdgeInsets.symmetric(vertical: wiz.space.s4 + wiz.space.s1, horizontal: wiz.space.s5),
        child: Row(
          children: [
            SizedBox(
              width: artSize,
              height: artSize,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: artRadius, boxShadow: const [BoxShadow(color: Color(0x80000000), spreadRadius: 1)]),
                child: ClipRRect(
                  borderRadius: artRadius,
                  child: AnimatedSwitcher(duration: m.panel, switchInCurve: m.tactile, child: artWidget),
                ),
              ),
            ),
            SizedBox(width: wiz.space.s5 + wiz.space.s1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label.toUpperCase(), style: wiz.type.label.copyWith(color: c.textTertiary)),
                  SizedBox(height: wiz.space.s1),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: wiz.type.heading.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
            SizedBox(width: wiz.space.s5),
            WizSurface(
              spec: wiz.elevation.well,
              radius: artRadius,
              color: c.char1000,
              width: chevronWell,
              height: chevronWell,
              alignment: Alignment.center,
              child: WizIcon(WizIcons.chevronRight, size: 15, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run, format, analyze, commit**

```bash
flutter test test/core/widgets/mode_row_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/widgets/mode_row.dart test/core/widgets/mode_row_test.dart
git commit -m "feat(kit): ModeRow with cross-fading art"
```

---

### Task 26: Synthesized sound and haptics

**Files:**
- Create: `lib/core/feedback/wiz_synth.dart`, `lib/core/feedback/audio_player_port.dart`, `lib/core/feedback/soloud_player.dart`, `lib/core/feedback/haptic_mapper.dart`, `lib/core/feedback/synth_feedback_service.dart`
- Test: `test/core/feedback/wiz_synth_test.dart`, `test/core/feedback/synth_feedback_service_test.dart`

**Interfaces:**
- Produces: `class WizSynth { static const int sampleRate = 44100; static const double masterGain = 0.9; static Float32List render(FeedbackKind kind); static Uint8List renderWav(FeedbackKind kind); }`; `abstract interface class AudioPlayerPort { Future<void> init(); Future<void> load(String name, Uint8List wav); void play(String name, {double volume}); Future<void> dispose(); }`; `class SoLoudPlayer implements AudioPlayerPort` (over `flutter_soloud`); `class HapticMapper { HapticMapper({bool? supported, Future<void> Function()? selection, light, medium, heavy}); Future<void> play(FeedbackKind kind); }`; `class SynthFeedbackService implements FeedbackService { SynthFeedbackService({required AudioPlayerPort player, required HapticMapper haptics, bool enabled = true, ValueChanged<bool>? onEnabledChanged}); Future<void> init(); }`.

- [ ] **Step 1: Write the failing tests**

`test/core/feedback/wiz_synth_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/wiz_synth.dart';

void main() {
  test('every kind renders a short, bounded, audible buffer', () {
    for (var kind in FeedbackKind.values) {
      var pcm = WizSynth.render(kind);
      expect(pcm.length, greaterThan(WizSynth.sampleRate ~/ 100), reason: '$kind too short');
      expect(pcm.length, lessThan(WizSynth.sampleRate ~/ 5), reason: '$kind longer than 200 ms');
      var peak = pcm.fold<double>(0, (p, s) => s.abs() > p ? s.abs() : p);
      expect(peak, lessThanOrEqualTo(1.0), reason: '$kind clips');
      expect(peak, greaterThan(0.005), reason: '$kind is silent');
    }
  });

  test('durations follow the recipes', () {
    int ms(FeedbackKind k) => (WizSynth.render(k).length * 1000 / WizSynth.sampleRate).round();
    expect(ms(FeedbackKind.detent), closeTo(6 + 20, 2));
    expect(ms(FeedbackKind.press), closeTo(45 + 20, 2));
    expect(ms(FeedbackKind.power), closeTo(90 + 20, 2));
    expect(ms(FeedbackKind.confirm), closeTo(55 + 70 + 20, 2));
    expect(ms(FeedbackKind.reject), closeTo(120 + 20, 2));
  });

  test('rendering is deterministic and the WAV header is valid', () {
    var a = WizSynth.renderWav(FeedbackKind.tick);
    var b = WizSynth.renderWav(FeedbackKind.tick);
    expect(a, b);
    expect(String.fromCharCodes(a.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(a.sublist(8, 12)), 'WAVE');
    expect(a.length, 44 + WizSynth.render(FeedbackKind.tick).length * 2);
  });
}
```

`test/core/feedback/synth_feedback_service_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/feedback/audio_player_port.dart';
import 'package:wizctl_app/core/feedback/feedback_kind.dart';
import 'package:wizctl_app/core/feedback/haptic_mapper.dart';
import 'package:wizctl_app/core/feedback/synth_feedback_service.dart';

class FakePlayer implements AudioPlayerPort {
  final loaded = <String>[];
  final played = <(String, double)>[];
  bool inited = false;

  @override
  Future<void> init() async => inited = true;

  @override
  Future<void> load(String name, Uint8List wav) async => loaded.add(name);

  @override
  void play(String name, {double volume = 1}) => played.add((name, volume));

  @override
  Future<void> dispose() async {}
}

void main() {
  test('init loads nine sources; play routes sound and haptics', () async {
    var player = FakePlayer();
    var haptics = <String>[];
    var mapper = HapticMapper(
      supported: true,
      selection: () async => haptics.add('selection'),
      light: () async => haptics.add('light'),
      medium: () async => haptics.add('medium'),
      heavy: () async => haptics.add('heavy'),
    );
    var service = SynthFeedbackService(player: player, haptics: mapper);
    await service.init();
    expect(player.inited, isTrue);
    expect(player.loaded, hasLength(FeedbackKind.values.length));
    service.play(FeedbackKind.detent);
    service.play(FeedbackKind.power);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(player.played.map((p) => p.$1), ['detent', 'power']);
    expect(player.played.first.$2, 0.9);
    expect(haptics, ['selection', 'heavy']);
  });

  test('disabled plays nothing; enabling ticks once', () async {
    var player = FakePlayer();
    var service = SynthFeedbackService(player: player, haptics: HapticMapper(supported: false), enabled: false);
    await service.init();
    service.play(FeedbackKind.press);
    expect(player.played, isEmpty);
    await service.setEnabled(true);
    expect(player.played.map((p) => p.$1), ['tick']);
  });

  test('confirm and reject are two spaced impacts', () async {
    var haptics = <String>[];
    var mapper = HapticMapper(
      supported: true,
      selection: () async => haptics.add('selection'),
      light: () async => haptics.add('light'),
      medium: () async => haptics.add('medium'),
      heavy: () async => haptics.add('heavy'),
    );
    await mapper.play(FeedbackKind.confirm);
    await mapper.play(FeedbackKind.reject);
    expect(haptics, ['light', 'medium', 'heavy', 'heavy']);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/feedback`
Expected: compile error.

- [ ] **Step 3: Implement the synth**

`lib/core/feedback/wiz_synth.dart`:

```dart
import 'dart:math' as math;
import 'dart:typed_data';

import 'feedback_kind.dart';

enum _Wave { sine, triangle, sawtooth }

sealed class _Voice {
  final double at;
  final double dur;
  const _Voice({required this.at, required this.dur});
}

/// A filtered noise transient: the contact of a key.
class _Noise extends _Voice {
  final double cut;
  final double gain;
  const _Noise(double dur, this.cut, this.gain, {double at = 0}) : super(at: at, dur: dur);
}

/// A short low body with an optional exponential frequency ramp.
class _Tone extends _Voice {
  final double f;
  final double? f2;
  final double gain;
  final _Wave type;
  const _Tone(this.f, this.f2, double dur, this.gain, {double at = 0, this.type = _Wave.sine}) : super(at: at, dur: dur);
}

/// Sound is generated, not sampled (feedback.jsx). Nine recipes, each a
/// noise burst through a low-pass and/or a tone with the exact ramps and
/// envelopes of the design system, rendered once into PCM.
class WizSynth {
  WizSynth._();

  static const int sampleRate = 44100;
  static const double masterGain = 0.9;
  static const double attack = 0.004;
  static const double floor = 0.0001;
  static const double tail = 0.02;

  static List<_Voice> recipe(FeedbackKind kind) => switch (kind) {
    FeedbackKind.press => const [_Noise(0.012, 2400, 0.05), _Tone(200, 120, 0.045, 0.05)],
    FeedbackKind.release => const [_Noise(0.008, 4200, 0.022)],
    FeedbackKind.toggleOn => const [_Noise(0.010, 3200, 0.05), _Tone(320, 560, 0.055, 0.05)],
    FeedbackKind.toggleOff => const [_Noise(0.010, 2600, 0.045), _Tone(300, 170, 0.055, 0.045)],
    FeedbackKind.tick => const [_Noise(0.009, 3600, 0.035), _Tone(520, null, 0.03, 0.03, type: _Wave.triangle)],
    FeedbackKind.detent => const [_Noise(0.006, 5200, 0.02)],
    FeedbackKind.power => const [_Noise(0.014, 2200, 0.055), _Tone(150, 90, 0.09, 0.06)],
    FeedbackKind.confirm => const [
        _Tone(660, null, 0.05, 0.04, type: _Wave.triangle),
        _Tone(990, null, 0.07, 0.035, at: 0.055, type: _Wave.triangle),
      ],
    FeedbackKind.reject => const [_Tone(210, 140, 0.12, 0.05, type: _Wave.sawtooth)],
  };

  static Float32List render(FeedbackKind kind) {
    var voices = recipe(kind);
    var end = voices.fold<double>(0, (m, v) => math.max(m, v.at + v.dur)) + tail;
    var out = Float32List((end * sampleRate).round());
    var random = math.Random(kind.index + 1);
    for (var v in voices) {
      var start = (v.at * sampleRate).round();
      var n = (v.dur * sampleRate).round();
      switch (v) {
        case _Noise():
          var rc = 1 / (2 * math.pi * v.cut);
          var dt = 1 / sampleRate;
          var alpha = dt / (rc + dt);
          var y = 0.0;
          for (var i = 0; i < n && start + i < out.length; i++) {
            var x = (random.nextDouble() * 2 - 1) * (1 - i / n);
            y += alpha * (x - y);
            out[start + i] += y * v.gain;
          }
        case _Tone():
          var phase = 0.0;
          for (var i = 0; i < n && start + i < out.length; i++) {
            var t = i / sampleRate;
            var f = v.f2 == null ? v.f : v.f * math.pow(v.f2! / v.f, t / v.dur);
            phase += f / sampleRate;
            var p = phase - phase.floorToDouble();
            var sample = switch (v.type) {
              _Wave.sine => math.sin(2 * math.pi * p),
              _Wave.triangle => 2 * (2 * p - 1).abs() - 1,
              _Wave.sawtooth => 2 * p - 1,
            };
            var env = t < attack
                ? floor * math.pow(v.gain / floor, t / attack)
                : v.gain * math.pow(floor / v.gain, (t - attack) / math.max(1e-6, v.dur - attack));
            out[start + i] += sample * env;
          }
      }
    }
    for (var i = 0; i < out.length; i++) {
      out[i] = (out[i] * masterGain).clamp(-1.0, 1.0);
    }
    return out;
  }

  /// 16-bit mono PCM WAV, ready for any player.
  static Uint8List renderWav(FeedbackKind kind) {
    var pcm = render(kind);
    var data = ByteData(44 + pcm.length * 2);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + pcm.length * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, pcm.length * 2, Endian.little);
    for (var i = 0; i < pcm.length; i++) {
      data.setInt16(44 + i * 2, (pcm[i] * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
```

- [ ] **Step 4: Implement the player port, haptics and the service**

`lib/core/feedback/audio_player_port.dart`:

```dart
import 'dart:typed_data';

/// What the feedback service needs from an audio engine: load a WAV from
/// memory once, play it by name with low latency, polyphonically.
abstract interface class AudioPlayerPort {
  Future<void> init();
  Future<void> load(String name, Uint8List wav);
  void play(String name, {double volume = 1});
  Future<void> dispose();
}
```

`lib/core/feedback/soloud_player.dart` (verify the exact `flutter_soloud` 5.x method names with `read_package_uris` on `package:flutter_soloud/flutter_soloud.dart` before finalising):

```dart
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_player_port.dart';

/// flutter_soloud backend: in-memory sources, overlapping playback.
class SoLoudPlayer implements AudioPlayerPort {
  final Map<String, AudioSource> _sources = {};

  @override
  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();
  }

  @override
  Future<void> load(String name, Uint8List wav) async {
    _sources[name] = await SoLoud.instance.loadMem('wizctl-$name.wav', wav);
  }

  @override
  void play(String name, {double volume = 1}) {
    var source = _sources[name];
    if (source == null) return;
    SoLoud.instance.play(source, volume: volume);
  }

  @override
  Future<void> dispose() async {
    for (var s in _sources.values) {
      await SoLoud.instance.disposeSource(s);
    }
    _sources.clear();
  }
}
```

`lib/core/feedback/haptic_mapper.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'feedback_kind.dart';

/// Maps the nine kinds onto the platform's haptic vocabulary (spec §13).
/// Desktop has no haptics; the mapper no-ops there.
class HapticMapper {
  final bool supported;
  final Future<void> Function() selection;
  final Future<void> Function() light;
  final Future<void> Function() medium;
  final Future<void> Function() heavy;

  static const Duration confirmGap = Duration(milliseconds: 30);
  static const Duration rejectGap = Duration(milliseconds: 40);

  HapticMapper({
    bool? supported,
    Future<void> Function()? selection,
    Future<void> Function()? light,
    Future<void> Function()? medium,
    Future<void> Function()? heavy,
  })  : supported = supported ?? (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android),
        selection = selection ?? HapticFeedback.selectionClick,
        light = light ?? HapticFeedback.lightImpact,
        medium = medium ?? HapticFeedback.mediumImpact,
        heavy = heavy ?? HapticFeedback.heavyImpact;

  Future<void> play(FeedbackKind kind) async {
    if (!supported) return;
    switch (kind) {
      case FeedbackKind.detent:
        await selection();
      case FeedbackKind.press:
      case FeedbackKind.tick:
        await light();
      case FeedbackKind.toggleOn:
      case FeedbackKind.toggleOff:
        await medium();
      case FeedbackKind.power:
        await heavy();
      case FeedbackKind.confirm:
        await light();
        await Future<void>.delayed(confirmGap);
        await medium();
      case FeedbackKind.reject:
        await heavy();
        await Future<void>.delayed(rejectGap);
        await heavy();
      case FeedbackKind.release:
        break;
    }
  }
}
```

`lib/core/feedback/synth_feedback_service.dart`:

```dart
import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import 'audio_player_port.dart';
import 'feedback_kind.dart';
import 'feedback_service.dart';
import 'haptic_mapper.dart';
import 'wiz_synth.dart';

/// The real feedback layer: synthesized clicks through the audio port plus
/// haptics. On by default; the user's switch is persisted by the caller.
class SynthFeedbackService implements FeedbackService {
  final AudioPlayerPort player;
  final HapticMapper haptics;
  final ValueChanged<bool>? onEnabledChanged;
  bool _enabled;
  bool _ready = false;

  SynthFeedbackService({required this.player, required this.haptics, bool enabled = true, this.onEnabledChanged}) : _enabled = enabled;

  Future<void> init() async {
    await player.init();
    for (var kind in FeedbackKind.values) {
      await player.load(kind.name, WizSynth.renderWav(kind));
    }
    _ready = true;
  }

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    onEnabledChanged?.call(value);
    if (value) play(FeedbackKind.tick);
  }

  @override
  void play(FeedbackKind kind) {
    if (!_enabled) return;
    unawaited(haptics.play(kind));
    if (_ready) player.play(kind.name, volume: WizSynth.masterGain);
  }

  Future<void> dispose() => player.dispose();
}
```

- [ ] **Step 5: Run, format, analyze, commit**

```bash
flutter test test/core/feedback && dart format lib test && flutter analyze --fatal-infos
git add lib/core/feedback test/core/feedback
git commit -m "feat(feedback): synthesized clicks, SoLoud playback and haptic mapping"
```

---

### Task 27: Shared copy

**Files:**
- Create: `lib/core/copy/strings.dart`
- Test: `test/core/copy/strings_test.dart`

**Interfaces:**
- Produces: `class Strings` with `static const` fields: `privacy`, `roomsStored`, `broadcastHint`, `staleIp`, `dynamicPip`, `blinkHint` (the six lines that must not drift), and shared actions `cancel`, `close`, `retry`, `rescan`, `save`, `scanSubnet`, `scanAgain`, `discoverLights`, `lightMode`, `applyTo`, `wholeHome`, `mixed`, `nothingSet`, `colour`, `noResponse` (the light-card line), `noRoute`. Plan 4 adds per-screen copy in the same class.

- [ ] **Step 1: Write the failing test**

`test/core/copy/strings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/copy/strings.dart';

void main() {
  test('the six lines that must not drift', () {
    expect(Strings.privacy, 'No account, no cloud. Lights are reached over UDP on port 38899 on your own network.');
    expect(Strings.roomsStored, "Rooms are stored in this home's config file on this machine. Nothing is uploaded.");
    expect(Strings.broadcastHint, 'Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time.');
    expect(Strings.staleIp, 'The IP shown in the Philips app can be stale — it talks to the cloud. Your router\'s DHCP client list is the reliable source.');
    expect(Strings.dynamicPip, 'A cyan pip marks a dynamic scene. Those accept a speed from 10 to 200.');
    expect(Strings.blinkHint, 'Not sure which bulb is which? Tap the flash key on a card and that light blinks for two seconds, then goes back.');
  });

  test('no exclamation marks anywhere', () {
    for (var s in Strings.all) {
      expect(s.contains('!'), isFalse, reason: s);
    }
  });
}
```

- [ ] **Step 2: Implement**

`lib/core/copy/strings.dart`:

```dart
/// Every line the user reads. Second person, sentence case, no "we", no
/// emoji, no exclamation marks. Control labels are uppercased by widgets.
class Strings {
  Strings._();

  // Copy that must not drift (handoff spec)
  static const privacy = 'No account, no cloud. Lights are reached over UDP on port 38899 on your own network.';
  static const roomsStored = "Rooms are stored in this home's config file on this machine. Nothing is uploaded.";
  static const broadcastHint = 'Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time.';
  static const staleIp = "The IP shown in the Philips app can be stale — it talks to the cloud. Your router's DHCP client list is the reliable source.";
  static const dynamicPip = 'A cyan pip marks a dynamic scene. Those accept a speed from 10 to 200.';
  static const blinkHint = 'Not sure which bulb is which? Tap the flash key on a card and that light blinks for two seconds, then goes back.';

  // Shared actions
  static const cancel = 'Cancel';
  static const close = 'Close';
  static const retry = 'Retry';
  static const rescan = 'Rescan';
  static const save = 'Save';
  static const scanSubnet = 'Scan subnet';
  static const scanAgain = 'Scan again';
  static const discoverLights = 'Discover lights';
  static const dismiss = 'Dismiss';

  // Light mode
  static const lightMode = 'Light mode';
  static const applyTo = 'Apply to';
  static const wholeHome = 'Whole home';
  static const mixed = 'Mixed';
  static const nothingSet = 'Nothing set';
  static const colour = 'Colour';
  static const warmWhite = 'Warm white';
  static const powerOn = 'Power on';
  static const powerOff = 'Power off';

  // Conditions
  static const noResponse = 'No response on the local network';
  static const noRoute = 'No route to the light';

  static const List<String> all = [
    privacy, roomsStored, broadcastHint, staleIp, dynamicPip, blinkHint,
    cancel, close, retry, rescan, save, scanSubnet, scanAgain, discoverLights, dismiss,
    lightMode, applyTo, wholeHome, mixed, nothingSet, colour, warmWhite, powerOn, powerOff,
    noResponse, noRoute,
  ];
}
```

Then make `LightCard` use `Strings.noResponse` instead of its literal.

- [ ] **Step 3: Run, format, analyze, commit**

```bash
flutter test test/core/copy test/core/widgets/cards_test.dart && dart format lib test && flutter analyze --fatal-infos
git add lib/core/copy lib/core/widgets/light_card.dart test/core/copy
git commit -m "feat(copy): shared strings including the six locked lines"
```

---

### Task 28: Bootstrap and the debug gallery

**Files:**
- Create: `lib/app/bootstrap.dart`, `lib/app/app.dart`, `lib/features/gallery/gallery_screen.dart`, `lib/features/gallery/gallery_section.dart`
- Modify: `lib/main.dart`, `test/smoke_test.dart`

**Interfaces:**
- Produces: `class AppServices { FeedbackService feedback; ToastController toasts; }`; `Future<AppServices> bootstrap()` (binding, textures at the device pixel ratio, feedback service with a Noop fallback if the audio engine fails); `class WizCtlApp extends StatelessWidget { AppServices services; }` (theme, `WizLayoutScope`, `WizAppBackground`, home = gallery in debug builds); `class GalleryScreen extends StatefulWidget { ToastController toasts; }` showing every kit widget interactively, with a "Feedback" section of nine keys that play each sound; `class GallerySection extends StatelessWidget { title, child }`.

- [ ] **Step 1: Update the smoke test**

Replace `test/smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/app.dart';
import 'package:wizctl_app/app/bootstrap.dart';
import 'package:wizctl_app/core/feedback/feedback_service.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';

void main() {
  testWidgets('the app builds and the gallery shows the wordmark', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(WizCtlApp(services: AppServices(feedback: NoopFeedbackService(), toasts: ToastController())));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('WIZCTL'), findsOneWidget);
    expect(find.text('Keys'), findsWidgets);
  });
}
```

(`Size` needs `import 'package:flutter/material.dart';`.)

- [ ] **Step 2: Implement bootstrap and the app**

`lib/app/bootstrap.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/feedback/feedback_service.dart';
import '../core/feedback/haptic_mapper.dart';
import '../core/feedback/soloud_player.dart';
import '../core/feedback/synth_feedback_service.dart';
import '../core/theme/wiz_textures.dart';
import '../core/widgets/toast_controller.dart';

/// Everything the widget tree needs that is built once at start.
class AppServices {
  final FeedbackService feedback;
  final ToastController toasts;

  const AppServices({required this.feedback, required this.toasts});
}

/// Binding, textures at the real pixel ratio, and the feedback layer. If the
/// audio engine cannot start (no output device, a sandbox without audio),
/// the app runs silently rather than not at all.
Future<AppServices> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  var views = WidgetsBinding.instance.platformDispatcher.views;
  var dpr = views.isEmpty ? 1.0 : views.first.devicePixelRatio;
  await WizTextures.load(devicePixelRatio: dpr);

  FeedbackService feedback;
  try {
    var synth = SynthFeedbackService(player: SoLoudPlayer(), haptics: HapticMapper());
    await synth.init();
    feedback = synth;
  } catch (e) {
    debugPrint('Feedback audio unavailable: $e');
    feedback = NoopFeedbackService();
  }
  return AppServices(feedback: feedback, toasts: ToastController(feedback: feedback));
}
```

`lib/app/app.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/feedback/feedback_scope.dart';
import '../core/layout/wiz_layout.dart';
import '../core/theme/wiz_theme.dart';
import '../core/widgets/wiz_app_background.dart';
import '../features/gallery/gallery_screen.dart';
import 'bootstrap.dart';

class WizCtlApp extends StatelessWidget {
  final AppServices services;

  const WizCtlApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return FeedbackScope(
      service: services.feedback,
      child: MaterialApp(
        title: 'WizCtl',
        debugShowCheckedModeBanner: false,
        theme: buildWizThemeData(),
        builder: (context, child) => WizLayoutScope(child: WizAppBackground(child: child ?? const SizedBox())),
        // Plan 4 replaces this with the router; until then the debug gallery
        // is the only screen.
        home: kDebugMode ? GalleryScreen(toasts: services.toasts) : const Scaffold(body: Center(child: Text('WizCtl'))),
      ),
    );
  }
}
```

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  var services = await bootstrap();
  runApp(WizCtlApp(services: services));
}
```

- [ ] **Step 3: Implement the gallery**

`lib/features/gallery/gallery_section.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';

/// A titled block in the gallery.
class GallerySection extends StatelessWidget {
  final String title;
  final Widget child;

  const GallerySection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Padding(
      padding: EdgeInsets.only(bottom: wiz.space.s9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: wiz.type.heading.copyWith(color: wiz.colors.textPrimary)),
          SizedBox(height: wiz.space.s5),
          child,
        ],
      ),
    );
  }
}
```

`lib/features/gallery/gallery_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/copy/strings.dart';
import '../../core/feedback/feedback_kind.dart';
import '../../core/feedback/feedback_scope.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/layout/wiz_grid.dart';
import '../../core/layout/wiz_layout.dart';
import '../../core/motion/rise_in.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/util/color_maths.dart';
import '../../core/widgets/fixture_hero.dart';
import '../../core/widgets/light_card.dart';
import '../../core/widgets/mode_row.dart';
import '../../core/widgets/room_card.dart';
import '../../core/widgets/scene_gradients.dart';
import '../../core/widgets/toast_controller.dart';
import '../../core/widgets/wiz_badge.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_chip.dart';
import '../../core/widgets/wiz_color_wheel.dart';
import '../../core/widgets/wiz_dial.dart';
import '../../core/widgets/wiz_empty_state.dart';
import '../../core/widgets/wiz_filament_bar.dart';
import '../../core/widgets/wiz_icon_key.dart';
import '../../core/widgets/wiz_list_row.dart';
import '../../core/widgets/wiz_panel.dart';
import '../../core/widgets/wiz_power_key.dart';
import '../../core/widgets/wiz_scene_tile.dart';
import '../../core/widgets/wiz_segmented_control.dart';
import '../../core/widgets/wiz_sheet.dart';
import '../../core/widgets/wiz_skeleton.dart';
import '../../core/widgets/wiz_slider.dart';
import '../../core/widgets/wiz_stat_tile.dart';
import '../../core/widgets/wiz_status_banner.dart';
import '../../core/widgets/wiz_tab_bar.dart';
import '../../core/widgets/wiz_text_field.dart';
import '../../core/widgets/wiz_toast_layer.dart';
import '../../core/widgets/wiz_toggle.dart';
import '../../core/widgets/wiz_top_bar.dart';
import 'gallery_section.dart';

/// Debug-only catalogue of every kit widget, live, so the design can be
/// checked on a real device before any screen exists.
class GalleryScreen extends StatefulWidget {
  final ToastController toasts;

  const GalleryScreen({super.key, required this.toasts});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _toggle = true;
  bool _power = true;
  double _brightness = 70;
  double _kelvin = 2700;
  double _speed = 120;
  WizHsv _hsv = const WizHsv(28, 0.9);
  String _segment = 'colour';
  String _tab = 'home';
  int _scene = 6;
  WizFixture _fixture = WizFixture.bulb;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var gutter = context.layout.gutter;
    var compact = context.layout.widthClass.isCompact;
    var emission = _power ? WizEmission.lit(color: kelvinToColor(_kelvin.round()), brightness: _brightness.round()) : WizEmission.off;

    var sections = <Widget>[
      const WizTopBar(title: 'Gallery', subtitle: 'Every part of the kit, live'),
      GallerySection(title: 'Keys', child: Wrap(spacing: wiz.space.s4, runSpacing: wiz.space.s4, children: [
        WizButton(label: 'Create home', variant: WizButtonVariant.primary, icon: WizIcons.radio, onPressed: () {}),
        WizButton(label: 'Scan again', variant: WizButtonVariant.ghost, icon: WizIcons.refreshCw, onPressed: () {}),
        WizButton(label: 'Rename', size: WizButtonSize.sm, icon: WizIcons.pencil, onPressed: () {}),
        WizButton(label: 'Forget', variant: WizButtonVariant.danger, size: WizButtonSize.sm, icon: WizIcons.trash, onPressed: () {}),
        WizButton(label: 'Disabled', onPressed: null),
        WizIconKey(icon: WizIcons.house, onPressed: () {}, semanticsLabel: 'Homes'),
        WizIconKey(icon: WizIcons.lightbulb, active: true, onPressed: () {}, semanticsLabel: 'Blink'),
        WizChip(label: 'Living Room', selected: true, onTap: () {}),
        WizChip(label: 'Bedroom', onTap: () {}),
        WizChip(label: 'New room', icon: WizIcons.plus, accentText: true, onTap: () {}),
      ])),
      GallerySection(title: 'Switches', child: Row(children: [
        WizToggle(value: _toggle, onChanged: (v) => setState(() => _toggle = v), semanticsLabel: 'All lights'),
        SizedBox(width: wiz.space.s6),
        WizToggle(value: _toggle, size: WizToggleSize.sm, onChanged: (v) => setState(() => _toggle = v), semanticsLabel: 'Room'),
        const Spacer(),
        WizPowerKey(on: _power, onChanged: (v) => setState(() => _power = v), size: WizPowerKeySize.md),
      ])),
      GallerySection(title: 'Dials and rails', child: WizPanel(variant: WizPanelVariant.inset, child: LayoutBuilder(builder: (context, box) {
        var dial = ((box.maxWidth - wiz.space.s5) / 2).clamp(wiz.space.knobSm, wiz.space.knobLg);
        return Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            WizDial(value: _brightness, min: 10, max: 100, size: dial, label: 'Brightness', onChanged: (v) => setState(() => _brightness = v)),
            SizedBox(width: wiz.space.s5),
            WizDial(value: _kelvin, min: 2200, max: 6500, step: 50, size: dial, label: 'Colour temp.', unit: 'K', onChanged: (v) => setState(() => _kelvin = v)),
          ]),
          SizedBox(height: wiz.space.s6),
          WizSlider(value: _speed, min: 10, max: 200, fill: WizSliderFill.speed, label: 'Speed', readout: '${_speed.round()}', onChanged: (v) => setState(() => _speed = v)),
          SizedBox(height: wiz.space.s5),
          WizSlider(value: _kelvin, min: 2200, max: 6500, step: 50, fill: WizSliderFill.kelvin, label: 'Colour temp.', readout: '${_kelvin.round()}K', onChanged: (v) => setState(() => _kelvin = v)),
        ]);
      }))),
      GallerySection(title: 'Colour wheel', child: Center(child: LayoutBuilder(builder: (context, box) {
        var size = box.maxWidth < 228 ? box.maxWidth : 228.0;
        return WizColorWheel(hue: _hsv.hue, saturation: _hsv.saturation, size: size, onChanged: (v) => setState(() => _hsv = v));
      }))),
      GallerySection(title: 'Scenes', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        WizSegmentedControl<String>(
          segments: const [WizSegment(value: 'colour', label: 'Colour'), WizSegment(value: 'static', label: 'Static'), WizSegment(value: 'dynamic', label: 'Dynamic')],
          value: _segment,
          onChanged: (v) => setState(() => _segment = v),
        ),
        SizedBox(height: wiz.space.s5),
        WizGrid(minTile: 100, gap: wiz.space.s4 + 1, children: [
          for (var s in (_segment == 'dynamic' ? dynamicScenes : staticScenes).take(6))
            WizSceneTile(sceneId: s.id, selected: s.id == _scene, height: 82, radius: wiz.space.r3, labelSize: 14, onTap: () => setState(() => _scene = s.id)),
        ]),
        SizedBox(height: wiz.space.s5),
        ModeRow(art: SceneModeArt(_scene), name: sceneGradients[_scene]!.name, onTap: () => showWizSheet<void>(context, title: 'Light mode · Living Room', builder: (_) => Text(Strings.dynamicPip, style: wiz.type.body.copyWith(color: c.textTertiary)), footer: [WizButton(label: 'Close', variant: WizButtonVariant.ghost, onPressed: () => Navigator.of(context).pop())])),
      ])),
      GallerySection(title: 'Navigation', child: WizTabBar<String>(
        tabs: const [WizTab(value: 'home', icon: WizIcons.house, label: 'Home'), WizTab(value: 'rooms', icon: WizIcons.layoutGrid, label: 'Rooms'), WizTab(value: 'scenes', icon: WizIcons.sparkles, label: 'Scenes'), WizTab(value: 'settings', icon: WizIcons.slidersHorizontal, label: 'Settings')],
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
      )),
      GallerySection(title: 'Rows and tiles', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        WizListRow(icon: WizIcons.sofa, title: 'Living Room', meta: '3 lights · 2 on', trailing: const WizBadge(label: 'Live', tone: WizBadgeTone.online, dot: true), onTap: () {}),
        SizedBox(height: wiz.space.s4),
        Row(children: [
          const Expanded(child: WizStatTile(icon: WizIcons.thermometer, label: 'Colour temp', value: '2700', unit: 'K')),
          SizedBox(width: wiz.space.s5),
          const Expanded(child: WizStatTile(icon: WizIcons.gauge, label: 'Intensity', value: '70', unit: '%', accent: true)),
        ]),
        SizedBox(height: wiz.space.s4),
        WizGrid(minTile: 150, gap: wiz.space.s6, children: [
          RoomCard(name: 'Living Room', icon: WizIcons.sofa, lightCount: 3, onCount: 2, on: true, onToggle: (_) {}, onTap: () {}),
          RoomCard(name: 'Bedroom', icon: WizIcons.bed, lightCount: 2, onCount: 0, on: false, onToggle: (_) {}, onTap: () {}),
        ]),
        SizedBox(height: wiz.space.s4),
        LightCard(name: 'Ceiling dome light', meta: 'Cozy', icon: WizIcons.lampCeiling, on: _toggle, brightness: _brightness, onToggle: (v) => setState(() => _toggle = v), onBrightness: (v) => setState(() => _brightness = v), onTap: () {}),
        SizedBox(height: wiz.space.s4),
        LightCard(name: 'Hallway', meta: '192.168.1.118', icon: WizIcons.lightbulb, on: false, unreachable: true, brightness: 50, onToggle: (_) {}),
      ])),
      GallerySection(title: 'Hero', child: Column(children: [
        FixtureHero(fixture: _fixture, emission: emission),
        SizedBox(height: wiz.space.s5),
        Wrap(spacing: wiz.space.s3, children: [
          for (var f in WizFixture.values) WizChip(label: f.name, selected: f == _fixture, onTap: () => setState(() => _fixture = f)),
        ]),
      ])),
      GallerySection(title: 'States', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const WizFilamentBar(value: 0.47, label: 'Sweeping subnet'),
        SizedBox(height: wiz.space.s5),
        const WizFilamentBar(label: 'Discovering'),
        SizedBox(height: wiz.space.s5),
        WizPanel(padding: EdgeInsets.symmetric(vertical: wiz.space.s5, horizontal: wiz.space.s5 + 2), child: Row(children: [
          const WizSkeleton(height: 40, circle: true),
          SizedBox(width: wiz.space.s5 + 1),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [WizSkeleton(width: 160, height: 14), SizedBox(height: 7), WizSkeleton(width: 90, height: 10)])),
        ])),
        SizedBox(height: wiz.space.s5),
        WizStatusBanner(status: WizStatus.error, title: 'Not on the home network', body: 'This device is on 10.0.0.0/24. Lights answer only on 192.168.1.0/24.', action: WizButton(label: 'Retry', variant: WizButtonVariant.ghost, size: WizButtonSize.sm, onPressed: () {})),
        SizedBox(height: wiz.space.s5),
        const WizStatusBanner(status: WizStatus.loading, title: 'Sweeping 192.168.1.0/24', body: '68 of 254 addresses'),
        SizedBox(height: wiz.space.s5),
        Wrap(spacing: wiz.space.s4, runSpacing: wiz.space.s4, children: [
          WizButton(label: 'Success toast', size: WizButtonSize.sm, onPressed: () => widget.toasts.push(tone: WizToastTone.success, title: 'Cozy applied', body: 'to the whole home')),
          WizButton(label: 'Error toast', size: WizButtonSize.sm, onPressed: () => widget.toasts.push(tone: WizToastTone.error, title: 'No response after 3 tries', body: '192.168.1.118 did not answer on port 38899', actionLabel: 'Retry', onAction: () {})),
          WizButton(label: 'Loading toast', size: WizButtonSize.sm, onPressed: () {
            var id = widget.toasts.push(tone: WizToastTone.loading, title: 'Saving Bedside bulb');
            Future<void>.delayed(const Duration(milliseconds: 900), () => widget.toasts.update(id, tone: WizToastTone.success, title: 'Bedside bulb saved', body: '192.168.1.115 added to this home'));
          }),
        ]),
        SizedBox(height: wiz.space.s5),
        WizEmptyState(icon: WizIcons.radio, title: 'No response on the local network', body: Strings.broadcastHint, action: WizButton(label: 'Scan subnet', variant: WizButtonVariant.primary, icon: WizIcons.radio, onPressed: () {})),
      ])),
      GallerySection(title: 'Fields', child: const WizTextField(placeholder: 'Kaverappa House', height: 56)),
      GallerySection(title: 'Feedback', child: Wrap(spacing: wiz.space.s4, runSpacing: wiz.space.s4, children: [
        for (var kind in FeedbackKind.values)
          WizButton(label: kind.name, size: WizButtonSize.sm, onPressed: () => context.feedback.play(kind)),
      ])),
      Text('WIZCTL', style: wiz.type.title.copyWith(fontWeight: FontWeight.w900, letterSpacing: 30 * 0.02, color: c.amber500)),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(gutter, wiz.space.s4, gutter, wiz.space.s12 + wiz.space.tabBar),
              itemCount: sections.length,
              itemBuilder: (context, i) => RiseIn(index: i, child: sections[i]),
            ),
          ),
          WizToastLayer(
            controller: widget.toasts,
            placement: compact ? WizToastPlacement.aboveTabBar : WizToastPlacement.bottomRight,
            bottomInset: compact ? wiz.space.tabBar + wiz.space.tabBarFloat : 0,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run everything, then run on device**

```bash
flutter test && dart format lib test && flutter analyze --fatal-infos
flutter run -d macos
```

Then `flutter run -d <iphone id>` (from `flutter devices`). Walk through every section: press keys and hear clicks, drag both dials and feel detents, flick the toggle, tap the power key, spin the wheel, switch segments and tabs and watch the cap travel, push each toast, open the sheet on phone (bottom) and on macOS (dialog), resize the macOS window through the compact / medium / expanded widths. Fix what looks wrong against `design/reference/` before committing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(app): bootstrap, feedback engine wiring and the debug gallery"
```

Plan 2 is complete when the gallery runs on macOS and on the iPhone with sound and haptics, every test passes, and analyze is clean.
