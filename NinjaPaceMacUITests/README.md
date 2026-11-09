# Mac UI tests

The six scenarios in `NinjaPaceMacUITests.swift` use the same Page Object Model
structure as the iPhone and Watch suites:

- **Tests** describe scenarios and assert expected status, controls, and telemetry.
- **Pages/RelayDashboardPage.swift** owns dashboard locators and relay actions.
  `openHUDStudio()` returns a `HUDStudioPage` sharing the same application instance.
- **Pages/RelayTelemetrySection.swift** groups the six telemetry values.
- **Pages/HUDStudioPage.swift** identifies the editor using its existing content marker.
- **Support/NinjaPaceMacTestApp.swift** configures deterministic `offline`, `waiting`,
  and `live` launches through `NINJAPACE_MAC_UI_TEST_STATE`, with English locale.
- **Support/MacUITestPage.swift** provides interaction mechanics and text helpers.

Keep raw queries and taps in pages, and expected values in tests. Page construction
has no navigation or assertion side effects. Tests wait for initial dashboard and
HUD Studio markers; relay transitions wait for their expected text.

macOS SwiftUI StaticText can expose visible text through `value` rather than
`label`. Use `textValue` and `waitForText` to consistently read a nonempty String
value first, falling back to the label. These helpers belong to the Mac test target
so platform-specific behavior does not change iPhone or Watch interactions.

The launch-performance scenario uses the same app configuration without page waits
inside its measurement. The DEBUG harness remains unchanged: it supplies fake relay
states without binding a real network listener or requiring iPhone telemetry.

Xcode automatically includes Swift files in this synchronized folder; no project
file changes are needed.

## Running

Choose the **NinjaPaceMac** scheme and **My Mac**, then run **NinjaPaceMacUITests**.
Command-line equivalent:

```sh
xcodebuild test -project NinjaPace.xcodeproj -scheme NinjaPaceMac \
  -destination 'platform=macOS' -only-testing:NinjaPaceMacUITests \
  -parallel-testing-enabled NO
```
