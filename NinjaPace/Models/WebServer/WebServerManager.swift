//
//  WebServerManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/6/26.
//

import Foundation
import Combine
import Network

@MainActor
final class WebServerManager: ObservableObject {

    @Published var isRunning: Bool = false
    @Published var serverURLString: String?
    @Published var themeKey: String = "ninja"
    @Published var userAlert: WebServerAlert?

    private var listener: NWListener?
    private let connections = NSHashTable<NWConnection>.weakObjects()
    private let connectionsLock = NSLock()
    private weak var health: HealthStreamManager?

    // Configure port and allow external access (0.0.0.0)
    private let port: NWEndpoint.Port = 8080

    private var browser: NWBrowser?

    func start(health: HealthStreamManager) {
        guard listener == nil else { return }

        self.health = health
        userAlert = nil

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true

            let listener = try NWListener(
                using: params,
                on: port
            )

            self.listener = listener

            listener.stateUpdateHandler = { [weak self, weak listener] state in
                guard let self, let listener else { return }

                Task { @MainActor in
                    /*
                     Ignore a callback from a listener
                     NinjaPace is no longer using.
                     */
                    guard self.listener === listener else { return }

                    switch state {
                    case .ready:
                        self.isRunning = true

                        if let host = Self.localIPAddress() {
                            self.serverURLString =
                                "http://\(host):\(self.port.rawValue)/"
                        } else {
                            self.serverURLString =
                                "http://localhost:\(self.port.rawValue)/"
                        }

                        self.triggerLocalNetworkPrompt()

                    case .failed:
                        /*
                         This actually prevents the local
                         streaming feature from working,
                         so tell the user.
                         */
                        self.userAlert =
                            self.isRunning
                            ? .serverStoppedUnexpectedly
                            : .serverStartFailed

                        self.stop()

                    case .cancelled:
                        /*
                         Normal when the user intentionally
                         stops the server.
                         */
                        self.isRunning = false
                        self.serverURLString = nil

                        if self.listener === listener {
                            self.listener = nil
                        }

                    default:
                        break
                    }
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                guard let self else { return }

                Task { @MainActor in
                    self.handleNewConnection(connection)
                }
            }

            listener.start(
                queue: .global(qos: .userInitiated)
            )

        } catch {
            listener = nil
            isRunning = false
            serverURLString = nil
            userAlert = .serverStartFailed
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil

        let all = connections.allObjects
        connections.removeAllObjects()
        all.forEach { $0.cancel() }

        isRunning = false
        serverURLString = nil
    }
}

// MARK: - Networking (HTTP parsing/response)
private extension WebServerManager {
    func handleNewConnection(_ connection: NWConnection) {
        connections.add(connection)
        let managerUnsafe = self
        connection.stateUpdateHandler = { [managerUnsafe, connection] state in
            switch state {
            case .ready:
                Task { @MainActor in
                    let manager: WebServerManager? = managerUnsafe as WebServerManager
                    guard let manager else { return }
                    manager.receive(on: connection)
                }
            case .failed, .cancelled:
                Task { @MainActor in
                    let manager: WebServerManager? = managerUnsafe as WebServerManager
                    guard let manager else { return }
                    manager.connections.remove(connection)
                }
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 128 * 1024) { [weak self, connection] data, _, isComplete, error in
            guard let data, !data.isEmpty else {
                if isComplete || error != nil { connection.cancel() }
                return
            }
            
            // Split headers/body on CRLFCRLF
            let marker = Data("\r\n\r\n".utf8)
            let headData: Data
            let bodyData: Data

            if let range = data.range(of: marker) {
                headData = data.subdata(in: data.startIndex..<range.lowerBound)
                bodyData = data.subdata(in: range.upperBound..<data.endIndex)
            } else {
                headData = data
                bodyData = Data()
            }

            let headString = String(decoding: headData, as: UTF8.self)

            Task {
                let response: Data = await MainActor.run { [weak self] in
                    guard let strongSelf = self else {
                        // If self is gone, return a minimal 503 response
                        let body = Data("Service Unavailable".utf8)
                        return "HTTP/1.1 503 Service Unavailable\r\nContent-Length: \(body.count)\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n".data(using: .utf8)! + body
                    }
                    return strongSelf.routeAndBuildResponse(for: headString, body: bodyData)
                }

                await MainActor.run {
                    connection.send(content: response, completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                }
            }
        }
    }
    
    func routeAndBuildResponse(for rawRequest: String, body: Data) -> Data {
        let firstLine = rawRequest.split(separator: "\n").first ?? ""
        let parts = firstLine.split(separator: " ")
        let method = parts.count > 0 ? String(parts[0]) : "GET"
        let path = parts.count > 1 ? String(parts[1]) : "/"

        // CORS preflight
        if method == "OPTIONS" {
            return httpResponse(status: 204, headers: [
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            ], body: Data())
        }

        // GET /stats
        if method == "GET" && path == "/stats" {
            let json = statsJSON()
            return httpResponse(status: 200, headers: [
                "Content-Type": "application/json; charset=utf-8",
                "Cache-Control": "no-store",
                "Access-Control-Allow-Origin": "*"
            ], body: json)
        }
        
        // POST handler
        if method == "POST" && path == "/ingest" {
            // If you ever want your watch/iPhone to POST INTO this server, decode `body` here
            return httpResponse(status: 204, headers: [
                "Access-Control-Allow-Origin": "*",
                "Cache-Control": "no-store"
            ], body: Data())
        }

        // Not found
        let notFound = "Not Found".data(using: .utf8) ?? Data()
        return httpResponse(status: 404, headers: [
            "Content-Type": "text/plain; charset=utf-8",
            "Access-Control-Allow-Origin": "*"
        ], body: notFound)
    }
    
    func httpResponse(status: Int, headers: [String: String], body: Data) -> Data {
        var lines: [String] = []
        lines.append("HTTP/1.1 \(status) \(statusText(status))")
        lines.append("Content-Length: \(body.count)")
        for (key, value) in headers { lines.append("\(key): \(value)") }
        lines.append("")
        let head = lines.joined(separator: "\r\n") + "\r\n"
        var data = Data(head.utf8)
        data.append(body)
        return data
    }

    func statusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 204: return "No Content"
        case 404: return "Not Found"
        default: return "HTTP"
        }
    }

