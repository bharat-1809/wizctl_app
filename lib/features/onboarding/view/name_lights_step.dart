import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/assign_card.dart';

/// Step 3, "Name your lights" (spec §10.1): one card per kept light, and the
/// key that writes the home.
class NameLightsStep extends StatelessWidget {
  const NameLightsStep({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<OnboardingBloc>();
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // P67, as on step 2: Back is the only labelled control in the bar,
          // so without this the bar reads as one button carrying its titles.
          Semantics(
            container: true,
            explicitChildNodes: true,
            child: WizTopBar(
              title: Strings.nameYourLights,
              subtitle: Strings.nameReplacesAddress,
              leading: WizIconKey(
                icon: WizIcons.chevronLeft,
                semanticsLabel: Strings.back,
                // Once the finish is away the flow is over, whether it is
                // still in flight or already written: there is nothing to go
                // back to, and the notice navigates on.
                onPressed: state.finishing
                    ? null
                    : () => bloc.add(const OnboardingBack()),
              ),
            ),
          ),
          SizedBox(height: wiz.space.s5),
          Text(
            Strings.blinkHint,
            style: wiz.typography.bodySm.copyWith(
              color: wiz.colors.textTertiary,
            ),
          ),
          for (var (i, row) in state.kept.indexed) ...[
            SizedBox(height: wiz.space.s6),
            RiseIn(
              index: i,
              child: AssignCard(
                // Identity by address, so a card keeps its field's controller
                // across every rebuild the bloc causes.
                key: ValueKey(row.device.ip),
                row: row,
                assignment: state.assignments[row.device.ip]!,
                rooms: state.setupRooms,
              ),
            ),
          ],
          SizedBox(height: wiz.space.s7),
          WizButton(
            label: Strings.finishSetup,
            variant: WizButtonVariant.primary,
            fullWidth: true,
            // `finishing` stays true after a finish that succeeded (P75), so
            // this also stops a second press writing a second home; only a
            // refusal clears it and offers the key again.
            enabled: state.namesComplete && !state.finishing,
            onPressed: () => bloc.add(const OnboardingFinished()),
          ),
        ],
      ),
    );
  }
}
