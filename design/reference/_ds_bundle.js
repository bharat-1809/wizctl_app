/* @ds-bundle: {"format":4,"namespace":"WizCtlDesignSystem_2a6b25","components":[{"name":"ColorWheel","sourcePath":"components/controls/ColorWheel.jsx"},{"name":"Dial","sourcePath":"components/controls/Dial.jsx"},{"name":"PowerKey","sourcePath":"components/controls/PowerKey.jsx"},{"name":"Readout","sourcePath":"components/controls/Readout.jsx"},{"name":"SCENE_GRADIENTS","sourcePath":"components/controls/SceneTile.jsx"},{"name":"SceneTile","sourcePath":"components/controls/SceneTile.jsx"},{"name":"SLIDER_FILLS","sourcePath":"components/controls/Slider.jsx"},{"name":"Slider","sourcePath":"components/controls/Slider.jsx"},{"name":"Stepper","sourcePath":"components/controls/Stepper.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"ListRow","sourcePath":"components/core/ListRow.jsx"},{"name":"Panel","sourcePath":"components/core/Panel.jsx"},{"name":"SegmentedControl","sourcePath":"components/core/SegmentedControl.jsx"},{"name":"Toggle","sourcePath":"components/core/Toggle.jsx"},{"name":"Feedback","sourcePath":"components/core/feedback.jsx"},{"name":"EmptyState","sourcePath":"components/data/EmptyState.jsx"},{"name":"LightCard","sourcePath":"components/data/LightCard.jsx"},{"name":"RoomCard","sourcePath":"components/data/RoomCard.jsx"},{"name":"StatTile","sourcePath":"components/data/StatTile.jsx"},{"name":"FilamentBar","sourcePath":"components/feedback/FilamentBar.jsx"},{"name":"Skeleton","sourcePath":"components/feedback/Skeleton.jsx"},{"name":"Spinner","sourcePath":"components/feedback/Spinner.jsx"},{"name":"STATUS_TONES","sourcePath":"components/feedback/StatusBanner.jsx"},{"name":"StatusBanner","sourcePath":"components/feedback/StatusBanner.jsx"},{"name":"Toast","sourcePath":"components/feedback/Toast.jsx"},{"name":"ToastStack","sourcePath":"components/feedback/Toast.jsx"},{"name":"Toasts","sourcePath":"components/feedback/Toast.jsx"},{"name":"Sheet","sourcePath":"components/layout/Sheet.jsx"},{"name":"Sidebar","sourcePath":"components/layout/Sidebar.jsx"},{"name":"TabBar","sourcePath":"components/layout/TabBar.jsx"},{"name":"TopBar","sourcePath":"components/layout/TopBar.jsx"}],"sourceHashes":{"components/controls/ColorWheel.jsx":"5327dfa2ed91","components/controls/Dial.jsx":"26eb3c611d2a","components/controls/PowerKey.jsx":"4b576434a350","components/controls/Readout.jsx":"44e1fee33456","components/controls/SceneTile.jsx":"880883231d4d","components/controls/Slider.jsx":"0aadd4b524c5","components/controls/Stepper.jsx":"0d93a03afdb3","components/core/Badge.jsx":"caa20379ed60","components/core/Button.jsx":"c8d5043761c1","components/core/Icon.jsx":"e6df34b8cd4a","components/core/IconButton.jsx":"3433a5a9929d","components/core/ListRow.jsx":"47fb6dd0a1b7","components/core/Panel.jsx":"90f7a3ee5f7d","components/core/SegmentedControl.jsx":"9e4241a63ebf","components/core/Toggle.jsx":"736652cc6492","components/core/feedback.jsx":"5fa7d2bfa2ac","components/data/EmptyState.jsx":"d5a8fe2da5a3","components/data/LightCard.jsx":"fa3808d08ccb","components/data/RoomCard.jsx":"6f966c6b152f","components/data/StatTile.jsx":"32422b5d7ef9","components/feedback/FilamentBar.jsx":"12fe1f23d844","components/feedback/Skeleton.jsx":"1e9e20346681","components/feedback/Spinner.jsx":"502bdc0d279b","components/feedback/StatusBanner.jsx":"5fb19e2cc92d","components/feedback/Toast.jsx":"6c8ef573e0e4","components/layout/Sheet.jsx":"0086a1e64c27","components/layout/Sidebar.jsx":"388b5dacfcce","components/layout/TabBar.jsx":"df7542a437ee","components/layout/TopBar.jsx":"aab372c20212","ui_kits/desktop_app/desktop.jsx":"406b0c038a62","ui_kits/mobile_app/app.jsx":"00ee09163a46","ui_kits/mobile_app/screens.jsx":"9aba322e15b3"},"inlinedExternals":[],"unexposedExports":[{"name":"feedback","sourcePath":"components/core/feedback.jsx"},{"name":"iconNames","sourcePath":"components/core/Icon.jsx"},{"name":"useFeedback","sourcePath":"components/core/feedback.jsx"},{"name":"useToasts","sourcePath":"components/feedback/Toast.jsx"}]} */

(() => {

const __ds_ns = (window.WizCtlDesignSystem_2a6b25 = window.WizCtlDesignSystem_2a6b25 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/controls/Readout.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Instrument readout: large display numeral with a small unit, optional caps label above. */
function Readout({
  value,
  unit,
  label,
  tone = 'default',
  align = 'left',
  size = 'md',
  mono = false,
  style,
  ...rest
}) {
  const fs = size === 'sm' ? 'var(--type-readout-sm-size)' : size === 'lg' ? 48 : 'var(--type-readout-size)';
  const color = tone === 'accent' ? 'var(--amber-400)' : tone === 'muted' ? 'var(--text-tertiary)' : 'var(--text-primary)';
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 4,
      alignItems: align === 'center' ? 'center' : 'flex-start',
      ...style
    }
  }, rest), label && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 2,
      fontFamily: mono ? 'var(--font-mono)' : 'var(--font-display)',
      fontSize: fs,
      fontWeight: mono ? 500 : 800,
      lineHeight: 1,
      color,
      fontVariantNumeric: 'tabular-nums'
    }
  }, value, unit && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: '0.44em',
      fontWeight: 600,
      color: 'var(--text-tertiary)'
    }
  }, unit)));
}
Object.assign(__ds_scope, { Readout });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/Readout.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const WZ_ANIM_ID = 'wz-anim';
const WZ_ANIM_CSS = '@keyframes wz-pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.4;transform:scale(.72)}}@keyframes wz-pop{0%{transform:scale(1)}38%{transform:scale(1.055)}100%{transform:scale(1)}}@keyframes wz-sheet-in{from{transform:translateY(14px);opacity:.6}to{transform:none;opacity:1}}';
function ensureAnim() {
  if (typeof document === 'undefined' || document.getElementById(WZ_ANIM_ID)) return;
  const el = document.createElement('style');
  el.id = WZ_ANIM_ID;
  el.textContent = WZ_ANIM_CSS;
  document.head.appendChild(el);
}
const BADGE_TONES = {
  neutral: {
    fg: 'var(--text-tertiary)',
    dot: 'var(--signal-offline)'
  },
  accent: {
    fg: 'var(--amber-400)',
    dot: 'var(--amber-500)'
  },
  online: {
    fg: 'var(--signal-online)',
    dot: 'var(--signal-online)'
  },
  danger: {
    fg: 'var(--signal-danger)',
    dot: 'var(--signal-danger)'
  }
};

/** Small engraved status pill: reachability, bulb class, scene state. */
function Badge({
  children,
  tone = 'neutral',
  dot = false,
  style,
  ...rest
}) {
  ensureAnim();
  const t = BADGE_TONES[tone] || BADGE_TONES.neutral;
  const live = dot && tone !== 'neutral';
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      height: 22,
      padding: '0 9px',
      borderRadius: 'var(--radius-pill)',
      background: 'rgba(0,0,0,.35)',
      boxShadow: 'var(--elev-well)',
      color: t.fg,
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--type-caption-size)',
      fontWeight: 600,
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      ...style
    }
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: '50%',
      background: t.dot,
      boxShadow: live ? `0 0 8px ${t.dot}` : 'none',
      animation: live ? 'wz-pulse 2.2s var(--ease-tactile) infinite' : 'none'
    }
  }), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
