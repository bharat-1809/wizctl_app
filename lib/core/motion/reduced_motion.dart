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
/// * state still changes rather than jumping: caps travel, dials turn,
///   colours change. These ask for nothing of their own — they ride the
///   scaling Flutter already applies, which is the next paragraph — so a
///   control still reads as something that moved rather than something that
///   broke.
///
/// What the framework shortens, and what it does not, is the whole reason for
/// that split. An `AnimationController` built the ordinary way carries
/// `AnimationBehavior.normal`, and `forward`, `reverse` and `animateTo` then
/// run at **5 %** of the stated duration while the platform flag is on
/// (`animation_controller.dart`, `_animateToInternal`: "run at 5% of the
/// normal duration to limit most animations to a single frame"). Every state
/// change in the kit is an implicit widget — `AnimatedScale`,
/// `AnimatedSwitcher`, `TweenAnimationBuilder` and the rest — which cannot be
/// handed `AnimationBehavior.preserve` and is not handed it anywhere here, so
/// all of them already collapse to about one frame on a device with the
/// switch on. That is the last clause above, and it needs no code of ours.
///
/// `repeat()` is **not** scaled: a repeating animation keeps its period by
/// design, so that a widget which ignores the flag cannot flash. A loop
/// therefore runs at full speed for ever unless something stops it, which is
/// why every looping and staggered animation here asks `wizReducedMotion` for
/// itself. Page and step transitions ask too: 5 % of 300 ms is 15 ms, which is
/// neither the "no time" the spec asks for nor nothing, and a gate that waits
/// on `AnimationStatus.completed` wants the answer exactly rather than nearly.
///
/// The one place the platform switch is read, so a widget that has to stop
/// a loop rather than merely freeze what it paints reads the same thing
/// everything else does. Read it inside `didChangeDependencies` or `build`,
/// where the dependency is registered and the switch flipping rebuilds — or,
/// where neither is possible, hand it in: a `Page`'s durations are fixed
/// above the navigator, so `wizFadePage` takes the answer as a flag.
bool wizReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
