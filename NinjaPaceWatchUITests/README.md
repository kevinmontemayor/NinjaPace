# Watch UI tests

The seven scenarios in `NinjaPaceWatchUITests.swift` follow the same
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
hide child metric identifiers on watchOS. Dashboard taps let XCTest scroll controls
into view on small Watch displays.

Helpers stay in the Watch test target so Watch-specific behavior can evolve
without changing iPhone interactions. Xcode automatically includes these Swift
files through the existing synchronized folder; no project-file edits are needed.
The app's deterministic DEBUG harness remains unchanged and avoids real workout
and connectivity dependencies.

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