// Phosphor Bold icon geometry, copied verbatim from github.com/phosphor-icons/core (assets/bold/*.svg).
// Keys are WizCtl's own names; several map onto a differently-named Phosphor glyph
// (lightbulb -> lightbulb-filament, sofa -> couch, radio -> broadcast, zap -> lightning, ...).
// Raw source files also live in assets/icons/ under these same names, for non-React use.
const ICONS = {
  'arrow-left': '<path d="M228,128a12,12,0,0,1-12,12H69l51.52,51.51a12,12,0,0,1-17,17l-72-72a12,12,0,0,1,0-17l72-72a12,12,0,0,1,17,17L69,116H216A12,12,0,0,1,228,128Z"></path>',
  'arrow-right': '<path d="M224.49,136.49l-72,72a12,12,0,0,1-17-17L187,140H40a12,12,0,0,1,0-24H187L135.51,64.48a12,12,0,0,1,17-17l72,72A12,12,0,0,1,224.49,136.49Z"></path>',
  'bath': '<path d="M240,92H211.3A12,12,0,0,0,200,84H136a12,12,0,0,0-11.3,8H68V52a8,8,0,0,1,8-8,8.5,8.5,0,0,1,8.24,6.39,12,12,0,0,0,23.52-4.78A32.22,32.22,0,0,0,44,52V92H16A12,12,0,0,0,4,104v40a60.07,60.07,0,0,0,56,59.85V216a12,12,0,0,0,24,0V204h88v12a12,12,0,0,0,24,0V203.85A60.07,60.07,0,0,0,252,144V104A12,12,0,0,0,240,92Zm-92,16h40v24H148Zm80,36a36,36,0,0,1-36,36H64a36,36,0,0,1-36-36V116h96v28a12,12,0,0,0,12,12h64a12,12,0,0,0,12-12V116h16Z"></path>',
  'bed': '<path d="M212,68H36V48a12,12,0,0,0-24,0V208a12,12,0,0,0,24,0V180H232v28a12,12,0,0,0,24,0V112A44.05,44.05,0,0,0,212,68ZM100,156H36V92h64Zm132,0H124V92h88a20,20,0,0,1,20,20Z"></path>',
  'check': '<path d="M232.49,80.49l-128,128a12,12,0,0,1-17,0l-56-56a12,12,0,1,1,17-17L96,183,215.51,63.51a12,12,0,0,1,17,17Z"></path>',
  'chevron-down': '<path d="M216.49,104.49l-80,80a12,12,0,0,1-17,0l-80-80a12,12,0,0,1,17-17L128,159l71.51-71.52a12,12,0,0,1,17,17Z"></path>',
  'chevron-left': '<path d="M168.49,199.51a12,12,0,0,1-17,17l-80-80a12,12,0,0,1,0-17l80-80a12,12,0,0,1,17,17L97,128Z"></path>',
  'chevron-right': '<path d="M184.49,136.49l-80,80a12,12,0,0,1-17-17L159,128,87.51,56.49a12,12,0,1,1,17-17l80,80A12,12,0,0,1,184.49,136.49Z"></path>',
  'circle-dot': '<path d="M128,20A108,108,0,1,0,236,128,108.12,108.12,0,0,0,128,20Zm0,192a84,84,0,1,1,84-84A84.09,84.09,0,0,1,128,212Z"></path>',
  'clock': '<path d="M128,20A108,108,0,1,0,236,128,108.12,108.12,0,0,0,128,20Zm0,192a84,84,0,1,1,84-84A84.09,84.09,0,0,1,128,212Zm68-84a12,12,0,0,1-12,12H128a12,12,0,0,1-12-12V72a12,12,0,0,1,24,0v44h44A12,12,0,0,1,196,128Z"></path>',
  'coffee': '<path d="M212,76H32A12,12,0,0,0,20,88v48a100.24,100.24,0,0,0,26.73,68H32a12,12,0,0,0,0,24H208a12,12,0,0,0,0-24H193.27a100.75,100.75,0,0,0,20-32A44,44,0,0,0,256,128v-8A44.05,44.05,0,0,0,212,76Zm-16,60a76.27,76.27,0,0,1-42,68H86a76.27,76.27,0,0,1-42-68V100H196Zm36-8a20,20,0,0,1-12.57,18.55A97.17,97.17,0,0,0,220,136V101.68A20,20,0,0,1,232,120ZM68,48V24a12,12,0,0,1,24,0V48a12,12,0,0,1-24,0Zm40,0V24a12,12,0,0,1,24,0V48a12,12,0,0,1-24,0Zm40,0V24a12,12,0,0,1,24,0V48a12,12,0,0,1-24,0Z"></path>',
  'droplet': '<path d="M134.88,6.17a12,12,0,0,0-13.76,0,259,259,0,0,0-42.18,39C50.85,77.43,36,111.62,36,144a92,92,0,0,0,184,0C220,66.64,138.36,8.6,134.88,6.17ZM128,212a68.07,68.07,0,0,1-68-68c0-33.31,20-63.37,36.7-82.71A249.35,249.35,0,0,1,128,31.11a249.35,249.35,0,0,1,31.3,30.18C176,80.63,196,110.69,196,144A68.07,68.07,0,0,1,128,212Zm49.62-52.4a52,52,0,0,1-34,34,12.2,12.2,0,0,1-3.6.55,12,12,0,0,1-3.6-23.45,28,28,0,0,0,18.32-18.32,12,12,0,0,1,22.9,7.2Z"></path>',
  'ellipsis': '<path d="M144,128a16,16,0,1,1-16-16A16,16,0,0,1,144,128ZM60,112a16,16,0,1,0,16,16A16,16,0,0,0,60,112Zm136,0a16,16,0,1,0,16,16A16,16,0,0,0,196,112Z"></path>',
  'flame': '<path d="M177.62,159.6a52,52,0,0,1-34,34,12.2,12.2,0,0,1-3.6.55,12,12,0,0,1-3.6-23.45,28,28,0,0,0,18.32-18.32,12,12,0,0,1,22.9,7.2ZM220,144a92,92,0,0,1-184,0c0-28.81,11.27-58.18,33.48-87.28a12,12,0,0,1,17.9-1.33L107.07,74.5,127,19.89a12,12,0,0,1,18.94-5.12C168.2,33.25,220,82.85,220,144Zm-24,0c0-41.71-30.61-78.39-52.52-99.29l-20.21,55.4a12,12,0,0,1-19.63,4.5L80.71,82.36C67,103.38,60,124.06,60,144a68,68,0,0,0,136,0Z"></path>',
  'gauge': '<path d="M209.88,69.83A115.19,115.19,0,0,0,128,36h-.41C63.85,36.22,12,88.76,12,153.13V176a20,20,0,0,0,20,20H224a20,20,0,0,0,20-20V152A115.25,115.25,0,0,0,209.88,69.83ZM220,172H127.32l46.44-65A12,12,0,1,0,154.24,93L97.82,172H36V153.13c0-1.72,0-3.43.14-5.13H56a12,12,0,0,0,0-24H40.62c10.91-33.39,40-58.52,75.38-63.21V80a12,12,0,0,0,24,0V60.8A92,92,0,0,1,215.66,124H200a12,12,0,0,0,0,24h19.9c.06,1.33.1,2.66.1,4Z"></path>',
  'house': '<path d="M222.14,105.85l-80-80a20,20,0,0,0-28.28,0l-80,80A19.86,19.86,0,0,0,28,120v96a12,12,0,0,0,12,12h64a12,12,0,0,0,12-12V164h24v52a12,12,0,0,0,12,12h64a12,12,0,0,0,12-12V120A19.86,19.86,0,0,0,222.14,105.85ZM204,204H164V152a12,12,0,0,0-12-12H104a12,12,0,0,0-12,12v52H52V121.65l76-76,76,76Z"></path>',
  'house-plus': '<path d="M240,204H228V144a12,12,0,0,0,12.49-19.78L142.14,25.85a20,20,0,0,0-28.28,0L15.51,124.2A12,12,0,0,0,28,144v60H16a12,12,0,0,0,0,24H240a12,12,0,0,0,0-24ZM52,121.65l76-76,76,76V204H164V152a12,12,0,0,0-12-12H104a12,12,0,0,0-12,12v52H52ZM140,204H116V164h24Z"></path>',
  'lamp-ceiling': '<path d="M180,72.28V72a20,20,0,0,0-20-20H140V16a12,12,0,0,0-24,0V52H96A20,20,0,0,0,76,72v.28A115.7,115.7,0,0,0,12,176a12,12,0,0,0,12,12H84.19a44,44,0,0,0,87.62,0H232a12,12,0,0,0,12-12A115.7,115.7,0,0,0,180,72.28ZM128,204a20,20,0,0,1-19.6-16h39.2A20,20,0,0,1,128,204ZM36.78,164A91.75,91.75,0,0,1,92.62,91.05,12,12,0,0,0,100,80V76h56v4a12,12,0,0,0,7.38,11.08,91.75,91.75,0,0,1,55.84,73Z"></path>',
  'lamp-desk': '<path d="M251,147.27l-48-112A12,12,0,0,0,192,28H64a12,12,0,0,0-11,7.27l-48,112A12,12,0,0,0,16,164H116v40H96a12,12,0,0,0,0,24h64a12,12,0,0,0,0-24H140V164h48v28a12,12,0,0,0,24,0V164h28a12,12,0,0,0,11-16.73ZM34.2,140,71.91,52H184.09l37.71,88Z"></path>',
  'layout-grid': '<path d="M100,36H56A20,20,0,0,0,36,56v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V56A20,20,0,0,0,100,36ZM96,96H60V60H96ZM200,36H156a20,20,0,0,0-20,20v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V56A20,20,0,0,0,200,36Zm-4,60H160V60h36Zm-96,40H56a20,20,0,0,0-20,20v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V156A20,20,0,0,0,100,136Zm-4,60H60V160H96Zm104-60H156a20,20,0,0,0-20,20v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V156A20,20,0,0,0,200,136Zm-4,60H160V160h36Z"></path>',
  'lightbulb': '<path d="M180,232a12,12,0,0,1-12,12H88a12,12,0,0,1,0-24h80A12,12,0,0,1,180,232Zm40-128a92.47,92.47,0,0,1-37,73.73,7.81,7.81,0,0,0-3,6.27,20,20,0,0,1-20,20H96a20,20,0,0,1-20-20v-.23a7.76,7.76,0,0,0-3.25-6.2,91.36,91.36,0,0,1-36.75-73C35.73,54.69,76,13.2,125.79,12A92,92,0,0,1,220,104Zm-24,0a68,68,0,0,0-69.65-68C89.56,36.89,59.8,67.56,60,104.39a67.52,67.52,0,0,0,27.18,54h0A32.14,32.14,0,0,1,99.77,180H116V149L87.51,120.49a12,12,0,0,1,17-17L128,127l23.51-23.51a12,12,0,0,1,17,17L140,149v31h16.25a31.89,31.89,0,0,1,12.41-21.49A67.45,67.45,0,0,0,196,104Z"></path>',
  'minus': '<path d="M228,128a12,12,0,0,1-12,12H40a12,12,0,0,1,0-24H216A12,12,0,0,1,228,128Z"></path>',
  'monitor': '<path d="M208,36H48A28,28,0,0,0,20,64V176a28,28,0,0,0,28,28H208a28,28,0,0,0,28-28V64A28,28,0,0,0,208,36Zm4,140a4,4,0,0,1-4,4H48a4,4,0,0,1-4-4V64a4,4,0,0,1,4-4H208a4,4,0,0,1,4,4Zm-40,52a12,12,0,0,1-12,12H96a12,12,0,0,1,0-24h64A12,12,0,0,1,172,228Z"></path>',
  'moon': '<path d="M236.37,139.4a12,12,0,0,0-12-3A84.07,84.07,0,0,1,119.6,31.59a12,12,0,0,0-15-15A108.86,108.86,0,0,0,49.69,55.07,108,108,0,0,0,136,228a107.09,107.09,0,0,0,64.93-21.69,108.86,108.86,0,0,0,38.44-54.94A12,12,0,0,0,236.37,139.4Zm-49.88,47.74A84,84,0,0,1,68.86,69.51,84.93,84.93,0,0,1,92.27,48.29Q92,52.13,92,56A108.12,108.12,0,0,0,200,164q3.87,0,7.71-.27A84.79,84.79,0,0,1,186.49,187.14Z"></path>',
  'palette': '<path d="M203.57,51A107.9,107.9,0,0,0,20,128c0,44.72,27.6,82.25,72,97.94A36,36,0,0,0,140,192a12,12,0,0,1,12-12h46.21a35.79,35.79,0,0,0,35.1-28A108.6,108.6,0,0,0,236,127.09,107.23,107.23,0,0,0,203.57,51Zm6.34,95.67a11.91,11.91,0,0,1-11.7,9.3H152a36,36,0,0,0-36,36,12,12,0,0,1-16,11.3c-16.65-5.88-30.65-15.76-40.48-28.56A76,76,0,0,1,44,128a84,84,0,0,1,83.13-84H128a84.35,84.35,0,0,1,84,83.29A84.72,84.72,0,0,1,209.91,146.71ZM144,76a16,16,0,1,1-16-16A16,16,0,0,1,144,76Zm-44,24A16,16,0,1,1,84,84,16,16,0,0,1,100,100Zm0,56a16,16,0,1,1-16-16A16,16,0,0,1,100,156Zm88-56a16,16,0,1,1-16-16A16,16,0,0,1,188,100Z"></path>',
  'pause': '<path d="M200,28H160a20,20,0,0,0-20,20V208a20,20,0,0,0,20,20h40a20,20,0,0,0,20-20V48A20,20,0,0,0,200,28Zm-4,176H164V52h32ZM96,28H56A20,20,0,0,0,36,48V208a20,20,0,0,0,20,20H96a20,20,0,0,0,20-20V48A20,20,0,0,0,96,28ZM92,204H60V52H92Z"></path>',
  'pencil': '<path d="M230.14,70.54,185.46,25.85a20,20,0,0,0-28.29,0L33.86,149.17A19.85,19.85,0,0,0,28,163.31V208a20,20,0,0,0,20,20H92.69a19.86,19.86,0,0,0,14.14-5.86L230.14,98.82a20,20,0,0,0,0-28.28ZM91,204H52V165l84-84,39,39ZM192,103,153,64l18.34-18.34,39,39Z"></path>',
  'play': '<path d="M234.49,111.07,90.41,22.94A20,20,0,0,0,60,39.87V216.13a20,20,0,0,0,30.41,16.93l144.08-88.13a19.82,19.82,0,0,0,0-33.86ZM84,208.85V47.15L216.16,128Z"></path>',
  'plus': '<path d="M228,128a12,12,0,0,1-12,12H140v76a12,12,0,0,1-24,0V140H40a12,12,0,0,1,0-24h76V40a12,12,0,0,1,24,0v76h76A12,12,0,0,1,228,128Z"></path>',
  'power': '<path d="M116,128V48a12,12,0,0,1,24,0v80a12,12,0,0,1-24,0Zm66.55-82a12,12,0,0,0-13.1,20.1C191.41,80.37,204,103,204,128a76,76,0,0,1-152,0c0-25,12.59-47.63,34.55-61.95A12,12,0,0,0,73.45,46C44.56,64.78,28,94.69,28,128a100,100,0,0,0,200,0C228,94.69,211.44,64.78,182.55,46Z"></path>',
  'radio': '<path d="M128,84a44,44,0,1,0,44,44A44.05,44.05,0,0,0,128,84Zm0,64a20,20,0,1,1,20-20A20,20,0,0,1,128,148Zm77.39,12.7A83.94,83.94,0,0,1,190.61,184a12,12,0,0,1-17.89-16,59.92,59.92,0,0,0,0-80,12,12,0,0,1,17.89-16,84.07,84.07,0,0,1,14.78,88.7ZM83.28,168a12,12,0,0,1-17.89,16,83.94,83.94,0,0,1,0-112A12,12,0,0,1,83.28,88a59.92,59.92,0,0,0,0,80ZM252,128a123.63,123.63,0,0,1-35.43,86.78A12,12,0,1,1,199.43,198a99.88,99.88,0,0,0,0-140,12,12,0,0,1,17.14-16.8A123.63,123.63,0,0,1,252,128ZM56.57,198a12,12,0,0,1-17.14,16.8,123.89,123.89,0,0,1,0-173.56A12,12,0,0,1,56.57,58a99.88,99.88,0,0,0,0,140Z"></path>',
  'refresh-cw': '<path d="M228,48V96a12,12,0,0,1-12,12H168a12,12,0,0,1,0-24h19l-7.8-7.8a75.55,75.55,0,0,0-53.32-22.26h-.43A75.49,75.49,0,0,0,72.39,75.57,12,12,0,1,1,55.61,58.41a99.38,99.38,0,0,1,69.87-28.47H126A99.42,99.42,0,0,1,196.2,59.23L204,67V48a12,12,0,0,1,24,0ZM183.61,180.43a75.49,75.49,0,0,1-53.09,21.63h-.43A75.55,75.55,0,0,1,76.77,179.8L69,172H88a12,12,0,0,0,0-24H40a12,12,0,0,0-12,12v48a12,12,0,0,0,24,0V189l7.8,7.8A99.42,99.42,0,0,0,130,226.06h.56a99.38,99.38,0,0,0,69.87-28.47,12,12,0,0,0-16.78-17.16Z"></path>',
  'search': '<path d="M232.49,215.51,185,168a92.12,92.12,0,1,0-17,17l47.53,47.54a12,12,0,0,0,17-17ZM44,112a68,68,0,1,1,68,68A68.07,68.07,0,0,1,44,112Z"></path>',
  'settings': '<path d="M128,76a52,52,0,1,0,52,52A52.06,52.06,0,0,0,128,76Zm0,80a28,28,0,1,1,28-28A28,28,0,0,1,128,156Zm92-27.21v-1.58l14-17.51a12,12,0,0,0,2.23-10.59A111.75,111.75,0,0,0,225,71.89,12,12,0,0,0,215.89,66L193.61,63.5l-1.11-1.11L190,40.1A12,12,0,0,0,184.11,31a111.67,111.67,0,0,0-27.23-11.27A12,12,0,0,0,146.3,22L128.79,36h-1.58L109.7,22a12,12,0,0,0-10.59-2.23A111.75,111.75,0,0,0,71.89,31.05,12,12,0,0,0,66,40.11L63.5,62.39,62.39,63.5,40.1,66A12,12,0,0,0,31,71.89,111.67,111.67,0,0,0,19.77,99.12,12,12,0,0,0,22,109.7l14,17.51v1.58L22,146.3a12,12,0,0,0-2.23,10.59,111.75,111.75,0,0,0,11.29,27.22A12,12,0,0,0,40.11,190l22.28,2.48,1.11,1.11L66,215.9A12,12,0,0,0,71.89,225a111.67,111.67,0,0,0,27.23,11.27A12,12,0,0,0,109.7,234l17.51-14h1.58l17.51,14a12,12,0,0,0,10.59,2.23A111.75,111.75,0,0,0,184.11,225a12,12,0,0,0,5.91-9.06l2.48-22.28,1.11-1.11L215.9,190a12,12,0,0,0,9.06-5.91,111.67,111.67,0,0,0,11.27-27.23A12,12,0,0,0,234,146.3Zm-24.12-4.89a70.1,70.1,0,0,1,0,8.2,12,12,0,0,0,2.61,8.22l12.84,16.05A86.47,86.47,0,0,1,207,166.86l-20.43,2.27a12,12,0,0,0-7.65,4,69,69,0,0,1-5.8,5.8,12,12,0,0,0-4,7.65L166.86,207a86.47,86.47,0,0,1-10.49,4.35l-16.05-12.85a12,12,0,0,0-7.5-2.62c-.24,0-.48,0-.72,0a70.1,70.1,0,0,1-8.2,0,12.06,12.06,0,0,0-8.22,2.6L99.63,211.33A86.47,86.47,0,0,1,89.14,207l-2.27-20.43a12,12,0,0,0-4-7.65,69,69,0,0,1-5.8-5.8,12,12,0,0,0-7.65-4L49,166.86a86.47,86.47,0,0,1-4.35-10.49l12.84-16.05a12,12,0,0,0,2.61-8.22,70.1,70.1,0,0,1,0-8.2,12,12,0,0,0-2.61-8.22L44.67,99.63A86.47,86.47,0,0,1,49,89.14l20.43-2.27a12,12,0,0,0,7.65-4,69,69,0,0,1,5.8-5.8,12,12,0,0,0,4-7.65L89.14,49a86.47,86.47,0,0,1,10.49-4.35l16.05,12.85a12.06,12.06,0,0,0,8.22,2.6,70.1,70.1,0,0,1,8.2,0,12,12,0,0,0,8.22-2.6l16.05-12.85A86.47,86.47,0,0,1,166.86,49l2.27,20.43a12,12,0,0,0,4,7.65,69,69,0,0,1,5.8,5.8,12,12,0,0,0,7.65,4L207,89.14a86.47,86.47,0,0,1,4.35,10.49l-12.84,16.05A12,12,0,0,0,195.88,123.9Z"></path>',
  'sliders-horizontal': '<path d="M40,92H70.06a36,36,0,0,0,67.88,0H216a12,12,0,0,0,0-24H137.94a36,36,0,0,0-67.88,0H40a12,12,0,0,0,0,24Zm64-24A12,12,0,1,1,92,80,12,12,0,0,1,104,68Zm112,96H201.94a36,36,0,0,0-67.88,0H40a12,12,0,0,0,0,24h94.06a36,36,0,0,0,67.88,0H216a12,12,0,0,0,0-24Zm-48,24a12,12,0,1,1,12-12A12,12,0,0,1,168,188Z"></path>',
  'smartphone': '<path d="M176,12H80A28,28,0,0,0,52,40V216a28,28,0,0,0,28,28h96a28,28,0,0,0,28-28V40A28,28,0,0,0,176,12ZM76,76H180V180H76Zm4-40h96a4,4,0,0,1,4,4V52H76V40A4,4,0,0,1,80,36Zm96,184H80a4,4,0,0,1-4-4V204H180v12A4,4,0,0,1,176,220Z"></path>',
  'sofa': '<path d="M244,104V72a20,20,0,0,0-20-20H32A20,20,0,0,0,12,72v32a20,20,0,0,0-8,16v48a20,20,0,0,0,20,20h4v12a12,12,0,0,0,24,0V188H204v12a12,12,0,0,0,24,0V188h4a20,20,0,0,0,20-20V120A20,20,0,0,0,244,104Zm-24-4H208a20,20,0,0,0-20,20v4H140V76h80ZM116,76v48H68v-4a20,20,0,0,0-20-20H36V76Zm112,88H28V124H44v12a12,12,0,0,0,12,12H200a12,12,0,0,0,12-12V124h16Z"></path>',
  'sparkles': '<path d="M199,125.31l-49.88-18.39L130.69,57a19.92,19.92,0,0,0-37.38,0L74.92,106.92,25,125.31a19.92,19.92,0,0,0,0,37.38l49.88,18.39L93.31,231a19.92,19.92,0,0,0,37.38,0l18.39-49.88L199,162.69a19.92,19.92,0,0,0,0-37.38Zm-63.38,35.16a12,12,0,0,0-7.11,7.11L112,212.28l-16.47-44.7a12,12,0,0,0-7.11-7.11L43.72,144l44.7-16.47a12,12,0,0,0,7.11-7.11L112,75.72l16.47,44.7a12,12,0,0,0,7.11,7.11L180.28,144ZM140,40a12,12,0,0,1,12-12h12V16a12,12,0,0,1,24,0V28h12a12,12,0,0,1,0,24H188V64a12,12,0,0,1-24,0V52H152A12,12,0,0,1,140,40ZM252,88a12,12,0,0,1-12,12h-4v4a12,12,0,0,1-24,0v-4h-4a12,12,0,0,1,0-24h4V72a12,12,0,0,1,24,0v4h4A12,12,0,0,1,252,88Z"></path>',
  'sun': '<path d="M116,36V20a12,12,0,0,1,24,0V36a12,12,0,0,1-24,0Zm80,92a68,68,0,1,1-68-68A68.07,68.07,0,0,1,196,128Zm-24,0a44,44,0,1,0-44,44A44.05,44.05,0,0,0,172,128ZM51.51,68.49a12,12,0,1,0,17-17l-12-12a12,12,0,0,0-17,17Zm0,119-12,12a12,12,0,0,0,17,17l12-12a12,12,0,1,0-17-17ZM196,72a12,12,0,0,0,8.49-3.51l12-12a12,12,0,0,0-17-17l-12,12A12,12,0,0,0,196,72Zm8.49,115.51a12,12,0,0,0-17,17l12,12a12,12,0,0,0,17-17ZM48,128a12,12,0,0,0-12-12H20a12,12,0,0,0,0,24H36A12,12,0,0,0,48,128Zm80,80a12,12,0,0,0-12,12v16a12,12,0,0,0,24,0V220A12,12,0,0,0,128,208Zm108-92H220a12,12,0,0,0,0,24h16a12,12,0,0,0,0-24Z"></path>',
  'terminal': '<path d="M72.5,150.63,100.79,128,72.5,105.37a12,12,0,1,1,15-18.74l40,32a12,12,0,0,1,0,18.74l-40,32a12,12,0,0,1-15-18.74ZM144,172h32a12,12,0,0,0,0-24H144a12,12,0,0,0,0,24ZM236,56V200a20,20,0,0,1-20,20H40a20,20,0,0,1-20-20V56A20,20,0,0,1,40,36H216A20,20,0,0,1,236,56Zm-24,4H44V196H212Z"></path>',
  'thermometer': '<path d="M180,150.69V56A52,52,0,0,0,76,56v94.69a64,64,0,1,0,104,0ZM128,228a40,40,0,0,1-30.91-65.39,12,12,0,0,0,2.91-7.83V56a28,28,0,0,1,56,0v98.77a12,12,0,0,0,2.77,7.68A40,40,0,0,1,128,228Zm24-40a24,24,0,1,1-36-20.78V92a12,12,0,0,1,24,0v75.22A24,24,0,0,1,152,188Z"></path>',
  'trash': '<path d="M216,48H180V36A28,28,0,0,0,152,8H104A28,28,0,0,0,76,36V48H40a12,12,0,0,0,0,24h4V208a20,20,0,0,0,20,20H192a20,20,0,0,0,20-20V72h4a12,12,0,0,0,0-24ZM100,36a4,4,0,0,1,4-4h48a4,4,0,0,1,4,4V48H100Zm88,168H68V72H188ZM116,104v64a12,12,0,0,1-24,0V104a12,12,0,0,1,24,0Zm48,0v64a12,12,0,0,1-24,0V104a12,12,0,0,1,24,0Z"></path>',
  'trees': '<path d="M201.17,59.62a80,80,0,0,0-146.34,0,76,76,0,0,0,61.17,139V232a12,12,0,0,0,24,0V198.64A76.26,76.26,0,0,0,168,204l1.92,0A76,76,0,0,0,201.17,59.62ZM169.35,180A52,52,0,0,1,140,171.79V135.42l41.37-20.69a12,12,0,1,0-10.74-21.46L140,108.58V88a12,12,0,0,0-24,0v44.58L85.37,117.27a12,12,0,0,0-10.74,21.46L116,159.42v12.37A52.24,52.24,0,0,1,86.65,180c-27.53-.69-50.72-24.56-50.65-52.13a51.81,51.81,0,0,1,32.61-48.1,12,12,0,0,0,6.78-7,56,56,0,0,1,105.22,0,12,12,0,0,0,6.78,7A51.81,51.81,0,0,1,220,127.85C220.08,155.41,196.88,179.29,169.35,180Z"></path>',
  'tv': '<path d="M216,60H157l27.52-27.52a12,12,0,0,0-17-17L128,55,88.49,15.51a12,12,0,0,0-17,17L99,60H40A20,20,0,0,0,20,80V200a20,20,0,0,0,20,20H216a20,20,0,0,0,20-20V80A20,20,0,0,0,216,60Zm-4,136H44V84H212Z"></path>',
  'utensils-crossed': '<path d="M68,88V40a12,12,0,0,1,24,0V88a12,12,0,0,1-24,0ZM220,40V224a12,12,0,0,1-24,0V180H152a12,12,0,0,1-12-12,273.23,273.23,0,0,1,7.33-57.82C157.42,68.42,176.76,40.33,203.27,29A12,12,0,0,1,220,40ZM196,62.92C182.6,77,175,98,170.77,115.38A254.41,254.41,0,0,0,164.55,156H196ZM128,39A12,12,0,0,0,104,41l4,47.46a28,28,0,0,1-56,0L56,41A12,12,0,1,0,32,39L28,87c0,.34,0,.67,0,1a52.1,52.1,0,0,0,40,50.59V224a12,12,0,0,0,24,0V138.59A52.1,52.1,0,0,0,132,88c0-.33,0-.66,0-1Z"></path>',
  'waves-horizontal': '<path d="M225.24,174.74a12,12,0,0,1-1.58,16.89C205.49,206.71,189.06,212,174.15,212c-19.76,0-36.86-9.29-51.88-17.44-25.06-13.62-44.86-24.37-74.61.3a12,12,0,1,1-15.32-18.48c42.25-35,75-17.23,101.39-2.92,25.06,13.61,44.86,24.37,74.61-.3A12,12,0,0,1,225.24,174.74Zm-16.9-57.59c-29.75,24.67-49.55,13.91-74.61.3-26.35-14.3-59.14-32.11-101.39,2.92a12,12,0,0,0,15.32,18.48c29.75-24.67,49.55-13.92,74.61-.3,15,8.15,32.12,17.44,51.88,17.44,14.91,0,31.34-5.29,49.51-20.36a12,12,0,0,0-15.32-18.48ZM47.66,82.84c29.75-24.67,49.55-13.92,74.61-.3,15,8.15,32.12,17.44,51.88,17.44,14.91,0,31.34-5.29,49.51-20.36a12,12,0,0,0-15.32-18.48c-29.75,24.67-49.55,13.92-74.61.3-26.35-14.3-59.14-32.11-101.39,2.93A12,12,0,1,0,47.66,82.84Z"></path>',
  'wifi': '<path d="M144,204a16,16,0,1,1-16-16A16,16,0,0,1,144,204ZM239.61,83.91a176,176,0,0,0-223.22,0,12,12,0,1,0,15.23,18.55,152,152,0,0,1,192.76,0,12,12,0,1,0,15.23-18.55Zm-32.16,35.73a128,128,0,0,0-158.9,0,12,12,0,0,0,14.9,18.81,104,104,0,0,1,129.1,0,12,12,0,0,0,14.9-18.81ZM175.07,155.3a80.05,80.05,0,0,0-94.14,0,12,12,0,0,0,14.14,19.4,56,56,0,0,1,65.86,0,12,12,0,1,0,14.14-19.4Z"></path>',
  'x': '<path d="M208.49,191.51a12,12,0,0,1-17,17L128,145,64.49,208.49a12,12,0,0,1-17-17L111,128,47.51,64.49a12,12,0,0,1,17-17L128,111l63.51-63.52a12,12,0,0,1,17,17L145,128Z"></path>',
  'zap': '<path d="M219.71,117.38a12,12,0,0,0-7.25-8.52L161.28,88.39l10.59-70.61a12,12,0,0,0-20.64-10l-112,120a12,12,0,0,0,4.31,19.33l51.18,20.47L84.13,238.22a12,12,0,0,0,20.64,10l112-120A12,12,0,0,0,219.71,117.38ZM113.6,203.55l6.27-41.77a12,12,0,0,0-7.41-12.92L68.74,131.37,142.4,52.45l-6.27,41.77a12,12,0,0,0,7.41,12.92l43.72,17.49Z"></path>'
};
const iconNames = Object.keys(ICONS);
function Icon({
  name,
  size = 20,
  style,
  ...rest
}) {
  const body = ICONS[name];
  if (!body) return null;
  return /*#__PURE__*/React.createElement("svg", _extends({
    viewBox: "0 0 256 256",
    width: size,
    height: size,
    fill: "currentColor",
    "aria-hidden": "true",
    style: {
      display: 'block',
      flex: 'none',
      ...style
    },
    dangerouslySetInnerHTML: {
      __html: body
    }
  }, rest));
}
Object.assign(__ds_scope, { iconNames, Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/Panel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Chassis surface. `raised` for cards that sit on the app, `inset` for wells that hold controls. */
function Panel({
  children,
  variant = 'raised',
  radius = 'var(--radius-4)',
  padding = 'var(--panel-pad)',
  grain = true,
  glow,
  style,
  ...rest
}) {
  const shadow = variant === 'inset' ? 'var(--elev-well)' : variant === 'flat' ? 'var(--elev-flat)' : 'var(--elev-panel)';
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      background: variant === 'inset' ? 'linear-gradient(180deg,var(--char-900),var(--char-950))' : 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      backgroundImage: grain ? `var(--grain), linear-gradient(180deg,${variant === 'inset' ? 'var(--char-900),var(--char-950)' : 'var(--surface-raised),var(--surface-panel)'})` : undefined,
      backgroundSize: grain ? 'var(--grain-size), auto' : undefined,
      borderRadius: radius,
      padding,
      color: 'var(--text-primary)',
      boxShadow: glow ? `${shadow},var(--glow-amber)` : shadow,
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Panel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Panel.jsx", error: String((e && e.message) || e) }); }

// components/core/feedback.jsx
try { (() => {
/**
 * Tactile feedback: short synthesized clicks (WebAudio, no audio files) plus device haptics.
 * Every control in this system calls this on press, so the app feels like hardware.
 *
 * Sound is generated, not sampled: a filtered noise transient for the contact, and a short
 * low sine for the body of the click. Nothing is longer than 70ms.
 */

const STORE_KEY = 'wizctl.feedback';
let ctx = null;
let enabled = true;
try {
  const saved = typeof localStorage !== 'undefined' ? localStorage.getItem(STORE_KEY) : null;
  if (saved !== null) enabled = saved === 'on';
} catch (e) {/* private mode */}
function audio() {
  if (typeof window === 'undefined') return null;
  const AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return null;
  if (!ctx) ctx = new AC();
  if (ctx.state === 'suspended') ctx.resume();
  return ctx;
}
function noise(ac, out, {
  dur = 0.014,
  cut = 2600,
  gain = 0.05,
  at = 0
}) {
  const n = Math.max(1, Math.floor(ac.sampleRate * dur));
  const buf = ac.createBuffer(1, n, ac.sampleRate);
  const d = buf.getChannelData(0);
  for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n);
  const src = ac.createBufferSource();
  src.buffer = buf;
  const lp = ac.createBiquadFilter();
  lp.type = 'lowpass';
  lp.frequency.value = cut;
  const g = ac.createGain();
  g.gain.value = gain;
  src.connect(lp).connect(g).connect(out);
  src.start(ac.currentTime + at);
}
function tone(ac, out, {
  f = 220,
  f2,
  dur = 0.05,
  gain = 0.06,
  at = 0,
  type = 'sine'
}) {
  const t = ac.currentTime + at;
  const osc = ac.createOscillator();
  osc.type = type;
  osc.frequency.setValueAtTime(f, t);
  if (f2) osc.frequency.exponentialRampToValueAtTime(f2, t + dur);
  const g = ac.createGain();
  g.gain.setValueAtTime(0.0001, t);
  g.gain.exponentialRampToValueAtTime(gain, t + 0.004);
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  osc.connect(g).connect(out);
  osc.start(t);
  osc.stop(t + dur + 0.02);
}

/** kind -> [sound recipe, haptic pattern] */
const KINDS = {
  /** any labelled or icon key going down */
  press: {
    haptic: 10,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.012,
        cut: 2400,
        gain: 0.05
      });
      tone(ac, out, {
        f: 200,
        f2: 120,
        dur: 0.045,
        gain: 0.05
      });
    }
  },
  /** a key coming back up — quieter, brighter */
  release: {
    haptic: 0,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.008,
        cut: 4200,
        gain: 0.022
      });
    }
  },
  /** switch closing: contact plus a rising body */
  toggleOn: {
    haptic: 14,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.01,
        cut: 3200,
        gain: 0.05
      });
      tone(ac, out, {
        f: 320,
        f2: 560,
        dur: 0.055,
        gain: 0.05
      });
    }
  },
  /** switch opening: same contact, falling body */
  toggleOff: {
    haptic: 10,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.01,
        cut: 2600,
        gain: 0.045
      });
      tone(ac, out, {
        f: 300,
        f2: 170,
        dur: 0.055,
        gain: 0.045
      });
    }
  },
  /** moving between tabs / segments */
  tick: {
    haptic: 8,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.009,
        cut: 3600,
        gain: 0.035
      });
      tone(ac, out, {
        f: 520,
        dur: 0.03,
        gain: 0.03,
        type: 'triangle'
      });
    }
  },
  /** a dial or rail crossing a notch — the smallest sound in the system */
  detent: {
    haptic: 4,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.006,
        cut: 5200,
        gain: 0.02
      });
    }
  },
  /** power key engaging a light */
  power: {
    haptic: 18,
    play: (ac, out) => {
      noise(ac, out, {
        dur: 0.014,
        cut: 2200,
        gain: 0.055
      });
      tone(ac, out, {
        f: 150,
        f2: 90,
        dur: 0.09,
        gain: 0.06
      });
    }
  },
  /** save / apply succeeded */
  confirm: {
    haptic: [8, 26, 12],
    play: (ac, out) => {
      tone(ac, out, {
        f: 660,
        dur: 0.05,
        gain: 0.04,
        type: 'triangle'
      });
      tone(ac, out, {
        f: 990,
        dur: 0.07,
        gain: 0.035,
        at: 0.055,
        type: 'triangle'
      });
    }
  },
  /** something failed or is unreachable */
  reject: {
    haptic: [12, 40, 12],
    play: (ac, out) => {
      tone(ac, out, {
        f: 210,
        f2: 140,
        dur: 0.12,
        gain: 0.05,
        type: 'sawtooth'
      });
    }
  }
};
const Feedback = {
  isEnabled: () => enabled,
  setEnabled(next) {
    enabled = !!next;
    try {
      localStorage.setItem(STORE_KEY, enabled ? 'on' : 'off');
    } catch (e) {/* ignore */}
    if (enabled) Feedback.play('tick');
  },
  kinds: Object.keys(KINDS),
  /** Fire sound + haptics for one of Feedback.kinds. Safe to call on every pointerdown. */
  play(kind = 'press') {
    if (!enabled) return;
    const k = KINDS[kind] || KINDS.press;
    if (k.haptic && typeof navigator !== 'undefined' && navigator.vibrate) {
      try {
        navigator.vibrate(k.haptic);
      } catch (e) {/* ignore */}
    }
    const ac = audio();
    if (!ac) return;
    try {
      const out = ac.createGain();
      out.gain.value = 0.9;
      out.connect(ac.destination);
      k.play(ac, out);
    } catch (e) {/* audio blocked until first gesture */}
  }
};