    func statsJSON() -> Data {
        struct Stats: Codable {
            let theme: String
            let miles: Double
            let steps: Int
            let hr: Int
            let elapsed: String
            let elapsedMilliseconds: Int
            let running: Bool
            let paused: Bool
            let pace: String
        }
        
        let health = self.health
        let stats = Stats(
            theme: self.themeKey,
            miles: health?.miles ?? 0,
            steps: health?.steps ?? 0,
            hr: health?.heartRateBpm ?? 0,
            elapsed: health?.elapsedString ?? "00:00:00.00",
            elapsedMilliseconds: health?.renderedElapsedMilliseconds ?? 0,
            running: health?.isWorkoutRunning ?? false,
            paused: health?.isWorkoutPaused ?? false,
            pace: health?.paceString ?? "—"
        )
        
        return (try? JSONEncoder().encode(stats)) ?? Data("{}".utf8)
    }
    
    static func localIPAddress() -> String? {
        // Try to get a Wi‑Fi/primary IPv4 address
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) { // IPv4
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" {
                        let addr = interface.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                        let ip = String(cString: inet_ntoa(addr.sin_addr))
                        address = ip
                        break
                    }
                }
                ptr = interface.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    private func triggerLocalNetworkPrompt() {
        let params = NWParameters()
        params.includePeerToPeer = true

        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: params)
        self.browser = browser

        browser.stateUpdateHandler = { [browser] state in
            // Stop — prompt should appear
            if case .ready = state {
                browser.cancel()
            }
        }

        browser.start(queue: .global(qos: .utility))
    }
}
