import 'package:flutter/material.dart';

/// Type tokens from `tokens/typography.css`.
///
/// The user's words are set in the grotesque, the machine's words in mono,
/// the instrument's numbers in the display face. Letter-spacing values in the
/// CSS are in em; here they are already multiplied out to logical pixels —
/// except on the display face, which takes the floor in [displayTracking]
/// wherever it is set.
@immutable
class WizType {
  const WizType._();

  static const WizType standard = WizType._();

  static const String familyDisplay = 'NeumaticCompressed';
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

  // SceneTile.jsx label — the design system's scene *chip*: UI face 13.5/15
  // with letter-spacing -0.005 em.
  static const double sceneLabelTracking = -0.005;

  /// The display face never tracks tighter than [displayTrackingPad] logical
  /// pixels plus [displayTrackingEm] of its size.
  ///
  /// Impeller — the only renderer Flutter 3.47 has on iOS and macOS — draws
  /// Neumatic Compressed with rectangular cut-outs wherever the boxes of two
  /// neighbouring glyphs overlap; Skia and CoreText draw the same font
  /// cleanly. The face's sidebearings are close to zero, so at the design's
  /// tracking (−0.005 em on hero up to 0.025 em on heading; .01 em on the
  /// dial readout, .015 em on the light card's meter, .02 em on scene tiles
  /// and the wordmark) every run of it overlaps. A probe on macOS at 2× on
  /// 2026-09-12 found the cut-outs gone from about 1 px at 13–34 px and 2 px
  /// at 64 px: a fixed margin the renderer pads each glyph with, plus an
  /// overshoot that grows with the size. This floor is roughly twice that,
  /// so a 1× screen and the largest readouts stay clear. Every design value
  /// above sits under it, so every display style takes the floor outright.
  static const double displayTrackingPad = 1;
  static const double displayTrackingEm = 0.03;

  /// Tracking for the display face at [size]: the floor above. A caller that
  /// resizes a display style passes the new size here rather than keeping
  /// the spacing the style was built with.
  static double displayTracking(double size) =>
      size * displayTrackingEm + displayTrackingPad;

  // Design: −0.005 em, under the display floor.
  final TextStyle hero = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 64,
    height: 0.92,
    letterSpacing: 64 * displayTrackingEm + displayTrackingPad,
    fontWeight: FontWeight.w800,
  );
  // Design: 0.005 em, under the display floor.
  final TextStyle display = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 44,
    height: 0.98,
    letterSpacing: 44 * displayTrackingEm + displayTrackingPad,
    fontWeight: FontWeight.w700,
  );
  // Design: 0.015 em, under the display floor.
  final TextStyle title = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 30,
    height: 1.06,
    letterSpacing: 30 * displayTrackingEm + displayTrackingPad,
    fontWeight: FontWeight.w700,
  );
  // Design: 0.025 em, under the display floor.
  final TextStyle heading = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 23,
    height: 1.16,
    letterSpacing: 23 * displayTrackingEm + displayTrackingPad,
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
  // Design: no tracking; the display floor applies.
  final TextStyle readout = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 34,
    height: 1,
    letterSpacing: 34 * displayTrackingEm + displayTrackingPad,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );
  // Design: no tracking; the display floor applies.
  final TextStyle readoutSm = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 18,
    height: 1,
    letterSpacing: 18 * displayTrackingEm + displayTrackingPad,
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
