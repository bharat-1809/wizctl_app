import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/capability_rules.dart';

void main() {
  test('capabilities per class, spec §5.1', () {
    expect(CapabilityRules.brightness(BulbClass.socket), isFalse);
    expect(CapabilityRules.brightness(BulbClass.dw), isTrue);
    expect(CapabilityRules.brightness(null), isTrue);
    expect(CapabilityRules.kelvin(BulbClass.rgb), isTrue);
    expect(CapabilityRules.kelvin(BulbClass.tw), isTrue);
    expect(CapabilityRules.kelvin(BulbClass.dw), isFalse);
    expect(CapabilityRules.kelvin(BulbClass.fanDim), isFalse);
    expect(CapabilityRules.kelvin(null), isTrue);
    expect(CapabilityRules.colour(BulbClass.rgb), isTrue);
    expect(CapabilityRules.colour(BulbClass.tw), isFalse);
    expect(CapabilityRules.colour(null), isTrue);
    expect(CapabilityRules.scenes(BulbClass.socket), isFalse);
    expect(CapabilityRules.scenes(BulbClass.dw), isTrue);
  });

  test('speed only while on a dynamic scene', () {
    expect(CapabilityRules.isDynamicScene(1), isTrue);
    expect(CapabilityRules.isDynamicScene(6), isFalse);
    expect(CapabilityRules.isDynamicScene(1000), isTrue);
    expect(CapabilityRules.isDynamicScene(999), isFalse);
    expect(CapabilityRules.speed(LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 1)), isTrue);
    expect(CapabilityRules.speed(LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 6)), isFalse);
    expect(CapabilityRules.speed(LiveState.initial.copyWith(active: ActiveChannel.white, sceneId: 1)), isFalse);
  });
}
