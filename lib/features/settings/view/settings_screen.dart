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

/// Settings (spec §10.7) with the prototype switches a debug build adds
/// (spec §18).
///
/// [UnreachableBanner] shrinks to nothing when every light answers, and the
/// list still puts its gap after it: 12 px of extra air on this one screen,
/// taken rather than reading the cubit here as well to decide whether the
/// banner is worth a slot.
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
          subtitle: desktop
              ? Strings.homeLivesOnMachine
              : Strings.homeLivesOnDevice,
        ),
        const UnreachableBanner(),
        const SettingsRows(),
        WizPanel(
          variant: WizPanelVariant.inset,
          child: Text(
            Strings.privacy,
            style: wiz.typography.bodySm.copyWith(
              color: wiz.colors.textTertiary,
            ),
          ),
        ),
        if (kDebugMode) const PrototypeSwitches(),
        const AboutCaption(),
      ],
    );
  }
}
