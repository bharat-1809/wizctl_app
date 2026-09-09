import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/motion/breathe.dart';
import 'package:wizctl_app/core/motion/reduced_motion.dart';
import 'package:wizctl_app/core/motion/rise_in.dart';
import 'package:wizctl_app/core/motion/wiz_fade_page.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';

import '../../support/wiz_test_app.dart';

void main() {
  var motion = WizMotion.standard;

  /// One display frame: the test binding elapses the whole of a `pump`'s
  /// duration and only then runs a frame, so a ticker started in between
  /// takes its first tick with zero elapsed and needs another frame to
  /// report any progress at all.
  const frame = Duration(milliseconds: 16);

  double opacityOf(WidgetTester tester, Key key) => tester
      .widget<Opacity>(
        find
            .ancestor(of: find.byKey(key), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  testWidgets('RiseIn starts invisible, staggers, and settles opaque', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const Column(
          children: [
            RiseIn(index: 0, child: SizedBox(key: Key('a'), height: 10)),
            RiseIn(index: 2, child: SizedBox(key: Key('b'), height: 10)),
          ],
        ),
      ),
    );
    expect(opacityOf(tester, const Key('a')), 0);
    // Lets the first item's slot come up and its controller take its first
    // tick, so the 200 ms below is 200 ms of animation rather than the
    // frame the animation starts on.
    await tester.pump(frame);
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacityOf(tester, const Key('a')), greaterThan(0.3));
    expect(
      opacityOf(tester, const Key('b')),
      lessThan(opacityOf(tester, const Key('a'))),
    );
    await tester.pumpAndSettle();
    expect(opacityOf(tester, const Key('a')), 1);
    expect(opacityOf(tester, const Key('b')), 1);
  });

  testWidgets('RiseIn holds an item back until its own stagger slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const RiseIn(index: 2, child: SizedBox(key: Key('c'), height: 10)),
      ),
    );
    // One slot in: it is not this item's turn yet.
    await tester.pump(motion.stagger);
    expect(opacityOf(tester, const Key('c')), 0);
    // Two slots in: the controller starts here, and moves on the next frame.
    await tester.pump(motion.stagger);
    await tester.pump(frame);
    expect(opacityOf(tester, const Key('c')), greaterThan(0));
    await tester.pumpAndSettle();
    expect(opacityOf(tester, const Key('c')), 1);
  });

  testWidgets('a disabled RiseIn renders at rest without animating', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const RiseIn(
          index: 3,
          enabled: false,
          child: SizedBox(key: Key('e'), height: 10),
        ),
      ),
    );
    expect(opacityOf(tester, const Key('e')), 1);
    var at = tester.getTopLeft(find.byKey(const Key('e')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('e'))), at);
  });

  testWidgets('wizReducedMotion reads the platform switch', (tester) async {
    late bool off;
    late bool on;
    await tester.pumpWidget(
      wizTestApp(
        Column(
          children: [
            Builder(
              builder: (context) {
                off = wizReducedMotion(context);
                return const SizedBox.shrink();
              },
            ),
            MediaQuery(
              // The platform's "reduce motion" switch, over the harness's
              // own MediaQuery.
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  on = wizReducedMotion(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
    expect(off, isFalse);
    expect(on, isTrue);
  });

  testWidgets('reduced motion parks RiseIn at rest on its first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: RiseIn(index: 3, child: SizedBox(key: Key('d'), height: 10)),
        ),
      ),
    );
    expect(opacityOf(tester, const Key('d')), 1);
    var at = tester.getTopLeft(find.byKey(const Key('d')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('d'))), at);
  });

  testWidgets('reduced motion stops Breathe rather than only its paint', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Breathe(
            active: true,
            child: SizedBox(key: Key('z'), height: 10),
          ),
        ),
      ),
    );
    // A gated paint over a running loop would never settle.
    await tester.pumpAndSettle();
    expect(opacityOf(tester, const Key('z')), 1);
  });

  testWidgets('Breathe oscillates only while active', (tester) async {
    await tester.pumpWidget(
      wizTestApp(
        const Breathe(active: true, child: SizedBox(key: Key('x'), height: 10)),
      ),
    );
    // Lets the loop take its first tick before anything is measured.
    await tester.pump(frame);
    var a = opacityOf(tester, const Key('x'));
    await tester.pump(const Duration(milliseconds: 2750));
    var b = opacityOf(tester, const Key('x'));
    expect(a, isNot(closeTo(b, 0.01)));
    expect(b, inInclusiveRange(0.88, 1));
    await tester.pumpWidget(
      wizTestApp(
        const Breathe(
          active: false,
          child: SizedBox(key: Key('x'), height: 10),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacityOf(tester, const Key('x')), 1);
  });

  testWidgets('Breathe starts and stops with active, leaving no ticker up', (
    tester,
  ) async {
    Widget app(bool active) => wizTestApp(
      Breathe(
        active: active,
        child: const SizedBox(key: Key('y'), height: 10),
      ),
    );
    await tester.pumpWidget(app(false));
    // Nothing is running yet, so this returns rather than timing out.
    await tester.pumpAndSettle();
    expect(opacityOf(tester, const Key('y')), 1);
    await tester.pumpWidget(app(true));
    // Bounded: an active Breathe loops, so it never settles.
    await tester.pump(motion.breathe ~/ 4);
    expect(opacityOf(tester, const Key('y')), lessThan(1));
    await tester.pumpWidget(app(false));
    // Returns only because deactivating stopped the loop.
    await tester.pumpAndSettle();
    expect(opacityOf(tester, const Key('y')), 1);
  });

  testWidgets('wizFadePage enters on opacity alone over screenEnter', (
    tester,
  ) async {
    var page = wizFadePage<void>(
      key: const ValueKey<String>('screen'),
      child: const SizedBox(key: Key('body')),
      motion: motion,
    );
    expect(page.transitionDuration, motion.screenEnter);
    expect(page.reverseTransitionDuration, motion.screenEnter);
    const body = SizedBox(key: Key('body'));
    late Widget transition;
    await tester.pumpWidget(
      wizTestApp(
        Builder(
          builder: (context) {
            transition = page.transitionsBuilder(
              context,
              const AlwaysStoppedAnimation<double>(0.5),
              kAlwaysDismissedAnimation,
              body,
            );
            return transition;
          },
        ),
      ),
    );
    // Opacity only: the screen is wrapped in a fade and in nothing else —
    // no slide, no scale — and the fade is driven by the route's own
    // animation rather than parked at either end.
    expect(transition, isA<FadeTransition>());
    var fade = transition as FadeTransition;
    expect(identical(fade.child, body), isTrue);
    expect(fade.opacity.value, greaterThan(0));
    expect(fade.opacity.value, lessThan(1));
  });
  testWidgets('reduced motion switched on mid-rise lands the item at rest', (
    tester,
  ) async {
    Widget app(bool reduced, String tag, int index) => wizTestApp(
      MediaQuery(
        // The platform's "reduce motion" switch, over the harness's own
        // MediaQuery.
        data: MediaQueryData(disableAnimations: reduced),
        // Keyed, so the two halves below each get a State of their own.
        child: RiseIn(
          key: ValueKey('rise-$tag'),
          index: index,
          child: SizedBox(key: Key(tag), height: 10),
        ),
      ),
    );

    // A rise already under way when the switch goes on.
    await tester.pumpWidget(app(false, 'f', 0));
    await tester.pump(frame);
    await tester.pump(const Duration(milliseconds: 120));
    expect(opacityOf(tester, const Key('f')), inExclusiveRange(0, 1));
    await tester.pumpWidget(app(true, 'f', 0));
    expect(opacityOf(tester, const Key('f')), 1);
    // Returns only because the run was stopped, not merely painted over.
    await tester.pumpAndSettle();
    expect(opacityOf(tester, const Key('f')), 1);

    // A rise still waiting for its stagger slot.
    await tester.pumpWidget(app(false, 'g', 3));
    await tester.pump(motion.stagger);
    expect(opacityOf(tester, const Key('g')), 0);
    await tester.pumpWidget(app(true, 'g', 3));
    expect(opacityOf(tester, const Key('g')), 1);
    var at = tester.getTopLeft(find.byKey(const Key('g')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const Key('g'))),
      at,
      reason: 'the cancelled slot must not come up and move it again',
    );
  });
}
