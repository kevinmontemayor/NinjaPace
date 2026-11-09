//
//  MacRelayServer.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 2/12/26.
//

import Combine
import Foundation
import Network

@MainActor
final class MacRelayServer: ObservableObject {

    @Published var isRunning = false
    @Published var baseURLString: String?
    @Published private(set) var displayedStats: Stats = .zero
    @Published private(set) var activePort: Int?
    @Published private(set) var displayedStatsReceivedAt: Date = .distantPast
    @Published var userAlert: MacRelayAlert?

    private static let lastThemeKey = "NinjaPaceMac.lastRelayTheme"
    private static let hudConfigurationModeKey = "NinjaPaceMac.hudConfigurationMode"
    private static let localHUDConfigurationKey = "NinjaPaceMac.localHUDConfiguration"

    @Published private(set) var lastKnownThemeKey: String

    @Published var hudConfigurationMode: MacHUDConfigurationMode {
        didSet {
            persistHUDConfigurationMode()
            synchronizeHUDOverrideStorage()
        }
    }

    @Published var localHUDConfiguration: HUDConfiguration {
        didSet {
            persistLocalHUDConfiguration()
            synchronizeHUDOverrideStorage()
        }
    }

    private var listener: NWListener?
    private let relayPortRange = 8787...8795
    private let lock = NSLock()
    private var hasStoredLocalHUDConfiguration = false

    nonisolated(unsafe) private var latestStats: Stats = .zero
    nonisolated(unsafe) private var latestStatsReceivedAt: Date = .distantPast
    nonisolated(unsafe) private var hudConfigurationModeStorage: MacHUDConfigurationMode = .followIPhone
    nonisolated(unsafe) private var localHUDConfigurationStorage: HUDConfiguration = .default
    nonisolated(unsafe) private var latestStatsSentAt: TimeInterval?
    
    init() {
        lastKnownThemeKey = UserDefaults.standard.string(forKey: Self.lastThemeKey) ?? "ninja"

        if let rawMode = UserDefaults.standard.string(forKey: Self.hudConfigurationModeKey),
           let storedMode = MacHUDConfigurationMode(rawValue: rawMode) {
            hudConfigurationMode = storedMode
        } else {
            hudConfigurationMode = .followIPhone
        }

        if let data = UserDefaults.standard.data(forKey: Self.localHUDConfigurationKey),
           let configuration = try? JSONDecoder().decode(HUDConfiguration.self, from: data) {
            localHUDConfiguration = configuration
            hasStoredLocalHUDConfiguration = true
        } else {
            localHUDConfiguration = .default
        }

        hudConfigurationModeStorage = hudConfigurationMode
        localHUDConfigurationStorage = localHUDConfiguration
    }

    nonisolated struct Stats: Codable, Sendable {
        var theme: String?
        var miles: Double
        var steps: Int
        var hr: Int
        var elapsed: String
        var elapsedSeconds: Int
        var elapsedMilliseconds: Int
        var pace: String
        var activeCalories: Double
        var totalCalories: Double
        var goalMiles: Double
        var progress: Double
        var running: Bool
        var paused: Bool
        var hudConfiguration: HUDConfiguration?
        var sentAt: TimeInterval? = nil
        
        static let zero = Stats(
            theme: nil, miles: 0, steps: 0, hr: 0,
            elapsed: "00:00:00", elapsedSeconds: 0, elapsedMilliseconds: 0, pace: "—",
            activeCalories: 0, totalCalories: 0, goalMiles: 3.11, progress: 0,
            running: false, paused: false, hudConfiguration: nil
        )
    }

    func start() {
        guard listener == nil else { return }
        isRunning = false
        activePort = nil
        baseURLString = nil
        startListening(on: relayPortRange.lowerBound)
    }

    func stop() {
        let currentListener = listener
        listener = nil
        activePort = nil
        isRunning = false
        baseURLString = nil
        currentListener?.cancel()
    }

    // MARK: - HTTP

