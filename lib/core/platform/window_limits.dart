/// The desktop minimum window (spec §14, §17): 720×560, under which the
/// medium layout cannot hold its rail, content and dialog. The three
/// runners repeat these two numbers in their own languages; this file is
/// the Dart side's copy and the tests pin the runners to it.
class WindowLimits {
  WindowLimits._();

  /// The narrowest window the medium layout fits in, in logical pixels.
  static const double minWidth = 720;

  /// The shortest window the medium layout fits in, in logical pixels.
  static const double minHeight = 560;
}
