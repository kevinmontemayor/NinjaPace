# Screenshot capture manifest

[Ecosystem overview](../README.md) · [Streaming HUD](README-Streaming-HUD.md)

These are captures of the current apps and browser HUD with synthetic workout data. They are not evidence of physical-device background delivery or a live broadcast. All files remain local until the repository is committed and uploaded.

## Shared fixture

| Metric | Value |
|---|---|
| Distance | 3.14 mi |
| Steps | 6,240 |
| Heart rate | 142 bpm |
| Elapsed | 00:28:10.00 (Watch displays 00:28:10) |
| Pace | 8:58 /mi |
| Active calories | 418 kcal |
| Goal | 5.00 mi |
| Progress | 63% |

Goal Complete changes distance to 5.00 mi and progress to 100%. Idle retains the completed session snapshot with `running=false`. Watch READY uses zero values. The iPhone goal image shows goal controls, not a completed workout.

## Captures

| Set | Completed files | Notes |
|---|---|---|
| iPhone | `welcome-warrior-selection.png`, `today-live.png`, `today-goal.png`, `training-schedule.png`, `history.png`, `workout-detail.png`, `awards.png`, `hud-customization.png`, `relay-setup-locked.png` | [iPhone images](images/iphone); iPhone 18 Pro Max, iOS 27 simulator. History, schedule, and awards use opt-in demo data. |
| Watch | `watch-ready.png`, `watch-live.png`, `watch-paused.png` | [Watch images](images/watch); Ultra 3 49 mm, watchOS 26 simulator. Rebuilt and recaptured after the metric-label update to `ET.⏱️`, `Pace 👟`, `HR ❤️`, `Cal.🔥`, and `Steps 👣`. |
| Mac | `mac-relay-offline.png`, `mac-relay-live.png`, `mac-hud-studio-follow-iphone.png`, `mac-hud-studio-local.png` | [Mac images](images/mac); Debug demo launch states, no real LAN address. |
| HUD states | `hud-idle-ninja.png`, `hud-live-ninja.png`, `hud-paused-ninja.png`, `hud-goal-ninja.png` | [HUD images](images/hud); same Ninja preset and telemetry where state permits. |
| HUD themes | `hud-live-ninja.png`, `hud-live-viking.png`, `hud-live-knight.png`, `hud-live-pirate.png`, `hud-live-cyborg.png`, `hud-live-spartan.png` | Preset values read from `AppTheme+HUDPreset.swift`. |
| Custom HUD | `hud-customized.png` | Matches the Mac identity edits: “ROAD TO FIVE” / “Every mile counts”. |
| OBS | `ninjapace-in-obs.png` | [Real OBS capture](images/hero/ninjapace-in-obs.png); existing stream-starting scene with demo LIVE HUD. Preview and source toolbar retained; activity-feed/chat docks excluded. Original browser URL restored afterward. No broadcast or recording started. |

## Composites

- [Ecosystem hero](images/hero/ninjapace-ecosystem.png) — 1600 × 900; includes the recaptured Watch LIVE image.
- [Four-state comparison](images/hud/hud-states.png) — 1600 × 900.
- [Six-warrior showcase](images/hud/hud-six-themes.png) — 1600 × 1080.
- [Editor → browser result](images/hud/hud-customization-before-after.png) — 1600 × 900.

The editor/result comparison shows the same title and subtitle values in native HUD Studio and the browser fixture. It is a still comparison, not a recorded demonstration of relay propagation.

## README previews

The READMEs use compact PNG derivatives in `images/previews/`, linked to the full-resolution originals. Composite previews are 640 pixels wide; individual app previews are 200 pixels wide. App rows use standard Markdown image links rather than raw HTML, so renderers that suppress HTML still display them and narrow layouts can wrap the images.

Regenerate the referenced previews after changing source screenshots:

```sh
python3 docs/tools/build_readme_previews.py
```

Original captures and composites remain at their original resolution.

## Reproduce app captures

Build Debug with the shared Xcode schemes. Select simulator destinations without forcing a single `-sdk`: the iPhone build also contains a Watch target that needs its own SDK. Use `xcrun simctl list devices booted` to select the current device IDs.

| App | Launch environment | States |
|---|---|---|
| iPhone | `NINJAPACE_IPHONE_UI_TEST_STATE` | `welcome`, `ready`, `live` |
| Watch | `NINJAPACE_UI_TEST_STATE` | `ready`, `live`, `paused` |
| Mac | `NINJAPACE_MAC_UI_TEST_STATE` | `offline`, `waiting`, `live` |

