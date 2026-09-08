import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_theme.dart';
import 'package:wizctl_app/core/theme/wiz_type.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('context.wiz exposes every token group', (tester) async {
    late WizTheme wiz;
    late BuildContext capturedContext;
    await tester.pumpWidget(
      wizTestApp(
        Builder(
          builder: (context) {
            wiz = context.wiz;
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(wiz.colors.amber500, const Color(0xFFFFB020));
    expect(wiz.space.hitMin, 44);
    expect(wiz.motion.press.inMilliseconds, 80);
    expect(wiz.typography.body.fontFamily, 'HankenGrotesk');
    expect(wiz.elevation.panel.outer, isNotEmpty);
    // The extension contract itself must work: `type` is no longer shadowed,
    // so the standard framework lookup finds the installed WizTheme.
    expect(Theme.of(capturedContext).extension<WizTheme>(), isNotNull);
  });

  testWidgets('the theme paints the app surface and warm ink', (tester) async {
    late ThemeData theme;
    await tester.pumpWidget(
      wizTestApp(
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(theme.scaffoldBackgroundColor, const Color(0xFF101013));
    expect(theme.colorScheme.onSurface, const Color(0xFFF6F3ED));
    expect(theme.brightness, Brightness.dark);
    expect(theme.splashFactory, NoSplash.splashFactory);
  });

  testWidgets('the text theme carries the design faces, not a blanket one', (
    tester,
  ) async {
    late ThemeData theme;
    await tester.pumpWidget(
      wizTestApp(
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(theme.textTheme.displayLarge?.fontFamily, WizType.familyDisplay);
    expect(theme.textTheme.bodyMedium?.fontFamily, WizType.familyUi);
  });

  testWidgets('context.wiz finds the installed WizTheme, not always standard', (
    tester,
  ) async {
    // `ThemeExtension.type` is the key `ThemeData` uses for its extensions
    // map, and `WizTheme` no longer shadows it with a field of its own
    // (that field is `typography`, not `type`), so the standard
    // `Theme.of(context).extension<WizTheme>()` lookup finds a non-default
    // installed WizTheme rather than always falling back to `standard`.
    final installed = WizTheme(colors: WizColors.standard);
    late WizTheme found;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildWizThemeData().copyWith(extensions: [installed]),
        home: Builder(
          builder: (context) {
            found = context.wiz;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(found, installed), isTrue);
  });
}
