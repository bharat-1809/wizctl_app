import 'package:flutter/material.dart';

import '../../../app/widgets/fixture_kind.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../domain/entities/entities.dart';

/// Spec §10.4, "grid of the five fixtures, min tile 100".
const double fixtureTileMin = 100;

/// "Show it as" (spec §10.4): the five fixtures, min tile 100, the current
/// one amber. Resolves to the pick, or null.
Future<Fixture?> showFixtureSheet(
  BuildContext context, {
  required Fixture current,
}) {
  // Read before the sheet is built, not from inside it: the sheet is pushed
  // on the root navigator, and a tile that popped its own context would take
  // the wrong route down.
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
            style: wiz.typography.bodySm.copyWith(
              color: wiz.colors.textTertiary,
            ),
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

class _FixtureTile extends StatelessWidget {
  final Fixture fixture;
  final bool selected;
  final VoidCallback onTap;

  const _FixtureTile({
    required this.fixture,
    required this.selected,
    required this.onTap,
  });

  /// `WizCtl_Mobile.dc.html` line 655: `icXl` in the fixture option.
  static const double glyph = 26;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var label = fixtureLabelOf(fixture);
    return WizPressable(
      onTap: onTap,
      semanticsLabel: label,
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
              color: selected
                  ? wiz.colors.textOnAccent
                  : wiz.colors.textSecondary,
            ),
            SizedBox(height: wiz.space.s3),
            Text(
              label,
              style: wiz.typography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: selected
                    ? wiz.colors.textOnAccent
                    : wiz.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
