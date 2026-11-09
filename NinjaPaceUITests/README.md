# iPhone UI tests

The 20 scenarios in `NinjaPaceUITests.swift` use Page Object Model (POM).

- **Tests** describe the scenario and assert expected results. Expected mileage,
  telemetry, titles, and privacy behavior stay visible in the tests.
- **Pages/** owns accessibility queries and user actions. Navigation methods return
  the destination page, sharing the same app instance. Page construction does not
  navigate or assert; tests explicitly wait for destination markers.
  `TrainingHomePage.openHUD()` additionally synchronizes the transient menu:
  it waits for hittable controls and the destination navigation bar before returning.
- **GoalSection / TelemetrySection** model components on Training Home.
- **HUDResetDialog** models the reset confirmation separately from the editor.
- **Support/NinjaPaceTestApp.swift** configures deterministic launches and English
  locale. Functional tests wait for the launch page; the performance test measures
  launch without page readiness assertions inside the measurement.
- **Support/UITestPage.swift** contains shared tap/scroll mechanics and element
  waits. Missing controls fail the test; business assertions belong in scenarios.

## Adding coverage

Add or reuse a named locator and action on the relevant page. Keep raw element
queries, taps, scrolls, and text replacement out of the test methods. Assert the
result in the test, waiting for asynchronous UI changes where needed. Do not cache
resolved element values across navigation; page properties query the current UI.

Preserve these SwiftUI details:

- Scroll to lower HUD editor sections before tapping them.
- Tap the right side of a switch row to hit the physical toggle.
- Query confirmation-dialog labels across element types, not just buttons.
- Wait for accordion content to disappear before asserting its removal.

The DEBUG harness uses `NINJAPACE_IPHONE_UI_TEST_STATE` with `welcome`, `ready`, and
`live`. It keeps SwiftData in memory and avoids real HealthKit, WatchConnectivity,
Bonjour, and relay networking. Persistence scenarios reopen views in the same
launch; a new launch resets the deterministic fixture.

## Running

Select the **NinjaPace** scheme and an iPhone simulator in Xcode, then run the
**NinjaPaceUITests** target. For command-line execution, substitute an available
simulator ID:

```sh
xcodebuild test -project NinjaPace.xcodeproj -scheme NinjaPace \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UUID>' \
  -only-testing:NinjaPaceUITests -parallel-testing-enabled NO
```

The UI-test folder is an Xcode synchronized group; new Swift page files are picked
up automatically without editing `project.pbxproj`.
