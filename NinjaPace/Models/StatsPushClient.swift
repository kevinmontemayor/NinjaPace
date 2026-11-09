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
    private var pushTask: Task<Void, Never>?
    private var consecutiveFailures = 0

    struct Payload: Codable {
        var theme: String
        var miles: Double
        var steps: Int
        var hr: Int
        var elapsed: String
        var elapsedSeconds: Int
        let elapsedMilliseconds: Int
        var pace: String
        var activeCalories: Double
        var totalCalories: Double
        var goalMiles: Double
        var progress: Double
        var running: Bool
        var paused: Bool
        var hudConfiguration: HUDConfiguration?
        /// Timestamp representing when this telemetry snapshot was created
        var sentAt: TimeInterval = Date().timeIntervalSince1970
    }

    init(defaultBaseURL: String = "") {
        let stored = UserDefaults.standard.string(forKey: Self.storedBaseURLKey)
        self.macBaseURL = stored ?? defaultBaseURL
        self.warningMessage = nil
    }

    // MARK: - Public API

    func startPushing(getPayload: @escaping () -> Payload) {
        stopPushing()
        enabled = true
        status = .pushing

        pushTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled, self.enabled {
                let payload = getPayload()
                await self.push(payload)

                do {
                    try await Task.sleep(for: .milliseconds(250))
                } catch {
                    return
                }
            }
        }
    }

    func stopPushing() {
        pushTask?.cancel()
        pushTask = nil
        enabled = false
        status = .idle
    }

    /// Handy for “Test Connection” button in UI.
    @MainActor
    func testConnection() async {
        guard let url = buildURL(path: "/stats") else {
            status = .failed("Invalid Mac URL")
            return
        }

        do {
            let (_, resp) = try await URLSession.shared.data(from: url)

            if let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                consecutiveFailures = 0
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

        var req = URLRequest(url: url, timeoutInterval: 5)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            req.httpBody = try JSONEncoder().encode(payload)
            let (_, resp) = try await URLSession.shared.data(for: req)

            if let http = resp as? HTTPURLResponse {
                if http.statusCode != 204 && http.statusCode != 200 {
                    consecutiveFailures += 1
                    if consecutiveFailures >= 3 {
                        status = .failed("HTTP \(http.statusCode)")
                    }
                } else {
                    consecutiveFailures = 0
                    status = .success
                }
            }
        } catch {
            consecutiveFailures += 1
            if consecutiveFailures >= 3 {
                status = .failed("Unable to reach NinjaPaceMac")
            }
        }
    }
    
    func pushNow(_ payload: Payload) async {
        guard enabled else { return }
        // Finish the upload triggered by a Watch wake even if iOS backgrounds us
        // before URLSession completes. This is finite work, not a keep-alive loop.
#if os(iOS)
        let backgroundDelivery = RelayBackgroundDelivery()
        defer { backgroundDelivery.end() }
#endif
        await push(payload)
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
            warningMessage = "Using localhost will point to this device, not your Mac. Enter your Mac's IP (e.g., 192.168.x.x:8787)."
        } else {
            warningMessage = nil
        }

        return URL(string: normalized + path)
    }

    private func normalizeBaseURL(_ raw: String) -> String {
        var string = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        string = string.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if string.isEmpty { return "" }

        // If user types just "192.###.#.###:8787" -> add http://
        if !string.lowercased().hasPrefix("http://") &&
            !string.lowercased().hasPrefix("https://") {
            string = "http://" + string
        }

        return string
    }

    private func save(_ raw: String) {
        UserDefaults.standard.set(raw, forKey: Self.storedBaseURLKey)
    }
}
