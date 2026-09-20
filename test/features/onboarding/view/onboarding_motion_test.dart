import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/core/widgets/wiz_text_field.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:wizctl_app/features/onboarding/view/discovering_step.dart';
import 'package:wizctl_app/features/onboarding/view/onboarding_screen.dart';

import '../../../support/app_scope.dart';
import '../../../support/router_harness.dart';
import '../../../support/seed.dart';
import '../../../support/wiz_test_app.dart';

/// The phone (P58): 390 wide is the width class the steps are written for.
///
/// The height is the phone's 844 stretched (P69), as the screen test's is: a
/// step draws more than one screenful, and `tester.tap` on something below the
/// surface's bottom edge lands on whatever is at those coordinates instead of
/// on the target — so the taller surface is what keeps the primary key
/// reachable when this test drives step 1 to step 2.
const Size _phone = Size(390, 2000);

void main() {
  /// Builds the fixture, runs [body] and tears it down inside the tester's
  /// zone (P56, and `AppScope`'s own doc): a bloc closed with an awaited
  /// `close()` outside the body deadlocks on the fakes' streams.
  ///
  /// The broadcast finds nothing, so step 2 settles on its empty view instead
  /// of holding reads open while this test is measuring frames.
  Future<void> withOnboarding(
    WidgetTester tester,
    Future<void> Function(
      AppScope scope,
      OnboardingBloc onboarding,
      DiscoveryBloc discovery,
    )
    body,
  ) async {
    var scope = AppScope(SeedHome.empty());
    await scope.start();
    scope.gateway.broadcastResult = [];
    scope.gateway.sweepEvents = [const ScanDone([])];
    var onboarding = OnboardingBloc(
      finishOnboarding: scope.finishOnboarding,
      ids: scope.ids,
    );
    var discovery = DiscoveryBloc(
      onboarding: true,
      runDiscovery: scope.runDiscovery,
      saveDiscoveredLight: scope.saveDiscoveredLight,
      learnHomeSubnet: scope.learnHomeSubnet,
      sync: scope.sync,
    );
    try {
      await body(scope, onboarding, discovery);
    } finally {
      unawaited(onboarding.close());
      unawaited(discovery.close());
      await scope.dispose();
    }
  }

  /// The screen the way the router mounts it (Task 19): the shell carries the
  /// `Scaffold`, and step 1's field needs the `Material` inside one.
  Widget screen(
    AppScope scope,
    OnboardingBloc onboarding,
    DiscoveryBloc discovery, {
    required bool reduced,
  }) => scope.wrap(
    Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<OnboardingBloc>.value(value: onboarding),
          BlocProvider<DiscoveryBloc>.value(value: discovery),
        ],
        child: reducedMotion(const OnboardingScreen(), reduced: reduced),
      ),
    ),
  );

  Duration switcherDuration(WidgetTester tester) =>
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration;

  /// Whether the pointer gate above [step] is shut (P77).
  bool ignoring(WidgetTester tester, Type step) => tester
      .widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byType(step),
              matching: find.byType(IgnorePointer),
            )
            .first,
      )
      .ignoring;

  /// Leaves step 1 for step 2, then one frame — the frame that mounts the
  /// arriving step and gives the switcher's controller its first tick.
  Future<void> toStepTwo(WidgetTester tester) async {
    await tester.enterText(find.byType(WizTextField), 'Kaverappa House');
    await tester.pump();
    await tester.tap(find.text('CREATE HOME'));
    await tester.pump();
  }

  testWidgets('under reduced motion the step switcher takes no time, and the '
      'step that arrives takes pointers at once', (tester) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        screen(scope, onboarding, discovery, reduced: true),
        size: _phone,
      );
      expect(switcherDuration(tester), Duration.zero);

      await toStepTwo(tester);
      expect(find.byType(DiscoveringStep), findsOneWidget);
      // A zero-length controller reaches `completed` on the tick it is
      // forwarded, so the P77 gate — which shuts every child whose own
      // animation has not finished — is open on the first frame the step
      // is on. Without this the 300 ms the gate costs would still be spent
      // with reduced motion on, and nothing on the step could be pressed.
      expect(ignoring(tester, DiscoveringStep), isFalse);
    });
  });

  testWidgets('with motion on, the switcher still cross-fades over '
      'screenEnter', (tester) async {
    await withOnboarding(tester, (scope, onboarding, discovery) async {
      await pumpRouted(
        tester,
        screen(scope, onboarding, discovery, reduced: false),
        size: _phone,
      );
      expect(switcherDuration(tester), scope.motion.screenEnter);
    });
  });
}
