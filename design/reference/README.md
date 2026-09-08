# Design reference (not code)

Copied from the Claude Design project "Philips Wiz Light Controller App"
(https://claude.ai/design/p/9e13200d-ef9c-452f-8e84-0b76ccab6bc2) on 2026-09-08.

- `WizCtl_Mobile.dc.html` — phone prototype, 390×844. The `Component` class at the bottom is the behaviour spec.
- `WizCtl_Desktop.dc.html` — desktop prototype, 1232×712.
- `_ds_bundle.js` — compiled design-system components. Lines 11–3013 are the component sources:
  Readout, Badge, Icon (49 Phosphor Bold paths), Panel, Feedback (sound recipes), ColorWheel, Dial,
  PowerKey, SceneTile + SCENE_GRADIENTS (36 scenes), Slider + SLIDER_FILLS, Stepper, Button, IconButton,
  ListRow, SegmentedControl, Toggle, EmptyState, LightCard, RoomCard, StatTile, FilamentBar, Skeleton,
  Spinner, StatusBanner, Toast/ToastStack, Sheet, Sidebar, TabBar, TopBar.
- `tokens/*.css` — the design tokens. The Flutter theme ports these one for one.

Behaviour, copy, ranges and motion are consolidated in `docs/superpowers/specs/2026-09-08-wizctl-app-design.md`.
Do not port the HTML; recreate it in Flutter.
