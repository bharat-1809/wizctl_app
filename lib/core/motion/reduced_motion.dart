import 'package:flutter/widgets.dart';

/// The reduced-motion policy (spec §12, "all skipped under reduced motion").
///
/// When the platform's "reduce motion" switch is on, `wizReducedMotion`
/// returns true and:
///
/// * entrances do not stagger or rise (`RiseIn` shows its child at once);
/// * nothing loops: the powered light's breathe, the radar's pings, the
///   skeleton's sheen, the badge dot's pulse, the filament's travel all
///   stand still at their parked frame;
/// * screen and step transitions take no time (the fade page, the
///   onboarding switcher);
/// * state still changes as it would: caps travel, dials turn, colours
///   change, but on their token durations rather than instantly, because a
///   control that snaps with no motion at all reads as broken.
///
/// Nothing shortens a duration on a widget's behalf — this is a read, not a
/// setting the framework applies — so every loop, stagger and transition
/// asks for itself. A state change asks for nothing: it takes its duration
/// from `context.wiz.motion` and keeps it, which is the last clause above.
///
/// The one place the platform switch is read, so a widget that has to stop
/// a loop rather than merely freeze what it paints reads the same thing
/// everything else does. Read it inside `didChangeDependencies` or `build`,
/// where the dependency is registered and the switch flipping rebuilds — or,
/// where neither is possible, hand it in: a `Page`'s durations are fixed
/// above the navigator, so `wizFadePage` takes the answer as a flag.
bool wizReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
