import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/theme/wiz_textures.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/theme/wiz_type.dart';
import '../../core/widgets/scene_gradients.dart';
import '../../core/widgets/wiz_panel.dart';
import '../../core/widgets/wiz_pressable.dart';
import '../../core/widgets/wiz_rail.dart';
import '../../core/widgets/wiz_surface.dart';
import '../../features/home/bloc/home_screen_bloc.dart';
import '../../features/home/widgets/homes_sheet.dart';
import '../blocs/homes_bloc.dart';
import '../blocs/homes_state.dart';
import '../routes.dart';
import 'rail_item.dart';

/// The desktop rail (spec §10.9): the wordmark over the home-switcher pill,
/// ROOMS with a light count each, HOUSE, and a footer naming what is lit and
/// the port the lights answer on. Collapsed to glyphs on a medium window.
///
/// Its width is the kit's (`WizRail` reads the window's class itself), and its
/// data is the `HomeScreenBloc` the shell provides — never a route's, because
/// the rail is above the branch navigator and has to be right on Settings too.
class DesktopRail extends StatelessWidget {
  final bool collapsed;

  const DesktopRail({super.key, required this.collapsed});

  /// The footer's terminal mark and the pill's chevron (spec §11.3, "14–15 in
  /// captions"; the prototype's sidebar draws them at 15 and 14).
  static const double footerGlyph = 15;
  static const double pillGlyph = 14;

  /// Which item [location] lights, or null for a location the rail does not
  /// name: the rooms list, which is a phone route, and a light, whose room
  /// Task 21 lights through the inspector.
  ///
  /// A pushed light inside the Rooms branch does not reach this — go_router
  /// leaves the branch's own location on the match list — so opening a light
  /// keeps its room lit.
  static RailItem? itemFor(String location) {
    if (location == AppRoutes.home) return const AllLightsRailItem();
    if (location == AppRoutes.modes) return const ScenesRailItem();
    if (location == AppRoutes.discover) return const DiscoveryRailItem();
    if (location == AppRoutes.settings) return const SettingsRailItem();
    var prefix = '${AppRoutes.rooms}/';
    if (location.startsWith(prefix)) {
      var id = location.substring(prefix.length);
      if (id.isNotEmpty && !id.contains('/')) return RoomRailItem(id);
    }
    return null;
  }

  /// Every row switches what the content column shows inside its branch, so
  /// every row is a `go`: nothing here is pushed over what is on screen.
  void _go(BuildContext context, RailItem item) => context.go(switch (item) {
    RoomRailItem(:var roomId) => AppRoutes.room(roomId),
    AllLightsRailItem() => AppRoutes.home,
    ScenesRailItem() => AppRoutes.modes,
    DiscoveryRailItem() => AppRoutes.discover,
    SettingsRailItem() => AppRoutes.settings,
  });

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var location = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    var homes = context.watch<HomesBloc>().state;
    var home = context.watch<HomeScreenBloc>().state;
    return WizRail<RailItem>(
      collapsed: collapsed,
      brand: _Brand(homes: homes),
      collapsedBrand: _Brand(homes: homes, collapsed: true),
      sections: [
        // Dropped whole when the home has none, rather than leaving a caption
        // over nothing: a first run, or the last room deleted.
        if (home.rooms.isNotEmpty)
          WizRailSection(
            title: Strings.rooms,
            items: [
              for (var tile in home.rooms)
                WizRailItem(
                  value: RoomRailItem(tile.room.id),
                  label: tile.room.name,
                  icon: WizIcons.byName(tile.room.glyph.iconName)!,
                  meta: '${tile.lightCount}',
                ),
            ],
          ),
        WizRailSection(
          title: Strings.railHouse,
          items: [
            WizRailItem(
              value: const AllLightsRailItem(),
              label: Strings.allLights,
              icon: WizIcons.layoutGrid,
              meta: '${home.lightCount}',
            ),
            WizRailItem(
              value: const ScenesRailItem(),
              label: Strings.tabScenes,
              icon: WizIcons.sparkles,
              meta: '${sceneGradients.length}',
            ),
            const WizRailItem(
              value: DiscoveryRailItem(),
              label: Strings.discovery,
              icon: WizIcons.radio,
            ),
            const WizRailItem(
              value: SettingsRailItem(),
              label: Strings.settings,
              icon: WizIcons.slidersHorizontal,
            ),
          ],
        ),
      ],
      value: itemFor(location),
      onChanged: (item) => _go(context, item),
      footer: collapsed
          ? null
          : WizPanel(
              variant: WizPanelVariant.inset,
              padding: EdgeInsets.symmetric(
                horizontal: wiz.space.s5,
                vertical: wiz.space.s4,
              ),
              child: Row(
                children: [
                  WizIcon(
                    WizIcons.terminal,
                    size: footerGlyph,
                    color: wiz.colors.textTertiary,
                  ),
                  SizedBox(width: wiz.space.s3),
                  Flexible(
                    child: Text(
                      Strings.railFooter(home.onCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: wiz.typography.mono.copyWith(
                        color: wiz.colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// WIZCTL over the home-switcher pill, the prototype's sidebar brand block.
/// Collapsed, only the pill is left, as a house key.
class _Brand extends StatelessWidget {
  final HomesState homes;
  final bool collapsed;

  const _Brand({required this.homes, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var name = homes.activeHome?.name ?? '';
    var pill = WizPressable(
      onTap: () => showHomesSheet(context),
      semanticsLabel: Strings.homes,
      scale: wiz.motion.keyScale,
      focusRadius: BorderRadius.circular(wiz.space.pill),
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.key,
        radius: BorderRadius.circular(wiz.space.pill),
        gradient: wizVertical(wiz.colors.surfaceKey, wiz.colors.surfaceRaised),
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.s5,
          vertical: wiz.space.s3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!collapsed) ...[
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: wiz.typography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: wiz.colors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: wiz.space.s2),
            ],
            WizIcon(
              collapsed ? WizIcons.house : WizIcons.chevronDown,
              size: DesktopRail.pillGlyph,
              color: wiz.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
    if (collapsed) return pill;
    // The same mark `GalleryWordmark` draws: the display face the `title`
    // token already carries, at weight 900 with the wordmark's own tracking.
    var title = wiz.typography.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.wordmark,
          style: title.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: title.fontSize! * WizType.wordmarkTracking,
            height: 1,
            color: wiz.colors.textPrimary,
          ),
        ),
        SizedBox(height: wiz.space.s3),
        pill,
      ],
    );
  }
}
