import XCTest

@MainActor
final class HUDStudioPage: MacUITestPage {
    // Use the existing content marker rather than depending on a window title.
    var marker: XCUIElement { app.staticTexts["hudStudioWindowMarker"] }
}