    nonisolated private func handle(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 128 * 1024) { [weak self] data, _, _, _ in
            guard let self, let data else { return }
            let response = self.route(String(decoding: data, as: UTF8.self), bodyData: data)
            connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
        }
    }

    nonisolated private func route(_ raw: String, bodyData: Data) -> Data {
        let firstLine = raw.split(separator: "\n").first ?? ""
        let parts = firstLine.split(separator: " ")
        let method = parts.indices.contains(0) ? String(parts[0]) : "GET"
        let path = parts.indices.contains(1) ? String(parts[1]) : "/"

        if method == "GET", path == "/" {
            return http(
                200,
                headers: [
                    "Content-Type": "text/html; charset=utf-8",
                    "Cache-Control": "no-store",
                    "Access-Control-Allow-Origin": "*"
                ],
                body: Data(loadOverlayHTML().utf8)
            )
        }

        if method == "GET", path == "/stats" {
            let json = (try? JSONEncoder().encode(readStats())) ?? Data("{}".utf8)
            return http(
                200,
                headers: [
                    "Content-Type": "application/json; charset=utf-8",
                    "Cache-Control": "no-store",
                    "Access-Control-Allow-Origin": "*"
                ],
                body: json
            )
        }

        if method == "POST", path == "/ingest" {
            let separator = Data("\r\n\r\n".utf8)
            guard let range = bodyData.range(of: separator) else {
                return http(400, headers: ["Content-Type": "text/plain"], body: Data("Bad Request".utf8))
            }

            let body = bodyData.subdata(in: range.upperBound..<bodyData.count)
            guard !body.isEmpty else {
                return http(
                    204,
                    headers: ["Access-Control-Allow-Origin": "*", "Cache-Control": "no-store"],
                    body: Data()
                )
            }

            do {
                let decoded = try JSONDecoder().decode(Stats.self, from: body)
                guard writeStats(decoded) else {
                    return http(204, headers: ["Access-Control-Allow-Origin": "*", "Cache-Control": "no-store"], body: Data())
                }

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    
                    if let sentAt = decoded.sentAt,
                       let displayedSentAt = self.displayedStats.sentAt, sentAt <= displayedSentAt {
                        return
                    }
                    
                    if let theme = decoded.theme {
                        rememberTheme(theme)
                    }
                    
                    let now = Date()
                    var displayStats = decoded
                    
                    // Prevent a delayed packet from nudging
                    // the visible stopwatch backwards.
                    if displayedStats.running, !displayedStats.paused, displayStats.running, !displayStats.paused, displayedStatsReceivedAt != .distantPast {
                        let currentlyRendered = renderedDisplayedElapsedMilliseconds(at: now)
                        displayStats.elapsedMilliseconds = max(displayStats.elapsedMilliseconds, currentlyRendered)
                        displayStats.elapsed = Self.formatElapsed(milliseconds: displayStats.elapsedMilliseconds)
                    }
                    
                    displayedStats = displayStats
                    displayedStatsReceivedAt = now
                }
                return http(204, headers: ["Access-Control-Allow-Origin": "*", "Cache-Control": "no-store"], body: Data())
            } catch {
                return http(400, headers: ["Content-Type": "text/plain; charset=utf-8", "Access-Control-Allow-Origin": "*"], body: Data("Invalid telemetry payload".utf8))
            }
        }
        return http(404, headers: ["Content-Type": "text/plain"], body: Data("Not Found".utf8))
    }

    nonisolated private func readStats() -> Stats {
        lock.lock()
        defer { lock.unlock() }

        var stats = latestStats

        // The iPhone owns telemetry. The Mac may override presentation only.
        if hudConfigurationModeStorage == .localOverride {
            stats.hudConfiguration = localHUDConfigurationStorage
        }

        guard stats.running, !stats.paused, latestStatsReceivedAt != .distantPast else { return stats }

        let deltaMilliseconds = max(0, Int(Date().timeIntervalSince(latestStatsReceivedAt) * 1_000))
        stats.elapsedMilliseconds += deltaMilliseconds
        stats.elapsed = Self.formatElapsed(milliseconds: stats.elapsedMilliseconds)
        return stats
    }
    
    @discardableResult
    nonisolated private func writeStats(_ stats: Stats) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        if let sentAt = stats.sentAt {
            guard sentAt.isFinite else {
                return false
            }
            
            if let latestStatsSentAt, sentAt <= latestStatsSentAt {
                return false
            }
            
            latestStatsSentAt = sentAt
        }
        
        latestStats = stats
        latestStatsReceivedAt = Date()
        
        return true
    }
    
    nonisolated private func http(_ code: Int, headers: [String: String], body: Data) -> Data {
        let reasonPhrase: String
        
        switch code {
        case 200: reasonPhrase = "OK"
        case 204: reasonPhrase = "No Content"
        case 400: reasonPhrase = "Bad Request"
        case 404: reasonPhrase = "Not Found"
        default: reasonPhrase = "HTTP"
        }
        
        var lines = [
            "HTTP/1.1 \(code) \(reasonPhrase)",
            "Content-Length: \(body.count)",
            "Connection: close"
        ]
        
        for (key, value) in headers {
            lines.append("\(key): \(value)")
        }
        
        lines.append("")
        
        var data = Data((lines.joined(separator: "\r\n") + "\r\n").utf8)
        data.append(body)
        return data
    }

    // MARK: - Listener

    private func startListening(on portNumber: Int) {
        guard relayPortRange.contains(portNumber),
              let candidate = NWEndpoint.Port(rawValue: UInt16(portNumber)) else {
            markRelayStartFailed()
            return
        }

        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true

            let newListener = try NWListener(using: parameters, on: candidate)
            let computerName = Host.current().localizedName ?? "NinjaPace Mac"

            newListener.service = NWListener.Service(
                name: "\(computerName) — NinjaPace",
                type: "_ninjapace._tcp"
            )
            listener = newListener

            newListener.stateUpdateHandler = { [weak self, weak newListener] state in
                guard let self, let newListener else { return }

                Task { @MainActor in
                    guard self.listener === newListener else { return }

                    switch state {
                    case .ready:
                        self.isRunning = true
                        self.activePort = Int(candidate.rawValue)
                        self.baseURLString = "http://localhost:\(candidate.rawValue)/"

                    case .failed(let error):
                        let wasRunning = self.isRunning
                        self.listener = nil
                        self.activePort = nil
                        newListener.cancel()

                        if case .posix(let code) = error, code == .EADDRINUSE {
                            let nextPort = portNumber + 1
                            if self.relayPortRange.contains(nextPort) {
                                self.startListening(on: nextPort)
                            } else {
                                self.markRelayStartFailed()
                            }
                        } else {
                            self.isRunning = false
                            self.baseURLString = nil
                            self.presentAlert(wasRunning ? .relayStoppedUnexpectedly : .relayStartFailed)
                        }

                    case .cancelled:
                        if self.listener === newListener {
                            self.listener = nil
                            self.activePort = nil
                            self.isRunning = false
                            self.baseURLString = nil
                        }

                    default:
                        break
                    }
                }
            }

            newListener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection)
            }
            newListener.start(queue: .global(qos: .userInitiated))
        } catch {
            let nextPort = portNumber + 1
            if relayPortRange.contains(nextPort) {
                startListening(on: nextPort)
            } else {
                markRelayStartFailed()
            }
        }
    }

    private func markRelayStartFailed() {
        listener = nil
        activePort = nil
        isRunning = false
        baseURLString = nil
        presentAlert(.relayStartFailed)
    }

    private func rememberTheme(_ theme: String) {
        let normalized = theme.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, normalized != lastKnownThemeKey else { return }
        lastKnownThemeKey = normalized
        UserDefaults.standard.set(normalized, forKey: Self.lastThemeKey)
    }

    // MARK: - HUD Configuration

    var incomingHUDConfiguration: HUDConfiguration? {
        displayedStats.hudConfiguration
    }

    var effectiveHUDConfiguration: HUDConfiguration {
        switch hudConfigurationMode {
        case .followIPhone: return incomingHUDConfiguration ?? .default
        case .localOverride: return localHUDConfiguration
        }
    }

    var hasIncomingHUDConfiguration: Bool {
        incomingHUDConfiguration != nil
    }

    func beginLocalHUDCustomization() {
        if !hasStoredLocalHUDConfiguration, let incoming = incomingHUDConfiguration {
            localHUDConfiguration = incoming
        }
        hudConfigurationMode = .localOverride
    }

    func followIPhoneHUDConfiguration() {
        hudConfigurationMode = .followIPhone
    }

    func resetLocalHUDToIncoming() {
        localHUDConfiguration = incomingHUDConfiguration ?? .default
    }

    private func persistHUDConfigurationMode() {
        UserDefaults.standard.set(hudConfigurationMode.rawValue, forKey: Self.hudConfigurationModeKey)
    }

    private func persistLocalHUDConfiguration() {
        guard let data = try? JSONEncoder().encode(localHUDConfiguration) else { return }
        UserDefaults.standard.set(data, forKey: Self.localHUDConfigurationKey)
        hasStoredLocalHUDConfiguration = true
    }

    private func synchronizeHUDOverrideStorage() {
        lock.lock()
        hudConfigurationModeStorage = hudConfigurationMode
        localHUDConfigurationStorage = localHUDConfiguration
        lock.unlock()
    }

    // MARK: - Helpers

    nonisolated private static func formatElapsed(milliseconds: Int) -> String {
        let safeMilliseconds = max(milliseconds, 0)
        let totalSeconds = safeMilliseconds / 1_000
        let hundredths = (safeMilliseconds % 1_000) / 10
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, hundredths)
    }

    func renderedDisplayedElapsed(at date: Date = Date()) -> String {
        Self.formatElapsed(milliseconds: renderedDisplayedElapsedMilliseconds(at: date))
    }

    func renderedDisplayedElapsedMilliseconds(at date: Date = Date()) -> Int {
        let stats = displayedStats
        guard stats.running, !stats.paused, displayedStatsReceivedAt != .distantPast else {
            return stats.elapsedMilliseconds
        }

        let deltaMilliseconds = max(0, Int(date.timeIntervalSince(displayedStatsReceivedAt) * 1_000))
        return stats.elapsedMilliseconds + deltaMilliseconds
    }

    private func presentAlert(_ alert: MacRelayAlert) {
        guard userAlert == nil else { return }
        userAlert = alert
    }
}

