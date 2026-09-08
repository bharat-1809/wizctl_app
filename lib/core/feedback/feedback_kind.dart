/// The nine tactile events, mapped to the hardware metaphor (spec §13).
enum FeedbackKind {
  /// Any labelled or icon key going down.
  press,

  /// A key coming back up: quieter, brighter.
  release,

  /// A switch closing.
  toggleOn,

  /// A switch opening.
  toggleOff,

  /// Moving between tabs, segments or rail items.
  tick,

  /// A dial, rail or wheel crossing a notch: the smallest sound.
  detent,

  /// The power key engaging a light: the heaviest.
  power,

  /// Save or apply succeeded.
  confirm,

  /// Something failed, is unreachable, or a disabled key was pressed.
  reject,
}
