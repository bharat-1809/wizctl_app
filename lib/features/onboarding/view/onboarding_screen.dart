import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/layout/wiz_layout.dart';
import '../../../core/motion/reduced_motion.dart';
import '../../../core/theme/wiz_theme.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_state.dart';
import 'discovering_step.dart';
import 'name_home_step.dart';
import 'name_lights_step.dart';

/// The first run (spec §10.1): stacked on a phone, a centred 560 column on
/// anything wider. It scrolls as one, inside the safe areas and the gutter;
/// no tab bar exists yet, so there is no bottom inset beyond the safe area.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  /// `design/reference/WizCtl_Desktop.dc.html:43`: `width: 560px`.
  static const double desktopColumn = 560;

  /// The column itself, so a test can measure it.
  static const Key columnKey = Key('onboarding-column');

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var gutter = context.layout.gutter;
    var step = context.select<OnboardingBloc, OnboardingStep>(
      (b) => b.state.step,
    );
    var body = switch (step) {
      OnboardingStep.nameHome => const NameHomeStep(),
      OnboardingStep.discovering => const DiscoveringStep(),
      OnboardingStep.nameLights => const NameLightsStep(),
    };
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          key: columnKey,
          constraints: const BoxConstraints(maxWidth: desktopColumn),
          // A single scroll view rather than the lazy list every other screen
          // uses: a step is one block of copy and controls, and the keyboard
          // has to be able to push all of it.
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              wiz.space.s4,
              gutter,
              wiz.space.s8,
            ),
            child: AnimatedSwitcher(
              // A step change is a screen transition, which reduced motion
              // spends no time on (see `reduced_motion.dart`). Read here
              // rather than left to the framework: the switcher's controller
              // is an ordinary one, so the flag alone would shorten this to
              // 5 % of 300 ms — 15 ms, one frame of cross-fade, which is not
              // the "no time" the spec asks for. It also has to be exactly
              // zero for the gate below, which waits on `completed`.
              duration: wizReducedMotion(context)
                  ? Duration.zero
                  : wiz.motion.screenEnter,
              switchInCurve: wiz.motion.tactile,
              // The fade is `AnimatedSwitcher`'s own recipe, on the duration
              // and curve above.
              transitionBuilder: (child, animation) => AnimatedBuilder(
                animation: animation,
                child: FadeTransition(opacity: animation, child: child),
                // The switcher stacks the step that is leaving under the one
                // arriving and, by default, leaves both hit-testable for the
                // whole cross-fade — so a tap aimed at the new step can land
                // on whatever the old one had at those coordinates. That is a
                // real mis-press, not only a test hazard (P77). Only the child
                // whose own animation has finished takes pointers, so the
                // 300 ms belongs to neither step.
                //
                // Gated in this builder rather than in the transition itself:
                // `AnimatedSwitcher` builds each child's transition once and
                // caches the widget, so a status read out there would keep the
                // value it was born with for ever. Read against the animation
                // it means the arriving step is shut from the frame it
                // appears, and the leaving step from the fade's first tick —
                // one frame after the switch, which is as early as a cached
                // subtree can be told anything.
                builder: (context, faded) => IgnorePointer(
                  ignoring: animation.status != AnimationStatus.completed,
                  child: faded,
                ),
              ),
              // Identity by step, so the switcher cross-fades between them
              // instead of rebuilding one subtree in place.
              child: KeyedSubtree(key: ValueKey(step), child: body),
            ),
          ),
        ),
      ),
    );
  }
}
