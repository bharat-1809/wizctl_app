import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/mode_art.dart';
import 'package:wizctl_app/core/widgets/mode_row.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  test('a scene keeps its id, a solid becomes a colour, flat stays flat', () {
    expect((modeArtOf(const SceneArt(12)) as SceneModeArt).sceneId, 12);
    expect(
      (modeArtOf(const SolidArt(Rgb.amber)) as SolidModeArt).color,
      const Color.fromARGB(255, 255, 176, 32),
      reason: 'opaque: the domain carries no alpha',
    );
    expect(modeArtOf(const FlatArt()), isA<FlatModeArt>());
  });
}
