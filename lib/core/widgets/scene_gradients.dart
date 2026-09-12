import 'package:flutter/material.dart';

/// Two colours per built-in WiZ scene, authored by the design system since
/// the library has no colour data for scenes. Keyed by `WizScene.id`.
@immutable
class SceneGradient {
  final int id;
  final String name;
  final bool isDynamic;
  final Color from;
  final Color to;

  const SceneGradient(this.id, this.name, this.isDynamic, this.from, this.to);
}

/// Every id, name and dynamic flag mirrors `WizScene` in the wizctl package —
/// the library is the authority and `scene_gradients_test.dart` asserts the
/// two agree entry for entry. The colours come from `SCENE_GRADIENTS` in the
/// design bundle's `SceneTile.jsx`; ordering is by id, which the
/// [staticScenes] and [dynamicScenes] getters inherit.
const Map<int, SceneGradient> sceneGradients = {
  1: SceneGradient(1, 'Ocean', true, Color(0xFF0B6FD8), Color(0xFF25D8C0)),
  2: SceneGradient(2, 'Romance', true, Color(0xFFC2185B), Color(0xFFFF8A2B)),
  3: SceneGradient(3, 'Sunset', true, Color(0xFFFF4A3D), Color(0xFFFFD52B)),
  4: SceneGradient(4, 'Party', true, Color(0xFFA45BFF), Color(0xFFFF3FC0)),
  5: SceneGradient(5, 'Fireplace', true, Color(0xFF8A1E05), Color(0xFFFF8A2B)),
  6: SceneGradient(6, 'Cozy', false, Color(0xFFB4600F), Color(0xFFFFC24D)),
  7: SceneGradient(7, 'Forest', true, Color(0xFF0E5B2A), Color(0xFFB7F03C)),
  8: SceneGradient(
    8,
    'Pastel Colors',
    true,
    Color(0xFFFFB6C1),
    Color(0xFFB8E1FF),
  ),
  9: SceneGradient(9, 'Wake Up', true, Color(0xFF3A2A5C), Color(0xFFFFD98A)),
  10: SceneGradient(10, 'Bedtime', true, Color(0xFF241634), Color(0xFFFF8A2B)),
  11: SceneGradient(
    11,
    'Warm White',
    false,
    Color(0xFFB4772A),
    Color(0xFFFFE0BC),
  ),
  12: SceneGradient(
    12,
    'Daylight',
    false,
    Color(0xFFC9D8F0),
    Color(0xFFFFF4E6),
  ),
  13: SceneGradient(
    13,
    'Cool White',
    false,
    Color(0xFF7FA8D9),
    Color(0xFFDCE9FF),
  ),
  14: SceneGradient(
    14,
    'Night Light',
    false,
    Color(0xFF2A1E10),
    Color(0xFF8A5A1E),
  ),
  15: SceneGradient(15, 'Focus', false, Color(0xFF9FC6FF), Color(0xFFFFFFFF)),
  16: SceneGradient(16, 'Relax', false, Color(0xFF1E5B3A), Color(0xFF9FE6B8)),
  17: SceneGradient(
    17,
    'True Colors',
    false,
    Color(0xFFFF4A3D),
    Color(0xFF2E7BFF),
  ),
  18: SceneGradient(18, 'TV Time', false, Color(0xFF122A4A), Color(0xFF2ECBFF)),
  19: SceneGradient(
    19,
    'Plant Growth',
    false,
    Color(0xFF5B1E8A),
    Color(0xFF38D06B),
  ),
  20: SceneGradient(20, 'Spring', true, Color(0xFF7CFF9E), Color(0xFFFFD52B)),
  21: SceneGradient(21, 'Summer', true, Color(0xFFFF8A2B), Color(0xFFFFD52B)),
  22: SceneGradient(22, 'Fall', true, Color(0xFF8A3A05), Color(0xFFFFB25C)),
  23: SceneGradient(
    23,
    'Deep Dive',
    true,
    Color(0xFF04234A),
    Color(0xFF2ECBFF),
  ),
  24: SceneGradient(24, 'Jungle', true, Color(0xFF04361E), Color(0xFFB7F03C)),
  25: SceneGradient(25, 'Mojito', true, Color(0xFF0E6B3A), Color(0xFFD6FF6E)),
  26: SceneGradient(26, 'Club', true, Color(0xFF5B5BFF), Color(0xFFFF3FC0)),
  27: SceneGradient(
    27,
    'Christmas',
    true,
    Color(0xFFC81E1E),
    Color(0xFF38D06B),
  ),
  28: SceneGradient(
    28,
    'Halloween',
    true,
    Color(0xFF4A1E6B),
    Color(0xFFFF8A2B),
  ),
  29: SceneGradient(
    29,
    'Candlelight',
    true,
    Color(0xFF7A3A05),
    Color(0xFFFFC24D),
  ),
  30: SceneGradient(
    30,
    'Golden White',
    false,
    Color(0xFFC08A1E),
    Color(0xFFFFF0C9),
  ),
  31: SceneGradient(31, 'Pulse', true, Color(0xFF1B1B22), Color(0xFFFF4A3D)),
  32: SceneGradient(
    32,
    'Steampunk',
    false,
    Color(0xFF5C4326),
    Color(0xFFD9A85C),
  ),
  33: SceneGradient(33, 'Diwali', true, Color(0xFF8A0F5B), Color(0xFFFFD52B)),
  34: SceneGradient(34, 'White', false, Color(0xFFE8ECF5), Color(0xFFFFFFFF)),
  35: SceneGradient(35, 'Alarm', true, Color(0xFF8A0505), Color(0xFFFF4A3D)),
  1000: SceneGradient(
    1000,
    'Rhythm',
    true,
    Color(0xFF2E7BFF),
    Color(0xFFA45BFF),
  ),
};

/// The fixed-colour scenes, in id order.
List<SceneGradient> get staticScenes =>
    sceneGradients.values.where((s) => !s.isDynamic).toList();

/// The animated scenes — the ones that support speed — in id order.
List<SceneGradient> get dynamicScenes =>
    sceneGradients.values.where((s) => s.isDynamic).toList();
