/// Width classes, spec §14. Evaluated from the available width, never from
/// the platform, so a resized desktop window or a folded phone re-lays out.
enum WidthClass {
  compact,
  medium,
  expanded,
  wide;

  bool get isCompact => this == compact;

  /// Medium and above: rail instead of tab bar, dialogs instead of sheets.
  bool get isDesktopLike => this != compact;

  /// Expanded and wide: the inspector is a fixed column.
  bool get hasInspectorColumn => this == expanded || this == wide;
}

/// Breakpoints from the handoff spec, §14 (layout & width classes):
/// compact below 720, medium 720–1100, expanded 1100–1600, wide at or
/// above 1600.
class WizBreakpoints {
  WizBreakpoints._();

  static const double compactMax = 720;
  static const double mediumMax = 1100;
  static const double wideMin = 1600;

  static WidthClass classify(double width) {
    if (width < compactMax) return WidthClass.compact;
    if (width < mediumMax) return WidthClass.medium;
    if (width < wideMin) return WidthClass.expanded;
    return WidthClass.wide;
  }
}
