/// The desktop minimum window (spec §14, §17): 720×560, under which the
/// medium layout cannot hold its rail, content and dialog. The three
/// runners repeat these two numbers in their own languages; this file is
/// the Dart side's copy and the tests pin the runners to it.
///
/// [minWidth] is deliberately the same 720 as `WizBreakpoints.compactMax`
/// (lib/core/layout/wiz_breakpoints.dart): the window floor sits exactly on
/// the compact/medium boundary, so a desktop window is never narrower than
/// the medium layout it is handed. They stay two constants — one classifies
/// any available width, the other bounds one native window — but they must
/// not drift apart silently: moving either one is a decision about both.
class WindowLimits {
  WindowLimits._();

  /// The narrowest window the medium layout fits in, in logical pixels.
  static const double minWidth = 720;

  /// The shortest window the medium layout fits in, in logical pixels.
  static const double minHeight = 560;
}
