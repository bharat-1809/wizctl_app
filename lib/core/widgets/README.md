# The kit

`lib/core/widgets` is the WizCtl design system in Flutter: every control,
surface and instrument the screens compose. This page is the vocabulary
and the rules that are easy to get wrong; the spec (§11) has the geometry.

## Vocabulary

- `value` is a control's number or choice (a dial's brightness, a
  segmented control's tab, a toggle's position). It is owned by the caller;
  the widget reports changes through `onChanged` — and, where the change is
  a drag, again through `onChangeEnd` when the finger lifts — and never
  keeps its own.
- `on` is power: a light, a room, a power key, the glow behind a card.
  Power draws the emission (amber, glow, lit well).
- `active` is "this is the current one" for navigation-like parts: the icon
  key, the list row for the active home. Active draws amber without
  emission — an amber cap, an amber hairline. A rail says the same thing by
  comparing each item's `value` with the rail's, rather than through a flag
  of its own.
- `selected` is a pick inside a set: a scene tile, a chip, a card in the
  desktop grid. A tile and a card draw the 1.5 amber ring
  (`space.keyBorder`); a chip, being a pill of its own, fills amber
  instead.
- `enabled: false` draws the control at 42 % (`WizColors.disabledAlpha`)
  and makes it inert and silent.

## Press and feedback

`WizPressable` is the one press recipe: the part sinks `motion.pressTravel`
(1.5) and scales in 80 ms, then springs back on the settle curve in 140 ms.
It reports `pressed` to its builder, which is how a widget flips its own
shadow spec — the sink and the scale are the pressable's, the shape under
them is the widget's.

The cue fires on pointer down, of the kind the widget handed its pressable:
`WizButton` gives `confirm` for a primary cap, `reject` for a danger cap and
`press` for secondary and ghost; a chip gives `tick`; a scene tile gives
`tick` unselected and `press` selected; a power key gives `power` turning on
and `toggleOff` turning off; and `WizPressable` itself defaults to `press`.

A control whose cue belongs to something other than the touch passes
`feedback: null` and plays its own instead. A toggle plays
`toggleOn`/`toggleOff` on the commit, so a drag that comes home again is
silent. Tabs, rail items and segments play `tick` on the change, so a tap on
the one already current is silent. And there is a third shape: `LightCard`
passes `feedback: null` to stay silent altogether, because its own key would
fire at the arena's 100 ms tap-down — which a finger resting on the brightness
rail reaches before the drag recogniser claims it — so the card played `press`
twice and sank under the handle.

The drag instruments — dial, slider, colour wheel — are not pressables at all.
They play `press` themselves when the drag starts, and `detent` on each notch
crossed after that.

A disabled key plays nothing — the pressable returns before the cue — so
`reject` is only ever a refusal *after* a press, never "you pressed
something you could not press".

## Arena-resolved widgets

By default a pressable takes the pointer the instant it lands, through a
`Listener`, which is the tactile ideal. `arenaResolved: true` hands that to
`GestureDetector`'s tap callbacks instead, so the gesture arena decides
first. Two kinds of widget need it:

- a pressable that *hosts* other controls, so it stays still when a child
  wins the arena — `LightCard` passes it on its own card button because it
  holds a toggle and a brightness rail;
- a pressable that *is* hosted by something scrollable or draggable —
  `WizToggle` (its cap can be dragged off its own tap), `WizRail`,
  `WizSegmentedControl` and `WizListRow` all pass it.

Do the same for any control you host in a card or a list row.

## Radius typing

Surfaces take a `BorderRadius`: `WizSurface`, which clips and paints the
inset shadows, is given the shape outright. Panels take a `double` and
build the radius themselves (`WizPanel.radius`). Do not convert one to the
other at a call site; pick the widget that takes what you have.

## RiseIn in lazy lists

`RiseIn` runs its entrance once, on mount, and never replays it. A lazy
list (`ListView.builder`) builds items as they scroll into view, so an item
that scrolls in rises then rather than on the screen's first build, which
is not the design's "first build only". Use `RiseIn` in a non-lazy column,
or key each item so its entrance state survives rebuilding. `ScreenScroll`
is a `ListView.separated` over a screen's handful of sections, which is
short enough that they are all built at once.

## Hosted-control semantics

A labelled pressable is one semantics node: its drawn copy is excluded and
the label speaks for the whole. That node has no container of its own,
though, so inside a semantics boundary it will absorb the words beside it —
which is why a part that hosts several labelled things isolates them with
`Semantics(container: true, explicitChildNodes: true)`: `WizTopBar`,
`WizStatusBanner`, `WizToast` and the sheet route all do. A card that hosts
a toggle or a rail wraps each in `Semantics(container: true)` for the same
reason, so a screen reader reaches the switch inside the card. The toggle
reads as a switch through the toggled flags (`hasToggledState`,
`isToggled`); the engine has no switch role.

## Reduced motion

See `lib/core/motion/reduced_motion.dart` for the policy. In short: no
staggers, no loops, no timed transitions; state changes still move rather
than jump.

The division of labour is the part to remember. Flutter runs an ordinary
controller's `forward`/`reverse`/`animateTo` at 5 % of its duration while the
platform flag is on, so a state change — each one on an ordinary controller,
implicit or explicit, and none of them handed
`AnimationBehavior.preserve` — collapses to about a frame on its own, and asks
for nothing. (Most are implicit; the explicit controllers live in `wiz_glow`,
`fixture_hero`, `wiz_badge`, `wiz_filament_bar`, `wiz_spinner` and
`wiz_skeleton`, of which `WizGlow`'s is the one driving a state change rather
than a loop.)
`repeat()` is *not* scaled, and nor is a duration that has to be exactly
zero, so every loop, every stagger and the page and step transitions ask
`wizReducedMotion(context)` for themselves.

## Sizes

No control reaches for an inline number where a token exists: spacing from
`context.wiz.space`, faces and sizes from `context.wiz.typography`, colours
from `context.wiz.colors`, durations and curves from `context.wiz.motion`,
shadows from `context.wiz.elevation`. A widget's own geometry — a dial's
sweep, a toggle's track and cap, a rail's row height — is a named
`static const` at the top of its file with the design source in a comment,
and so are the alphas and offsets of a shadow transcribed from the design
system's CSS.

## Known debt

Carried from reviews; none of it is load-bearing, and each is one commit's
worth of work.

- `add_room_sheet.dart`, `rename_light_sheet.dart` and
  `rename_home_sheet.dart` are three near-identical single-field name
  sheets that could share one `showNameSheet`.
- `WizListRow.meta` is one line; a second line has to go under the row as
  its own caption (P78).
- `WizButton` has no busy state: onboarding's Finish shows the disabled cap
  and a toast instead (P75).
- `ToastController.update` on an id that has already been dismissed is a
  silent no-op, so a loading toast the user swiped away swallows its
  outcome.
- `DualDials(kelvin:, onKelvin: null)` draws an inert live knob rather than
  the kit's disabled dial (P61/P62 records this as the behaviour as built).
