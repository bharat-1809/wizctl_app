import 'package:flutter/material.dart';

import 'fixture_hero.dart';

/// One shade's box: its size, its top and bottom corner radii, how far below
/// the stage's centre its own centre sits, and whether cords hang above it.
typedef WizShade = ({
  double w,
  double h,
  Radius top,
  Radius bottom,
  double offset,
  bool cord,
});

/// A glow: where its box starts, how tall it is, how many fixture widths
/// wide, and the CSS `filter: blur()` it carries.
typedef WizGlow = ({double top, double height, double width, double blur});

/// Geometry of the hero in its 350×236 design box, from the prototype's
/// `GEO` map and hero markup (`design/reference/WizCtl_Mobile.dc.html` and
/// `WizCtl_Desktop.dc.html`, cited per number below). Everything scales
/// uniformly from here, so every value is in design pixels or a fraction.
class FixtureGeometry {
  FixtureGeometry._();

  /// The stage: `height:236px` with the fixture centred (Mobile:247), 350
  /// wide — spec §352, "inside a 350×236 design box scaled uniformly to the
  /// available width".
  static const Size box = Size(350, 236);

  /// The desktop inspector's well: `height:132px` (Desktop:357) on the same
  /// 350-wide design box — spec §352, "a 132-tall well at 0.6 scale".
  static const Size compactBox = Size(350, 132);

  /// Desktop:359 `transform:scale(.6)` on the fixture itself.
  static const double compactScale = 0.6;

  /// A blur sigma is roughly half the CSS blur radius it mimics — the same
  /// conversion `paintInsets` applies to a `WizInset` blur — so every `blur()`
  /// below keeps the prototype's own number and is divided by this on the
  /// way into a `MaskFilter`.
  static const double blurToSigma = 2;

  static double sigma(double cssBlur) => cssBlur / blurToSigma;

  /// The four shade fixtures, from the prototype's `GEO` map (Mobile:721,
  /// 723, 724, 725). CSS `border-radius:14px 14px 108px 108px / 14px 14px
  /// 54px 54px` is a circular 14 at the top over an elliptical 108×54 at the
  /// bottom; the socket's `var(--radius-4)` is 20 (`tokens/spacing.css:6`),
  /// which spec §352 repeats as "socket (104 square, radius 20)".
  ///
  /// `offset` is half the `GEO` entry's `top`, which the prototype applies
  /// as a `margin-top`: the stage centres the fixture's *margin* box
  /// (`place-items:center`, Mobile:247), so a 34 px margin moves the shade
  /// itself down by 17.
  static const Map<WizFixture, WizShade> shades = {
    WizFixture.dome: (
      w: 216,
      h: 78,
      top: Radius.circular(14),
      bottom: Radius.elliptical(108, 54),
      offset: 17,
      cord: true,
    ),
    WizFixture.desk: (
      w: 140,
      h: 76,
      top: Radius.elliptical(78, 62),
      bottom: Radius.circular(14),
      offset: 9,
      cord: false,
    ),
    WizFixture.strip: (
      w: 262,
      h: 20,
      top: Radius.circular(10),
      bottom: Radius.circular(10),
      offset: 0,
      cord: false,
    ),
    WizFixture.socket: (
      w: 104,
      h: 104,
      top: Radius.circular(20),
      bottom: Radius.circular(20),
      offset: 0,
      cord: false,
    ),
  };

  /// Mobile:257 shade body: `linear-gradient(180deg,#3A3A42,#141418 62%)`,
  /// `railDark` to `shadeBottom`.
  static const double shadeStop = 0.62;

  /// Mobile:258 knurled grip: `height:34%` of the shade, at `opacity:.5`.
  static const double knurlBand = 0.34;
  static const double knurlBandAlpha = 0.5;

  /// Mobile:260 grain over the shade: `background-size:3px 3px;opacity:.7`.
  static const double shadeGrain = 0.7;

  /// Mobile:259, the mouth the light leaves by: `left:6%;right:6%;
  /// bottom:-6%;height:52%;border-radius:50%` filled with
  /// `radial-gradient(60% 100% at 50% 100%,var(--em),var(--emSoft) 58%,
  /// rgba(0,0,0,.9) 100%)`.
  static const double mouthInset = 0.06;
  static const double mouthWidth = 0.88;
  static const double mouthHeight = 0.52;
  static const double mouthDrop = 0.06;
  static const double mouthSoftStop = 0.58;
  static const double mouthEdgeAlpha = 0.9;

  /// That gradient's ending shape, `60% 100%`: the glow reaches 60 % of the
  /// mouth's width sideways and its full height upwards. Flutter measures a
  /// radial radius against the box's shortest side — the height, since all
  /// four mouths are wider than they are tall — so [mouthRadius] is the
  /// vertical 100 % and [mouthEllipseX] is applied on top of it as a
  /// horizontal stretch of `mouthEllipseX × width / height`.
  static const double mouthRadius = 1;
  static const double mouthEllipseX = 0.6;

