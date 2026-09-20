import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/copy/strings.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_status_banner.dart';
import '../../domain/entities/entities.dart';
import '../blocs/unreachable_cubit.dart';
import '../routes.dart';

/// "One light did not answer", or the count with the first one named, and
/// Rescan (spec §15). Nothing at all when every light answers, so screens can
/// place it unconditionally, the way `OffNetworkBanner` is placed.
///
/// A condition, not an event: it has no dismissal. It goes when the lights
/// answer, and Rescan opens discovery rather than resending anything, because
/// a light that is silent needs finding, not another write.
class UnreachableBanner extends StatelessWidget {
  const UnreachableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreachableCubit, List<Light>>(
      builder: (context, lights) {
        if (lights.isEmpty) return const SizedBox.shrink();
        return WizStatusBanner(
          status: WizStatus.error,
          title: lights.length == 1
              ? Strings.oneLightDidNotAnswer
              : Strings.lightsDidNotAnswer(lights.length),
          body: Strings.mayBeOffAtWallNamed(lights.first.name),
          action: WizButton(
            label: Strings.rescan,
            variant: WizButtonVariant.ghost,
            size: WizButtonSize.sm,
            onPressed: () => context.go(AppRoutes.discover),
          ),
        );
      },
    );
  }
}
