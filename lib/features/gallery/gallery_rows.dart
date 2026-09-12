import 'package:flutter/material.dart';

import '../../core/icons/wiz_icon_data.dart';
import '../../core/layout/wiz_grid.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/light_card.dart';
import '../../core/widgets/room_card.dart';
import '../../core/widgets/wiz_badge.dart';
import '../../core/widgets/wiz_list_row.dart';
import '../../core/widgets/wiz_stat_tile.dart';
import 'gallery_section.dart';

/// Rows, badges, stat tiles and both cards, including the unreachable state.
class GalleryRows extends StatefulWidget {
  /// The ceiling light's power and brightness, shared with the switches and
  /// the hero so the whole gallery agrees about one light.
  final bool power;
  final double brightness;
  final double kelvin;
  final ValueChanged<bool> onPower;
  final ValueChanged<double> onBrightness;

  const GalleryRows({
    super.key,
    required this.power,
    required this.brightness,
    required this.kelvin,
    required this.onPower,
    required this.onBrightness,
  });

  /// Two room cards fit side by side on a phone at this minimum.
  static const double cardMinWidth = 150;

  @override
  State<GalleryRows> createState() => _GalleryRowsState();
}

class _GalleryRowsState extends State<GalleryRows> {
  bool _bedroomOn = false;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return GallerySection(
      title: 'Rows and tiles',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizListRow(
            icon: WizIcons.sofa,
            title: 'Living Room',
            meta: '3 lights · 2 on',
            trailing: const WizBadge(
              label: 'Live',
              tone: WizBadgeTone.online,
              dot: true,
            ),
            onTap: () {},
          ),
          SizedBox(height: space.s4),
          WizListRow(
            icon: WizIcons.lampDesk,
            title: 'Desk lamp',
            meta: '192.168.1.118',
            active: true,
            trailing: const WizBadge(
              label: 'Offline',
              tone: WizBadgeTone.danger,
              dot: true,
            ),
            onTap: () {},
          ),
          SizedBox(height: space.s5),
          Wrap(
            spacing: space.s4,
            runSpacing: space.s4,
            children: const [
              WizBadge(label: 'Dynamic', tone: WizBadgeTone.accent),
              WizBadge(label: 'Static'),
            ],
          ),
          SizedBox(height: space.s5),
          Row(
            children: [
              Expanded(
                child: WizStatTile(
                  icon: WizIcons.thermometer,
                  label: 'Colour temp',
                  value: '${widget.kelvin.round()}',
                  unit: 'K',
                ),
              ),
              SizedBox(width: space.s5),
              Expanded(
                child: WizStatTile(
                  icon: WizIcons.gauge,
                  label: 'Intensity',
                  value: '${widget.brightness.round()}',
                  unit: '%',
                  accent: true,
                ),
              ),
            ],
          ),
          SizedBox(height: space.s5),
          WizGrid(
            minTile: GalleryRows.cardMinWidth,
            gap: space.s6,
            children: [
              RoomCard(
                name: 'Living Room',
                icon: WizIcons.sofa,
                lightCount: 3,
                onCount: widget.power ? 2 : 0,
                on: widget.power,
                onToggle: widget.onPower,
                onTap: () {},
              ),
              RoomCard(
                name: 'Bedroom',
                icon: WizIcons.bed,
                lightCount: 2,
                onCount: _bedroomOn ? 2 : 0,
                on: _bedroomOn,
                onToggle: (v) => setState(() => _bedroomOn = v),
                onTap: () {},
              ),
            ],
          ),
          SizedBox(height: space.s5),
          LightCard(
            name: 'Ceiling dome light',
            meta: 'Cozy',
            icon: WizIcons.lampCeiling,
            on: widget.power,
            brightness: widget.brightness,
            onToggle: widget.onPower,
            onBrightness: widget.onBrightness,
            onTap: () {},
          ),
          SizedBox(height: space.s4),
          const LightCard(
            name: 'Hallway',
            meta: '192.168.1.118',
            icon: WizIcons.lightbulb,
            on: false,
            unreachable: true,
            brightness: 50,
          ),
        ],
      ),
    );
  }
}
