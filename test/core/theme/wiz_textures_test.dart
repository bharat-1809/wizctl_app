import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_textures.dart';

void main() {
  testWidgets('grainPaint opacity actually changes the painted output', (
    tester,
  ) async {
    // Picture.toImage needs a real event loop, unlike the rest of a widget
    // test's fake async zone.
    await tester.runAsync(() => WizTextures.load());
    expect(WizTextures.hasGrain, isTrue);

    var full = WizTextures.grainPaint();
    var half = WizTextures.grainPaint(opacity: 0.5);

    // Regression guard for the controller correction: opacity must be
    // applied so it actually changes what gets painted, not swallowed by a
    // `Paint.color` a shader would make dead.
    expect(full!.colorFilter, isNot(equals(half!.colorFilter)));
  });

  test('load is idempotent', () async {
    await WizTextures.load();
    expect(WizTextures.hasGrain, isTrue);
    // A second call while a tile already exists must be a no-op, not throw
    // or re-render.
    await WizTextures.load();
    expect(WizTextures.hasGrain, isTrue);
  });
}
