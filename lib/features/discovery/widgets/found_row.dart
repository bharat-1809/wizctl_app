import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/blink_cubit.dart';
import '../../../app/widgets/blink_key.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/light_card_well.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../domain/entities/entities.dart';

/// One device that answered (spec §10.8): the well lights while it blinks,
/// the flash key, and Save — or a spent Saved once it is in the home.
class FoundRow extends StatelessWidget {
  final FoundDevice row;

  /// Null while this row's save is in flight, which also disables the key: a
  /// second tap would save the light twice.
  final VoidCallback? onSave;

  const FoundRow({super.key, required this.row, required this.onSave});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var device = row.device;
    var blinking = context.select<BlinkCubit, bool>(
      (c) => c.state.isBlinking(device.ip),
    );
    var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
    return WizListRow(
      iconWidget: LightCardWell(icon: WizIcons.lightbulb, lit: blinking),
      title: device.displayName,
      meta: Strings.ipAndClass(device.ip, cls),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlinkKey(ip: device.ip, bulbClass: device.bulbClass),
          SizedBox(width: space.s3),
          device.alreadySaved
              ? const WizButton(
                  label: Strings.saved,
                  variant: WizButtonVariant.ghost,
                  size: WizButtonSize.sm,
                  enabled: false,
                )
              : WizButton(
                  label: Strings.save,
                  variant: WizButtonVariant.primary,
                  size: WizButtonSize.sm,
                  enabled: onSave != null,
                  onPressed: onSave,
                ),
        ],
      ),
    );
  }
}
