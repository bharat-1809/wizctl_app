import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';

/// Whatever the screen shows when no device is on it (spec §10.8): nothing
/// tried yet, nothing answered (before or after a sweep), and a run that
/// failed.
class DiscoveryEmpty extends StatelessWidget {
  final DiscoveryState state;
  const DiscoveryEmpty({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<DiscoveryBloc>();
    switch (state.view) {
      case DiscoveryView.idle:
        return WizEmptyState(
          icon: WizIcons.radio,
          title: Strings.nothingFoundYet,
          body: Strings.lightsAnswerLocally,
          action: WizButton(
            label: Strings.discoverLights,
            variant: WizButtonVariant.primary,
            icon: WizIcons.radio,
            onPressed: () => bloc.add(const DiscoveryStarted()),
          ),
        );
      case DiscoveryView.error:
        // P71: the copy is keyed on the failure's type, never on its message.
        // A run that threw something the domain never modelled arrives as an
        // `UnreachableFailure` with no address, whose own message would read
        // "Cannot reach : …"; and the one failure the user can act on
        // differently is being on the wrong network.
        var wrongNetwork = state.failure is OffNetworkFailure;
        return WizEmptyState(
          icon: WizIcons.radio,
          title: wrongNetwork
              ? Strings.notOnHomeNetworkTitle
              : Strings.searchFailedTitle,
          body: wrongNetwork
              ? Strings.joinHomeNetwork
              : Strings.searchFailedBody,
          // The sweep is offered on every failure, with no gate (P91 as
          // amended): `state.subnet` is always null after a quick run that
          // threw — only the sweeping phase and `DiscoveryFinished` carry one
          // — and `sweep()` learns its own range anyway, which is why the
          // empty view offers the same key ungated. A broadcast with no route
          // is otherwise a dead end on the first run.
          action: Wrap(
            alignment: WrapAlignment.center,
            spacing: wiz.space.s5,
            runSpacing: wiz.space.s5,
            children: [
              WizButton(
                label: Strings.tryAgain,
                variant: WizButtonVariant.primary,
                onPressed: () => bloc.add(const DiscoveryStarted()),
              ),
              WizButton(
                label: Strings.scanSubnet,
                variant: WizButtonVariant.secondary,
                icon: WizIcons.radio,
                onPressed: () => bloc.add(const DiscoverySweepRequested()),
              ),
            ],
          ),
        );
      case _:
        return Column(
          children: [
            WizEmptyState(
              icon: WizIcons.radio,
              title: Strings.noResponse,
              // A sweep has already walked every address, so pointing at the
              // sweep again is only worth saying once.
              body: state.sweptOnce
                  ? Strings.sweepTheSubnet
                  : Strings.broadcastHint,
              action: WizButton(
                label: Strings.scanSubnet,
                variant: WizButtonVariant.primary,
                icon: WizIcons.radio,
                onPressed: () => bloc.add(const DiscoverySweepRequested()),
              ),
            ),
            SizedBox(height: wiz.space.s6),
            WizPanel(
              variant: WizPanelVariant.inset,
              child: Text(
                Strings.staleIp,
                style: wiz.typography.bodySm.copyWith(
                  color: wiz.colors.textTertiary,
                ),
              ),
            ),
          ],
        );
    }
  }
}
