import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/core/widgets/scene_gradients.dart';

void main() {
  test('all 36 WiZ scenes, 23 dynamic and 13 static, keyed by id', () {
    expect(sceneGradients, hasLength(36));
    expect(dynamicScenes, hasLength(23));
    expect(staticScenes, hasLength(13));
    expect(sceneGradients[1]!.name, 'Ocean');
    expect(sceneGradients[1]!.isDynamic, isTrue);
    expect(sceneGradients[6]!.name, 'Cozy');
    expect(sceneGradients[6]!.isDynamic, isFalse);
    expect(sceneGradients[1000]!.name, 'Rhythm');
    expect(sceneGradients[29]!.from, const Color(0xFF7A3A05));
    expect(sceneGradients[29]!.to, const Color(0xFFFFC24D));
  });

  test('the table agrees with the library about every scene', () {
    expect(
      sceneGradients.keys.toSet(),
      WizScene.values.map((s) => s.id).toSet(),
    );
    for (var entry in sceneGradients.entries) {
      var scene = WizScene.fromId(entry.key);
      expect(scene, isNotNull, reason: 'no WizScene for id ${entry.key}');
      expect(
        entry.value.isDynamic,
        scene!.isDynamic,
        reason: '${entry.value.name} disagrees with WizScene.${scene.name}',
      );
      expect(entry.value.name, scene.displayName);
      expect(entry.value.id, entry.key);
    }
  });

  test('dynamicScenes and staticScenes are in id order', () {
    expect(
      dynamicScenes.map((s) => s.id).toList(),
      orderedEquals(
        sceneGradients.keys.where((id) => sceneGradients[id]!.isDynamic),
      ),
    );
    expect(
      dynamicScenes.map((s) => s.id).toList(),
      List.of(dynamicScenes.map((s) => s.id))..sort(),
    );
    expect(
      staticScenes.map((s) => s.id).toList(),
      List.of(staticScenes.map((s) => s.id))..sort(),
    );
  });
}