/** Convenience for handlers: onPointerDown={() => feedback('press')} */
function feedback(kind) {
  Feedback.play(kind);
}

/** Returns a stable play function; use inside components. */
function useFeedback() {
  return React.useCallback(kind => Feedback.play(kind), []);
}
Object.assign(__ds_scope, { Feedback, feedback, useFeedback });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/feedback.jsx", error: String((e && e.message) || e) }); }

// components/controls/ColorWheel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function hsvToRgb(h, s) {
  const f = n => {
    const k = (n + h / 60) % 6;
    return Math.round(255 * (1 - s * Math.max(0, Math.min(k, 4 - k, 1))));
  };
  return [f(5), f(3), f(1)];
}

/** HSV colour wheel with a raised puck. Drag inside the disc; reports { h, s, rgb }. */
function ColorWheel({
  hue = 30,
  saturation = 1,
  onChange,
  size = 240,
  disabled,
  style,
  ...rest
}) {
  const disc = React.useRef(null);
  const dragging = React.useRef(false);
  const notch = React.useRef(null);
  const r = size / 2;
  const rad = (hue - 90) * Math.PI / 180;
  const px = r + Math.cos(rad) * saturation * (r - 18);
  const py = r + Math.sin(rad) * saturation * (r - 18);
  const [cr, cg, cb] = hsvToRgb(hue, saturation);
  const fromEvent = e => {
    const b = disc.current.getBoundingClientRect();
    const x = e.clientX - b.left - r,
      y = e.clientY - b.top - r;
    const dist = Math.min(1, Math.hypot(x, y) / (r - 18));
    let h = Math.atan2(y, x) * 180 / Math.PI + 90;
    if (h < 0) h += 360;
    const n = Math.round(h / 15);
    if (n !== notch.current) {
      if (notch.current !== null) __ds_scope.Feedback.play('detent');
      notch.current = n;
    }
    if (onChange) onChange({
      h: Math.round(h),
      s: +dist.toFixed(3),
      rgb: hsvToRgb(h, dist)
    });
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    ref: disc,
    role: "application",
    "aria-label": "Colour wheel",
    onPointerDown: e => {
      if (disabled) return;
      dragging.current = true;
      notch.current = null;
      e.currentTarget.setPointerCapture(e.pointerId);
      __ds_scope.Feedback.play('press');
      fromEvent(e);
    },
    onPointerMove: e => {
      if (dragging.current) fromEvent(e);
    },
    onPointerUp: () => {
      dragging.current = false;
    },
    style: {
      position: 'relative',
      width: size,
      height: size,
      borderRadius: '50%',
      background: 'conic-gradient(from -90deg,#FF4A3D,#FFD52B,#38D06B,#25D8C0,#2ECBFF,#5B5BFF,#A45BFF,#FF3FC0,#FF4A3D)',
      boxShadow: 'inset 0 0 0 8px var(--char-900),var(--elev-knob)',
      touchAction: 'none',
      cursor: disabled ? 'not-allowed' : 'crosshair',
      opacity: disabled ? 0.4 : 1,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 8,
      borderRadius: '50%',
      background: 'radial-gradient(circle,rgba(255,255,255,.95) 0%,rgba(255,255,255,0) 62%)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 8,
      borderRadius: '50%',
      boxShadow: 'inset 0 2px 10px rgba(0,0,0,.45)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      left: px,
      top: py,
      width: 34,
      height: 34,
      marginLeft: -17,
      marginTop: -17,
      borderRadius: '50%',
      background: `rgb(${cr},${cg},${cb})`,
      boxShadow: '0 0 0 4px rgba(250,248,244,.92),0 4px 10px rgba(0,0,0,.6),0 0 26px -2px rgba(' + cr + ',' + cg + ',' + cb + ',.8)',
      pointerEvents: 'none',
      transition: dragging.current ? 'none' : 'left var(--dur-release) var(--ease-tactile),top var(--dur-release) var(--ease-tactile)'
    }
  }));
}
Object.assign(__ds_scope, { ColorWheel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/ColorWheel.jsx", error: String((e && e.message) || e) }); }

// components/controls/Dial.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Rotary knob. Drag vertically (or use arrow keys) to change the value.
 * Machined bezel, knurled rim, engraved index mark, amber sweep arc showing position.
 */
function Dial({
  value = 50,
  min = 0,
  max = 100,
  step = 1,
  onChange,
  size = 168,
  label,
  unit = '%',
  disabled,
  style,
  ...rest
}) {
  const drag = React.useRef(null);
  const notch = React.useRef(null);
  const [down, setDown] = React.useState(false);
  const pct = Math.min(1, Math.max(0, (value - min) / (max - min)));
  const sweep = 280;
  const angle = -140 + pct * sweep;
  const commit = v => {
    const next = Math.round(Math.min(max, Math.max(min, v)) / step) * step;
    const n = Math.round((next - min) / (max - min) * 40);
    if (n !== notch.current) {
      if (notch.current !== null) __ds_scope.Feedback.play('detent');
      notch.current = n;
    }
    if (onChange) onChange(next);
  };
  const onDown = e => {
    if (disabled) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    drag.current = {
      y: e.clientY,
      v: value
    };
    notch.current = Math.round(pct * 40);
    setDown(true);
    __ds_scope.Feedback.play('press');
  };
  const onMove = e => {
    if (!drag.current) return;
    commit(drag.current.v + (drag.current.y - e.clientY) / 160 * (max - min));
  };
  const onUp = () => {
    drag.current = null;
    setDown(false);
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'inline-flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 10,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    role: "slider",
    tabIndex: disabled ? -1 : 0,
    "aria-valuenow": value,
    "aria-valuemin": min,
    "aria-valuemax": max,
    "aria-label": label,
    onPointerDown: onDown,
    onPointerMove: onMove,
    onPointerUp: onUp,
    onPointerCancel: onUp,
    onKeyDown: e => {
      if (e.key === 'ArrowUp' || e.key === 'ArrowRight') commit(value + step * 5);
      if (e.key === 'ArrowDown' || e.key === 'ArrowLeft') commit(value - step * 5);
    },
    style: {
      position: 'relative',
      width: size,
      height: size,
      borderRadius: '50%',
      background: 'conic-gradient(from -140deg,var(--amber-600) 0deg,var(--amber-400) ' + pct * sweep * 0.65 + 'deg,var(--amber-500) ' + pct * sweep + 'deg,var(--char-1000) ' + pct * sweep + 'deg,var(--char-1000) ' + sweep + 'deg,transparent ' + sweep + 'deg)',
      boxShadow: 'var(--elev-well)',
      filter: pct > 0 ? 'drop-shadow(0 0 12px rgba(255,176,32,.28))' : 'none',
      touchAction: 'none',
      cursor: disabled ? 'not-allowed' : 'ns-resize',
      opacity: disabled ? 0.45 : 1,
      transform: down ? 'scale(.985)' : 'scale(1)',
      transition: 'transform var(--dur-release) var(--ease-settle),filter var(--dur-ui) var(--ease-tactile)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: size * 0.085,
      borderRadius: '50%',
      backgroundColor: 'var(--char-850)',
      backgroundImage: 'var(--knurl),radial-gradient(circle at 32% 22%,rgba(255,255,255,.14),rgba(255,255,255,0) 58%),linear-gradient(180deg,var(--surface-key),var(--char-950))',
      backgroundBlendMode: 'soft-light,screen,normal',
      boxShadow: 'var(--elev-knob)',
      transform: 'rotate(' + angle + 'deg)',
      transition: drag.current ? 'none' : 'transform var(--dur-release) var(--ease-settle)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      left: '50%',
      top: size * 0.05,
      width: 3,
      height: size * 0.125,
      marginLeft: -1.5,
      borderRadius: 2,
      background: 'var(--amber-300)',
      boxShadow: '0 0 10px rgba(255,194,77,.9)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: size * 0.235,
      borderRadius: '50%',
      display: 'grid',
      placeItems: 'center',
      backgroundColor: 'var(--char-900)',
      backgroundImage: 'repeating-radial-gradient(circle at 50% 50%,rgba(255,255,255,.035) 0 1px,rgba(0,0,0,.14) 1px 3px),radial-gradient(circle at 50% 12%,rgba(255,255,255,.10),rgba(255,255,255,0) 55%),linear-gradient(180deg,var(--char-850),var(--char-1000))',
      boxShadow: 'var(--elev-well-deep)',
      color: 'var(--text-primary)',
      pointerEvents: 'none'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: size * 0.24,
      fontWeight: 800,
      lineHeight: 1,
      letterSpacing: '.01em',
      fontVariantNumeric: 'tabular-nums'
    }
  }, Math.round(value), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: size * 0.11,
      color: 'var(--text-tertiary)'
    }
  }, unit)))), label && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, label));
}
Object.assign(__ds_scope, { Dial });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/Dial.jsx", error: String((e && e.message) || e) }); }

// components/controls/PowerKey.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const POWERKEY_D = {
  md: 96,
  lg: 132
};

/** Hero power control on a light or room detail screen. Off = dead charcoal, on = tungsten glow. */
function PowerKey({
  on,
  onChange,
  size = 'lg',
  disabled,
  label = 'Power',
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  const d = POWERKEY_D[size] || POWERKEY_D.lg;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": !!on,
    "aria-label": label,
    disabled: disabled,
    onClick: () => {
      __ds_scope.Feedback.play(on ? 'toggleOff' : 'power');
      if (onChange) onChange(!on);
    },
    onPointerDown: () => setDown(true),
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      position: 'relative',
      width: d,
      height: d,
      flex: 'none',
      border: 0,
      borderRadius: '50%',
      display: 'grid',
      placeItems: 'center',
      cursor: disabled ? 'not-allowed' : 'pointer',
      background: on ? 'radial-gradient(circle at 50% 32%,var(--amber-300),var(--amber-500) 58%,var(--amber-700))' : 'linear-gradient(180deg,var(--surface-key),var(--char-900))',
      color: on ? 'var(--text-on-accent)' : 'var(--text-tertiary)',
      boxShadow: down ? 'var(--elev-pressed)' : on ? 'var(--elev-knob),var(--glow-amber-strong)' : 'var(--elev-knob)',
      transform: down ? 'translateY(2px) scale(var(--press-scale))' : 'none',
      opacity: disabled ? 0.4 : 1,
      transition: 'var(--transition-control),box-shadow var(--dur-light) var(--ease-tactile)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "power",
    size: Math.round(d * 0.34)
  }));
}
Object.assign(__ds_scope, { PowerKey });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/PowerKey.jsx", error: String((e && e.message) || e) }); }

// components/controls/SceneTile.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Gradient per built-in WiZ scene, keyed by the scene id from wizctl's `WizScene` enum.
 * Ids and display names are copied from lib/src/scene.dart; `dynamic` mirrors `isDynamic`
 * (dynamic scenes accept a speed value of 10-200).
 */
