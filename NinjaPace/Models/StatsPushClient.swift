//
//  StatsPushClient.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/12/26.
//

import Combine
import Foundation

public protocol StatsPushClientProtocol: ObservableObject {
    associatedtype StatusType
    var macBaseURL: String { get set }
    var status: StatusType { get }
    @MainActor
    func testConnection() async
}

@MainActor
final class StatsPushClient: StatsPushClientProtocol {

    enum Status: Equatable {
        case idle
        case pushing
        case success
        case failed(String)
    }

    typealias StatusType = Status

    // MARK: - Persistence
    private static let storedBaseURLKey = "StatsPushClient.macBaseURL"

    /// What the user edits in the app UI.
    @Published var macBaseURL: String {
        didSet { save(macBaseURL) }
    }
    
    @Published var warningMessage: String? = nil

    @Published var enabled: Bool = false
    @Published var status: Status = .idle

    private var timer: Timer?

    struct Payload: Codable {
        var theme: String
        var miles: Double
        var steps: Int
        var hr: Int
        var elapsed: String
        var elapsedSeconds: Int
        var pace: String
        var activeCalories: Double
        var totalCalories: Double
        var goalMiles: Double
        var progress: Double
        var running: Bool
        var paused: Bool
    }

    init(defaultBaseURL: String = "") {
        // If we have a stored value, use it. Otherwise use defaultBaseURL (or empty).
        let stored = UserDefaults.standard.string(forKey: Self.storedBaseURLKey)
        self.macBaseURL = stored ?? defaultBaseURL
        self.warningMessage = nil
    }

    // MARK: - Public API
    func startPushing(getPayload: @escaping () -> Payload) {
        stopPushing()
        enabled = true
        status = .pushing

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                guard self.enabled else { return }
                await self.push(getPayload())
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopPushing() {
        timer?.invalidate()
        timer = nil
        enabled = false
        status = .idle
    }

    /// Handy for “Test Connection” button in UI
    @MainActor func testConnection() async {
        guard let url = buildURL(path: "/stats") else {
            status = .failed("Invalid Mac URL")
            return
        }

        do {
            let (_, resp) = try await URLSession.shared.data(from: url)
            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                status = .success
            } else {
                status = .failed("Mac responded, but not OK")
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Internals
    private func push(_ payload: Payload) async {
        guard let url = buildURL(path: "/ingest") else {
            status = .failed("Invalid Mac URL")
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            req.httpBody = try JSONEncoder().encode(payload)
            let (_, resp) = try await URLSession.shared.data(for: req)

            if let http = resp as? HTTPURLResponse, http.statusCode != 204 && http.statusCode != 200 {
                status = .failed("HTTP \(http.statusCode)")
                print("❌ push HTTP", http.statusCode)
            } else {
                status = .success
                print("✅ pushed")
            }
        } catch {
            status = .failed(error.localizedDescription)
            print("❌ push failed:", error.localizedDescription)
        }
    }
    
    static func formatHMS(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func buildURL(path: String) -> URL? {
        let normalized = normalizeBaseURL(macBaseURL)
        guard !normalized.isEmpty else { return nil }
        
        if normalized.contains("localhost") || normalized.contains("127.0.0.1") {
            // "localhost" points to the device itself (iPhone/iPad)
            self.warningMessage = "Using localhost will point to this device, not your Mac. Enter your Mac's IP (e.g., 192.168.x.x:8787)."
        } else {
            self.warningMessage = nil
        }

        return URL(string: normalized + path)
    }

    private func normalizeBaseURL(_ raw: String) -> String {
        var string = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        string = string.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if string.isEmpty { return "" }

        // If user types just "192.###.#.###:8787" -> add http://
        if !string.lowercased().hasPrefix("http://") && !string.lowercased().hasPrefix("https://") {
            string = "http://" + string
        }

        return string
    }

    private func save(_ raw: String) {
        UserDefaults.standard.set(raw, forKey: Self.storedBaseURLKey)
    }
}
