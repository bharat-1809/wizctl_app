import '../../../core/widgets/wiz_scene_tile.dart';

/// Where the modes body is being shown; the prototypes size the wheel, the
/// swatches and the scene grid differently in each (spec §10.5, §10.9).
enum ModesLayout {
  /// The Scenes tab on a phone (`WizCtl_Mobile.dc.html` lines 346–408).
  compactTab(
    wheel: 228,
    swatch: 52,
    whiteWidth: 60,
    whiteHeight: 64,
    sceneMinTile: 160,
    sceneHeight: null,
    tileVariant: WizSceneTileVariant.tab,
    labelSize: WizSceneTile.labelSizeTab,
  ),

  /// The Scenes view on a desktop (`WizCtl_Desktop.dc.html` lines 223–284).
  desktopTab(
    wheel: 216,
    swatch: 48,
    whiteWidth: 58,
    whiteHeight: 60,
    sceneMinTile: 130,
    sceneHeight: 140,
    tileVariant: WizSceneTileVariant.tab,
    labelSize: 18,
  ),

  /// The bottom sheet on a phone (`WizCtl_Mobile.dc.html` lines 519–574).
  sheet(
    wheel: 196,
    swatch: 44,
    whiteWidth: 52,
    whiteHeight: 60,
    sceneMinTile: 100,
    sceneHeight: 82,
    tileVariant: WizSceneTileVariant.sheet,
    labelSize: WizSceneTile.labelSizeSheet,
  ),

  /// The centred dialog on a desktop (`WizCtl_Desktop.dc.html` lines
  /// 423–476): 640 wide inside, four columns of 104.
  dialog(
    wheel: 216,
    swatch: 48,
    whiteWidth: 58,
    whiteHeight: 60,
    sceneMinTile: 140,
    sceneHeight: 104,
    tileVariant: WizSceneTileVariant.sheet,
    labelSize: WizSceneTile.labelSizeSheet,
  );

  final double wheel;
  final double swatch;
  final double whiteWidth;
  final double whiteHeight;
  final double sceneMinTile;

  /// Null means square tiles.
  final double? sceneHeight;
  final WizSceneTileVariant tileVariant;
  final double labelSize;

  const ModesLayout({
    required this.wheel,
    required this.swatch,
    required this.whiteWidth,
    required this.whiteHeight,
    required this.sceneMinTile,
    required this.sceneHeight,
    required this.tileVariant,
    required this.labelSize,
  });

  /// The dialog is 680 wide (spec §10.9); the sheet keeps the kit's 520.
  double? get maxWidth => this == dialog ? dialogWidth : null;

  static const double dialogWidth = 680;
}