const SCENE_GRADIENTS = {
  1: {
    name: 'Ocean',
    dynamic: true,
    from: '#0B6FD8',
    to: '#25D8C0'
  },
  2: {
    name: 'Romance',
    dynamic: true,
    from: '#C2185B',
    to: '#FF8A2B'
  },
  3: {
    name: 'Sunset',
    dynamic: true,
    from: '#FF4A3D',
    to: '#FFD52B'
  },
  4: {
    name: 'Party',
    dynamic: true,
    from: '#A45BFF',
    to: '#FF3FC0'
  },
  5: {
    name: 'Fireplace',
    dynamic: true,
    from: '#8A1E05',
    to: '#FF8A2B'
  },
  6: {
    name: 'Cozy',
    dynamic: false,
    from: '#B4600F',
    to: '#FFC24D'
  },
  7: {
    name: 'Forest',
    dynamic: true,
    from: '#0E5B2A',
    to: '#B7F03C'
  },
  8: {
    name: 'Pastel Colors',
    dynamic: true,
    from: '#FFB6C1',
    to: '#B8E1FF'
  },
  9: {
    name: 'Wake Up',
    dynamic: true,
    from: '#3A2A5C',
    to: '#FFD98A'
  },
  10: {
    name: 'Bedtime',
    dynamic: true,
    from: '#241634',
    to: '#FF8A2B'
  },
  11: {
    name: 'Warm White',
    dynamic: false,
    from: '#B4772A',
    to: '#FFE0BC'
  },
  12: {
    name: 'Daylight',
    dynamic: false,
    from: '#C9D8F0',
    to: '#FFF4E6'
  },
  13: {
    name: 'Cool White',
    dynamic: false,
    from: '#7FA8D9',
    to: '#DCE9FF'
  },
  14: {
    name: 'Night Light',
    dynamic: false,
    from: '#2A1E10',
    to: '#8A5A1E'
  },
  15: {
    name: 'Focus',
    dynamic: false,
    from: '#9FC6FF',
    to: '#FFFFFF'
  },
  16: {
    name: 'Relax',
    dynamic: false,
    from: '#1E5B3A',
    to: '#9FE6B8'
  },
  17: {
    name: 'True Colors',
    dynamic: false,
    from: '#FF4A3D',
    to: '#2E7BFF'
  },
  18: {
    name: 'TV Time',
    dynamic: false,
    from: '#122A4A',
    to: '#2ECBFF'
  },
  19: {
    name: 'Plant Growth',
    dynamic: false,
    from: '#5B1E8A',
    to: '#38D06B'
  },
  20: {
    name: 'Spring',
    dynamic: true,
    from: '#7CFF9E',
    to: '#FFD52B'
  },
  21: {
    name: 'Summer',
    dynamic: true,
    from: '#FF8A2B',
    to: '#FFD52B'
  },
  22: {
    name: 'Fall',
    dynamic: true,
    from: '#8A3A05',
    to: '#FFB25C'
  },
  23: {
    name: 'Deep Dive',
    dynamic: true,
    from: '#04234A',
    to: '#2ECBFF'
  },
  24: {
    name: 'Jungle',
    dynamic: true,
    from: '#04361E',
    to: '#B7F03C'
  },
  25: {
    name: 'Mojito',
    dynamic: true,
    from: '#0E6B3A',
    to: '#D6FF6E'
  },
  26: {
    name: 'Club',
    dynamic: true,
    from: '#5B5BFF',
    to: '#FF3FC0'
  },
  27: {
    name: 'Christmas',
    dynamic: true,
    from: '#C81E1E',
    to: '#38D06B'
  },
  28: {
    name: 'Halloween',
    dynamic: true,
    from: '#4A1E6B',
    to: '#FF8A2B'
  },
  29: {
    name: 'Candlelight',
    dynamic: true,
    from: '#7A3A05',
    to: '#FFC24D'
  },
  30: {
    name: 'Golden White',
    dynamic: false,
    from: '#C08A1E',
    to: '#FFF0C9'
  },
  31: {
    name: 'Pulse',
    dynamic: true,
    from: '#1B1B22',
    to: '#FF4A3D'
  },
  32: {
    name: 'Steampunk',
    dynamic: false,
    from: '#5C4326',
    to: '#D9A85C'
  },
  33: {
    name: 'Diwali',
    dynamic: true,
    from: '#8A0F5B',
    to: '#FFD52B'
  },
  34: {
    name: 'White',
    dynamic: false,
    from: '#E8ECF5',
    to: '#FFFFFF'
  },
  35: {
    name: 'Alarm',
    dynamic: true,
    from: '#8A0505',
    to: '#FF4A3D'
  },
  1000: {
    name: 'Rhythm',
    dynamic: true,
    from: '#2E7BFF',
    to: '#A45BFF'
  }
};

/** Scene chip. `sceneId` must be a wizctl WizScene id; the gradient and name come from that. */
function SceneTile({
  sceneId,
  selected,
  onClick,
  size = 'md',
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  const scene = SCENE_GRADIENTS[sceneId];
  if (!scene) return null;
  const dot = size === 'sm' ? 26 : 38;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-pressed": !!selected,
    onClick: onClick,
    onPointerDown: () => {
      setDown(true);
      __ds_scope.Feedback.play(selected ? 'press' : 'tick');
    },
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: size === 'sm' ? '6px 12px 6px 6px' : '8px 16px 8px 8px',
      border: 0,
      borderRadius: 'var(--radius-pill)',
      background: selected ? 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))' : 'linear-gradient(180deg,var(--surface-panel),var(--char-900))',
      boxShadow: down ? 'var(--elev-pressed)' : selected ? 'var(--elev-raised),inset 0 0 0 1.5px var(--amber-500)' : 'var(--elev-panel)',
      transform: down ? 'translateY(var(--press-travel)) scale(.96)' : 'scale(1)',
      color: selected ? 'var(--text-primary)' : 'var(--text-secondary)',
      cursor: 'pointer',
      transition: 'var(--transition-control),transform var(--dur-release) var(--ease-settle)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: dot,
      height: dot,
      flex: 'none',
      borderRadius: '50%',
      background: `radial-gradient(circle at 34% 28%,${scene.to},${scene.from})`,
      boxShadow: `inset 0 -2px 6px rgba(0,0,0,.45),0 0 16px -3px ${scene.to}`
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-ui)',
      fontSize: size === 'sm' ? 13.5 : 15,
      fontWeight: 600,
      letterSpacing: '-.005em',
      whiteSpace: 'nowrap'
    }
  }, scene.name), scene.dynamic && /*#__PURE__*/React.createElement("span", {
    title: "Dynamic scene \u2014 supports speed",
    style: {
      width: 5,
      height: 5,
      borderRadius: '50%',
      background: 'var(--hue-cyan)',
      boxShadow: '0 0 8px var(--hue-cyan)'
    }
  }));
}
Object.assign(__ds_scope, { SCENE_GRADIENTS, SceneTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/SceneTile.jsx", error: String((e && e.message) || e) }); }

// components/controls/Slider.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const SLIDER_FILLS = {
  brightness: 'linear-gradient(90deg,#3A3A42,var(--amber-300))',
  kelvin: 'linear-gradient(90deg,var(--kelvin-2200),var(--kelvin-3500),var(--kelvin-4500),var(--kelvin-6500))',
  speed: 'linear-gradient(90deg,#3A3A42,var(--hue-cyan))',
  neutral: 'linear-gradient(90deg,#3A3A42,#8C8C96)'
};

/** Recessed rail with a raised ivory handle. Drag or click anywhere on the track. */
function Slider({
  value = 50,
  min = 0,
  max = 100,
  step = 1,
  onChange,
  fill = 'brightness',
  label,
  readout,
  disabled,
  style,
  ...rest
}) {
  const track = React.useRef(null);
  const dragging = React.useRef(false);
  const notch = React.useRef(null);
  const pct = Math.min(1, Math.max(0, (value - min) / (max - min)));
  const fromEvent = e => {
    const r = track.current.getBoundingClientRect();
    const p = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
    const v = min + p * (max - min);
    const n = Math.round(p * 20);
    if (n !== notch.current) {
      if (notch.current !== null) __ds_scope.Feedback.play('detent');
      notch.current = n;
    }
    if (onChange) onChange(Math.round(v / step) * step);
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      ...style
    }
  }, rest), (label || readout) && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      justifyContent: 'space-between',
      gap: 12
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, label), readout && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 20,
      fontWeight: 700,
      fontVariantNumeric: 'tabular-nums'
    }
  }, readout)), /*#__PURE__*/React.createElement("div", {
    ref: track,
    role: "slider",
    tabIndex: disabled ? -1 : 0,
    "aria-valuenow": value,
    "aria-valuemin": min,
    "aria-valuemax": max,
    "aria-label": label,
    onPointerDown: e => {
      if (disabled) return;
      dragging.current = true;
      notch.current = null;
      e.currentTarget.setPointerCapture(e.pointerId);
      __ds_scope.Feedback.play('press');
      fromEvent(e);
    },
    onPointerMove: e => {
      if (dragging.current) fromEvent(e);
    },
    onPointerUp: () => {
      dragging.current = false;
    },
    onKeyDown: e => {
      if (disabled || !onChange) return;
      if (e.key === 'ArrowRight') onChange(Math.min(max, value + step));
      if (e.key === 'ArrowLeft') onChange(Math.max(min, value - step));
    },
    style: {
      position: 'relative',
      height: 'var(--track-thickness)',
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      touchAction: 'none',
      cursor: disabled ? 'not-allowed' : 'pointer',
      opacity: disabled ? 0.45 : 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 2,
      right: 'auto',
      width: `calc(${pct * 100}% - 4px)`,
      minWidth: 6,
      borderRadius: 'var(--radius-pill)',
      background: SLIDER_FILLS[fill] || SLIDER_FILLS.neutral,
      boxShadow: fill === 'brightness' || fill === 'kelvin' ? '0 0 14px -2px rgba(255,176,32,.45)' : 'none',
      transition: dragging.current ? 'none' : 'width var(--dur-release) var(--ease-tactile)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: '50%',
      left: `${pct * 100}%`,
      width: 26,
      height: 26,
      marginTop: -13,
      marginLeft: -13,
      borderRadius: '50%',
      background: 'linear-gradient(180deg,#FBFAF7,#C9C5BD)',
      boxShadow: '0 3px 6px rgba(0,0,0,.6),inset 0 1px 0 rgba(255,255,255,.95)',
      transition: dragging.current ? 'none' : 'left var(--dur-release) var(--ease-tactile)'
    }
  })));
}
Object.assign(__ds_scope, { SLIDER_FILLS, Slider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/Slider.jsx", error: String((e && e.message) || e) }); }

// components/controls/Stepper.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function StepperKey({
  icon,
  onClick,
  disabled
}) {
  const [down, setDown] = React.useState(false);
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onClick,
    disabled: disabled,
    onPointerDown: () => {
      setDown(true);
      __ds_scope.Feedback.play(disabled ? 'reject' : 'detent');
    },
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      width: 44,
      height: 44,
      display: 'grid',
      placeItems: 'center',
      border: 0,
      borderRadius: '50%',
      background: 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))',
      boxShadow: down ? 'var(--elev-pressed)' : 'var(--elev-raised)',
      transform: down ? 'translateY(var(--press-travel)) scale(.94)' : 'scale(1)',
      color: 'var(--text-secondary)',
      opacity: disabled ? 0.35 : 1,
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'var(--transition-control),transform var(--dur-release) var(--ease-settle)'
    }
  }, icon);
}

/** Minus / value / plus pad in a recessed well — for discrete values (kelvin steps, schedule hours). */
function Stepper({
  value = 0,
  min = -Infinity,
  max = Infinity,
  step = 1,
  unit,
  onChange,
  label,
  style,
  ...rest
}) {
  const set = v => onChange && onChange(Math.min(max, Math.max(min, v)));
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 12,
      padding: 6,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(StepperKey, {
    icon: /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "minus",
      size: 18
    }),
    onClick: () => set(value - step),
    disabled: value <= min
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 62,
      textAlign: 'center'
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 26,
      fontWeight: 800,
      fontVariantNumeric: 'tabular-nums'
    }
  }, value, unit && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)'
    }
  }, unit))), /*#__PURE__*/React.createElement(StepperKey, {
    icon: /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "plus",
      size: 18
    }),
    onClick: () => set(value + step),
    disabled: value >= max
  }));
}
Object.assign(__ds_scope, { Stepper });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/Stepper.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const BUTTON_SIZES = {
  sm: {
    h: 'var(--control-height-sm)',
    px: 14,
    fs: 12,
    gap: 6,
    r: 'var(--radius-2)'
  },
  md: {
    h: 'var(--control-height)',
    px: 20,
    fs: 13.5,
    gap: 8,
    r: 'var(--radius-3)'
  },
  lg: {
    h: 'var(--control-height-lg)',
    px: 26,
    fs: 15,
    gap: 10,
    r: 'var(--radius-4)'
  }
};
const BUTTON_TONES = {
  primary: {
    bg: 'linear-gradient(180deg,var(--amber-400),var(--amber-600))',
    fg: 'var(--text-on-accent)',
    shadow: 'var(--elev-key)'
  },
  secondary: {
    bg: 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))',
    fg: 'var(--text-primary)',
    shadow: 'var(--elev-raised)'
  },
  ghost: {
    bg: 'linear-gradient(180deg,var(--char-800),var(--char-850))',
    fg: 'var(--text-secondary)',
    shadow: 'var(--elev-raised)'
  },
  danger: {
    bg: 'linear-gradient(180deg,#E2543F,#A82B1C)',
    fg: '#FFF1ED',
    shadow: 'var(--elev-raised)'
  }
};

/** Tactile key. Label is display-face uppercase; press sinks it into the chassis. */
function Button({
  children,
  variant = 'secondary',
  size = 'md',
  icon,
  iconAfter,
  fullWidth,
  disabled,
  onClick,
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  const [hover, setHover] = React.useState(false);
  const s = BUTTON_SIZES[size] || BUTTON_SIZES.md;
  const t = BUTTON_TONES[variant] || BUTTON_TONES.secondary;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: disabled,
    onClick: onClick,
    onPointerDown: () => {
      setDown(true);
      __ds_scope.Feedback.play(variant === 'primary' ? 'confirm' : variant === 'danger' ? 'reject' : 'press');
    },
    onPointerUp: () => setDown(false),
    onPointerLeave: () => {
      setDown(false);
      setHover(false);
    },
    onPointerEnter: () => setHover(true),
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: s.gap,
      height: s.h,
      padding: `0 ${s.px}px`,
      width: fullWidth ? '100%' : undefined,
      border: 0,
      borderRadius: s.r,
      background: t.bg,
      color: t.fg,
      fontFamily: 'var(--font-ui)',
      fontSize: s.fs,
      fontWeight: 700,
      letterSpacing: 'var(--label-ls)',
      textTransform: 'uppercase',
      whiteSpace: 'nowrap',
      boxShadow: down ? 'var(--elev-pressed)' : t.shadow,
      filter: hover && !down && !disabled ? 'brightness(1.08)' : 'none',
      transform: down ? 'translateY(var(--press-travel)) scale(.97)' : 'scale(1)',
      opacity: disabled ? 0.42 : 1,
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'var(--transition-control),transform var(--dur-release) var(--ease-settle)',
      ...style
    }
  }, rest), icon, children, iconAfter);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const ICONBUTTON_D = {
  sm: 36,
  md: 44,
  lg: 56
};

