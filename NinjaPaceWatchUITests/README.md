# Watch UI tests

The dashboard and workout scenarios in `NinjaPaceWatchUITests.swift` follow the same
Page Object Model structure as the iPhone suite:

- **Tests** describe scenarios and assert expected status, controls, and metrics.
- **Pages/WorkoutPage.swift** owns dashboard locators and pause, stop, and resume
  actions. Pause and stop return a `WorkoutConfirmationPage`.
- **Pages/WorkoutMetricsSection.swift** groups dashboard labels and metric values.
- **Pages/WorkoutConfirmationPage.swift** owns confirmation actions. Confirm and
  cancel wait for dismissal and return a workout page using the same app instance.
- **Support/NinjaPaceWatchTestApp.swift** configures deterministic `ready`, `live`,
  and `paused` launches with English locale through `NINJAPACE_UI_TEST_STATE`.
- **Support/WatchUITestPage.swift** provides interaction mechanics and element waits.

Keep element queries and taps in pages; keep expected values in tests. Page
construction does not navigate or assert. The test launch helper waits for the
initial dashboard, and state-transition assertions wait for the expected label.

## watchOS interaction rules

SwiftUI Watch alerts are not reliably exposed as `XCUIElementTypeAlert`. Use the
Cancel button as the presentation marker and find the matching hittable action
among buttons with the same label. This preserves the existing Watch alert
workaround. Wait for Cancel to disappear before returning to the dashboard.

Query metric leaf identifiers directly. A parent accessibility identifier can
hide child metric identifiers on watchOS. Page helpers swipe vertically until the target page title is visible; settings
helpers use small Digital Crown steps to bring the entire control below the
navigation bar. Toggle helpers tap the nested switch and wait for its value to
change; an existing or partly visible row is not sufficient. Home and Controls share action identifiers,
so queries select the first current match.

Helpers stay in the Watch test target so Watch-specific behavior can evolve
without changing iPhone interactions. Xcode automatically includes these Swift
files through the existing synchronized folder; no project-file edits are needed.
The deterministic DEBUG harness avoids real workout and connectivity dependencies.
It also supports optional page, theme, goal, and preference-reset launch settings;
see the Watch README for the complete list.

## Running

In Xcode, choose **NinjaPaceWatch**, select a Watch simulator, and run
**NinjaPaceWatchUITests**. Or substitute an available Watch simulator ID:

```sh
xcodebuild test -project NinjaPace.xcodeproj \
  -scheme 'NinjaPaceWatch' \
  -destination 'platform=watchOS Simulator,id=<SIMULATOR_UUID>' \
  '-only-testing:NinjaPaceWatchUITests' \
  -parallel-testing-enabled NO
```

## Watch v2 coverage

DashboardSettingsPage handles the settings sheet and warrior chooser. Tests verify
that preferences survive relaunch, disabled Overview is skipped, optional Calories
is reachable, warrior selection updates the artwork, and rest days omit progress.
The screenshot test keeps attachments for Home (Ready/Live/Paused), Overview, and
Distance. Run on both a 40 mm SE and an Ultra to inspect the adaptive layout.

`WatchIdleClockUITests` covers idle eligibility, exclusion from active/paused workouts
and disabled settings, reappearance after 60 seconds from any page or picker, activity resets, native touch/Crown scrolling above Home, re-enabling after settings,
and both styles persisting through relaunch. It captures Ninja (early/legendary),
Viking, Cyborg, and Pirate progression screenshots. Existing Ready dashboard tests
dismiss the idle screen first; `homeClock` now identifies the idle clock container.
The DEBUG Start action enters a deterministic running state without invoking HealthKit.

## GitHub gallery captures

`WatchDocumentationScreenshots/testCaptureWatchV2Gallery` saves 14 named PNG
attachments: all six level-4 warrior Home screens, Ready and Paused, Overview,
Distance, Heart Rate, Controls, Dashboard settings, and the warrior picker.
Run it on the 49 mm Ultra simulator for the repository gallery. It uses the same
synthetic telemetry fixtures and performs no real workout recording.

Export the result with `docs/tools/export_watch_screenshots.py`; see the
[capture manifest](../docs/SCREENSHOTS.md#november-25-watch-v2-gallery) for commands.