private extension MacRelayServer {

    nonisolated func loadOverlayHTML() -> String {
        guard let url = Bundle.main.url(forResource: "overlay", withExtension: "html") else {
            Task { @MainActor [weak self] in self?.presentAlert(.overlayUnavailable) }
            return Self.overlayFailureHTML
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            Task { @MainActor [weak self] in self?.presentAlert(.overlayUnavailable) }
            return Self.overlayFailureHTML
        }
    }

    nonisolated static var overlayFailureHTML: String {
        """
        <!doctype html>
        <html>
        <body style="
            background:transparent;
            color:white;
            font-family:system-ui;
        ">
            NinjaPace streaming HUD unavailable
        </body>
        </html>
        """
    }
}

#if DEBUG

@MainActor
extension MacRelayServer {

    func configurePreview(
        theme: String,
        miles: Double,
        steps: Int,
        hr: Int,
        elapsed: String,
        goalMiles: Double,
        progress: Double,
        running: Bool
    ) {
        isRunning = true
        activePort = 8787
        baseURLString = "http://localhost:8787/"

        displayedStats = Stats(
            theme: theme,
            miles: miles,
            steps: steps,
            hr: hr,
            elapsed: elapsed,
            elapsedSeconds: 2_912,
            elapsedMilliseconds: 2_912_000,
            pace: "10:04",
            activeCalories: 482,
            totalCalories: 611,
            goalMiles: goalMiles,
            progress: progress,
            running: running,
            paused: false,
            hudConfiguration: nil
        )
    }
}

