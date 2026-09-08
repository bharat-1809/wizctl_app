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

  /// Shadows [ThemeExtension.type] (used internally to key the theme's
  /// extensions map), so [WizTheme.of] does not rely on
  /// `ThemeData.extension<WizTheme>()` — see the comment there.
  @override
  final WizType type;
  final WizSpace space;
  final WizElevation elevation;
  final WizMotion motion;

  /// Not `const`, and defaults are resolved in the initializer list rather
  /// than as parameter defaults: [WizElevation.standard] is `static final`
  /// (its shadow specs are built from [WizColors.standard] at construction,
  /// not from literals), so it is not a compile-time constant, and Dart
  /// requires parameter default values to be constant regardless of
  /// whether the constructor itself is `const`.
  WizTheme({
    WizColors? colors,
    WizType? type,
    WizSpace? space,
    WizElevation? elevation,
    WizMotion? motion,
  }) : colors = colors ?? WizColors.standard,
       type = type ?? WizType.standard,
       space = space ?? WizSpace.standard,
       elevation = elevation ?? WizElevation.standard,
       motion = motion ?? WizMotion.standard;

  static final WizTheme standard = WizTheme();

  /// Not `Theme.of(context).extension<WizTheme>()`: that keys its lookup by
  /// each extension's [type] getter, which [WizTheme.type] shadows with the
  /// [WizType] token group instead of the `WizTheme` runtime type the
  /// framework expects there. Scanning `extensions.values` finds the
  /// installed [WizTheme] regardless.
  static WizTheme of(BuildContext context) {
    for (final extension in Theme.of(context).extensions.values) {
      if (extension is WizTheme) return extension;
    }
    return standard;
  }

  @override
  WizTheme copyWith() => this;

  @override
  WizTheme lerp(ThemeExtension<WizTheme>? other, double t) => this;
}

extension WizThemeContext on BuildContext {
  WizTheme get wiz => WizTheme.of(this);
}

/// The Material theme underneath the kit: dark, no ripples, warm ink, and
/// the design faces built explicitly into the text theme so any stray
/// Material widget still reads right.
ThemeData buildWizThemeData() {
  final wiz = WizTheme.standard;
  final c = wiz.colors;
  final t = wiz.type;
  final scheme = ColorScheme.dark(
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
    // No `fontFamily:` here: that stamps the display face onto every
    // Material text style, including body text. Each Material slot below
    // is assigned its WizType style explicitly instead.
    textTheme: TextTheme(
      displayLarge: t.hero,
      displayMedium: t.display,
      titleLarge: t.title,
      titleMedium: t.heading,
      bodyLarge: t.bodyLg,
      bodyMedium: t.body,
      bodySmall: t.bodySm,
      labelLarge: t.label,
      labelSmall: t.caption,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.amber400,
      selectionColor: c.accentSoft,
      selectionHandleColor: c.amber400,
    ),
    extensions: [wiz],
  );
}
