import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'scene_gradients.dart';
import 'wiz_pressable.dart';
import 'wiz_scene_art.dart';

/// Where the tile is being shown. The reference draws the same scene two
/// ways: the big two-up grid on the Scenes tab
/// (`design/reference/WizCtl_Mobile.dc.html:391-396`) and the tighter
/// three-up grid inside the scene sheet (`:558-562`).
enum WizSceneTileVariant { tab, sheet }

/// Everything the variant decides, so the two sets sit side by side.
typedef _VariantSpec = ({
  double labelSize,
  FontWeight labelWeight,
  double scrimAlpha,
  bool sheen,
});

/// A scene as an art tile: procedural art, the name in the display face over
/// a bottom gradient, a cyan pip when the scene is dynamic, and a 1.5 amber
/// ring when selected. One tap applies.
///
/// [variant] picks the reference's tab or sheet treatment; [radius],
/// [labelSize] and [sheen] override individual pieces of it.
class WizSceneTile extends StatelessWidget {
  final int sceneId;
  final bool selected;
  final VoidCallback? onTap;
  final WizSceneTileVariant variant;

  /// Null takes the variant's radius: `r4` on a tab, `r3` in the sheet.
  final double? radius;

  /// Null takes the variant's label size: 20 on a tab, 14 in the sheet.
  final double? labelSize;

  /// Null takes the variant's sheen: the tab grid always carries it, the
  /// sheet never does.
  final bool? sheen;

  final double? height;

  const WizSceneTile({
    super.key,
    required this.sceneId,
    required this.selected,
    required this.onTap,
    this.variant = WizSceneTileVariant.tab,
    this.radius,
    this.labelSize,
    this.sheen,
    this.height,
  });

  /// Spec §332: the label is "20 tab / 14 sheet"
  /// (`design/reference/WizCtl_Mobile.dc.html:396` and `:562`).
  static const double labelSizeTab = 20;
  static const double labelSizeSheet = 14;

  /// The tab label is `font-weight:700` (`:396`), the sheet's `600` (`:562`).
  static const FontWeight _labelWeightTab = FontWeight.w700;
  static const FontWeight _labelWeightSheet = FontWeight.w600;

  /// The tab grid stacks a sheen over the art (`:393`); the sheet's tiles go
  /// straight from art to grain (`:559-560`), with none.
  static const bool _sheenTab = true;
  static const bool _sheenSheet = false;

  /// How dark the label scrim gets at the bottom edge:
  /// `rgba(8,8,10,.86)` on a tab (`:395`), `.88` in the sheet (`:561`).
  static const double _scrimAlphaTab = .86;
  static const double _scrimAlphaSheet = .88;

  /// The tab scrim's `padding:10px 12px` (`:395`) is the one number here with
  /// no spacing token; its 12 is `space.s5`, and the sheet's `6px 8px`
  /// (`:561`) is `space.s3` over `space.s4`.
  static const double _scrimPadTabVertical = 10;

  static const _VariantSpec _tabSpec = (
    labelSize: labelSizeTab,
    labelWeight: _labelWeightTab,
    scrimAlpha: _scrimAlphaTab,
    sheen: _sheenTab,
  );

  static const _VariantSpec _sheetSpec = (
    labelSize: labelSizeSheet,
    labelWeight: _labelWeightSheet,
    scrimAlpha: _scrimAlphaSheet,
    sheen: _sheenSheet,
  );

  /// Spec §332: "cyan 5 px pip with glow for dynamic".
  static const double pipSize = 5;

  /// The glow the spec leaves unmeasured: `SceneTile.jsx` draws it as
  /// `box-shadow: 0 0 8px var(--hue-cyan)`.
  static const double pipGlowBlur = 8;

  /// Square, unless the caller gives the tile a height — the tab grid is
  /// `aspect-ratio:1 / 1` (`:391`) and the sheet passes `height:82px`
  /// (`:558`).
  static const double _aspect = 1;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var scene = sceneGradients[sceneId]!;
    var spec = switch (variant) {
      WizSceneTileVariant.tab => _tabSpec,
      WizSceneTileVariant.sheet => _sheetSpec,
    };
    // `border-radius:var(--radius-4)` on a tab (`:391`), `--radius-3` in the
    // sheet (`:558`).
    var border = BorderRadius.circular(
      radius ??
          switch (variant) {
            WizSceneTileVariant.tab => wiz.space.r4,
            WizSceneTileVariant.sheet => wiz.space.r3,
          },
    );
    // Scrim padding: `10px 12px` on a tab (`:395`), `6px 8px` in the sheet
    // (`:561`).
    var scrimPad = switch (variant) {
      WizSceneTileVariant.tab => EdgeInsets.symmetric(
        horizontal: wiz.space.s5,
        vertical: _scrimPadTabVertical,
      ),
      WizSceneTileVariant.sheet => EdgeInsets.symmetric(
        horizontal: wiz.space.s4,
        vertical: wiz.space.s3,
      ),
    };
    var size = labelSize ?? spec.labelSize;
    // The reference sets no line-height on either label
    // (`:396`, `:562`), so the display face's own 1.16 stands.
    var label = wiz.typography.heading.copyWith(
      fontSize: size,
      fontWeight: spec.labelWeight,
      letterSpacing: size * WizType.sceneTileTracking,
      color: c.ink1000,
    );
    var tile = Stack(
      fit: StackFit.expand,
      children: [
        WizSceneArt.scene(sceneId, radius: border, sheen: sheen ?? spec.sheen),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: scrimPad,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.char1000.withValues(alpha: 0),
                  c.char1000.withValues(alpha: spec.scrimAlpha),
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
