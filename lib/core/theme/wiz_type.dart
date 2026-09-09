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

  /// Uppercase control labels track wide: 0.10 em (design system
  /// `--label-ls`, `tokens/typography.css`).
  static const double labelTracking = 0.10;

  /// `WizSegmentedControl` items track: 0.08 em (design system §11.2,
  /// `WizSegmentedControl`).
  static const double segmentTracking = 0.08;

  /// A `WizListRow` title tracks in a hair: -0.005 em (ListRow.jsx, the
  /// 16 px title's `letterSpacing: '-.005em'`).
  static const double rowTitleTracking = -0.005;

  // SceneTile.jsx label — the design system's scene *chip*: UI face 13.5/15
  // with letter-spacing -0.005 em.
  static const double sceneLabelTracking = -0.005;

  /// The scene *tile*'s label is the display face and tracks the other way:
  /// 0.02 em in both variants (`design/reference/WizCtl_Mobile.dc.html:396`
  /// for the 20 px tab grid, `:562` for the 14 px sheet).
  static const double sceneTileTracking = 0.02;

  // WIZCTL wordmark (Sidebar brand): display face, weight 900, 0.02 em.
  static const double wordmarkTracking = 0.02;

  final TextStyle hero = const TextStyle(
    fontFamily: familyDisplay,
    fontSize: 64,
    height: 0.92,
    letterSpacing: 64 * -0.005,
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
