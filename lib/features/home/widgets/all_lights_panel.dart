import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_toggle.dart';

/// "ALL LIGHTS" with the home's state in display type and the master switch
/// (spec §10.2). The prototype pads it 18; the kit's large panel padding
/// (20) is the token nearest to that.
class AllLightsPanel extends StatelessWidget {
  final int onCount;
  final int total;
  final ValueChanged<bool>? onToggle;

  const AllLightsPanel({
    super.key,
    required this.onCount,
    required this.total,
    this.onToggle,
  });

  /// "All off" / "All on" / "\<k\> of \<n\> on".
  static String stateLabel(int on, int total) {
    if (total == 0 || on == 0) return Strings.allOff;
    if (on == total) return Strings.allOn;
    return Strings.someOn(on, total);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return WizPanel(
      variant: WizPanelVariant.inset,
      padding: EdgeInsets.all(wiz.space.panelPadLg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel(Strings.allLights),
                SizedBox(height: wiz.space.s2),
                Text(
                  stateLabel(onCount, total),
                  style: wiz.typography.title.copyWith(
                    color: wiz.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // A node of its own, like the switch on a `RoomCard`: the switch is
          // the only thing in the panel that annotates, so without this the
          // label and the state beside it merge into its node and the whole
          // panel reads "ALL LIGHTS / 3 of 6 on / All lights" as one button.
          Semantics(
            container: true,
            child: WizToggle(
              value: onCount > 0,
              onChanged: onToggle,
              semanticsLabel: Strings.allLights,
            ),
          ),
        ],
      ),
    );
  }
}