/** Round or squircle icon key — the default control for anything without a text label. */
function IconButton({
  icon,
  size = 'md',
  shape = 'circle',
  active,
  disabled,
  label,
  onClick,
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  const d = ICONBUTTON_D[size] || ICONBUTTON_D.md;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label,
    disabled: disabled,
    onClick: onClick,
    onPointerDown: () => {
      setDown(true);
      __ds_scope.Feedback.play('press');
    },
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      width: d,
      height: d,
      display: 'grid',
      placeItems: 'center',
      border: 0,
      borderRadius: shape === 'circle' ? 'var(--radius-circle)' : 'var(--radius-3)',
      background: active ? 'linear-gradient(180deg,var(--amber-400),var(--amber-600))' : 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))',
      color: active ? 'var(--text-on-accent)' : 'var(--text-secondary)',
      boxShadow: down ? 'var(--elev-pressed)' : 'var(--elev-raised)',
      transform: down ? 'translateY(var(--press-travel)) scale(.94)' : 'scale(1)',
      opacity: disabled ? 0.4 : 1,
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'var(--transition-control),transform var(--dur-release) var(--ease-settle)',
      ...style
    }
  }, rest), icon);
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/ListRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** One line in a list of rooms, lights or settings. Leading icon well, title, meta, trailing slot. */
function ListRow({
  icon,
  title,
  meta,
  trailing,
  active,
  onClick,
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  const interactive = !!onClick;
  return /*#__PURE__*/React.createElement("div", _extends({
    role: interactive ? 'button' : undefined,
    tabIndex: interactive ? 0 : undefined,
    onClick: onClick,
    onPointerDown: () => {
      if (!interactive) return;
      setDown(true);
      __ds_scope.Feedback.play('press');
    },
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      padding: '12px 14px',
      borderRadius: 'var(--radius-3)',
      background: active ? 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))' : 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: down ? 'var(--elev-pressed)' : active ? 'var(--elev-raised),inset 0 0 0 1px rgba(255,176,32,.28)' : 'var(--elev-panel)',
      transform: down ? 'translateY(var(--press-travel)) scale(.985)' : active ? 'scale(1.004)' : 'scale(1)',
      cursor: interactive ? 'pointer' : 'default',
      transition: 'var(--transition-control),transform var(--dur-release) var(--ease-settle)',
      ...style
    }
  }, rest), icon && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 40,
      height: 40,
      flex: 'none',
      display: 'grid',
      placeItems: 'center',
      borderRadius: 'var(--radius-2)',
      background: 'var(--char-1000)',
      boxShadow: 'var(--elev-well)',
      color: active ? 'var(--amber-400)' : 'var(--text-tertiary)'
    }
  }, icon), /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 0,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-ui)',
      fontSize: 16,
      fontWeight: 600,
      letterSpacing: '-.005em',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, title), meta && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 1,
      color: 'var(--text-tertiary)',
      fontSize: 'var(--type-body-sm-size)'
    }
  }, meta)), trailing);
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedControl.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Recessed track holding one raised selector that slides between items. Items: [{ value, label, icon }]. */
function SegmentedControl({
  items = [],
  value,
  onChange,
  fullWidth,
  size = 'md',
  style,
  ...rest
}) {
  const h = size === 'sm' ? 36 : 44;
  const wrap = React.useRef(null);
  const refs = React.useRef({});
  const [thumb, setThumb] = React.useState(null);
  React.useLayoutEffect(() => {
    const el = refs.current[value];
    if (!el || !wrap.current) return;
    setThumb({
      left: el.offsetLeft,
      width: el.offsetWidth
    });
  }, [value, items, fullWidth, size]);
  return /*#__PURE__*/React.createElement("div", _extends({
    ref: wrap,
    role: "tablist",
    style: {
      position: 'relative',
      display: fullWidth ? 'grid' : 'inline-grid',
      gridAutoFlow: 'column',
      gridAutoColumns: fullWidth ? '1fr' : 'auto',
      gap: 4,
      padding: 4,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      ...style
    }
  }, rest), thumb && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      position: 'absolute',
      top: 4,
      height: h,
      left: thumb.left,
      width: thumb.width,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))',
      boxShadow: 'var(--elev-raised)',
      pointerEvents: 'none',
      transition: 'left var(--dur-panel) var(--ease-settle),width var(--dur-panel) var(--ease-settle)'
    }
  }), items.map(it => {
    const on = it.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.value,
      ref: el => {
        refs.current[it.value] = el;
      },
      type: "button",
      role: "tab",
      "aria-selected": on,
      onClick: () => {
        if (!on) __ds_scope.Feedback.play('tick');
        if (onChange) onChange(it.value);
      },
      style: {
        position: 'relative',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 7,
        height: h,
        padding: '0 16px',
        border: 0,
        borderRadius: 'var(--radius-pill)',
        background: 'transparent',
        color: on ? 'var(--text-primary)' : 'var(--text-tertiary)',
        fontFamily: 'var(--font-ui)',
        fontSize: size === 'sm' ? 12 : 13,
        fontWeight: 700,
        letterSpacing: '.08em',
        textTransform: 'uppercase',
        whiteSpace: 'nowrap',
        cursor: 'pointer',
        transition: 'color var(--dur-ui) var(--ease-tactile),transform var(--dur-release) var(--ease-settle)',
        transform: on ? 'scale(1)' : 'scale(.98)'
      }
    }, it.icon, it.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/core/Toggle.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const TOGGLE_S = {
  sm: {
    w: 46,
    h: 27,
    k: 21
  },
  md: {
    w: 60,
    h: 33,
    k: 27
  }
};

/** Physical rocker switch: recessed well, glossy ivory cap, amber filament glow when live. */
function Toggle({
  checked,
  onChange,
  size = 'md',
  disabled,
  label,
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  const s = TOGGLE_S[size] || TOGGLE_S.md;
  const pad = (s.h - s.k) / 2;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": !!checked,
    "aria-label": label,
    disabled: disabled,
    onClick: () => {
      __ds_scope.Feedback.play(checked ? 'toggleOff' : 'toggleOn');
      if (onChange) onChange(!checked);
    },
    onPointerDown: () => setDown(true),
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      position: 'relative',
      width: s.w,
      height: s.h,
      flex: 'none',
      border: 0,
      padding: 0,
      borderRadius: 'var(--radius-pill)',
      cursor: disabled ? 'not-allowed' : 'pointer',
      background: checked ? 'linear-gradient(180deg,var(--amber-600),var(--amber-400) 62%,var(--amber-500))' : 'linear-gradient(180deg,var(--char-1000),var(--char-800))',
      boxShadow: checked ? 'inset 0 2px 5px rgba(120,60,0,.55),inset 0 -1px 0 rgba(255,255,255,.35),0 0 16px -3px rgba(255,176,32,.65)' : 'inset 0 2px 5px rgba(0,0,0,.7),inset 0 -1px 0 rgba(255,255,255,.07)',
      opacity: disabled ? 0.45 : 1,
      transform: down ? 'scale(.96)' : 'scale(1)',
      transition: 'background var(--dur-ui) var(--ease-tactile),box-shadow var(--dur-ui) var(--ease-tactile),transform var(--dur-release) var(--ease-settle)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      position: 'absolute',
      top: pad,
      left: checked ? s.w - s.k - pad : pad,
      width: s.k,
      height: s.k,
      borderRadius: '50%',
      background: 'radial-gradient(circle at 38% 26%,#FFFFFF,#F1EEE8 42%,#C8C4BB 78%,#A8A49B)',
      boxShadow: '0 3px 6px rgba(0,0,0,.55),0 1px 0 rgba(255,255,255,.4) inset,inset 0 -2px 3px rgba(0,0,0,.18)',
      transform: down ? 'scale(.93)' : 'scale(1)',
      transition: 'left var(--dur-panel) var(--ease-settle),transform var(--dur-release) var(--ease-settle)'
    }
  }));
}
Object.assign(__ds_scope, { Toggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Toggle.jsx", error: String((e && e.message) || e) }); }

// components/data/EmptyState.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Empty / zero state: recessed glyph well, one line of plain explanation, one action. */
function EmptyState({
  icon,
  title,
  body,
  action,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 16,
      padding: 'var(--space-10) var(--space-7)',
      textAlign: 'center',
      ...style
    }
  }, rest), icon && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 76,
      height: 76,
      display: 'grid',
      placeItems: 'center',
      borderRadius: '50%',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well-deep)',
      color: 'var(--text-tertiary)'
    }
  }, icon), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-display)',
      fontSize: 'var(--type-heading-size)',
      fontWeight: 700,
      letterSpacing: 'var(--type-heading-ls)'
    }
  }, title), body && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 6,
      maxWidth: 320,
      color: 'var(--text-tertiary)',
      fontSize: 'var(--type-body-size)'
    }
  }, body)), action);
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/data/LightCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** A single light: name, address/class meta, power switch, and brightness as a rail or a read-only meter. */
function LightCard({
  name,
  meta,
  icon = 'lightbulb',
  on,
  onToggle,
  brightness = 70,
  onBrightness,
  brightnessControl = 'rail',
  unreachable,
  style,
  ...rest
}) {
  const lit = on && !unreachable;
  const pct = Math.min(100, Math.max(0, Math.round(brightness)));
  const showRail = lit && brightnessControl === 'rail';
  const showMeter = lit && brightnessControl === 'meter';
  const hasSecondRow = showRail || showMeter || unreachable;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: hasSecondRow ? 14 : 0,
      padding: 'var(--panel-pad)',
      borderRadius: 'var(--radius-4)',
      background: 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: lit ? 'var(--elev-panel),var(--glow-amber)' : 'var(--elev-panel)',
      opacity: unreachable ? 0.55 : 1,
      transition: 'box-shadow var(--dur-light) var(--ease-tactile)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 13
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 46,
      height: 46,
      flex: 'none',
      display: 'grid',
      placeItems: 'center',
      borderRadius: 'var(--radius-2)',
      background: lit ? 'radial-gradient(circle at 50% 30%,var(--amber-400),var(--amber-700))' : 'var(--char-1000)',
      boxShadow: lit ? 'inset 0 1px 0 rgba(255,255,255,.35),0 0 20px -4px rgba(255,176,32,.7)' : 'var(--elev-well)',
      color: lit ? 'var(--text-on-accent)' : 'var(--text-tertiary)',
      transition: 'background var(--dur-light) var(--ease-tactile),box-shadow var(--dur-light) var(--ease-tactile)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 22
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 0,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-ui)',
      fontSize: 16.5,
      fontWeight: 600,
      letterSpacing: '-.005em',
      lineHeight: 1.2,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, name), meta && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 2,
      fontFamily: 'var(--font-mono)',
      fontSize: 11,
      color: 'var(--text-tertiary)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, meta)), /*#__PURE__*/React.createElement(__ds_scope.Toggle, {
    checked: !!lit,
    onChange: onToggle,
    disabled: unreachable,
    label: name
  })), showRail && /*#__PURE__*/React.createElement(__ds_scope.Slider, {
    value: brightness,
    min: 10,
    max: 100,
    onChange: onBrightness,
    readout: `${pct}%`,
    label: "Brightness"
  }), showMeter && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      height: 6,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      height: '100%',
      width: `${pct}%`,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(90deg,var(--amber-700),var(--amber-300))',
      transition: 'width var(--dur-light) var(--ease-tactile)'
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 'none',
      fontFamily: 'var(--font-display)',
      fontSize: 18,
      fontWeight: 800,
      letterSpacing: '.015em',
      color: 'var(--amber-400)',
      fontVariantNumeric: 'tabular-nums'
    }
  }, pct, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 10.5,
      color: 'var(--text-tertiary)'
    }
  }, "%"))), unreachable && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 7,
      color: 'var(--signal-danger)',
      fontSize: 'var(--type-body-sm-size)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "wifi",
    size: 15
  }), "No response on the local network"));
}
Object.assign(__ds_scope, { LightCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/LightCard.jsx", error: String((e && e.message) || e) }); }

// components/data/RoomCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Room summary tile: room glyph, light count, how many are on, master switch. */
function RoomCard({
  name,
  icon = 'sofa',
  lightCount = 0,
  onCount = 0,
  on,
  onToggle,
  onOpen,
  style,
  ...rest
}) {
  const [down, setDown] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onOpen,
    onPointerDown: () => {
      setDown(true);
      __ds_scope.Feedback.play('press');
    },
    onPointerUp: () => setDown(false),
    onPointerLeave: () => setDown(false),
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 18,
      padding: 'var(--panel-pad)',
      borderRadius: 'var(--radius-4)',
      background: 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: down ? 'var(--elev-pressed)' : on ? 'var(--elev-panel),var(--glow-amber)' : 'var(--elev-panel)',
      transform: down ? 'translateY(var(--press-travel)) scale(.975)' : 'scale(1)',
      cursor: onOpen ? 'pointer' : 'default',
      transition: 'var(--transition-control),transform var(--dur-release) var(--ease-settle)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 42,
      height: 42,
      display: 'grid',
      placeItems: 'center',
      borderRadius: 'var(--radius-2)',
      background: 'var(--char-1000)',
      boxShadow: 'var(--elev-well)',
      color: on ? 'var(--amber-400)' : 'var(--text-tertiary)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 21
  })), /*#__PURE__*/React.createElement(__ds_scope.Toggle, {
    size: "sm",
    checked: !!on,
    onChange: onToggle,
    label: name
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-ui)',
      fontSize: 19,
      fontWeight: 600,
      letterSpacing: '-.01em',
      lineHeight: 1.15
    }
  }, name), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 3,
      color: 'var(--text-tertiary)',
      fontSize: 'var(--type-body-sm-size)'
    }
  }, lightCount, " light", lightCount === 1 ? '' : 's', onCount > 0 ? ` · ${onCount} on` : ' · all off')));
}
Object.assign(__ds_scope, { RoomCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/RoomCard.jsx", error: String((e && e.message) || e) }); }

// components/data/StatTile.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Small instrument tile: caps label with glyph, then a display-face value. */
function StatTile({
  icon,
  label,
  value,
  unit,
  tone = 'default',
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12,
      padding: '14px 16px',
      borderRadius: 'var(--radius-3)',
      background: 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: 'var(--elev-panel)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 7,
      color: 'var(--text-tertiary)',
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase'
    }
  }, icon, label), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 2,
      fontFamily: 'var(--font-display)',
      fontSize: 28,
      fontWeight: 800,
      lineHeight: 1,
      color: tone === 'accent' ? 'var(--amber-400)' : 'var(--text-primary)',
      fontVariantNumeric: 'tabular-nums'
    }
  }, value, unit && /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 600,
      color: 'var(--text-tertiary)'
    }
  }, unit)));
}
Object.assign(__ds_scope, { StatTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data/StatTile.jsx", error: String((e && e.message) || e) }); }

// components/feedback/FilamentBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * The system's primary loader: a tungsten filament heating up.
 * Indeterminate by default — a hot spot travels the wire. Pass `value` (0-100) for determinate.
 */
function FilamentBar({
  value,
  label,
  thickness = 6,
  style,
  ...rest
}) {
  const determinate = typeof value === 'number';
  React.useEffect(() => {
    if (typeof document === 'undefined' || document.getElementById('wz-filament')) return;
    const el = document.createElement('style');
    el.id = 'wz-filament';
    el.textContent = '@keyframes wz-filament{0%{transform:translateX(-105%)}100%{transform:translateX(205%)}}@keyframes wz-filament-heat{0%,100%{opacity:.62}50%{opacity:1}}';
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      ...style
    }
  }, rest), label && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      gap: 12,
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, /*#__PURE__*/React.createElement("span", null, label), determinate && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      letterSpacing: 0
    }
  }, Math.round(value), "%")), /*#__PURE__*/React.createElement("div", {
    role: "progressbar",
    "aria-valuenow": determinate ? Math.round(value) : undefined,
    style: {
      position: 'relative',
      height: thickness,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      overflow: 'hidden'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'repeating-linear-gradient(90deg,rgba(255,255,255,.05) 0 1px,transparent 1px 4px)'
    }
  }), determinate ? /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 0,
      bottom: 0,
      left: 0,
      width: `${Math.min(100, Math.max(0, value))}%`,
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(90deg,var(--amber-700),var(--amber-300))',
      boxShadow: '0 0 14px -1px rgba(255,176,32,.7)',
      transition: 'width var(--dur-light) var(--ease-tactile)'
    }
  }) : /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: 0,
      bottom: 0,
      left: 0,
      width: '38%',
      borderRadius: 'var(--radius-pill)',
      background: 'linear-gradient(90deg,rgba(255,176,32,0),var(--amber-300) 50%,rgba(255,176,32,0))',
      boxShadow: '0 0 16px 0 rgba(255,176,32,.55)',
      animation: 'wz-filament 1.35s var(--ease-tactile) infinite,wz-filament-heat 1.35s ease-in-out infinite'
    }
  })));
}
Object.assign(__ds_scope, { FilamentBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/FilamentBar.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Skeleton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Empty machined well standing in for content that has not arrived. A faint sheen crosses it. */
function Skeleton({
  width = '100%',
  height = 16,
  radius = 'var(--radius-2)',
  circle,
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (typeof document === 'undefined' || document.getElementById('wz-skel')) return;
    const el = document.createElement('style');
    el.id = 'wz-skel';
    el.textContent = '@keyframes wz-sheen{0%{transform:translateX(-100%)}100%{transform:translateX(100%)}}';
    document.head.appendChild(el);
  }, []);
  return /*#__PURE__*/React.createElement("span", _extends({
    "aria-hidden": "true",
    style: {
      position: 'relative',
      display: 'block',
      overflow: 'hidden',
      flex: 'none',
      width: circle ? height : width,
      height,
      borderRadius: circle ? '50%' : radius,
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'linear-gradient(90deg,transparent,rgba(255,255,255,.055),transparent)',
      animation: 'wz-sheen 1.6s var(--ease-tactile) infinite'
    }
  }));
}
Object.assign(__ds_scope, { Skeleton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Skeleton.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Spinner.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Sweeping needle in a recessed ring — the inline loader, sized to sit beside text or in a key. */
function Spinner({
  size = 22,
  tone = 'accent',
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (typeof document === 'undefined' || document.getElementById('wz-spin')) return;
    const el = document.createElement('style');
    el.id = 'wz-spin';
    el.textContent = '@keyframes wz-sweep{to{transform:rotate(360deg)}}';
    document.head.appendChild(el);
  }, []);
  const c = tone === 'accent' ? 'var(--amber-400)' : 'var(--text-secondary)';
  return /*#__PURE__*/React.createElement("span", _extends({
    role: "status",
    "aria-label": "Loading",
    style: {
      position: 'relative',
      width: size,
      height: size,
      flex: 'none',
      display: 'inline-block',
      borderRadius: '50%',
      background: 'linear-gradient(180deg,var(--char-1000),var(--char-900))',
      boxShadow: 'var(--elev-well)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      inset: Math.max(1, size * 0.09),
      borderRadius: '50%',
      background: `conic-gradient(from 0deg,rgba(0,0,0,0) 0deg,rgba(0,0,0,0) 210deg,${c} 355deg,${c} 360deg)`,
      WebkitMask: `radial-gradient(farthest-side,transparent calc(100% - ${Math.max(1.5, size * 0.11)}px),#000 0)`,
      mask: `radial-gradient(farthest-side,transparent calc(100% - ${Math.max(1.5, size * 0.11)}px),#000 0)`,
      animation: 'wz-sweep 900ms linear infinite'
    }
  }));
}
Object.assign(__ds_scope, { Spinner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Spinner.jsx", error: String((e && e.message) || e) }); }

// components/feedback/StatusBanner.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const STATUS_TONES = {
  loading: {
    icon: null,
    color: 'var(--text-secondary)',
    dot: 'var(--amber-400)'
  },
  success: {
    icon: 'check',
    color: 'var(--signal-online)',
    dot: 'var(--signal-online)'
  },
  error: {
    icon: 'x',
    color: 'var(--signal-danger)',
    dot: 'var(--signal-danger)'
  },
  warn: {
    icon: 'wifi',
    color: 'var(--signal-warn)',
    dot: 'var(--signal-warn)'
  },
  info: {
    icon: 'terminal',
    color: 'var(--text-secondary)',
    dot: 'var(--char-600)'
  }
};

/** Inline state band inside a screen or panel: what is happening, and what to do about it. */
function StatusBanner({
  status = 'info',
  title,
  body,
  action,
  style,
  ...rest
}) {
  const t = STATUS_TONES[status] || STATUS_TONES.info;
  return /*#__PURE__*/React.createElement("div", _extends({
    role: status === 'error' ? 'alert' : 'status',
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 13,
      padding: '12px 14px',
      borderRadius: 'var(--radius-3)',
      background: 'linear-gradient(180deg,var(--char-900),var(--char-950))',
      boxShadow: 'var(--elev-well)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 30,
      height: 30,
      flex: 'none',
      display: 'grid',
      placeItems: 'center',
      borderRadius: 'var(--radius-2)',
      background: 'var(--char-1000)',
      boxShadow: 'inset 0 1px 3px rgba(0,0,0,.6)',
      color: t.color
    }
  }, status === 'loading' ? /*#__PURE__*/React.createElement(__ds_scope.Spinner, {
    size: 18
  }) : /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: t.icon,
    size: 16,
    strokeWidth: 2.25
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 0,
      flex: 1
    }
  }, title && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 14,
      fontWeight: 600,
      letterSpacing: '-.005em',
      color: 'var(--text-primary)'
    }
  }, title), body && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 1,
      fontSize: 'var(--type-body-sm-size)',
      color: 'var(--text-tertiary)'
    }
  }, body)), action);
}
Object.assign(__ds_scope, { STATUS_TONES, StatusBanner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/StatusBanner.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Toast.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const TOAST_TONES = {
  success: {
    icon: 'check',
    color: 'var(--signal-online)',
    sound: 'confirm'
  },
  error: {
    icon: 'x',
    color: 'var(--signal-danger)',
    sound: 'reject'
  },
  loading: {
    icon: null,
    color: 'var(--amber-400)',
    sound: null
  },
  info: {
    icon: 'zap',
    color: 'var(--text-secondary)',
    sound: 'tick'
  }
};

/** One toast. Normally created through useToasts(), not mounted directly. */
function Toast({
  tone = 'info',
  title,
  body,
  action,
  onDismiss,
  style,
  ...rest
}) {
  const t = TOAST_TONES[tone] || TOAST_TONES.info;
  return /*#__PURE__*/React.createElement("div", _extends({
    role: tone === 'error' ? 'alert' : 'status',
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '11px 13px',
      borderRadius: 'var(--radius-3)',
      background: 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: 'var(--elev-key),0 18px 40px -18px rgba(0,0,0,.8)',
      animation: 'wz-toast-in var(--dur-panel) var(--ease-settle)',
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 26,
      height: 26,
      flex: 'none',
      display: 'grid',
      placeItems: 'center',
      borderRadius: 'var(--radius-1)',
      background: 'var(--char-1000)',
      boxShadow: 'var(--elev-well)',
      color: t.color
    }
  }, tone === 'loading' ? /*#__PURE__*/React.createElement(__ds_scope.Spinner, {
    size: 16
  }) : /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: t.icon,
    size: 14,
    strokeWidth: 2.5
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 0,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontSize: 13.5,
      fontWeight: 600,
      letterSpacing: '-.005em'
    }
  }, title), body && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 1,
      fontSize: 12,
      color: 'var(--text-tertiary)'
    }
  }, body)), action, onDismiss && /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Dismiss",
    onClick: onDismiss,
    style: {
      width: 26,
      height: 26,
      flex: 'none',
      display: 'grid',
      placeItems: 'center',
      border: 0,
      borderRadius: '50%',
      background: 'transparent',
      color: 'var(--text-tertiary)',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "x",
    size: 14
  })));
}