#endif

#if DEBUG

@MainActor
extension MacRelayServer {

    func configureUITestState(_ state: String) {
        stop()

        switch state {
        case "offline":
            displayedStats = .zero
            displayedStatsReceivedAt = .distantPast

        case "waiting":
            isRunning = true
            activePort = 8787
            baseURLString = "http://localhost:8787/"
            displayedStats = Stats(
                theme: "ninja",
                miles: 0,
                steps: 0,
                hr: 0,
                elapsed: "00:00:00.00",
                elapsedSeconds: 0,
                elapsedMilliseconds: 0,
                pace: "—",
                activeCalories: 0,
                totalCalories: 0,
                goalMiles: 5,
                progress: 0,
                running: false,
                paused: false,
                hudConfiguration: nil
            )
            displayedStatsReceivedAt = .distantPast

        case "live":
            isRunning = true
            activePort = 8787
            baseURLString = "http://localhost:8787/"
            displayedStats = Stats(
                theme: "ninja",
                miles: 3.14,
                steps: 6_240,
                hr: 142,
                elapsed: "00:28:10.00",
                elapsedSeconds: 1_690,
                elapsedMilliseconds: 1_690_000,
                pace: "8:58",
                activeCalories: 418,
                totalCalories: 518,
                goalMiles: 5,
                progress: 0.63,
                running: true,
                paused: false,
                hudConfiguration: nil
            )
            displayedStatsReceivedAt = .distantPast

        default:
            break
        }
    }
}

#endif