For iPhone History, Awards, and Schedule, also set `NINJAPACE_SCREENSHOT_DATA=1`. This requires a UI-test state and seeds ten synthetic records into the existing in-memory SwiftData container. Dates are relative to the capture day. It also sets a running/rest weekly schedule and hides the Debug-only award-completion toggle. Normal launches and Release builds do not seed these records. Theme and schedule preferences use the existing simulator defaults; use a dedicated simulator for future capture sessions.

Example after installing the Debug iPhone app into a simulator:

```sh
SIMCTL_CHILD_NINJAPACE_IPHONE_UI_TEST_STATE=live \
SIMCTL_CHILD_NINJAPACE_SCREENSHOT_DATA=1 \
xcrun simctl launch --terminate-running-process <IPHONE_SIMULATOR_ID> \
  com.github.kevinmontemayor.NinjaPace

xcrun simctl io <IPHONE_SIMULATOR_ID> screenshot docs/images/iphone/today-live.png
```

Navigate to the relevant screen before saving. Keep the relay address locked. For native Mac captures, save the app window, not the desktop.

## Reproduce HUD and composite captures

```sh
python3 docs/tools/preview_screenshots.py
```

Open `http://127.0.0.1:8878/hud?theme=ninja&state=live`. Supported themes are `ninja`, `viking`, `knight`, `pirate`, `cyborg`, and `spartan`; states are `idle`, `live`, `paused`, and `goal`. Add `custom=1` for the edited identity or `obs=1` for a transparent OBS source.

The loopback-only server serves a copy of the production HTML with demo JSON. Capture-only changes freeze elapsed interpolation and animations/transitions, and add a neutral background and 40-pixel inset. It does not modify the shipped overlay. Confirm all telemetry and progress-bar values have rendered before capturing.

Raw browser captures use a 425 × 390 crop. Layout sources are [ecosystem](tools/ecosystem.html), [states](tools/hud-states.html), [themes](tools/hud-six-themes.html), and [customization](tools/customization.html). Open them through the same local server under `/docs/tools/`. Match the viewport to the entire composition: 1600 × 900 for ecosystem, states, and customization; 1600 × 1080 for themes. Inspect the rendered canvas, then capture the viewport (`fullPage: false`). Smaller viewports with full-page capture can bake scrollbars and clipped content into the image. Inspect the saved file before regenerating previews. Convert JPEG screenshot output to PNG if needed rather than merely renaming extensions.

## Review notes

- Watch LIVE was recaptured on October 15, 2026 with the content scrolled slightly upward to show the complete Goal value and progress bar; this framing also appears in the ecosystem hero. READY and PAUSED retain their original first viewport. Workout controls continue below the visible area.
- Ninja's red-on-dark app text and the Pirate HUD's truncated subtitle reflect the current UI; they have not been retouched.
- Workout Detail contains splits and heart-rate zones further down the screen; the chosen capture shows its summary, heart rate, and calories.
- The Mac fixture displays ONLINE without opening the real relay. These images illustrate the UI state.
- The OBS image shows stream artwork, not gameplay.
- The optional animation was omitted to keep this refresh focused on stills.

## Validation

- Debug builds passed for iPhone, Mac, and the updated Watch app.
- Existing iPhone UI tests `testLiveTelemetryShowsDeterministicMetrics` and `testMainTabsNavigateAcrossApp` passed: 2 tests, 0 failures. The latter confirms ordinary UI-test launches still have empty History.
- Original capture pass checked 72 local README/media references and 31 PNG file signatures. The preview refresh adds 21 compact derivatives; local links and PNG signatures were rechecked after the markup changes.
- `git diff --check` passed. Physical-device HealthKit/background delivery was not tested in this capture session.

## Before committing

- [x] Root README covers the ecosystem.
- [x] Streaming HUD guide lives under `docs/`.
- [x] App guides link to current captures.
- [x] Legacy media is collapsed.
- [x] All four composites and a real OBS capture exist.
- [x] Updated Watch screenshots replace the first capture set.
- [ ] User review of the final README presentation and media.
- [ ] Commit and GitHub upload — intentionally not performed.

## October 19 recovery feature capture

- `images/iphone/history-recovery.png`: real recovery introduction sheet on the iPhone 18 Pro Max iOS 27 simulator, using the existing synthetic history fixture. No private Health data or simulated recovery result is displayed.
- Added a 200-pixel README preview and recovery sections in the root and iPhone guides.
- Verified the NinjaPace scheme builds in Release configuration for the iOS simulator; this is not an App Store archive or submission check.

## October 20 iPhone Duo captures

Captured from the iOS 27.2 Duo simulator after the adaptive Training and Welcome layout changes:

