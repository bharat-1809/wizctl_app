import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/widgets/wiz_icon_key.dart';
import '../blocs/blink_cubit.dart';

/// The flash key beside a discovered or saved light: amber while that
/// address is blinking (spec §5.10, §10.1).
class BlinkKey extends StatelessWidget {
  final String ip;
  final BulbClass? bulbClass;
  final WizKeySize size;

  const BlinkKey({
    super.key,
    required this.ip,
    this.bulbClass,
    this.size = WizKeySize.md,
  });

  @override
  Widget build(BuildContext context) {
    var blinking = context.select<BlinkCubit, bool>(
      (c) => c.state.isBlinking(ip),
    );
    return WizIconKey(
      icon: WizIcons.lightbulb,
      size: size,
      active: blinking,
      semanticsLabel: Strings.blinkLight,
      onPressed: () =>
          context.read<BlinkCubit>().blink(ip, bulbClass: bulbClass),
    );
  }
}
