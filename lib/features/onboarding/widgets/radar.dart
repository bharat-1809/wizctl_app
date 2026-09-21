import 'package:flutter/material.dart';

import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/reduced_motion.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_surface.dart';
import 'ping_ring.dart';

/// The scanning art of the first run (spec §10.1 step 2): a 150 well, two
/// ping rings on the 2.2 s clock with the second 0.7 s behind, and a 64 key
/// carrying the radio glyph.
class Radar extends StatefulWidget {
  const Radar({super.key});

  /// `WizCtl_Mobile.dc.html` lines 72–79: the well, the key and its glyph.
  /// The key is [keySize] rather than `key`, which every widget already has.
  static const double well = 150;
  static const double keySize = 64;
  static const double glyph = 26;

  /// The second ring starts this far into the first's cycle: 0.7 s of the
  /// 2.2 s `ping`.
  static const double ringDelayFraction = 0.7 / 2.2;

  /// The key, so a test can measure it.
  static const Key keyKey = Key('radar-key');

  @override
  State<Radar> createState() => _RadarState();
}

class _RadarState extends State<Radar> with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies
  // (`WizFilamentBar` and `RiseIn` carry the same note).
  AnimationController? _clock;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var motion = context.wiz.motion;
    var clock = _clock ??= AnimationController(
      vsync: this,
      duration: motion.ping,
    );
    clock.duration = motion.ping;
    // Read where the dependency is registered, so turning the platform switch
    // on stops the loop rather than merely freezing what it paints.
    if (wizReducedMotion(context)) {
      clock.stop();
    } else if (!clock.isAnimating) {
      // `repeat` carries on from wherever the clock stands, so switching
      // reduced motion off mid-cycle does not jump the rings back to nothing.
      clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var clock = _clock!;
    return SizedBox(
      width: Radar.well,
      height: Radar.well,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WizSurface(
            spec: wiz.elevation.well,
            radius: BorderRadius.circular(Radar.well / 2),
            color: wiz.colors.surfaceWell,
            width: Radar.well,
            height: Radar.well,
          ),
          PingRing(clock: clock, offset: 0, diameter: Radar.well),
          PingRing(
            clock: clock,
            offset: Radar.ringDelayFraction,
            diameter: Radar.well,
          ),
          WizSurface(
            key: Radar.keyKey,
            spec: wiz.elevation.key,
            radius: BorderRadius.circular(Radar.keySize / 2),
            gradient: wizVertical(
              wiz.colors.surfaceKey,
              wiz.colors.surfaceRaised,
            ),
            width: Radar.keySize,
            height: Radar.keySize,
            alignment: Alignment.center,
            child: WizIcon(
              WizIcons.radio,
              size: Radar.glyph,
              color: wiz.colors.amber500,
            ),
          ),
        ],
      ),
    );
  }
}
