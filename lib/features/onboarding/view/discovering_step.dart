import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_filament_bar.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/entities/entities.dart';
import '../../discovery/bloc/discovery_bloc.dart';
import '../../discovery/bloc/discovery_event.dart';
import '../../discovery/bloc/discovery_state.dart';
import '../../discovery/widgets/discovery_empty.dart';
import '../../discovery/widgets/skeleton_rows.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../widgets/keep_row.dart';
import '../widgets/radar.dart';

/// Step 2, "Discovering" (spec §10.1): the broadcast runs on entry and the
/// sweep only when the user asks. The kept rows go on to naming.
class DiscoveringStep extends StatefulWidget {
  const DiscoveringStep({super.key});

  @override
  State<DiscoveringStep> createState() => _DiscoveringStepState();
}

class _DiscoveringStepState extends State<DiscoveringStep> {
  @override
  void initState() {
    super.initState();
    // Only from idle: coming back to this step from naming must not throw away
    // the rows the user already picked over.
    var discovery = context.read<DiscoveryBloc>();
    if (discovery.state.view == DiscoveryView.idle) {
      discovery.add(const DiscoveryStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var onboarding = context.read<OnboardingBloc>();
    var discovery = context.read<DiscoveryBloc>();
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        var progress = state.progress;
        var subnet = state.subnet;
        var sweeping = state.view == DiscoveryView.sweeping;
        // Only a sweep knows how far along it is, address by address; a
        // broadcast is one wait with nothing to count.
        var counted = sweeping && progress != null && progress.isDeterminate
            ? progress
            : null;
        // Which run the rows on show came from: a sweep can say how many
        // addresses it walked, a broadcast only which network it went out on.
        // The phase of the last progress report decides, never `sweptOnce`,
        // which latches for the step's life (P74).
        var sweptJustNow = progress?.phase == DiscoveryPhase.sweeping;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WizTopBar(
              title: Strings.discovering,
              subtitle: counted == null
                  ? Strings.localNetwork
                  : Strings.addresses(counted.probed, counted.total),
              leading: WizIconKey(
                icon: WizIcons.chevronLeft,
                semanticsLabel: Strings.back,
                onPressed: () {
                  // Cancel first: the run's own wind-down can take as long
                  // as the gateway's timeout, and the step is leaving now.
                  discovery.add(const DiscoveryCancelled());
                  onboarding.add(const OnboardingBack());
                },
              ),
            ),
            SizedBox(height: wiz.space.s6),
            if (state.isScanning) ...[
              const Center(child: Radar()),
              SizedBox(height: wiz.space.s6),
              WizFilamentBar(
                label: sweeping
                    ? Strings.sweepingSubnet
                    : Strings.listeningForLights,
                value: counted?.fraction,
              ),
              SizedBox(height: wiz.space.s6),
              const SkeletonRows(),
            ] else if (state.view == DiscoveryView.found) ...[
              WizStatusBanner(
                status: WizStatus.success,
                title: Strings.lightsAnswered(state.found.length),
                body: subnet == null
                    ? Strings.localNetwork
                    : sweptJustNow
                    ? Strings.sweptSubnet(subnet, progress?.total ?? 0)
                    : Strings.broadcastOn(subnet),
                action: const WizBadge(
                  label: Strings.live,
                  tone: WizBadgeTone.online,
                  dot: true,
                ),
              ),
              for (var row in state.found) ...[
                SizedBox(height: wiz.space.s4),
                KeepRow(
                  row: row,
                  onToggle: () =>
                      discovery.add(DiscoveryKeepToggled(row.device.ip)),
                ),
              ],
              SizedBox(height: wiz.space.s6),
              WizButton(
                label: Strings.saveNLights(state.keptCount),
                variant: WizButtonVariant.primary,
                fullWidth: true,
                enabled: state.keptCount > 0,
                // The rows the user kept, as the state's own getter reports
                // them: the bloc filters again on the way in, so this reads
                // the way the event's contract does.
                onPressed: () =>
                    onboarding.add(OnboardingToNaming(state.kept, subnet)),
              ),
              SizedBox(height: wiz.space.s4),
              WizButton(
                label: Strings.scanAgain,
                variant: WizButtonVariant.ghost,
                icon: WizIcons.refreshCw,
                fullWidth: true,
                onPressed: () => discovery.add(const DiscoveryStarted()),
              ),
            ] else
              // Idle, nothing found and a run that failed are the same three
              // zero states the discovery screen shows, including the
              // wrong-network copy a failure keys on (P91), so they are drawn
              // by the same widget rather than written twice.
              DiscoveryEmpty(state: state),
          ],
        );
      },
    );
  }
}
