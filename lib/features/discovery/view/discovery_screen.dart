import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/navigation.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/discovery_empty.dart';
import '../widgets/found_row.dart';
import '../widgets/save_light_sheet.dart';
import '../widgets/scanning_view.dart';

/// Discovery (spec §10.8): "Discover lights" with a back key on a phone,
/// "Discovery" with a Rescan key on a desktop, and then whichever of idle,
/// scanning, found, empty and failed applies.
///
/// A run is not started here — the screen opens idle and the user asks. The
/// bloc's `close()` cancels whatever is still going, which is how leaving the
/// screen cancels a scan.
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  Future<void> _save(BuildContext context, FoundDevice row) async {
    var bloc = context.read<DiscoveryBloc>();
    var homeId = bloc.homeId;
    // Onboarding has no home to save into; it keeps rows instead (Task 16).
    if (homeId == null) return;
    var result = await showSaveLightSheet(
      context,
      device: row.device,
      homeId: homeId,
    );
    if (result == null) return;
    bloc.add(
      DiscoverySaveRequested(
        ip: row.device.ip,
        alias: result.alias,
        roomId: result.roomId,
        fixture: Fixture.defaultFor(row.device.bulbClass),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var compact = context.layout.widthClass.isCompact;
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        var bloc = context.read<DiscoveryBloc>();
        var progress = state.progress;
        var counting =
            state.view == DiscoveryView.sweeping &&
            progress != null &&
            progress.isDeterminate;
        var subnet = state.subnet;
        // Where the devices came from: a sweep can say how many addresses it
        // walked, a broadcast only which network it went out on, and a run
        // nothing reported a subnet for neither.
        //
        // The phase of the last progress report is what decides, not
        // `state.sweptOnce` (P74): that flag latches for the screen's life, so
        // keying on it would have every quick rescan after one sweep claim to
        // have swept — and a quick run's progress carries no address count, so
        // it would claim it as "· 0 addresses". `sweptOnce` keeps its other
        // job, which is whether the empty state still offers the sweep.
        String foundOn;
        if (subnet == null) {
          foundOn = Strings.localNetwork;
        } else if (progress != null &&
            progress.phase == DiscoveryPhase.sweeping) {
          // The count is the sweep's own; both the real gateway and the
          // fault-injecting one report the /24's addresses, so there is no
          // literal here.
          foundOn = Strings.sweptSubnet(subnet, progress.total);
        } else {
          foundOn = Strings.broadcastOn(subnet);
        }
        return ScreenScroll(
          children: [
            // The bar's children are made explicit, the way
            // `WizStatusBanner` makes its own: a labelled `WizPressable` is
            // one node that absorbs the words beside it, and on a phone the
            // only labelled control in this bar is Back — so without this the
            // whole bar collapses into one button called "Back / Discover
            // lights / Local network" (P67; the Light screen carries the same
            // wrapper for the same reason, and Task 23 fixes the kit).
            Semantics(
              container: true,
              explicitChildNodes: true,
              child: WizTopBar(
                title: compact ? Strings.discoverLights : Strings.discovery,
                subtitle: counting
                    ? Strings.addresses(progress.probed, progress.total)
                    : Strings.localNetwork,
                leading: compact
                    ? WizIconKey(
                        icon: WizIcons.chevronLeft,
                        semanticsLabel: Strings.back,
                        onPressed: () => popOr(context, AppRoutes.home),
                      )
                    : null,
                trailing: compact
                    ? null
                    : WizButton(
                        label: Strings.rescan,
                        variant: WizButtonVariant.ghost,
                        size: WizButtonSize.sm,
                        icon: WizIcons.refreshCw,
                        onPressed: state.isScanning
                            ? null
                            : () => bloc.add(const DiscoveryStarted()),
                      ),
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            if (state.isScanning)
              ScanningView(state: state)
            else if (state.view == DiscoveryView.found) ...[
              WizStatusBanner(
                status: WizStatus.success,
                title: Strings.lightsAnswered(state.found.length),
                body: foundOn,
                action: const WizBadge(
                  label: Strings.live,
                  tone: WizBadgeTone.online,
                  dot: true,
                ),
              ),
              for (var row in state.found)
                FoundRow(
                  row: row,
                  // A save already in flight for this address takes the key
                  // away: a second tap would make a second light.
                  onSave: state.saving.containsKey(row.device.ip)
                      ? null
                      : () => _save(context, row),
                ),
              WizButton(
                label: Strings.scanAgain,
                variant: WizButtonVariant.ghost,
                icon: WizIcons.refreshCw,
                fullWidth: true,
                onPressed: () => bloc.add(const DiscoveryStarted()),
              ),
              WizButton(
                label: Strings.sweepSubnet,
                variant: WizButtonVariant.ghost,
                icon: WizIcons.radio,
                fullWidth: true,
                onPressed: () => bloc.add(const DiscoverySweepRequested()),
              ),
            ] else
              DiscoveryEmpty(state: state),
          ],
        );
      },
    );
  }
}
