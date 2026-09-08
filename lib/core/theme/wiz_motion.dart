import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Motion tokens from `tokens/motion.css` and the handoff motion table.
/// Fast in, settle out. Nothing bounces except a released knob or cap.
@immutable
class WizMotion {
  const WizMotion._();

  static const WizMotion standard = WizMotion._();

  final Duration press = const Duration(milliseconds: 80);
  final Duration release = const Duration(milliseconds: 140);
  final Duration ui = const Duration(milliseconds: 180);
  final Duration panel = const Duration(milliseconds: 260);
  final Duration screenEnter = const Duration(milliseconds: 300);
  final Duration loadIn = const Duration(milliseconds: 360);
  final Duration light = const Duration(milliseconds: 420);
  final Duration breathe = const Duration(milliseconds: 5500);
  final Duration toast = const Duration(milliseconds: 3200);
  final Duration ping = const Duration(milliseconds: 2200);
  final Duration filament = const Duration(milliseconds: 1350);
  final Duration sheen = const Duration(milliseconds: 1600);
  final Duration spin = const Duration(milliseconds: 900);
  final Duration stagger = const Duration(milliseconds: 55);

  /// A write still in flight after this shows its loading toast.
  final Duration toastDelay = const Duration(milliseconds: 600);

  final Curve tactile = const Cubic(.2, .8, .2, 1);
  final Curve pressCurve = const Cubic(.4, 0, 1, 1);
  final Curve settle = const Cubic(.16, 1.02, .3, 1);

  /// How far a key sinks, in logical pixels.
  final double pressTravel = 1.5;
  final double pressScale = 0.985;
  final double smallKeyScale = 0.94;
  final double keyScale = 0.97;
  final double cardScale = 0.975;
  final double hoverBrightness = 1.08;
  final double breatheMin = 0.88;

  /// Load-in rise distance.
  final double riseDistance = 12;
}
