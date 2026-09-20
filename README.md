# wizctl_app

Control Philips WiZ lights on your local network. No account, no cloud —
lights are reached over UDP on port 38899 on your own network.

## Fonts

The app bundles four faces.

- **Big Shoulders Display** (display: headings, titles, readouts), **Hanken
  Grotesk** (UI) and **JetBrains Mono** (numerals and addresses) are under the
  [SIL Open Font License 1.1](https://openfontlicense.org). The licence texts
  ship as assets (`assets/fonts/OFL-*.txt`) and are registered with
  `LicenseRegistry` at start, so they appear on the app's licence page. The
  Big Shoulders files are static instances of Google Fonts' variable font at
  weights 600–900.
- **Neumatic Compressed** (the 64 px hero only, ExtraBold) is a commercial
  face. **To confirm before any store build:** the project owner must check
  that the licence held for it covers embedding in a distributed application
  on all five targets — Android, iOS, macOS, Linux and Windows — and obtain
  an app-embedding licence if it does not. Nothing here asserts what that
  licence permits.

## Platform notes

The app talks to the lights over UDP on the local network, and each platform
asks for that in its own way (spec §17). `test/platform/platform_config_test.dart`
reads the runner files and fails if any of this drifts.

- **iOS** declares `NSLocalNetworkUsageDescription` — "WizCtl finds and
  controls WiZ lights on your local network." — so the system prompt explains
  itself the first time discovery runs. No background modes: the app only
  talks to lights while it is on screen. The feedback clicks run through an
  ambient audio session (`lib/core/feedback/audio_session_config.dart`), so
  they mix with whatever is playing and go quiet with the mute switch.
- **macOS** is sandboxed, so both `DebugProfile.entitlements` and
  `Release.entitlements` carry `com.apple.security.network.client` and
  `com.apple.security.network.server`. Without the server entitlement the
  sandbox drops the replies the lights send back, and discovery finds
  nothing.
- **Android** asks for `INTERNET`. Nothing else: the traffic is UDP, so
  `usesCleartextTraffic` does not apply. **Caveat:** Android may drop the
  broadcast replies discovery listens for unless the app holds a
  `WifiManager.MulticastLock`, which is a platform-channel addition this app
  does not yet make. If broadcast discovery comes back empty on Android while
  a subnet scan finds the lights, the missing lock is the first suspect.
- **Desktop** (macOS, Windows, Linux) refuses to shrink below **720×560**,
  the narrowest window the medium layout fits in.
  `lib/core/platform/window_limits.dart` owns the two numbers; the three
  runners repeat them in Swift, C++ and C, each with a comment naming that
  file.