/** Stack of toasts. Place once per screen inside a positioned ancestor. */
function ToastStack({
  toasts = [],
  onDismiss,
  placement = 'bottom',
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (typeof document === 'undefined' || document.getElementById('wz-toast')) return;
    const el = document.createElement('style');
    el.id = 'wz-toast';
    el.textContent = '@keyframes wz-toast-in{from{transform:translateY(10px) scale(.97);opacity:0}to{transform:none;opacity:1}}';
    document.head.appendChild(el);
  }, []);
  if (!toasts.length) return null;
  const bottom = placement === 'bottom';
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: 'absolute',
      left: 'var(--space-6)',
      right: 'var(--space-6)',
      zIndex: 60,
      [bottom ? 'bottom' : 'top']: 'var(--space-6)',
      display: 'flex',
      flexDirection: bottom ? 'column-reverse' : 'column',
      gap: 'var(--space-4)',
      pointerEvents: 'none',
      ...style
    }
  }, rest), toasts.map(t => /*#__PURE__*/React.createElement(Toast, _extends({
    key: t.id
  }, t, {
    style: {
      pointerEvents: 'auto'
    },
    onDismiss: onDismiss ? () => onDismiss(t.id) : undefined
  }))));
}

/**
 * Toast queue. Returns { toasts, push, update, dismiss }.
 * push() returns the id so a loading toast can be resolved later.
 */
function useToasts({
  duration = 3200,
  max = 3
} = {}) {
  const [toasts, setToasts] = React.useState([]);
  const timers = React.useRef({});
  const dismiss = React.useCallback(id => {
    clearTimeout(timers.current[id]);
    delete timers.current[id];
    setToasts(list => list.filter(t => t.id !== id));
  }, []);
  const arm = React.useCallback((id, tone) => {
    if (tone === 'loading') return;
    timers.current[id] = setTimeout(() => dismiss(id), duration);
  }, [dismiss, duration]);
  const push = React.useCallback(({
    tone = 'info',
    title,
    body,
    action
  } = {}) => {
    const id = 't' + Date.now() + Math.random().toString(36).slice(2, 6);
    const sound = (TOAST_TONES[tone] || TOAST_TONES.info).sound;
    if (sound) __ds_scope.Feedback.play(sound);
    setToasts(list => [...list, {
      id,
      tone,
      title,
      body,
      action
    }].slice(-max));
    arm(id, tone);
    return id;
  }, [arm, max]);
  const update = React.useCallback((id, patch) => {
    setToasts(list => list.map(t => t.id === id ? {
      ...t,
      ...patch
    } : t));
    if (patch && patch.tone) {
      const sound = (TOAST_TONES[patch.tone] || {}).sound;
      if (sound) __ds_scope.Feedback.play(sound);
      clearTimeout(timers.current[id]);
      arm(id, patch.tone);
    }
  }, [arm]);
  React.useEffect(() => () => Object.values(timers.current).forEach(clearTimeout), []);
  return {
    toasts,
    push,
    update,
    dismiss
  };
}

/** Capitalized entry point so the queue reaches window.<Namespace>: const { toasts, push } = Toasts.use(); */
const Toasts = {
  use: useToasts
};
Object.assign(__ds_scope, { Toast, ToastStack, useToasts, Toasts });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Toast.jsx", error: String((e && e.message) || e) }); }

// components/layout/Sheet.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Bottom sheet (phone) / centred dialog (desktop). Grab handle, scrim, escape to close. */
function Sheet({
  open,
  onClose,
  title,
  children,
  footer,
  placement = 'bottom',
  style,
  ...rest
}) {
  React.useEffect(() => {
    if (!open) return;
    const h = e => e.key === 'Escape' && onClose && onClose();
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [open, onClose]);
  if (!open) return null;
  const centred = placement === 'center';
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClose,
    style: {
      position: 'absolute',
      inset: 0,
      zIndex: 40,
      display: 'flex',
      alignItems: centred ? 'center' : 'flex-end',
      justifyContent: 'center',
      background: 'var(--surface-scrim)',
      backdropFilter: 'blur(6px)',
      padding: centred ? 24 : 0
    }
  }, /*#__PURE__*/React.createElement("div", _extends({
    role: "dialog",
    "aria-modal": "true",
    "aria-label": typeof title === 'string' ? title : undefined,
    onClick: e => e.stopPropagation(),
    style: {
      width: centred ? 'min(520px,100%)' : '100%',
      maxHeight: '86%',
      overflow: 'auto',
      padding: 'var(--panel-pad-lg)',
      borderRadius: centred ? 'var(--radius-5)' : 'var(--radius-5) var(--radius-5) 0 0',
      background: 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: 'var(--elev-overlay)',
      animation: `wz-sheet-in var(--dur-panel) var(--ease-settle)`,
      ...style
    }
  }, rest), !centred && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 44,
      height: 4,
      margin: '0 auto 14px',
      borderRadius: 2,
      background: 'var(--char-700)',
      boxShadow: 'var(--elev-well)'
    }
  }), title && /*#__PURE__*/React.createElement("h3", {
    style: {
      margin: '0 0 14px',
      fontSize: 'var(--type-heading-size)',
      fontWeight: 600
    }
  }, title), children, footer && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 'var(--space-7)',
      display: 'flex',
      gap: 'var(--space-4)'
    }
  }, footer)));
}
Object.assign(__ds_scope, { Sheet });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/Sheet.jsx", error: String((e && e.message) || e) }); }

