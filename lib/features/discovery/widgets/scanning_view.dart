import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_filament_bar.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../bloc/discovery_state.dart';
import 'skeleton_rows.dart';

/// What a run in flight looks like (spec §10.8): the loading banner naming
/// the network being searched, the filament, and three skeleton rows.
class ScanningView extends StatelessWidget {
  final DiscoveryState state;
  const ScanningView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var sweeping = state.view == DiscoveryView.sweeping;
    var progress = state.progress;
    var subnet = state.subnet;
    // A broadcast learns the subnet only when it finishes, so the first quick
    // scan of a screen's life has none to name. A rescan does: `subnet` never
    // clears once a run has set it.
    var title = sweeping
        ? (subnet == null ? Strings.sweepSubnet : Strings.sweeping(subnet))
        : (subnet == null
              ? Strings.listeningForLights
              : Strings.listeningOn(subnet));
    // Only a sweep knows how far along it is, address by address; a broadcast
    // is one wait with nothing to count.
    var counted = sweeping && progress != null && progress.isDeterminate
        ? progress
        : null;
    return Column(
      children: [
        WizStatusBanner(
          status: WizStatus.loading,
          title: title,
          body: counted == null
              ? Strings.broadcast
              : Strings.addresses(counted.probed, counted.total),
        ),
        SizedBox(height: space.s6),
        WizFilamentBar(label: Strings.discovering, value: counted?.fraction),
        SizedBox(height: space.s6),
        const SkeletonRows(),
      ],
    );
  }
}
