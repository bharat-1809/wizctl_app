import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'scene_gradients.dart';
import 'wiz_pressable.dart';
import 'wiz_scene_art.dart';

/// A scene as an art tile: procedural art, the name in the display face over
/// a bottom gradient, a cyan pip when the scene is dynamic, and a 1.5 amber
/// ring when selected. One tap applies.
class WizSceneTile extends StatelessWidget {
  final int sceneId;
  final bool selected;
  final VoidCallback? onTap;
  final double? radius;
  final double? labelSize;
  final bool sheen;
  final double? height;

  const WizSceneTile({
    super.key,
    required this.sceneId,
    required this.selected,
    required this.onTap,
    this.radius,
    this.labelSize,
    this.sheen = false,
    this.height,
  });

  /// Spec §332: the label is "20 tab / 14 sheet". The grid on a tab is the
  /// default; the scene sheet passes the smaller one.
  static const double labelSizeTab = 20;
  static const double labelSizeSheet = 14;

  /// Spec §332: "cyan 5 px pip with glow for dynamic".
  static const double pipSize = 5;

  /// The glow the spec leaves unmeasured: `SceneTile.jsx` draws it as
  /// `box-shadow: 0 0 8px var(--hue-cyan)`.
  static const double pipGlowBlur = 8;

  /// How dark the label scrim gets at the bottom edge — the plan's value
  /// (task 16 brief, step 4) for the "bottom gradient label" of spec §332.
  static const double _labelScrimAlpha = .86;

  /// Square, unless the caller gives the tile a height.
  static const double _aspect = 1;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var scene = sceneGradients[sceneId]!;
    var border = BorderRadius.circular(radius ?? wiz.space.r4);
    var size = labelSize ?? labelSizeTab;
    var label = wiz.typography.heading.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: size * WizType.sceneLabelTracking,
      color: c.ink1000,
      height: 1.1,
    );
    var tile = Stack(
      fit: StackFit.expand,
      children: [
        WizSceneArt.scene(sceneId, radius: border, sheen: sheen),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: wiz.space.s5,
              vertical: wiz.space.s4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.char1000.withValues(alpha: 0),
                  c.char1000.withValues(alpha: _labelScrimAlpha),
                ],
              ),
            ),
            child: Text(
              scene.name,
              style: label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (scene.isDynamic)
          Positioned(
            top: wiz.space.s4,
            right: wiz.space.s4,
            child: Container(
              key: Key('scene-pip-$sceneId'),
              width: pipSize,
              height: pipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.hueCyan,
                boxShadow: [
                  BoxShadow(color: c.hueCyan, blurRadius: pipGlowBlur),
                ],
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: m.ui,
              curve: m.tactile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: border,
                  border: Border.all(
                    color: c.amber500,
                    width: wiz.space.keyBorder,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return WizPressable(
      onTap: onTap,
      enabled: onTap != null,
      feedback: selected ? FeedbackKind.press : FeedbackKind.tick,
      scale: m.pressScale,
      semanticsLabel: scene.name,
      toggled: selected,
      focusRadius: border,
      builder: (context, state) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: border,
          boxShadow: wiz.elevation.raised.outer,
        ),
        child: ClipRRect(
          borderRadius: border,
          child: height != null
              ? SizedBox(height: height, child: tile)
              : AspectRatio(aspectRatio: _aspect, child: tile),
        ),
      ),
    );
  }
}