// components/layout/Sidebar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Desktop rail: brand block, room/group nav with a sliding active cap, footer slot. */
function Sidebar({
  brand,
  sections = [],
  value,
  onChange,
  footer,
  style,
  ...rest
}) {
  const list = React.useRef(null);
  const refs = React.useRef({});
  const [cap, setCap] = React.useState(null);
  React.useLayoutEffect(() => {
    let frame = 0;
    const measure = () => {
      const el = refs.current[value];
      if (!el || !list.current) return;
      // The scroll container is a flex item, so geometry can be unresolved on the first
      // synchronous pass — retry next frame rather than storing zeros.
      if (!el.offsetHeight) {
        frame = requestAnimationFrame(measure);
        return;
      }
      setCap({
        top: el.offsetTop,
        height: el.offsetHeight,
        left: el.offsetLeft,
        width: el.offsetWidth
      });
    };
    measure();
    const ro = typeof ResizeObserver !== 'undefined' ? new ResizeObserver(measure) : null;
    if (ro && list.current) ro.observe(list.current);
    return () => {
      cancelAnimationFrame(frame);
      if (ro) ro.disconnect();
    };
  }, [value, sections]);
  return /*#__PURE__*/React.createElement("aside", _extends({
    style: {
      width: 'var(--sidebar-width)',
      flex: 'none',
      display: 'flex',
      flexDirection: 'column',
      gap: 'var(--space-8)',
      padding: 'var(--space-7)',
      background: 'linear-gradient(180deg,var(--char-900),var(--char-950))',
      boxShadow: 'inset -1px 0 0 var(--edge-hairline)',
      ...style
    }
  }, rest), brand, /*#__PURE__*/React.createElement("div", {
    ref: list,
    style: {
      position: 'relative',
      display: 'flex',
      flexDirection: 'column',
      gap: 'var(--space-8)',
      flex: 1,
      minHeight: 0,
      overflow: 'auto'
    }
  }, cap && cap.height > 0 && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      position: 'absolute',
      top: cap.top,
      left: cap.left,
      width: cap.width,
      height: cap.height,
      borderRadius: 'var(--radius-2)',
      background: 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))',
      boxShadow: 'var(--elev-raised)',
      pointerEvents: 'none',
      transition: 'top var(--dur-panel) var(--ease-settle),height var(--dur-panel) var(--ease-settle)'
    }
  }), sections.map(sec => /*#__PURE__*/React.createElement("div", {
    key: sec.title,
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 'var(--space-3)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      padding: '0 6px',
      fontSize: 'var(--type-caption-size)',
      letterSpacing: 'var(--type-caption-ls)',
      textTransform: 'uppercase',
      color: 'var(--text-tertiary)'
    }
  }, sec.title), sec.items.map(it => {
    const on = it.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.value,
      ref: el => {
        refs.current[it.value] = el;
      },
      type: "button",
      onClick: () => {
        if (!on) __ds_scope.Feedback.play('tick');
        if (onChange) onChange(it.value);
      },
      style: {
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        gap: 11,
        height: 42,
        padding: '0 12px',
        border: 0,
        borderRadius: 'var(--radius-2)',
        textAlign: 'left',
        background: 'transparent',
        color: on ? 'var(--text-primary)' : 'var(--text-secondary)',
        fontFamily: 'var(--font-ui)',
        fontSize: 15,
        fontWeight: 600,
        letterSpacing: '-.005em',
        cursor: 'pointer',
        transition: 'color var(--dur-ui) var(--ease-tactile),transform var(--dur-release) var(--ease-settle)'
      },
      onPointerDown: e => {
        e.currentTarget.style.transform = 'scale(.98)';
      },
      onPointerUp: e => {
        e.currentTarget.style.transform = 'scale(1)';
      },
      onPointerLeave: e => {
        e.currentTarget.style.transform = 'scale(1)';
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: on ? 'var(--amber-400)' : 'var(--text-tertiary)',
        display: 'flex',
        transition: 'color var(--dur-ui) var(--ease-tactile)'
      }
    }, it.icon), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        minWidth: 0,
        overflow: 'hidden',
        textOverflow: 'ellipsis',
        whiteSpace: 'nowrap'
      }
    }, it.label), it.meta && /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: 'var(--font-mono)',
        fontSize: 11,
        color: 'var(--text-tertiary)'
      }
    }, it.meta));
  })))), footer);
}
Object.assign(__ds_scope, { Sidebar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/Sidebar.jsx", error: String((e && e.message) || e) }); }

// components/layout/TabBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const WZ_ANIM_ID = 'wz-anim';
const WZ_ANIM_CSS = '@keyframes wz-pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.4;transform:scale(.72)}}@keyframes wz-pop{0%{transform:scale(1)}38%{transform:scale(1.055)}100%{transform:scale(1)}}@keyframes wz-sheet-in{from{transform:translateY(14px);opacity:.6}to{transform:none;opacity:1}}';
function ensureAnim() {
  if (typeof document === 'undefined' || document.getElementById(WZ_ANIM_ID)) return;
  const el = document.createElement('style');
  el.id = WZ_ANIM_ID;
  el.textContent = WZ_ANIM_CSS;
  document.head.appendChild(el);
}

/** Floating bottom nav on the phone: the amber cap slides to the tab you pick. */
function TabBar({
  items = [],
  value,
  onChange,
  style,
  ...rest
}) {
  ensureAnim();
  const wrap = React.useRef(null);
  const refs = React.useRef({});
  const [cap, setCap] = React.useState(null);
  React.useLayoutEffect(() => {
    const el = refs.current[value];
    if (!el) return;
    setCap({
      left: el.offsetLeft,
      top: el.offsetTop,
      width: el.offsetWidth,
      height: el.offsetHeight
    });
  }, [value, items]);
  return /*#__PURE__*/React.createElement("nav", _extends({
    ref: wrap,
    style: {
      position: 'relative',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-around',
      gap: 4,
      height: 'var(--tabbar-height)',
      padding: '0 10px',
      borderRadius: 'var(--radius-5)',
      background: 'linear-gradient(180deg,var(--surface-raised),var(--surface-panel))',
      boxShadow: 'var(--elev-key)',
      ...style
    }
  }, rest), cap && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      position: 'absolute',
      left: cap.left,
      top: cap.top,
      width: cap.width,
      height: cap.height,
      borderRadius: 'var(--radius-3)',
      background: 'linear-gradient(180deg,var(--amber-400),var(--amber-600))',
      boxShadow: 'var(--elev-raised)',
      pointerEvents: 'none',
      transition: 'left var(--dur-panel) var(--ease-settle),top var(--dur-panel) var(--ease-settle),width var(--dur-panel) var(--ease-settle),height var(--dur-panel) var(--ease-settle)'
    }
  }), items.map(it => {
    const on = it.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.value,
      ref: el => {
        refs.current[it.value] = el;
      },
      type: "button",
      "aria-label": it.label,
      "aria-current": on,
      onClick: () => {
        if (!on) __ds_scope.Feedback.play('tick');
        if (onChange) onChange(it.value);
      },
      style: {
        position: 'relative',
        width: 52,
        height: 52,
        display: 'grid',
        placeItems: 'center',
        border: 0,
        borderRadius: 'var(--radius-3)',
        background: 'transparent',
        color: on ? 'var(--text-on-accent)' : 'var(--text-tertiary)',
        cursor: 'pointer',
        transform: on ? 'scale(1.06)' : 'scale(1)',
        transition: 'color var(--dur-ui) var(--ease-tactile),transform var(--dur-panel) var(--ease-settle)'
      }
    }, it.icon);
  }));
}
Object.assign(__ds_scope, { TabBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/TabBar.jsx", error: String((e && e.message) || e) }); }

// components/layout/TopBar.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Screen header: optional back key, display-face title with sub-line, trailing slot. */
function TopBar({
  title,
  subtitle,
  onBack,
  leading,
  trailing,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("header", _extends({
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      minHeight: 56,
      ...style
    }
  }, rest), leading, /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 0,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      fontFamily: 'var(--font-display)',
      fontSize: 'var(--type-title-size)',
      fontWeight: 700,
      letterSpacing: 'var(--type-title-ls)',
      lineHeight: 'var(--type-title-lh)',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'block',
      marginTop: 2,
      color: 'var(--text-tertiary)',
      fontSize: 'var(--type-body-sm-size)'
    }
  }, subtitle)), trailing);
}
Object.assign(__ds_scope, { TopBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/layout/TopBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/desktop_app/desktop.jsx
try { (() => {
const {
  Icon,
  Button,
  IconButton,
  Panel,
  Badge,
  Toggle,
  SegmentedControl,
  ListRow,
  FilamentBar,
  Spinner,
  Skeleton,
  StatusBanner,
  ToastStack,
  PowerKey,
  Dial,
  Slider,
  ColorWheel,
  SceneTile,
  SCENE_GRADIENTS,
  Readout,
  Stepper,
  Sidebar,
  TopBar,
  Sheet,
  LightCard,
  RoomCard,
  StatTile,
  EmptyState
} = window.WizCtlDesignSystem_2a6b25 || {};
const NOOP_QUEUE = {
  toasts: [],
  push: () => {},
  update: () => {},
  dismiss: () => {}
};
function useToastQueue(opts) {
  const ns = window.WizCtlDesignSystem_2a6b25 || {};
  return ns.Toasts && ns.Toasts.use ? ns.Toasts.use(opts) : NOOP_QUEUE;
}
const ROOMS = [{
  id: 'living',
  name: 'Living Room',
  icon: 'sofa',
  lights: [{
    id: 'dome',
    name: 'Ceiling dome light',
    ip: '192.168.1.104',
    mac: 'a8:bb:50:9c:1d:44',
    cls: 'RGB',
    icon: 'lamp-ceiling',
    on: true,
    brightness: 70,
    kelvin: 2450,
    hue: 28,
    sat: .9,
    rgb: [255, 176, 32],
    sceneId: 6,
    speed: 150
  }, {
    id: 'floor',
    name: 'Corner floor lamp',
    ip: '192.168.1.107',
    mac: 'a8:bb:50:9c:22:0e',
    cls: 'RGB',
    icon: 'lamp-desk',
    on: true,
    brightness: 45,
    kelvin: 2700,
    hue: 12,
    sat: .8,
    rgb: [255, 120, 60],
    sceneId: 29,
    speed: 120
  }, {
    id: 'strip',
    name: 'Shelf strip',
    ip: '192.168.1.111',
    mac: 'a8:bb:50:a1:04:c2',
    cls: 'Tunable White',
    icon: 'waves-horizontal',
    on: false,
    brightness: 60,
    kelvin: 4000,
    hue: 30,
    sat: 0,
    rgb: [255, 224, 188],
    sceneId: 12,
    speed: 100
  }]
}, {
  id: 'bedroom',
  name: 'Bedroom',
  icon: 'bed',
  lights: [{
    id: 'bedside',
    name: 'Bedside bulb',
    ip: '192.168.1.115',
    mac: 'a8:bb:50:b3:71:9a',
    cls: 'RGB',
    icon: 'lightbulb',
    on: false,
    brightness: 30,
    kelvin: 2200,
    hue: 20,
    sat: .95,
    rgb: [255, 140, 40],
    sceneId: 10,
    speed: 90
  }, {
    id: 'hall',
    name: 'Hallway',
    ip: '192.168.1.118',
    mac: 'a8:bb:50:b3:88:11',
    cls: 'Dimmable White',
    icon: 'lightbulb',
    on: false,
    brightness: 50,
    kelvin: 2700,
    hue: 30,
    sat: 0,
    rgb: [255, 224, 188],
    sceneId: 11,
    speed: 100,
    unreachable: true
  }]
}, {
  id: 'kitchen',
  name: 'Kitchen',
  icon: 'utensils-crossed',
  lights: [{
    id: 'counter',
    name: 'Counter downlight',
    ip: '192.168.1.121',
    mac: 'a8:bb:50:c4:19:30',
    cls: 'Tunable White',
    icon: 'lamp-ceiling',
    on: true,
    brightness: 90,
    kelvin: 5000,
    hue: 30,
    sat: 0,
    rgb: [242, 246, 255],
    sceneId: 15,
    speed: 100
  }]
}];
function Inspector({
  light,
  act
}) {
  const [mode, setMode] = React.useState('white');
  const scene = SCENE_GRADIENTS[light.sceneId];
  const modes = [{
    value: 'white',
    label: 'White',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "sun",
      size: 15
    })
  }];
  if (light.cls === 'RGB') modes.push({
    value: 'colour',
    label: 'Colour',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "palette",
      size: 15
    })
  });
  modes.push({
    value: 'scene',
    label: 'Scene',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "sparkles",
      size: 15
    })
  });
  return /*#__PURE__*/React.createElement("div", {
    className: "inspector"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-display)',
      fontSize: 26,
      fontWeight: 700,
      letterSpacing: '.015em',
      lineHeight: 1.08
    }
  }, light.name), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 4,
      fontFamily: 'var(--font-mono)',
      fontSize: 11.5,
      color: 'var(--text-tertiary)'
    }
  }, light.ip, " \xB7 ", light.cls)), /*#__PURE__*/React.createElement(Badge, {
    tone: light.unreachable ? 'danger' : 'online',
    dot: true
  }, light.unreachable ? 'No reply' : 'Live')), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      padding: '4px 0'
    }
  }, /*#__PURE__*/React.createElement(Dial, {
    size: 176,
    value: light.brightness,
    min: 10,
    max: 100,
    label: "Brightness",
    onChange: v => act.brightness(light.id, v)
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(PowerKey, {
    size: "md",
    on: light.on,
    onChange: v => act.power(light.id, v)
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'grid',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "zap",
      size: 14
    }),
    label: "Draw",
    value: light.on ? Math.round(light.brightness * 0.26) : 0,
    unit: "W/h"
  }), /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "thermometer",
      size: 14
    }),
    label: "Kelvin",
    value: light.kelvin,
    unit: "K",
    tone: "accent"
  }))), /*#__PURE__*/React.createElement(SegmentedControl, {
    fullWidth: true,
    size: "sm",
    value: mode,
    onChange: setMode,
    items: modes
  }), mode === 'white' && /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "16px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 20
    }
  }, /*#__PURE__*/React.createElement(Slider, {
    label: "Brightness",
    min: 10,
    max: 100,
    value: light.brightness,
    readout: `${Math.round(light.brightness)}%`,
    onChange: v => act.brightness(light.id, v)
  }), /*#__PURE__*/React.createElement(Slider, {
    label: "Colour temp.",
    fill: "kelvin",
    min: 2200,
    max: 6500,
    step: 50,
    value: light.kelvin,
    readout: `${light.kelvin}K`,
    onChange: v => act.set(light.id, {
      kelvin: v
    })
  })), mode === 'colour' && /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "16px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(ColorWheel, {
    size: 216,
    hue: light.hue,
    saturation: light.sat,
    onChange: c => act.set(light.id, {
      hue: c.h,
      sat: c.s,
      rgb: c.rgb
    })
  }), /*#__PURE__*/React.createElement(Readout, {
    label: "RGB",
    value: light.rgb.join(', '),
    size: "sm",
    mono: true,
    align: "center"
  })), mode === 'scene' && /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "16px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexWrap: 'wrap',
      gap: 8
    }
  }, [6, 1, 3, 5, 16, 29].map(id => /*#__PURE__*/React.createElement(SceneTile, {
    key: id,
    size: "sm",
    sceneId: id,
    selected: light.sceneId === id,
    onClick: () => act.set(light.id, {
      sceneId: id
    })
  }))), /*#__PURE__*/React.createElement(Slider, {
    label: scene && scene.dynamic ? 'Speed' : 'Speed — static scene',
    fill: "speed",
    min: 10,
    max: 200,
    value: light.speed,
    readout: light.speed,
    disabled: !scene || !scene.dynamic,
    onChange: v => act.set(light.id, {
      speed: v
    })
  })), /*#__PURE__*/React.createElement(Panel, {
    variant: "flat",
    padding: "12px 14px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "caps"
  }, "Device"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 11.5,
      color: 'var(--text-tertiary)'
    }
  }, light.mac), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 11.5,
      color: 'var(--text-tertiary)'
    }
  }, "udp 38899 \xB7 fw 1.25.0")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    size: "sm",
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "refresh-cw",
      size: 14
    })
  }, "Reboot"), /*#__PURE__*/React.createElement(Button, {
    variant: "danger",
    size: "sm",
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "trash",
      size: 14
    })
  }, "Forget")));
}
function App() {
  const [rooms, setRooms] = React.useState(ROOMS);
  const [view, setView] = React.useState('living');
  const [selected, setSelected] = React.useState('dome');
  const [sheet, setSheet] = React.useState(false);
  const [found, setFound] = React.useState([]);
  const [scanning, setScanning] = React.useState(false);
  const [swept, setSwept] = React.useState(0);
  const {
    toasts,
    push,
    update,
    dismiss
  } = useToastQueue();
  const scan = () => {
    setScanning(true);
    setSwept(0);
    setFound([]);
    const tick = setInterval(() => setSwept(s => Math.min(254, s + 34)), 190);
    setTimeout(() => {
      clearInterval(tick);
      setScanning(false);
      setSwept(254);
      setFound([{
        ip: '192.168.1.126',
        name: 'WiZ RGBW Tunable',
        cls: 'RGB'
      }, {
        ip: '192.168.1.131',
        name: 'WiZ Dimmable',
        cls: 'Dimmable White'
      }, {
        ip: '192.168.1.140',
        name: 'WiZ Smart Plug',
        cls: 'Socket'
      }]);
      push({
        tone: 'success',
        title: '3 lights answered',
        body: 'Swept 192.168.1.0/24'
      });
    }, 1600);
  };
  const all = rooms.flatMap(r => r.lights);
  const mapLight = (id, fn) => setRooms(rs => rs.map(r => ({
    ...r,
    lights: r.lights.map(l => l.id === id ? fn(l) : l)
  })));
  const act = {
    power: (id, on) => mapLight(id, l => ({
      ...l,
      on
    })),
    brightness: (id, brightness) => mapLight(id, l => ({
      ...l,
      brightness,
      on: true
    })),
    set: (id, patch) => mapLight(id, l => ({
      ...l,
      ...patch
    })),
    roomPower: (roomId, on) => setRooms(rs => rs.map(r => r.id === roomId ? {
      ...r,
      lights: r.lights.map(l => l.unreachable ? l : {
        ...l,
        on
      })
    } : r))
  };
  const room = rooms.find(r => r.id === view);
  const light = all.find(l => l.id === selected) || all[0];
  const onCount = all.filter(l => l.on).length;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Sidebar, {
    value: view,
    onChange: setView,
    brand: /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: 'var(--font-display)',
        fontSize: 30,
        fontWeight: 900,
        letterSpacing: '.02em',
        lineHeight: 1
      }
    }, "WIZCTL"), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 4,
        fontSize: 12.5,
        color: 'var(--text-tertiary)'
      }
    }, "Kaverappa House")),
    sections: [{
      title: 'Rooms',
      items: rooms.map(r => ({
        value: r.id,
        label: r.name,
        icon: /*#__PURE__*/React.createElement(Icon, {
          name: r.icon,
          size: 18
        }),
        meta: String(r.lights.length)
      }))
    }, {
      title: 'House',
      items: [{
        value: 'all',
        label: 'All lights',
        icon: /*#__PURE__*/React.createElement(Icon, {
          name: "layout-grid",
          size: 18
        }),
        meta: String(all.length)
      }, {
        value: 'scenes',
        label: 'Scenes',
        icon: /*#__PURE__*/React.createElement(Icon, {
          name: "sparkles",
          size: 18
        }),
        meta: '36'
      }, {
        value: 'discover',
        label: 'Discovery',
        icon: /*#__PURE__*/React.createElement(Icon, {
          name: "radio",
          size: 18
        })
      }]
    }],
    footer: /*#__PURE__*/React.createElement(Panel, {
      variant: "inset",
      padding: "10px 12px",
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 9
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "terminal",
      size: 15,
      style: {
        color: 'var(--amber-400)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: 'var(--font-mono)',
        fontSize: 11,
        color: 'var(--text-tertiary)'
      }
    }, onCount, " on \xB7 udp 38899"))
  }), /*#__PURE__*/React.createElement("div", {
    className: "main"
  }, view === 'discover' ? scanning ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: "Discovery",
    subtitle: "Local network"
  }), /*#__PURE__*/React.createElement(StatusBanner, {
    status: "loading",
    title: "Sweeping 192.168.1.0/24",
    body: `${swept} of 254 addresses`
  }), /*#__PURE__*/React.createElement(FilamentBar, {
    label: "Discovering",
    value: Math.round(swept / 254 * 100)
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gap: 12
    }
  }, [0, 1, 2].map(i => /*#__PURE__*/React.createElement(Panel, {
    key: i,
    padding: "12px 14px"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 13,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Skeleton, {
    circle: true,
    height: 40
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      gap: 7
    }
  }, /*#__PURE__*/React.createElement(Skeleton, {
    width: ['42%', '30%', '48%'][i],
    height: 14
  }), /*#__PURE__*/React.createElement(Skeleton, {
    width: ['22%', '26%', '19%'][i],
    height: 10
  }))))))) : found.length === 0 ? /*#__PURE__*/React.createElement(EmptyState, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "radio",
      size: 30
    }),
    title: "Nothing found yet",
    body: "Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time.",
    action: /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "radio",
        size: 16
      }),
      onClick: scan
    }, "Scan subnet")
  }) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: "Discovery",
    subtitle: "Swept 192.168.1.0/24",
    trailing: /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: "ghost",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "refresh-cw",
        size: 14
      }),
      onClick: scan
    }, "Rescan")
  }), /*#__PURE__*/React.createElement(StatusBanner, {
    status: "success",
    title: `${found.length} lights answered`,
    body: "Swept 192.168.1.0/24",
    action: /*#__PURE__*/React.createElement(Badge, {
      tone: "online",
      dot: true
    }, "Live")
  }), found.map(f => /*#__PURE__*/React.createElement(ListRow, {
    key: f.ip,
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "lightbulb"
    }),
    title: f.name,
    meta: `${f.ip} · ${f.cls}`,
    trailing: /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: "primary",
      onClick: () => {
        const id = push({
          tone: 'loading',
          title: 'Saving ' + f.name
        });
        setTimeout(() => update(id, {
          tone: 'success',
          title: 'Light saved',
          body: f.ip + ' added to this home'
        }), 900);
      }
    }, "Save")
  }))) : view === 'scenes' ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: "Scenes",
    subtitle: "All 36 built-in WiZ scenes"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexWrap: 'wrap',
      gap: 10
    }
  }, Object.keys(SCENE_GRADIENTS).map(Number).map(id => /*#__PURE__*/React.createElement(SceneTile, {
    key: id,
    sceneId: id,
    selected: light.sceneId === id,
    onClick: () => act.set(light.id, {
      sceneId: id
    })
  })))) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: view === 'all' ? 'All lights' : room.name,
    subtitle: view === 'all' ? `${all.length} lights · ${onCount} on` : `${room.lights.length} lights`,
    trailing: /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 12
      }
    }, /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: "ghost",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "house-plus",
        size: 15
      }),
      onClick: () => setSheet(true)
    }, "Add room"), view !== 'all' && /*#__PURE__*/React.createElement(Toggle, {
      checked: room.lights.some(l => l.on),
      onChange: v => act.roomPower(room.id, v),
      label: room.name
    }))
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(3,minmax(0,1fr))',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "lightbulb",
      size: 14
    }),
    label: "Lights on",
    value: `${onCount} / ${all.length}`,
    tone: "accent"
  }), /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "zap",
      size: 14
    }),
    label: "Draw now",
    value: all.filter(l => l.on).reduce((a, l) => a + Math.round(l.brightness * 0.26), 0),
    unit: "W/h"
  }), /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "wifi",
      size: 14
    }),
    label: "Unreachable",
    value: all.filter(l => l.unreachable).length
  })), all.some(l => l.unreachable) && /*#__PURE__*/React.createElement(StatusBanner, {
    status: "error",
    title: "One light did not answer",
    body: "Hallway may be switched off at the wall, or the router changed its address.",
    action: /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      size: "sm",
      onClick: () => setView('discover')
    }, "Rescan")
  }), /*#__PURE__*/React.createElement("span", {
    className: "caps"
  }, "Lights"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fill,minmax(340px,1fr))',
      gap: 14
    }
  }, (view === 'all' ? all : room.lights).map(l => /*#__PURE__*/React.createElement("div", {
    key: l.id,
    onClick: e => {
      if (!e.target.closest('[role="switch"],[role="slider"]')) setSelected(l.id);
    },
    style: {
      borderRadius: 'var(--radius-4)',
      boxShadow: selected === l.id ? '0 0 0 1.5px var(--amber-500)' : 'none'
    }
  }, /*#__PURE__*/React.createElement(LightCard, {
    name: l.name,
    meta: `${l.ip} · ${l.cls}`,
    icon: l.icon,
    on: l.on,
    unreachable: l.unreachable,
    brightnessControl: "meter",
    onToggle: v => act.power(l.id, v),
    brightness: l.brightness
  })))))), /*#__PURE__*/React.createElement(Inspector, {
    key: light.id,
    light: light,
    act: act
  }), /*#__PURE__*/React.createElement(ToastStack, {
    toasts: toasts,
    onDismiss: dismiss,
    style: {
      left: 'auto',
      right: 'var(--space-8)',
      width: 340,
      bottom: 'var(--space-8)'
    }
  }), /*#__PURE__*/React.createElement(Sheet, {
    open: sheet,
    onClose: () => setSheet(false),
    placement: "center",
    title: "Add a room",
    footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      onClick: () => setSheet(false)
    }, "Cancel"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true,
      onClick: () => {
        setSheet(false);
        push({
          tone: 'success',
          title: 'Room saved'
        });
      }
    }, "Save room"))
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      color: 'var(--text-tertiary)'
    }
  }, "Rooms are stored in this home's config file on this machine. Nothing is uploaded.")));
}
const mount = document.getElementById('root');
if (mount) ReactDOM.createRoot(mount).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/desktop_app/desktop.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile_app/app.jsx
try { (() => {
const {
  Feedback,
  Icon,
  Button,
  Toggle,
  Sheet,
  TabBar,
  Panel,
  ToastStack
} = window.WizCtlDesignSystem_2a6b25 || {};
const NOOP_QUEUE = {
  toasts: [],
  push: () => {},
  update: () => {},
  dismiss: () => {}
};
function useToastQueue(opts) {
  const ns = window.WizCtlDesignSystem_2a6b25 || {};
  return ns.Toasts && ns.Toasts.use ? ns.Toasts.use(opts) : NOOP_QUEUE;
}
const INITIAL = {
  homeName: 'Kaverappa House',
  view: 'home',
  roomId: 'living',
  lightId: 'dome',
  sceneTarget: 'all',
  activeScene: 6,
  feedback: true,
  found: [],
  scanning: false,
  swept: 0,
  rooms: [{
    id: 'living',
    name: 'Living Room',
    icon: 'sofa',
    lights: [{
      id: 'dome',
      name: 'Ceiling dome light',
      ip: '192.168.1.104',
      cls: 'RGB',
      icon: 'lamp-ceiling',
      on: true,
      brightness: 70,
      kelvin: 2450,
      hue: 28,
      sat: .9,
      rgb: [255, 176, 32],
      sceneId: 6,
      speed: 150
    }, {
      id: 'floor',
      name: 'Corner floor lamp',
      ip: '192.168.1.107',
      cls: 'RGB',
      icon: 'lamp-desk',
      on: true,
      brightness: 45,
      kelvin: 2700,
      hue: 12,
      sat: .8,
      rgb: [255, 120, 60],
      sceneId: 29,
      speed: 120
    }, {
      id: 'strip',
      name: 'Shelf strip',
      ip: '192.168.1.111',
      cls: 'Tunable White',
      icon: 'waves-horizontal',
      on: false,
      brightness: 60,
      kelvin: 4000,
      hue: 30,
      sat: 0,
      rgb: [255, 224, 188],
      sceneId: 12,
      speed: 100
    }]
  }, {
    id: 'bedroom',
    name: 'Bedroom',
    icon: 'bed',
    lights: [{
      id: 'bedside',
      name: 'Bedside bulb',
      ip: '192.168.1.115',
      cls: 'RGB',
      icon: 'lightbulb',
      on: false,
      brightness: 30,
      kelvin: 2200,
      hue: 20,
      sat: .95,
      rgb: [255, 140, 40],
      sceneId: 10,
      speed: 90
    }, {
      id: 'hall',
      name: 'Hallway',
      ip: '192.168.1.118',
      cls: 'Dimmable White',
      icon: 'lightbulb',
      on: false,
      brightness: 50,
      kelvin: 2700,
      hue: 30,
      sat: 0,
      rgb: [255, 224, 188],
      sceneId: 11,
      speed: 100,
      unreachable: true
    }]
  }, {
    id: 'kitchen',
    name: 'Kitchen',
    icon: 'utensils-crossed',
    lights: [{
      id: 'counter',
      name: 'Counter downlight',
      ip: '192.168.1.121',
      cls: 'Tunable White',
      icon: 'lamp-ceiling',
      on: true,
      brightness: 90,
      kelvin: 5000,
      hue: 30,
      sat: 0,
      rgb: [242, 246, 255],
      sceneId: 15,
      speed: 100
    }]
  }]
};
const DISCOVERED = [{
  ip: '192.168.1.126',
  name: 'WiZ RGBW Tunable',
  cls: 'RGB'
}, {
  ip: '192.168.1.131',
  name: 'WiZ Dimmable',
  cls: 'Dimmable White'
}, {
  ip: '192.168.1.140',
  name: 'WiZ Smart Plug',
  cls: 'Socket'
}];
function App() {
  const [state, setState] = React.useState(INITIAL);
  const {
    toasts,
    push,
    update,
    dismiss
  } = useToastQueue();
  const [sheet, setSheet] = React.useState(null);
  const [roomDraft, setRoomDraft] = React.useState({
    name: '',
    icon: 'sofa'
  });
  const mapLight = (id, fn) => setState(s => ({
    ...s,
    rooms: s.rooms.map(r => ({
      ...r,
      lights: r.lights.map(l => l.id === id ? fn(l) : l)
    }))
  }));
  const act = {
    power: (id, on) => mapLight(id, l => ({
      ...l,
      on
    })),
    brightness: (id, brightness) => mapLight(id, l => ({
      ...l,
      brightness,
      on: true
    })),
    set: (id, patch) => mapLight(id, l => ({
      ...l,
      ...patch
    })),
    roomPower: (roomId, on) => setState(s => ({
      ...s,
      rooms: s.rooms.map(r => r.id === roomId ? {
        ...r,
        lights: r.lights.map(l => l.unreachable ? l : {
          ...l,
          on
        })
      } : r)
    })),
    allPower: on => setState(s => ({
      ...s,
      rooms: s.rooms.map(r => ({
        ...r,
        lights: r.lights.map(l => l.unreachable ? l : {
          ...l,
          on
        })
      }))
    })),
    allOff: () => act.allPower(false),
    setSceneTarget: v => setState(s => ({
      ...s,
      sceneTarget: v
    })),
    setFeedback: v => {
      Feedback.setEnabled(v);
      setState(s => ({
        ...s,
        feedback: v
      }));
    },
    applyScene: id => setState(s => ({
      ...s,
      activeScene: id,
      rooms: s.rooms.map(r => s.sceneTarget === 'all' || s.sceneTarget === r.id ? {
        ...r,
        lights: r.lights.map(l => l.unreachable ? l : {
          ...l,
          sceneId: id,
          on: true
        })
      } : r)
    })),
    scan: () => {
      setState(s => ({
        ...s,
        scanning: true,
        swept: 0,
        found: []
      }));
      const tick = setInterval(() => setState(s => ({
        ...s,
        swept: Math.min(254, s.swept + 34)
      })), 190);
      setTimeout(() => {
        clearInterval(tick);
        setState(s => ({
          ...s,
          scanning: false,
          swept: 254,
          found: DISCOVERED.map(d => ({
            ...d,
            saved: false
          }))
        }));
        push({
          tone: 'success',
          title: '3 lights answered',
          body: 'Swept 192.168.1.0/24'
        });
      }, 1500);
    },
    save: ip => {
      const light = DISCOVERED.find(d => d.ip === ip);
      setState(s => ({
        ...s,
        found: s.found.map(f => f.ip === ip ? {
          ...f,
          saved: true
        } : f)
      }));
      const id = push({
        tone: 'loading',
        title: 'Saving ' + (light ? light.name : ip)
      });
      setTimeout(() => update(id, {
        tone: 'success',
        title: 'Light saved',
        body: ip + ' added to this home'
      }), 900);
    },
    addRoom: () => {
      const name = roomDraft.name.trim() || 'New room';
      setState(s => ({
        ...s,
        rooms: [...s.rooms, {
          id: 'r' + Date.now(),
          name,
          icon: roomDraft.icon,
          lights: []
        }]
      }));
      setRoomDraft({
        name: '',
        icon: 'sofa'
      });
      setSheet(null);
      push({
        tone: 'success',
        title: 'Room saved',
        body: name + ' is empty — discover lights for it'
      });
    }
  };
  const go = (view, patch = {}) => {
    if (view === 'addRoom') return setSheet('addRoom');
    if (view === 'discover') return setState(s => ({
      ...s,
      view: 'discover'
    }));
    setState(s => ({
      ...s,
      view,
      ...patch
    }));
  };
  const tabs = [{
    value: 'home',
    label: 'Home',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "house"
    })
  }, {
    value: 'room',
    label: 'Rooms',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "layout-grid"
    })
  }, {
    value: 'scenes',
    label: 'Scenes',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "sparkles"
    })
  }, {
    value: 'settings',
    label: 'Settings',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "sliders-horizontal"
    })
  }];
  const Screen = {
    home: HomeScreen,
    room: RoomScreen,
    light: LightScreen,
    scenes: ScenesScreen,
    settings: SettingsScreen,
    discover: DiscoverScreen
  }[state.view];
  const tabValue = state.view === 'light' ? 'room' : state.view;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(StatusBar, null), /*#__PURE__*/React.createElement("div", {
    className: "body"
  }, /*#__PURE__*/React.createElement(Screen, {
    state: state,
    act: act,
    go: go
  })), state.view !== 'discover' && /*#__PURE__*/React.createElement("div", {
    className: "dock"
  }, /*#__PURE__*/React.createElement(TabBar, {
    value: tabValue,
    onChange: v => go(v),
    items: tabs
  })), /*#__PURE__*/React.createElement(ToastStack, {
    toasts: toasts,
    onDismiss: dismiss,
    style: {
      bottom: 'calc(var(--tabbar-height) + 28px)'
    }
  }), /*#__PURE__*/React.createElement(Sheet, {
    open: sheet === 'addRoom',
    onClose: () => setSheet(null),
    title: "Add a room",
    footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      onClick: () => setSheet(null)
    }, "Cancel"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      fullWidth: true,
      onClick: act.addRoom
    }, "Save room"))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "caps"
  }, "Room name"), /*#__PURE__*/React.createElement("input", {
    value: roomDraft.name,
    onChange: e => setRoomDraft(d => ({
      ...d,
      name: e.target.value
    })),
    placeholder: "Study",
    style: {
      height: 48,
      padding: '0 14px',
      borderRadius: 'var(--radius-3)',
      border: 0,
      background: 'var(--char-1000)',
      boxShadow: 'var(--elev-well)',
      color: 'var(--text-primary)',
      fontFamily: 'var(--font-ui)',
      fontSize: 16
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "caps"
  }, "Glyph"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10
    }
  }, ['sofa', 'bed', 'utensils-crossed', 'bath', 'lamp-desk', 'trees'].map(n => /*#__PURE__*/React.createElement("button", {
    key: n,
    type: "button",
    onClick: () => setRoomDraft(d => ({
      ...d,
      icon: n
    })),
    style: {
      width: 48,
      height: 48,
      display: 'grid',
      placeItems: 'center',
      border: 0,
      borderRadius: 'var(--radius-2)',
      background: roomDraft.icon === n ? 'linear-gradient(180deg,var(--amber-400),var(--amber-600))' : 'linear-gradient(180deg,var(--surface-key),var(--surface-raised))',
      color: roomDraft.icon === n ? 'var(--text-on-accent)' : 'var(--text-tertiary)',
      boxShadow: 'var(--elev-raised)',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: n,
    size: 20
  }))))))));
}
const mount = document.getElementById('root');
if (mount) ReactDOM.createRoot(mount).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile_app/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/mobile_app/screens.jsx
try { (() => {
const DS = window.WizCtlDesignSystem_2a6b25 || {};
const {
  Feedback,
  FilamentBar,
  Skeleton,
  StatusBanner,
  Icon,
  Button,
  IconButton,
  Panel,
  Badge,
  Toggle,
  SegmentedControl,
  ListRow,
  PowerKey,
  Dial,
  Slider,
  ColorWheel,
  SceneTile,
  SCENE_GRADIENTS,
  Readout,
  Stepper,
  TabBar,
  TopBar,
  Sheet,
  LightCard,
  RoomCard,
  StatTile,
  EmptyState
} = DS;
const StatusBar = () => /*#__PURE__*/React.createElement("div", {
  className: "status"
}, /*#__PURE__*/React.createElement("span", null, "9:41"), /*#__PURE__*/React.createElement("span", {
  style: {
    display: 'flex',
    gap: 6,
    alignItems: 'center'
  }
}, /*#__PURE__*/React.createElement(Icon, {
  name: "wifi",
  size: 15
}), /*#__PURE__*/React.createElement(Icon, {
  name: "zap",
  size: 15
})));

/* ---------- Home: home name, house summary, room grid ---------- */
function HomeScreen({
  state,
  act,
  go
}) {
  const lights = state.rooms.flatMap(r => r.lights);
  const onCount = lights.filter(l => l.on && !l.unreachable).length;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: state.homeName,
    subtitle: `${state.rooms.length} rooms · ${lights.length} lights`,
    trailing: /*#__PURE__*/React.createElement(IconButton, {
      label: "Discover lights",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "radio"
      }),
      onClick: () => go('discover')
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "lightbulb",
      size: 14
    }),
    label: "Lights on",
    value: `${onCount} / ${lights.length}`,
    tone: onCount ? 'accent' : 'default'
  }), /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "zap",
      size: 14
    }),
    label: "Draw now",
    value: onCount * 6,
    unit: "W/h"
  })), /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "14px 16px",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "caps",
    style: {
      flex: 1
    }
  }, "All lights"), /*#__PURE__*/React.createElement(Button, {
    size: "sm",
    variant: "ghost",
    onClick: () => act.allOff()
  }, "Off"), /*#__PURE__*/React.createElement(Toggle, {
    checked: onCount > 0,
    onChange: v => act.allPower(v),
    label: "All lights"
  })), /*#__PURE__*/React.createElement("span", {
    className: "caps"
  }, "Rooms"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12
    }
  }, state.rooms.map(r => /*#__PURE__*/React.createElement(RoomCard, {
    key: r.id,
    name: r.name,
    icon: r.icon,
    lightCount: r.lights.length,
    onCount: r.lights.filter(l => l.on).length,
    on: r.lights.some(l => l.on),
    onToggle: v => act.roomPower(r.id, v),
    onOpen: () => go('room', {
      roomId: r.id
    })
  }))), /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "house-plus",
      size: 16
    }),
    onClick: () => go('addRoom')
  }, "Add room"));
}