- [Compact training](images/iphone/duo-training-compact.png): collapsed section icons and maximum-rank warrior; synthetic workout data and Debug artwork preview, not a real achievement count.
- [Folded welcome](images/iphone/duo-welcome-folded.png): two-column cards, scrolled to expose both actions.
- [Expanded welcome](images/iphone/duo-welcome-expanded.png): three-column square cards with preserved image proportions. The screen can scroll further to Customize HUD.

Portrait README previews are 200 pixels wide; the expanded welcome preview is 640 pixels wide. Each links to its original capture. These images are stored in the repository rather than referencing temporary capture paths.

## October 26 Goal Alerts and celebrations

- `images/iphone/goal-alerts.png`: opt-in reminder screen with its default 6 PM time. The visible Testing section is Debug-only. No notification permission was requested or reminder enabled for this capture.
- `images/iphone/goal-celebration-settings.png`: Settings showing Goal Alerts and the enabled Goal Celebrations toggle; relay addresses remain hidden.
- `images/iphone/goal-celebration.png`: real Ninja-themed animation still captured through the Debug double-tap warrior preview gesture with synthetic telemetry; includes Device Hub window chrome. This demonstrates the visual effect, not a real completed workout or verified sound/banner delivery.
- Current Debug simulator build passed. No physical device installation or Health data changes were performed.

## October 28 Awards and achievement details

Exported directly from Xcode SwiftUI previews in dark appearance using the existing sample fixtures; no physical-device workout data was used.

- `images/iphone/awards.png`: refreshed Awards overview from “Some Goals Completed” (six workouts, five completed goals, 27.8 miles). The visible All Awards Completed switch is Debug-only and remains off.
- `images/iphone/achievement-unlocked.png`: “Marathon — Unlocked” from `AchievementDetailView`, showing a sample first-earned date and three qualifying marathons.
- `images/iphone/achievement-next-target.png`: “50 Miles — Next Target”, showing 87.4 cumulative miles and 12.6 miles remaining toward Century Runner.

Each has a 200-pixel-wide README preview linked to the full-resolution PNG. The current Debug simulator build succeeded. The locked Marathon preview was omitted because its fallback Legend Status text currently claims mastery despite incomplete progress; no app source was changed for this documentation update.

## November 3 Monthly challenge badges

- `images/iphone/monthly-badges-locked.png`: exported from the “All Monthly Badges - Locked” SwiftUI preview in `MonthlyChallengeBadgeView.swift`. All 12 designs use grayscale artwork and shield-lock overlays.
- `images/iphone/monthly-badges-unlocked.png`: exported from “All Monthly Badges”, showing all 12 designs in full color. This is an artwork gallery preview, not earned workout history.

Both captures use Xcode’s dark-appearance preview export with no editor chrome. The 320-pixel-wide README derivatives preserve the complete image and link to the original PNGs; `build_readme_previews.py` retains this width when regenerating them. Both states were visually inspected. No physical-device data or app source was changed.

### Monthly Challenges screen preview

Added `images/iphone/monthly-challenges-screen.png`, exported from the new “Monthly Challenges” preview in `MonthlyChallengesScreen.swift`, with a 200-pixel README derivative. The preview supplies a NavigationStack, ThemeStore, and empty in-memory SwiftData workout container so challenge detail navigation has a query context. The existing vault reads its reward store in the preview environment; this capture shows locked badges and November’s Iron Will mission. The screen follows the current calendar month. Xcode successfully compiled and rendered the preview, and the exported image and README links were checked.

### Unlocked monthly challenge detail

`images/iphone/monthly-challenge-unlocked.png` is a direct dark-appearance export of “Monthly Challenge - Unlocked” in `MonthlyChallengeBadgeView.swift`. It shows November 2026 Iron Will, ACHIEVEMENT UNLOCKED, 100% completion, and 12 / 12 workouts. The existing Debug override forces the visual state without persisting a reward, so the remaining-time message is still visible. No app code or reward data was changed. Its 200-pixel derivative is linked from both READMEs; the PNGs and references were verified.

### Grandmaster collection mastery

`images/iphone/achievement-grandmaster.png` was exported directly from the dark-appearance `AchievementMasteryView` SwiftUI preview. It shows the Grandmaster badge, Collection Mastered, 24 / 24 Awards Unlocked, 100% COMPLETE, and Enter the Hall of Legends. The 200-pixel preview links to the original in both READMEs. This is a sample mastery state captured after the opening `.grandmaster` particle bursts, not a real earned collection or verification of audio playback. No app source or achievement data was changed.
