import 'package:flutter/material.dart';

import '../../core/layout/wiz_layout.dart';
import '../../core/motion/reduced_motion.dart';
import '../../core/motion/rise_in.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/toast_controller.dart';
import '../../core/widgets/wiz_toggle.dart';
import '../../core/widgets/wiz_top_bar.dart';
import 'gallery_dials.dart';
import 'gallery_feedback.dart';
import 'gallery_fields.dart';
import 'gallery_hero.dart';
import 'gallery_keys.dart';
import 'gallery_navigation.dart';
import 'gallery_rows.dart';
import 'gallery_scenes.dart';
import 'gallery_states.dart';
import 'gallery_switches.dart';
import 'gallery_wheel.dart';

/// Debug-only catalogue of every kit widget, live, so the design can be
/// checked on a real device before any screen exists (spec §18: prototype
/// switches are compiled into debug builds only).
///
/// One light — power, brightness and colour temperature — is shared by the
/// switches, the dials, the cards and the hero, so that turning the power
/// key off visibly darkens the fixture two sections down.
class GalleryScreen extends StatefulWidget {
  final ToastController toasts;

  const GalleryScreen({super.key, required this.toasts});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  /// The light the gallery opens on: lit, a little under full, at the warm
  /// white the prototype's rooms sit at (`WizColors.kelvinStops` 2700).
  static const double initialBrightness = 70, initialKelvin = 2700;

  bool _power = true;
  double _brightness = initialBrightness;
  double _kelvin = initialKelvin;

  /// The debug reduced-motion switch: the platform setting cannot be flipped
  /// from inside the app, so the gallery pretends it was.
  bool _reducedMotion = false;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var gutter = context.layout.gutter;

    var sections = <Widget>[
      _Header(
        reducedMotion: _reducedMotion,
        onReducedMotion: (v) => setState(() => _reducedMotion = v),
      ),
      const GalleryKeys(),
      GallerySwitches(
        power: _power,
        onPower: (v) => setState(() => _power = v),
      ),
      GalleryDials(
        brightness: _brightness,
        kelvin: _kelvin,
        onBrightness: (v) => setState(() => _brightness = v),
        onKelvin: (v) => setState(() => _kelvin = v),
      ),
      const GalleryWheel(),
      const GalleryScenes(),
      const GalleryNavigation(),
      GalleryRows(
        power: _power,
        brightness: _brightness,
        kelvin: _kelvin,
        onPower: (v) => setState(() => _power = v),
        onBrightness: (v) => setState(() => _brightness = v),
      ),
      GalleryHero(power: _power, brightness: _brightness, kelvin: _kelvin),
      GalleryStates(toasts: widget.toasts),
      const GalleryFields(),
      const GalleryFeedback(),
    ];

    Widget body = SafeArea(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          gutter,
          wiz.space.s4,
          gutter,
          // Clear of the toast stack and of where the tab bar will float.
          wiz.space.s12 + wiz.space.tabBar,
        ),
        itemCount: sections.length,
        itemBuilder: (context, i) => RiseIn(index: i, child: sections[i]),
      ),
    );

    return Scaffold(
      // `WizAppBackground` above this paints the chassis, its vignette and
      // its grain; the scaffold only carries the layout and the Material
      // ancestor the text field needs. `Colors.transparent` is the same
      // non-chromatic use `buildWizThemeData` already makes of it.
      backgroundColor: Colors.transparent,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          // Never forces animations back *on*: a device that already asks
          // for reduced motion keeps it whatever this switch says.
          disableAnimations: _reducedMotion || wizReducedMotion(context),
        ),
        // Remounted when the switch flips, so entrances that decide once on
        // mount — `RiseIn` — are decided again under the new setting.
        child: KeyedSubtree(key: ValueKey(_reducedMotion), child: body),
      ),
    );
  }
}

/// The gallery's own header: what this screen is, and the one debug switch.
class _Header extends StatelessWidget {
  final bool reducedMotion;
  final ValueChanged<bool> onReducedMotion;

  const _Header({required this.reducedMotion, required this.onReducedMotion});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Padding(
      padding: EdgeInsets.only(bottom: wiz.space.s9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WizTopBar(
            title: 'Gallery',
            subtitle: 'Every part of the kit, live',
          ),
          SizedBox(height: wiz.space.s5),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reduced motion',
                  style: wiz.typography.bodySm.copyWith(
                    color: wiz.colors.textSecondary,
                  ),
                ),
              ),
              WizToggle(
                value: reducedMotion,
                size: WizToggleSize.sm,
                onChanged: onReducedMotion,
                semanticsLabel: 'Reduced motion',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
