import 'package:flutter/material.dart';

/// Type tokens from `tokens/typography.css`.
///
/// The user's words are set in the grotesque, the machine's words in mono,
/// the instrument's numbers in the display face. Letter-spacing values in the
/// CSS are in em; here they are already multiplied out to logical pixels.
///
/// The design named Neumatic Compressed as its display face. On device it
/// reads only at hero size: its glyphs are a quarter of an em wide, and at
/// 18–34 px in mixed case the readouts and headings did not read at all. So
/// on 2026-09-12 the display role moved to Big Shoulders Display — open
/// licence, condensed, digits narrow enough for the dial well — and Neumatic
/// kept the 64 px hero alone.
@immutable
class WizType {
  const WizType._();

  static const WizType standard = WizType._();

  /// The display face: every display style but [hero].
  static const String familyDisplay = 'BigShouldersDisplay';

  /// The hero's face: Neumatic Compressed, at the one size it reads.
  static const String familyHero = 'NeumaticCompressed';
  static const String familyUi = 'HankenGrotesk';
  static const String familyMono = 'JetBrainsMono';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Uppercase control labels track wide: 0.10 em (design system
  /// `--label-ls`, `tokens/typography.css`).
  static const double labelTracking = 0.10;

  /// `WizSegmentedControl` items track: 0.08 em (design system §11.2,
  /// `WizSegmentedControl`).
  static const double segmentTracking = 0.08;

  /// A `WizListRow` title tracks in a hair: -0.005 em (ListRow.jsx, the
  /// 16 px title's `letterSpacing: '-.005em'`).
  static const double rowTitleTracking = -0.005;

  /// A `RoomCard` title tracks twice as tight as a row's: -0.01 em
  /// (RoomCard.jsx, the 19 px name's `letterSpacing: '-.01em'`,
  /// `design/reference/_ds_bundle.js:2065`).
  static const double roomTitleTracking = -0.01;

  /// A `LightCard`'s brightness meter reads out the other way: 0.015 em
  /// (LightCard.jsx, the 18 px display readout's `letterSpacing: '.015em'`,
  /// `design/reference/_ds_bundle.js:1971`).
  static const double meterReadoutTracking = 0.015;

  // SceneTile.jsx label — the design system's scene *chip*: UI face 13.5/15
  // with letter-spacing -0.005 em.
  static const double sceneLabelTracking = -0.005;

  /// The scene *tile*'s label is the display face and tracks the other way:
  /// 0.02 em in both variants (`design/reference/WizCtl_Mobile.dc.html:396`
  /// for the 20 px tab grid, `:562` for the 14 px sheet).
  static const double sceneTileTracking = 0.02;

  // WIZCTL wordmark (Sidebar brand): display face, weight 900, 0.02 em.
  static const double wordmarkTracking = 0.02;

  /// Neumatic Compressed never tracks tighter than [neumaticTrackingPad]
  /// logical pixels plus [neumaticTrackingEm] of its size.
  ///
  /// Impeller — the only renderer Flutter 3.47 has on iOS and macOS — draws
  /// that face with rectangular cut-outs wherever the boxes of two
  /// neighbouring glyphs overlap; Skia and CoreText draw it cleanly. Its
  /// sidebearings are close to zero, so at the design's −0.005 em every run
  /// of it overlapped. A probe on macOS at 2× on 2026-09-12 found the
  /// cut-outs gone from about 1 px at 13–34 px and 2 px at 64 px: a fixed
  /// margin the renderer pads each glyph with, plus an overshoot that grows
  /// with the size. This floor is roughly twice that, so a 1× screen stays
  /// clear. The hero's design value sits under it and takes the floor
  /// outright; Big Shoulders Display needs none of this.
  static const double neumaticTrackingPad = 1;
  static const double neumaticTrackingEm = 0.03;

  /// Tracking for Neumatic Compressed at [size]: the floor above.
  static double neumaticTracking(double size) =>
      size * neumaticTrackingEm + neumaticTrackingPad;

  // Design: −0.005 em, under the Neumatic floor.
  final TextStyle hero = const TextStyle(
    fontFamily: familyHero,
    fontSize: 64,
    height: 0.92,
    letterSpacing: 64 * neumaticTrackingEm + neumaticTrackingPad,
    fontWeight: FontWeight.w800,
  );
  final TextStyle display = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 44,
    height: 0.98,
    letterSpacing: 44 * 0.005,
    fontWeight: FontWeight.w700,
  );
  final TextStyle title = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 30,
    height: 1.06,
    letterSpacing: 30 * 0.015,
    fontWeight: FontWeight.w700,
  );
  final TextStyle heading = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 23,
    height: 1.16,
    letterSpacing: 23 * 0.025,
    fontWeight: FontWeight.w600,
  );
  final TextStyle bodyLg = const TextStyle(
    fontFamily: familyUi,
    fontSize: 17,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  final TextStyle body = const TextStyle(
    fontFamily: familyUi,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  final TextStyle bodySm = const TextStyle(
    fontFamily: familyUi,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
  final TextStyle caption = const TextStyle(
    fontFamily: familyUi,
    fontSize: 11,
    height: 1.35,
    letterSpacing: 11 * 0.06,
    fontWeight: FontWeight.w400,
  );

  /// Uppercase control label; callers pass `text.toUpperCase()`.
  final TextStyle label = const TextStyle(
    fontFamily: familyUi,
    fontSize: 11,
    height: 1.35,
    letterSpacing: 11 * labelTracking,
    fontWeight: FontWeight.w600,
  );

  /// Tabular figures are asked for so a ticking value holds still; Big
  /// Shoulders Display ships none, so its digits keep their own widths.
  final TextStyle readout = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  final TextStyle readoutSm = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 18,
    height: 1,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  final TextStyle code = const TextStyle(
    fontFamily: familyMono,
    fontSize: 12.5,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  /// Mono at the small size rows use for `ip · class` (11.5).
  final TextStyle mono = const TextStyle(
    fontFamily: familyMono,
    fontSize: 11.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
}
