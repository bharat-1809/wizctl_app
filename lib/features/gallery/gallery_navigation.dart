import 'package:flutter/material.dart';

import '../../core/icons/wiz_icon.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_rail.dart';
import '../../core/widgets/wiz_tab_bar.dart';
import '../../core/widgets/wiz_toggle.dart';
import 'gallery_section.dart';

/// The phone's tab bar and the desktop rail, both live. The rail is shown at
/// a fixed height because it is a full-height nav column and the gallery
/// scrolls; on a real screen it takes the whole side.
class GalleryNavigation extends StatefulWidget {
  const GalleryNavigation({super.key});

  /// Tall enough for both sections and the footer, short enough to leave the
  /// gallery scrollable.
  static const double railHeight = 340;

  @override
  State<GalleryNavigation> createState() => _GalleryNavigationState();
}

/// The tab bar's destinations, spec §10.
enum _Tab { home, rooms, scenes, settings }

/// Rail destinations: the prototype's sidebar lists rooms, then the house
/// (`design/reference/_ds_bundle.js:3489`).
enum _RailItem { livingRoom, bedroom, kitchen, allLights, settings }

class _GalleryNavigationState extends State<GalleryNavigation> {
  _Tab _tab = _Tab.home;
  _RailItem _railValue = _RailItem.livingRoom;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var space = wiz.space;
    return GallerySection(
      title: 'Navigation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizTabBar<_Tab>(
            tabs: const [
              WizTab(value: _Tab.home, icon: WizIcons.house, label: 'Home'),
              WizTab(
                value: _Tab.rooms,
                icon: WizIcons.layoutGrid,
                label: 'Rooms',
              ),
              WizTab(
                value: _Tab.scenes,
                icon: WizIcons.sparkles,
                label: 'Scenes',
              ),
              WizTab(
                value: _Tab.settings,
                icon: WizIcons.slidersHorizontal,
                label: 'Settings',
              ),
            ],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          SizedBox(height: space.s6),
          Row(
            children: [
              Text(
                'Collapse the rail',
                style: wiz.typography.bodySm.copyWith(
                  color: wiz.colors.textSecondary,
                ),
              ),
              SizedBox(width: space.s5),
              WizToggle(
                value: _collapsed,
                size: WizToggleSize.sm,
                onChanged: (v) => setState(() => _collapsed = v),
                semanticsLabel: 'Collapse the rail',
              ),
            ],
          ),
          SizedBox(height: space.s5),
          SizedBox(
            height: GalleryNavigation.railHeight,
            // The rail sizes its own width; left-aligned so collapsing it is
            // visible as the column narrowing.
            child: Align(
              alignment: Alignment.centerLeft,
              child: WizRail<_RailItem>(
                collapsed: _collapsed,
                brand: const GalleryWordmark(),
                collapsedBrand: Center(
                  child: WizIcon(
                    WizIcons.zap,
                    size: WizRail.glyph,
                    color: wiz.colors.amber400,
                  ),
                ),
                sections: const [
                  WizRailSection(
                    title: 'Rooms',
                    items: [
                      WizRailItem(
                        value: _RailItem.livingRoom,
                        label: 'Living Room',
                        icon: WizIcons.sofa,
                        meta: '3',
                      ),
                      WizRailItem(
                        value: _RailItem.bedroom,
                        label: 'Bedroom',
                        icon: WizIcons.bed,
                        meta: '2',
                      ),
                      WizRailItem(
                        value: _RailItem.kitchen,
                        label: 'Kitchen',
                        icon: WizIcons.utensilsCrossed,
                        meta: '1',
                      ),
                    ],
                  ),
                  WizRailSection(
                    title: 'Home',
                    items: [
                      WizRailItem(
                        value: _RailItem.allLights,
                        label: 'All lights',
                        icon: WizIcons.lightbulb,
                      ),
                      WizRailItem(
                        value: _RailItem.settings,
                        label: 'Settings',
                        icon: WizIcons.settings,
                      ),
                    ],
                  ),
                ],
                value: _railValue,
                onChanged: (v) => setState(() => _railValue = v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
