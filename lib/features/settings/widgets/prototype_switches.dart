import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/settings_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_toggle.dart';

/// The debug-only block (spec §18): the three prototype switches, which set
/// the `DebugFlags` the fakes read, and — the user's decision for this plan —
/// the row to the widget gallery. Only ever built under `kDebugMode`; the
/// screen does the checking, so this widget stays testable.
class PrototypeSwitches extends StatelessWidget {
  const PrototypeSwitches({super.key});

  /// The chevron at the end of a row that leads somewhere
  /// (`WizCtl_Mobile.dc.html` line 1239: `icoChevron` is `chevron-right` at
  /// 18), the size `RoomsScreen` draws it at too.
  static const double chevron = 18;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var cubit = context.read<SettingsCubit>();
    var flags = context.watch<SettingsCubit>().state.debugFlags;
    var gap = SizedBox(height: wiz.space.s3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(Strings.prototypeSwitches),
        gap,
        WizListRow(
          icon: WizIcons.wifi,
          title: Strings.wrongNetwork,
          meta: Strings.showOffline,
          trailing: WizToggle(
            value: flags.offNetwork,
            size: WizToggleSize.sm,
            onChanged: cubit.setOffNetwork,
            semanticsLabel: Strings.wrongNetwork,
          ),
        ),
        gap,
        WizListRow(
          icon: WizIcons.clock,
          title: Strings.forceTimeout,
          meta: Strings.forceTimeoutMeta,
          trailing: WizToggle(
            value: flags.forceTimeout,
            size: WizToggleSize.sm,
            onChanged: cubit.setForceTimeout,
            semanticsLabel: Strings.forceTimeout,
          ),
        ),
        gap,
        WizListRow(
          icon: WizIcons.search,
          title: Strings.findsNothing,
          meta: Strings.findsNothingMeta,
          trailing: WizToggle(
            value: flags.findNothing,
            size: WizToggleSize.sm,
            onChanged: cubit.setFindNothing,
            semanticsLabel: Strings.findsNothing,
          ),
        ),
        gap,
        WizListRow(
          icon: WizIcons.layoutGrid,
          title: Strings.widgetGallery,
          meta: Strings.widgetGalleryMeta,
          trailing: WizIcon(
            WizIcons.chevronRight,
            size: chevron,
            color: wiz.colors.textTertiary,
          ),
          onTap: () => context.push(AppRoutes.gallery),
        ),
      ],
    );
  }
}