/* ---------- Room: lights in one room ---------- */
function RoomScreen({
  state,
  act,
  go
}) {
  const room = state.rooms.find(r => r.id === state.roomId) || state.rooms[0];
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: room.name,
    subtitle: `${room.lights.length} lights`,
    leading: /*#__PURE__*/React.createElement(IconButton, {
      label: "Back",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "chevron-left"
      }),
      onClick: () => go('home')
    }),
    trailing: /*#__PURE__*/React.createElement(Toggle, {
      checked: room.lights.some(l => l.on),
      onChange: v => act.roomPower(room.id, v),
      label: room.name
    })
  }), /*#__PURE__*/React.createElement(SegmentedControl, {
    fullWidth: true,
    value: room.id,
    onChange: id => go('room', {
      roomId: id
    }),
    items: state.rooms.map(r => ({
      value: r.id,
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: r.icon,
        size: 17
      })
    }))
  }), room.lights.map(l => /*#__PURE__*/React.createElement("div", {
    key: l.id,
    onClick: e => {
      if (e.target.closest('[role="switch"],[role="slider"]')) return;
      go('light', {
        lightId: l.id,
        roomId: room.id
      });
    }
  }, /*#__PURE__*/React.createElement(LightCard, {
    name: l.name,
    meta: `${l.ip} · ${l.cls}`,
    icon: l.icon,
    on: l.on,
    unreachable: l.unreachable,
    onToggle: v => act.power(l.id, v),
    brightness: l.brightness,
    onBrightness: v => act.brightness(l.id, v)
  }))));
}

/* ---------- Light detail: power key, dial, mode, scenes ---------- */
function LightScreen({
  state,
  act,
  go
}) {
  const room = state.rooms.find(r => r.id === state.roomId) || state.rooms[0];
  const light = room.lights.find(l => l.id === state.lightId) || room.lights[0];
  const [mode, setMode] = React.useState('white');
  const modes = [{
    value: 'white',
    label: 'White',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "sun",
      size: 15
    })
  }];
  if (light.cls === 'RGB') modes.push({
    value: 'colour',
    label: 'Colour',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "palette",
      size: 15
    })
  });
  modes.push({
    value: 'scene',
    label: 'Scene',
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "sparkles",
      size: 15
    })
  });
  const scene = SCENE_GRADIENTS[light.sceneId];
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: light.name,
    subtitle: `${room.name} · ${light.cls}`,
    leading: /*#__PURE__*/React.createElement(IconButton, {
      label: "Back",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "chevron-left"
      }),
      onClick: () => go('room', {
        roomId: room.id
      })
    }),
    trailing: /*#__PURE__*/React.createElement(Badge, {
      tone: light.unreachable ? 'danger' : 'online',
      dot: true
    }, light.unreachable ? 'No reply' : 'Live')
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      padding: '6px 0 2px'
    }
  }, /*#__PURE__*/React.createElement(PowerKey, {
    on: light.on,
    onChange: v => act.power(light.id, v)
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "zap",
      size: 14
    }),
    label: "Consumption",
    value: light.on ? Math.round(light.brightness * 0.26) : 0,
    unit: "W/h"
  }), /*#__PURE__*/React.createElement(StatTile, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "gauge",
      size: 14
    }),
    label: "Intensity",
    value: Math.round(light.brightness),
    unit: "%",
    tone: "accent"
  })), /*#__PURE__*/React.createElement(SegmentedControl, {
    fullWidth: true,
    value: mode,
    onChange: setMode,
    items: modes
  }), mode === 'white' && /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "18px 16px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 22
    }
  }, /*#__PURE__*/React.createElement(Slider, {
    label: "Brightness",
    fill: "brightness",
    min: 10,
    max: 100,
    value: light.brightness,
    readout: `${Math.round(light.brightness)}%`,
    onChange: v => act.brightness(light.id, v)
  }), /*#__PURE__*/React.createElement(Slider, {
    label: "Colour temp.",
    fill: "kelvin",
    min: 2200,
    max: 6500,
    step: 50,
    value: light.kelvin,
    readout: `${light.kelvin}K`,
    onChange: v => act.set(light.id, {
      kelvin: v
    })
  })), mode === 'colour' && /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "18px 16px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 20,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(ColorWheel, {
    size: 228,
    hue: light.hue,
    saturation: light.sat,
    onChange: c => act.set(light.id, {
      hue: c.h,
      sat: c.s,
      rgb: c.rgb
    })
  }), /*#__PURE__*/React.createElement(Readout, {
    label: "RGB",
    value: light.rgb.join(', '),
    size: "sm",
    mono: true,
    align: "center"
  }), /*#__PURE__*/React.createElement(Slider, {
    style: {
      alignSelf: 'stretch'
    },
    label: "Brightness",
    min: 10,
    max: 100,
    value: light.brightness,
    readout: `${Math.round(light.brightness)}%`,
    onChange: v => act.brightness(light.id, v)
  })), mode === 'scene' && /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "16px",
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexWrap: 'wrap',
      gap: 8
    }
  }, [6, 1, 3, 5, 16, 29, 12, 26].map(id => /*#__PURE__*/React.createElement(SceneTile, {
    key: id,
    size: "sm",
    sceneId: id,
    selected: light.sceneId === id,
    onClick: () => act.set(light.id, {
      sceneId: id
    })
  }))), /*#__PURE__*/React.createElement(Slider, {
    label: scene && scene.dynamic ? 'Speed' : 'Speed — static scene',
    fill: "speed",
    min: 10,
    max: 200,
    value: light.speed,
    readout: light.speed,
    disabled: !scene || !scene.dynamic,
    onChange: v => act.set(light.id, {
      speed: v
    })
  })));
}

/* ---------- Scenes: apply a scene to a room ---------- */
function ScenesScreen({
  state,
  act
}) {
  const ids = Object.keys(SCENE_GRADIENTS).map(Number);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: "Scenes",
    subtitle: "All 36 built-in WiZ scenes"
  }), /*#__PURE__*/React.createElement(SegmentedControl, {
    fullWidth: true,
    value: state.sceneTarget,
    onChange: v => act.setSceneTarget(v),
    items: [{
      value: 'all',
      label: 'All'
    }, ...state.rooms.slice(0, 3).map(r => ({
      value: r.id,
      label: r.name.split(' ')[0]
    }))]
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexWrap: 'wrap',
      gap: 8
    }
  }, ids.map(id => /*#__PURE__*/React.createElement(SceneTile, {
    key: id,
    size: "sm",
    sceneId: id,
    selected: state.activeScene === id,
    onClick: () => act.applyScene(id)
  }))), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      color: 'var(--text-tertiary)',
      fontSize: 13
    }
  }, "A cyan pip marks a dynamic scene. Those accept a speed from 10 to 200."));
}

/* ---------- Settings ---------- */
function SettingsScreen({
  state
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: "Settings",
    subtitle: "This home lives on this device"
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "house"
    }),
    title: state.homeName,
    meta: "Home name",
    trailing: /*#__PURE__*/React.createElement(Icon, {
      name: "pencil",
      size: 17
    }),
    onClick: () => {}
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "radio"
    }),
    title: "Discovery",
    meta: "Broadcast, then unicast sweep",
    trailing: /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 18
    }),
    onClick: () => {}
  }), state.rooms.some(r => r.lights.some(l => l.unreachable)) && /*#__PURE__*/React.createElement(StatusBanner, {
    status: "error",
    title: "One light did not answer",
    body: "Hallway may be switched off at the wall, or the router changed its address.",
    action: /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      size: "sm",
      onClick: () => go('discover')
    }, "Rescan")
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "terminal"
    }),
    title: "CLI parity",
    meta: "wizctl on -t \"Living Room\"",
    trailing: /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 18
    }),
    onClick: () => {}
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "refresh-cw"
    }),
    title: "Re-scan on launch",
    trailing: /*#__PURE__*/React.createElement(Toggle, {
      size: "sm",
      checked: true,
      onChange: () => {}
    })
  }), /*#__PURE__*/React.createElement(ListRow, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "zap"
    }),
    title: "Sound & haptics",
    meta: "Clicks and vibration on every control",
    trailing: /*#__PURE__*/React.createElement(Toggle, {
      size: "sm",
      checked: state.feedback,
      onChange: act.setFeedback
    })
  }), /*#__PURE__*/React.createElement(Panel, {
    variant: "inset",
    padding: "14px 16px"
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      color: 'var(--text-tertiary)',
      fontSize: 13
    }
  }, "No account, no cloud. Lights are reached over UDP on port 38899 on your own network.")));
}

/* ---------- Discovery ---------- */
function DiscoverScreen({
  state,
  act,
  go
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(TopBar, {
    title: "Discover lights",
    subtitle: "Local network",
    leading: /*#__PURE__*/React.createElement(IconButton, {
      label: "Back",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "chevron-left"
      }),
      onClick: () => go('home')
    })
  }), state.scanning ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(StatusBanner, {
    status: "loading",
    title: "Sweeping 192.168.1.0/24",
    body: `${state.swept} of 254 addresses`
  }), /*#__PURE__*/React.createElement(FilamentBar, {
    label: "Discovering",
    value: Math.round(state.swept / 254 * 100)
  }), [0, 1, 2].map(i => /*#__PURE__*/React.createElement(Panel, {
    key: i,
    padding: "12px 14px"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 13,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Skeleton, {
    circle: true,
    height: 40
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      gap: 7
    }
  }, /*#__PURE__*/React.createElement(Skeleton, {
    width: ['56%', '44%', '62%'][i],
    height: 14
  }), /*#__PURE__*/React.createElement(Skeleton, {
    width: ['32%', '38%', '28%'][i],
    height: 10
  })))))) : state.found.length === 0 ? /*#__PURE__*/React.createElement(EmptyState, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "radio",
      size: 30
    }),
    title: "Nothing found yet",
    body: "Lights answer on your local network. Make sure they are powered on, then scan the subnet.",
    action: /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "radio",
        size: 16
      }),
      onClick: act.scan
    }, "Scan subnet")
  }) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(StatusBanner, {
    status: "success",
    title: `${state.found.length} lights answered`,
    body: "Swept 192.168.1.0/24",
    action: /*#__PURE__*/React.createElement(Badge, {
      tone: "online",
      dot: true
    }, "Live")
  }), state.found.map(f => /*#__PURE__*/React.createElement(ListRow, {
    key: f.ip,
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "lightbulb"
    }),
    title: f.name,
    meta: `${f.ip} · ${f.cls}`,
    trailing: /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: f.saved ? 'ghost' : 'primary',
      onClick: () => act.save(f.ip)
    }, f.saved ? 'Saved' : 'Save')
  })), /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "refresh-cw",
      size: 15
    }),
    onClick: act.scan
  }, "Scan again")));
}
Object.assign(window, {
  StatusBar,
  HomeScreen,
  RoomScreen,
  LightScreen,
  ScenesScreen,
  SettingsScreen,
  DiscoverScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/mobile_app/screens.jsx", error: String((e && e.message) || e) }); }

__ds_ns.ColorWheel = __ds_scope.ColorWheel;

__ds_ns.Dial = __ds_scope.Dial;

__ds_ns.PowerKey = __ds_scope.PowerKey;

__ds_ns.Readout = __ds_scope.Readout;

__ds_ns.SCENE_GRADIENTS = __ds_scope.SCENE_GRADIENTS;

__ds_ns.SceneTile = __ds_scope.SceneTile;

__ds_ns.SLIDER_FILLS = __ds_scope.SLIDER_FILLS;

__ds_ns.Slider = __ds_scope.Slider;

__ds_ns.Stepper = __ds_scope.Stepper;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.Panel = __ds_scope.Panel;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Toggle = __ds_scope.Toggle;

__ds_ns.Feedback = __ds_scope.Feedback;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.LightCard = __ds_scope.LightCard;

__ds_ns.RoomCard = __ds_scope.RoomCard;

__ds_ns.StatTile = __ds_scope.StatTile;

__ds_ns.FilamentBar = __ds_scope.FilamentBar;

__ds_ns.Skeleton = __ds_scope.Skeleton;

__ds_ns.Spinner = __ds_scope.Spinner;

__ds_ns.STATUS_TONES = __ds_scope.STATUS_TONES;

__ds_ns.StatusBanner = __ds_scope.StatusBanner;

__ds_ns.Toast = __ds_scope.Toast;

__ds_ns.ToastStack = __ds_scope.ToastStack;

__ds_ns.Toasts = __ds_scope.Toasts;

__ds_ns.Sheet = __ds_scope.Sheet;

__ds_ns.Sidebar = __ds_scope.Sidebar;

__ds_ns.TabBar = __ds_scope.TabBar;

__ds_ns.TopBar = __ds_scope.TopBar;

})();

