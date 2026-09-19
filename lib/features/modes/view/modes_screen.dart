import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/scene_gradients.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import '../widgets/modes_body.dart';
import '../widgets/modes_layout.dart';
import '../widgets/target_sheet.dart';

/// The Scenes tab (`/modes`, spec §10.5): the APPLY TO well key, then the
/// modes body at the tab's sizes.
class ModesScreen extends StatelessWidget {
  final String homeId;
  const ModesScreen({super.key, required this.homeId});

  /// The chevron in the well key (`WizCtl_Mobile.dc.html` line 351).
  static const double chevron = 18;

  @override
  Widget build(BuildContext context) {
    var layout = context.layout.widthClass.isCompact
        ? ModesLayout.compactTab
        : ModesLayout.desktopTab;
    return BlocBuilder<LightModesBloc, LightModesState>(
      builder: (context, state) => ScreenScroll(
        children: [
          WizTopBar(
            title: Strings.lightModes,
            subtitle: Strings.modesSubtitle(
              staticScenes.length,
              dynamicScenes.length,
            ),
          ),
          _ApplyToKey(
            name: state.target is WholeHomeTarget
                ? Strings.wholeHome
                : state.targetName ?? Strings.wholeHome,
            onTap: () async {
              var bloc = context.read<LightModesBloc>();
              var picked = await showTargetSheet(
                context,
                homeId: homeId,
                current: state.target,
              );
              if (picked != null) bloc.add(ModesTargetChanged(picked));
            },
          ),
          ModesBody(layout: layout),
        ],
      ),
    );
  }
}

/// "APPLY TO" over the target's name with a chevron, as a raised key.
class _ApplyToKey extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _ApplyToKey({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPressable(
      onTap: onTap,
      semanticsLabel: Strings.applyTo,
      scale: wiz.motion.keyScale,
      focusRadius: BorderRadius.circular(wiz.space.r3),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.raised,
        radius: BorderRadius.circular(wiz.space.r3),
        gradient: wizVertical(
          wiz.colors.surfaceRaised,
          wiz.colors.surfacePanel,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.s6,
          vertical: wiz.space.s5,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel(Strings.applyTo),
                  SizedBox(height: wiz.space.s1),
                  Text(
                    name,
                    style: wiz.typography.heading.copyWith(
                      color: wiz.colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            WizIcon(
              WizIcons.chevronDown,
              size: ModesScreen.chevron,
              color: wiz.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
