import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/unreachable_cubit.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/seed.dart';

/// Long enough for the settings watch, the repository watch and the store to
/// deliver their first values and for the cubit to emit off them.
const Duration _settled = Duration(milliseconds: 5);

void main() {
  late SeedHome seed;
  setUp(() => seed = SeedHome());
  tearDown(() => seed.dispose());

  blocTest<UnreachableCubit, List<Light>>(
    "lists the active home's lights that do not answer, and follows the store",
    build: () => UnreachableCubit(
      lights: seed.lights,
      store: seed.store,
      settings: seed.settings,
    ),
    act: (cubit) async {
      cubit.subscribe();
      await Future<void>.delayed(_settled);
      expect(cubit.state.map((l) => l.name), ['Hallway']);
      seed.store.update('hall', (s) => s.copyWith(reachable: true));
      seed.store.update('dome', (s) => s.copyWith(reachable: false));
    },
    wait: _settled,
    verify: (cubit) =>
        expect(cubit.state.map((l) => l.name), ['Ceiling dome light']),
  );

  blocTest<UnreachableCubit, List<Light>>(
    'no active home means nothing',
    build: () {
      seed = SeedHome(active: false);
      return UnreachableCubit(
        lights: seed.lights,
        store: seed.store,
        settings: seed.settings,
      );
    },
    act: (cubit) => cubit.subscribe(),
    wait: _settled,
    verify: (cubit) => expect(cubit.state, isEmpty),
  );

  // The amendment this cubit is written against (P52): `asyncExpand` pauses
  // the active-home stream until the inner one ends, and a repository watch
  // never ends, so under it the state would stay on the home that was active
  // when the cubit subscribed. The Studio's one light answers.
  blocTest<UnreachableCubit, List<Light>>(
    'a home switch swaps which lights it watches',
    build: () => UnreachableCubit(
      lights: seed.lights,
      store: seed.store,
      settings: seed.settings,
    ),
    act: (cubit) async {
      cubit.subscribe();
      await Future<void>.delayed(_settled);
      expect(cubit.state.map((l) => l.name), ['Hallway']);
      await seed.settings.save(const AppSettings(activeHomeId: 'h2'));
    },
    wait: _settled,
    verify: (cubit) => expect(cubit.state, isEmpty),
  );

  blocTest<UnreachableCubit, List<Light>>(
    'a light that stops answering while it is subscribed arrives',
    build: () => UnreachableCubit(
      lights: seed.lights,
      store: seed.store,
      settings: seed.settings,
    ),
    act: (cubit) async {
      cubit.subscribe();
      await Future<void>.delayed(_settled);
      seed.store.update('counter', (s) => s.copyWith(reachable: false));
    },
    wait: _settled,
    // Repository order, which is `sortIndex`: the dome's room comes first, so
    // the kitchen downlight follows the hallway rather than leading it.
    verify: (cubit) => expect(cubit.state.map((l) => l.name), [
      'Hallway',
      'Counter downlight',
    ]),
  );
}
