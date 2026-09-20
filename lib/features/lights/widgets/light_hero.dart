import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/emission.dart';
import '../../../app/widgets/fixture_kind.dart';
import '../../../core/widgets/fixture_hero.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_state.dart';

/// The fixture drawn from "show it as", lit from the live state
/// (spec §10.4).
class LightHero extends StatelessWidget {
  const LightHero({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        return FixtureHero(
          fixture: fixtureOf(light.fixture),
          emission: emissionOf(state.live, light.bulbClass),
        );
      },
    );
  }
}
