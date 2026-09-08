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

  /// Disabled controls render at this opacity (spec §11.2, "Disabled:
  /// opacity 0.42").
  static const double disabledAlpha = 0.42;

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

  // Neumorphic elevation bases
  final Color highlightBase = const Color(0xFFFFFFFF); // neumorphic highlight base; elevation.css --nm-hi/--nm-hi-strong are this at .075/.13
  final Color shadowBase = const Color(
    0xFF000000,
  ); // neumorphic shadow base; elevation.css --nm-lo is this at .60

  // Kelvin ramp, keyed by kelvin. The single definition of the ramp;
  // `color_maths.dart` reads this map rather than declaring its own stops.
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
    hueRed,
    hueOrange,
    hueYellow,
    hueLime,
    hueGreen,
    hueTeal,
    hueCyan,
    hueBlue,
    hueIndigo,
    hueViolet,
    hueMagenta,
    huePink,
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
