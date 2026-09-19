import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/copy/strings.dart';
import '../../core/widgets/toast_controller.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_status_banner.dart';
import '../blocs/network_cubit.dart';
import '../blocs/network_state.dart';

/// The wrong-network condition (spec §15): a banner while it lasts, and the
/// "Still on …" toast when a retry changes nothing. Nothing at all on the
/// home network, so screens can place it unconditionally.
class OffNetworkBanner extends StatelessWidget {
  const OffNetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, state) {
        if (state.notice case StillOffNotice(:var currentSubnet)) {
          context.read<ToastController>().push(
            tone: WizToastTone.error,
            title: currentSubnet == null
                ? Strings.noLocalNetwork
                : Strings.stillOn(currentSubnet),
            body: Strings.joinHomeNetwork,
          );
        }
        context.read<NetworkCubit>().clearNotice();
      },
      child: BlocBuilder<NetworkCubit, NetworkState>(
        builder: (context, state) {
          if (!state.offNetwork) return const SizedBox.shrink();
          var current = state.currentSubnet;
          var home = state.homeSubnet;
          return WizStatusBanner(
            // The wifi glyph the `warn` tone carries is what this copy is
            // about (spec §11.2 pairs the two); §15 names no tone, and the
            // prototype's `error` would put an x beside a wifi condition.
            status: WizStatus.warn,
            title: Strings.notOnHomeNetworkTitle,
            body: current == null || home == null
                ? Strings.noLocalNetwork
                : Strings.deviceOn(current, home),
            action: WizButton(
              label: Strings.retry,
              variant: WizButtonVariant.ghost,
              size: WizButtonSize.sm,
              onPressed: () => context.read<NetworkCubit>().retry(),
            ),
          );
        },
      ),
    );
  }
}
