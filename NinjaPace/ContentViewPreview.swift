// ContentViewPreview.swift
// Preview container for ContentView with mock managers

import SwiftUI
import Combine

// Minimal mock classes for preview
private class MockHealthStreamManager: ObservableObject {
    @Published var miles: Double = 3.14
    @Published var steps: Int = 1234
    @Published var heartRateBpm: Int = 88
    @Published var elapsedString: String = "00:42:13"
    @Published var isWorkoutRunning: Bool = false

    func startWorkout() async {}
    func stopWorkout() async {}
    func requestAuthorization() async {}
}

private class MockWebServerManager: ObservableObject {
    @Published var isRunning: Bool = true
    var serverURLString: String? = "http://localhost:8080/hud"

    func start(health: AnyObject) {}
    func stop() {}
}

struct ContentView_PreviewContainer: View {
    @StateObject private var health = MockHealthStreamManager()
    @StateObject private var web = MockWebServerManager()

    var body: some View {
        ContentView()
            .environmentObject(health)
            .environmentObject(web)
    }
}

#Preview {
    ContentView_PreviewContainer()
}
