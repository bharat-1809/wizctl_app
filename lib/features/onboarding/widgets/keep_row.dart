import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/blink_cubit.dart';
import '../../../app/widgets/blink_key.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/light_card_well.dart';
import '../../../core/widgets/wiz_pressable.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../../domain/entities/entities.dart';

/// A found light in the first run (spec §10.1 step 2): the well, the name and
/// address, the flash key, and the check cap. The row itself is the switch —
/// tapping it anywhere keeps or drops the light.
class KeepRow extends StatelessWidget {
  final FoundDevice row;
  final VoidCallback onToggle;
  const KeepRow({super.key, required this.row, required this.onToggle});

  /// `WizCtl_Mobile.dc.html` lines 101–110: a 26 check cap with a 15 glyph.
  static const double cap = 26;
  static const double capGlyph = 15;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var device = row.device;
    var blinking = context.select<BlinkCubit, bool>(
      (c) => c.state.isBlinking(device.ip),
    );
    var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
    return WizPressable(
      onTap: onToggle,
      toggled: row.kept,
      scale: wiz.motion.cardScale,
      focusRadius: BorderRadius.circular(wiz.space.r4),
      // No `semanticsLabel`: a labelled `WizPressable` excludes everything it
      // draws, and this row draws the flash key — which would then be
      // unreachable to a screen reader. The name and address inside name the
      // switch and [Strings.keepLight] says what it does, exactly as
      // `LightCard` and `RoomCard` leave their own cards unnamed for the
      // controls they host.
      //
      // The row hosts that key's gesture too, so the sink waits for the arena
      // rather than firing under a finger on its way to it.
      arenaResolved: true,
      builder: (context, state) => WizSurface(
        spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.panel,
        radius: BorderRadius.circular(wiz.space.r4),
        gradient: wizVertical(
          wiz.colors.surfaceRaised,
          wiz.colors.surfacePanel,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.s6,
          vertical: wiz.space.s5,
        ),
        child: Row(
          children: [
            LightCardWell(icon: WizIcons.lightbulb, lit: blinking),
            SizedBox(width: wiz.space.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    style: wiz.typography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: wiz.colors.textPrimary,
                    ),
                  ),
                  Text(
                    Strings.ipAndClass(device.ip, cls),
                    style: wiz.typography.mono.copyWith(
                      color: wiz.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            BlinkKey(ip: device.ip, bulbClass: device.bulbClass),
            SizedBox(width: wiz.space.s4),
            // The cap is what shows the keep state, so it carries the word
            // for it; a node of its own, so it is read rather than folded
            // into the address beside it.
            Semantics(
              container: true,
              label: Strings.keepLight,
              child: WizSurface(
                spec: row.kept ? wiz.elevation.key : wiz.elevation.well,
                radius: BorderRadius.circular(wiz.space.r1),
                gradient: row.kept
                    ? wizVertical(wiz.colors.amber400, wiz.colors.amber600)
                    : wizVertical(wiz.colors.char1000, wiz.colors.char900),
                width: cap,
                height: cap,
                alignment: Alignment.center,
                child: WizIcon(
                  WizIcons.check,
                  size: capGlyph,
                  color: row.kept
                      ? wiz.colors.textOnAccent
                      : wiz.colors.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
