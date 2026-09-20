import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/widgets/emission.dart';
import 'package:wizctl_app/app/widgets/fixture_kind.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/util/color_maths.dart';
import 'package:wizctl_app/core/widgets/fixture_hero.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  const base = LiveState.initial;

  test('off or unreachable is the off emission', () {
    expect(emissionOf(base, BulbClass.rgb), WizEmission.off);
    expect(
      emissionOf(base.copyWith(isOn: true, reachable: false), BulbClass.rgb),
      WizEmission.off,
    );
  });

  test(
    'colour on an RGB bulb emits the colour; on another class the kelvin',
    () {
      var on = base.copyWith(
        isOn: true,
        reachable: true,
        active: ActiveChannel.colour,
        rgb: const Rgb(255, 0, 0),
        brightness: 100,
      );
      expect(emissionOf(on, BulbClass.rgb).color, const Color(0xFFFF0000));
      expect(emissionOf(on, BulbClass.tw).color, kelvinToColor(on.kelvin));
      expect(
        emissionOf(on, null).color,
        const Color(0xFFFF0000),
        reason: 'an unclassified bulb is treated as fully capable',
      );
    },
  );

  test('a scene emits its from colour; white the kelvin colour', () {
    var scene = base.copyWith(
      isOn: true,
      reachable: true,
      active: ActiveChannel.scene,
      sceneId: 1,
    );
    expect(emissionOf(scene, BulbClass.rgb).color, sceneGradients[1]!.from);
    var white = base.copyWith(
      isOn: true,
      reachable: true,
      active: ActiveChannel.white,
      kelvin: 4500,
    );
    expect(emissionOf(white, BulbClass.tw).color, kelvinToColor(4500));
    expect(
      emissionOf(white, BulbClass.tw).alpha,
      closeTo(0.30 + 0.60 * 0.62, 0.001),
    );
  });

  test("every fixture kind maps to the hero's, and to a label", () {
    for (var f in Fixture.values) {
      expect(fixtureOf(f).name, f.name);
      expect(fixtureLabelOf(f), isNotEmpty, reason: f.name);
    }
    // P59: the labels are copy, not the domain's own `Fixture.label`.
    expect(fixtureLabelOf(Fixture.bulb), Strings.fixtureBulb);
    expect(fixtureLabelOf(Fixture.dome), Strings.fixtureCeiling);
    expect(fixtureLabelOf(Fixture.desk), Strings.glyphLamp);
    expect(fixtureLabelOf(Fixture.strip), Strings.fixtureStrip);
    expect(fixtureLabelOf(Fixture.socket), Strings.fixturePlug);
  });
}
