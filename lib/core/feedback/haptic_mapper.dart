import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'feedback_kind.dart';

/// Maps the nine kinds onto the platform's haptic vocabulary (spec §13:
/// "detent → selectionClick; press, tick → lightImpact; toggleOn, toggleOff
/// → mediumImpact; power → heavyImpact; confirm → light then medium 30 ms
/// apart; reject → heavy twice 40 ms apart; release → none; desktop
/// platforms no-op").
///
/// The four platform calls are injectable so that tests can watch them
/// without a binding.
class HapticMapper {
  /// False on the platforms with no haptic vocabulary, where [play] does
  /// nothing at all. Defaults to the two phone platforms.
  final bool supported;

  final Future<void> Function() selection;
  final Future<void> Function() light;
  final Future<void> Function() medium;
  final Future<void> Function() heavy;

  /// Spec §13: confirm is "light then medium 30 ms apart".
  static const Duration confirmGap = Duration(milliseconds: 30);

  /// Spec §13: reject is "heavy twice 40 ms apart".
  static const Duration rejectGap = Duration(milliseconds: 40);

  HapticMapper({
    bool? supported,
    Future<void> Function()? selection,
    Future<void> Function()? light,
    Future<void> Function()? medium,
    Future<void> Function()? heavy,
  }) : supported =
           supported ??
           (defaultTargetPlatform == TargetPlatform.iOS ||
               defaultTargetPlatform == TargetPlatform.android),
       selection = selection ?? HapticFeedback.selectionClick,
       light = light ?? HapticFeedback.lightImpact,
       medium = medium ?? HapticFeedback.mediumImpact,
       heavy = heavy ?? HapticFeedback.heavyImpact;

  /// Fires [kind]'s haptic. The two-part patterns wait out their gap, so a
  /// caller on the pointer-down path should not await this.
  Future<void> play(FeedbackKind kind) async {
    if (!supported) return;
    switch (kind) {
      case FeedbackKind.detent:
        await selection();
      case FeedbackKind.press:
      case FeedbackKind.tick:
        await light();
      case FeedbackKind.toggleOn:
      case FeedbackKind.toggleOff:
        await medium();
      case FeedbackKind.power:
        await heavy();
      case FeedbackKind.confirm:
        await light();
        await Future<void>.delayed(confirmGap);
        await medium();
      case FeedbackKind.reject:
        await heavy();
        await Future<void>.delayed(rejectGap);
        await heavy();
      case FeedbackKind.release:
        // Deliberately nothing: a key coming back up is heard, not felt.
        break;
    }
  }
}