  /// Mobile:249-251, the two cords a dome hangs from: `width:1px;
  /// height:74px`, `gap:64px`, `linear-gradient(180deg,
  /// rgba(255,255,255,.16),rgba(255,255,255,.05))`.
  static const double cordWidth = 1;
  static const double cordHeight = 74;
  static const double cordGap = 64;
  static const double cordTopAlpha = 0.16;
  static const double cordBottomAlpha = 0.05;

  /// Mobile:265 screw cap: `width:44px;height:28px;border-radius:5px 5px 3px
  /// 3px` over the knurl.
  static const Size cap = Size(44, 28);
  static const Radius capTop = Radius.circular(5);
  static const Radius capBottom = Radius.circular(3);

  /// Mobile:266 neck: `width:58px;height:18px;margin-top:-1px` clipped to
  /// `polygon(16% 0,84% 0,100% 100%,0 100%)`.
  static const Size neck = Size(58, 18);
  static const double neckLeft = 0.16;
  static const double neckRight = 0.84;
  static const double neckOverlap = 1;

  /// Mobile:267 globe: `width:122px;height:122px;margin-top:-8px` — spec
  /// §352's "122 globe".
  static const double globe = 122;
  static const double globeOverlap = 8;

  /// Half the bulb column's `margin-top:8px` (Mobile:264) — see [shades].
  static const double bulbOffset = 4;

  /// Mobile:267 glass: `radial-gradient(58% 58% at 50% 58%,var(--em),
  /// var(--emSoft) 52%,rgba(24,24,29,.94) 100%)`. `50% 58%` is
  /// (0, 0.16) in [Alignment]'s -1..1 box.
  static const Alignment globeCentre = Alignment(0, 0.16);
  static const double globeRadius = 0.58;
  static const double globeSoftStop = 0.52;

  /// Mobile:267 glass rim: `inset 0 -10px 20px rgba(0,0,0,.55)` and
  /// `inset 0 3px 0 rgba(255,255,255,.12)`.
  static const double globeGrooveOffset = -10;
  static const double globeGrooveBlur = 20;
  static const double globeGrooveAlpha = 0.55;
  static const double globeRimOffset = 3;
  static const double globeRimAlpha = 0.12;

  /// Mobile:268-271 filaments: two `width:2px;height:34px` spans `gap:12px`
  /// apart, their top at `34%` of the globe, each under `filter:blur(.6px)`.
  static const double filamentTop = 0.34;
  static const double filamentHeight = 34;
  static const double filamentGap = 12;
  static const double filamentStroke = 2;
  static const double filamentBlur = 0.6;

  /// Mobile:272 the loop joining them: a `width:16px;height:10px` box with
  /// `border-radius:0 0 10px 10px` and a 2 px bottom border, its top at
  /// `calc(34% + 30px)` — the lower half of a 16×20 ellipse centred 30 below
  /// where the filaments start.
  static const Size loop = Size(16, 20);
  static const double loopTop = 30;

  /// Mobile:273 the highlight the glass catches: `left:18%;top:14%;
  /// width:26px;height:16px;border-radius:50%;
  /// background:rgba(255,255,255,.16);filter:blur(3px)`.
  static const double highlightLeft = 0.18;
  static const double highlightTop = 0.14;
  static const Size highlight = Size(26, 16);
  static const double highlightAlpha = 0.16;
  static const double highlightBlur = 3;

  /// Mobile:274 grain over the globe: `background-size:3px 3px;opacity:.5`.
  static const double globeGrain = 0.5;

  /// Mobile:254, the bloom above the fixture: `top:92px;
  /// width:calc(var(--w) * 1.55);height:190px;border-radius:50%;
  /// filter:blur(34px)`.
  static const WizGlow bloom = (top: 92, height: 190, width: 1.55, blur: 34);

  /// Desktop:358, the same bloom in the inspector well: `top:58px;
  /// width:calc(var(--w) * 1.1);height:110px;filter:blur(24px)`. That `--w`
  /// is the fixture's unscaled width — Desktop:359 scales the fixture, not
  /// the glow — so a compact dome's bloom is 216 × 1.1 wide, not 129.6 × 1.1.
  static const WizGlow compactBloom = (
    top: 58,
    height: 110,
    width: 1.1,
    blur: 24,
  );

  /// Mobile:255, the pool the fixture throws on the floor: `top:150px;
  /// width:calc(var(--w) * 0.9);height:26px;border-radius:50%;
  /// filter:blur(14px)` in flat `var(--em)`. The inspector well is too
  /// short to carry one (Desktop:357-359 draws no floor glow).
  static const WizGlow floor = (top: 150, height: 26, width: 0.9, blur: 14);

  /// Mobile:254 `radial-gradient(50% 52% at 50% 0%,var(--em),
  /// rgba(0,0,0,0) 74%)`: the fade starts at the top edge and is out by 74 %.
  /// CSS sizes its ending shape per axis (50 % of the width by 52 % of the
  /// height) where a Flutter radial radius is one number against the box's
  /// shortest side, so the task brief maps that vertical 52 % to 1.04 —
  /// twice it, the whole box measured down from a top-centred origin.
  static const double bloomRadius = 1.04;
  static const double bloomFade = 0.74;
}
