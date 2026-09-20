import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/emission.dart';
import '../../../app/widgets/fixture_kind.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/fixture_geometry.dart';
import '../../../core/widgets/fixture_hero.dart';
import '../../../core/widgets/wiz_surface.dart';
import '../../lights/bloc/light_bloc.dart';
import '../../lights/bloc/light_state.dart';

/// The inspector's stage (spec §10.9): a 132-tall well with the fixture at
/// 0.6 scale; the kit's compact hero draws exactly that.
class InspectorHero extends StatelessWidget {
  const InspectorHero({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        return WizSurface(
          spec: wiz.elevation.well,
          radius: BorderRadius.circular(wiz.space.r4),
          gradient: wizVertical(wiz.colors.char950, wiz.colors.char1000),
          height: FixtureGeometry.compactBox.height,
          child: FixtureHero(
            fixture: fixtureOf(light.fixture),
            emission: emissionOf(state.live, light.bulbClass),
            compact: true,
          ),
        );
      },
    );
  }
}
