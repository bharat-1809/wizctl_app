import 'package:flutter/material.dart';

import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_chip.dart';
import '../../core/widgets/wiz_icon_key.dart';
import 'gallery_section.dart';

/// Every variant and size of the three key shapes, plus the disabled state.
class GalleryKeys extends StatelessWidget {
  const GalleryKeys({super.key});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return GallerySection(
      title: 'Keys',
      child: Wrap(
        spacing: space.s4,
        runSpacing: space.s4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          WizButton(
            label: 'Create home',
            variant: WizButtonVariant.primary,
            icon: WizIcons.housePlus,
            onPressed: () {},
          ),
          WizButton(
            label: Strings.scanAgain,
            variant: WizButtonVariant.ghost,
            icon: WizIcons.refreshCw,
            onPressed: () {},
          ),
          WizButton(
            label: Strings.save,
            variant: WizButtonVariant.primary,
            size: WizButtonSize.lg,
            icon: WizIcons.check,
            onPressed: () {},
          ),
          WizButton(
            label: 'Rename',
            size: WizButtonSize.sm,
            icon: WizIcons.pencil,
            onPressed: () {},
          ),
          WizButton(
            label: 'Forget',
            variant: WizButtonVariant.danger,
            size: WizButtonSize.sm,
            icon: WizIcons.trash,
            onPressed: () {},
          ),
          // No handler: the key must read as disabled and stay silent.
          const WizButton(label: 'Disabled', onPressed: null),
          WizIconKey(
            icon: WizIcons.house,
            onPressed: () {},
            semanticsLabel: 'Homes',
          ),
          WizIconKey(
            icon: WizIcons.lightbulb,
            active: true,
            onPressed: () {},
            semanticsLabel: 'Blink',
          ),
          WizIconKey(
            icon: WizIcons.settings,
            size: WizKeySize.lg,
            shape: WizKeyShape.squircle,
            onPressed: () {},
            semanticsLabel: 'Settings',
          ),
          WizIconKey(
            icon: WizIcons.ellipsis,
            size: WizKeySize.sm,
            enabled: false,
            semanticsLabel: 'More',
          ),
          WizChip(label: 'Living Room', selected: true, onTap: () {}),
          WizChip(label: 'Bedroom', onTap: () {}),
          WizChip(
            label: 'New room',
            icon: WizIcons.plus,
            accentText: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
