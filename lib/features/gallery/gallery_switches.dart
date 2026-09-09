import 'package:flutter/material.dart';

import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_power_key.dart';
import '../../core/widgets/wiz_toggle.dart';
import 'gallery_section.dart';

/// Both toggle sizes and the power key, live, so the cap travel and the
/// glow can be judged by eye.
class GallerySwitches extends StatefulWidget {
  /// The room light the rest of the gallery reads: the hero lights with it.
  final bool power;
  final ValueChanged<bool> onPower;

  const GallerySwitches({
    super.key,
    required this.power,
    required this.onPower,
  });

  @override
  State<GallerySwitches> createState() => _GallerySwitchesState();
}

class _GallerySwitchesState extends State<GallerySwitches> {
  bool _all = true;
  bool _room = false;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return GallerySection(
      title: 'Switches',
      child: Row(
        children: [
          WizToggle(
            value: _all,
            onChanged: (v) => setState(() => _all = v),
            semanticsLabel: 'All lights',
          ),
          SizedBox(width: space.s6),
          WizToggle(
            value: _room,
            size: WizToggleSize.sm,
            onChanged: (v) => setState(() => _room = v),
            semanticsLabel: 'Living Room',
          ),
          SizedBox(width: space.s6),
          const WizToggle(
            value: true,
            enabled: false,
            onChanged: _ignored,
            semanticsLabel: 'Locked',
          ),
          const Spacer(),
          WizPowerKey(
            on: widget.power,
            onChanged: widget.onPower,
            size: WizPowerKeySize.md,
          ),
        ],
      ),
    );
  }
}

/// A disabled toggle still needs a handler it will never call.
void _ignored(bool value) {}
