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
    
    private var listener: NWListener?
    private let connections = NSHashTable<NWConnection>.weakObjects()
    private let connectionsLock = NSLock()
    private weak var health: HealthStreamManager?

    // Configure port and allow external access (0.0.0.0)
    private let port: NWEndpoint.Port = 8080
    private var browser: NWBrowser?
    
    func start(health: HealthStreamManager) {
        guard !isRunning else { return }
        self.health = health

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: port)
            self.listener = listener

            let manager = self
            listener.stateUpdateHandler = { [weak manager] state in
                guard let manager else { return }
                switch state {
                case .ready:
                    Task { @MainActor in
                        manager.isRunning = true
                        if let host = Self.localIPAddress() {
                            manager.serverURLString = "http://\(host):\(manager.port.rawValue)/"
                            print("Server running at:", manager.serverURLString ?? "-")
                        } else {
                            manager.serverURLString = "http://localhost:\(manager.port.rawValue)/"
                        }
                        manager.triggerLocalNetworkPrompt()
                    }
                case .failed(let error):
                    print("HTTP server failed:", error)
                    Task { @MainActor in
                        manager.stop()
                    }
                case .cancelled:
                    Task { @MainActor in
                        manager.isRunning = false
                        manager.serverURLString = nil
                    }
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak manager] connection in
                guard let manager else { return }
                Task { @MainActor in
                    manager.handleNewConnection(connection)
                }
            }

            listener.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Failed to start listener:", error)
            self.isRunning = false
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

        // GET /
        if method == "GET" && path == "/" {
            let html = Self.overlayHTML.data(using: .utf8) ?? Data()
            return httpResponse(status: 200, headers: [
                "Content-Type": "text/html; charset=utf-8",
                "Cache-Control": "no-store",
                "Access-Control-Allow-Origin": "*"
            ], body: html)
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
            let workoutRunning: Bool
            let pace: String
        }
        
        let health = self.health
        let stats = Stats(
            theme: self.themeKey,
            miles: health?.miles ?? 0,
            steps: health?.steps ?? 0,
            hr: health?.heartRateBpm ?? 0,
            elapsed: health?.elapsedString ?? "00:00:00",
            workoutRunning: health?.isWorkoutRunning ?? false,
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

// MARK: - Overlay HTML
extension WebServerManager {
    fileprivate static let overlayHTML: String = """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width,initial-scale=1" />
      <title>NinjaPace HUD</title>
      <style>
        html, body { margin:0; padding:0; background: transparent; }

        /* Default tokens (Ninja) */
        :root {
          --accent: rgba(0,255,234,0.95);
          --accent2: rgba(0,255,234,0.55);
          --title: rgba(255,255,255,0.95);
          --text: rgba(255,255,255,0.95);
          --muted: rgba(255,255,255,0.70);
          --glass: rgba(0,0,0,0.35);
          --border: rgba(255,255,255,0.18);
        }

        /* THEME OVERRIDES (set by data-theme) */
        .hud[data-theme="ninja"] {
          --accent: rgba(0,255,234,0.95);
          --accent2: rgba(0,255,234,0.55);
        }
        .hud[data-theme="viking"] {
          --accent: rgba(255,140,0,0.95);
          --accent2: rgba(255,140,0,0.55);
        }
        .hud[data-theme="pirate"] {
          --accent: rgba(240,200,160,0.95);
          --accent2: rgba(240,200,160,0.55);
        }
        .hud[data-theme="knight"] {
          --accent: rgba(90,170,255,0.95);
          --accent2: rgba(90,170,255,0.55);
        }
        .hud[data-theme="cyborg"] {
          --accent: rgba(0,255,170,0.95);
          --accent2: rgba(0,255,170,0.55);
        }
        .hud[data-theme="spartan"] {
          --accent: rgba(255,215,0,0.95);
          --accent2: rgba(255,215,0,0.55);
        }

        /* Debug badge (top-left) */
        .badge {
          position: fixed;
          top: 10px; left: 10px;
          z-index: 999999;
          font: 900 20px/1.1 system-ui;
          color: var(--accent);
          background: rgba(0,0,0,0.6);
          padding: 10px 14px;
          border-radius: 12px;
          border: 2px solid var(--accent2);
          box-shadow: 0 10px 30px rgba(0,0,0,0.25);
        }

        .hud {
          font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
          color: var(--text);
          padding: 18px 22px;
          width: 420px;
          border-radius: 18px;

          /* Liquid glass-ish */
          background: var(--glass);
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px);

          border: 1px solid var(--border);
          box-shadow: 0 10px 30px rgba(0,0,0,0.25);
          text-shadow: 0 0 10px rgba(0,0,0,0.25);
        }

        .row { display:flex; justify-content:space-between; align-items:baseline; margin: 8px 0; }
        .label { opacity: 0.8; font-size: 14px; color: var(--muted); }
        .value { font-size: 20px; font-weight: 800; letter-spacing: 0.5px; }

        .title {
          font-size: 14px;
          opacity: 0.95;
          margin-bottom: 10px;
          color: var(--title);
          display:flex;
          align-items:center;
          gap: 8px;
        }

        .titleDot {
          width: 10px;
          height: 10px;
          border-radius: 999px;
          background: var(--accent);
          box-shadow: 0 0 12px var(--accent2);
          flex: 0 0 auto;
        }

        .sub { font-size: 12px; opacity: 0.75; margin-top: 10px; color: var(--muted); }
      </style>
    </head>
    <body>

      <div class="hud" id="hud" data-theme="ninja">
        <div class="badge" id="badge">NINJAPACE OVERLAY ✅</div>

        <div class="title" id="hudTitle">
          <span class="titleDot"></span>
          <span id="titleText">Stream Running HUD</span>
        </div>

        <div class="row"><div class="label">Miles</div><div class="value" id="miles">—</div></div>
        <div class="row"><div class="label">Steps</div><div class="value" id="steps">—</div></div>
        <div class="row"><div class="label">HR</div><div class="value" id="hr">—</div></div>
        <div class="row"><div class="label">Elapsed</div><div class="value" id="elapsed">—</div></div>
        <div class="row"><div class="label">Pace</div><div class="value" id="pace">—</div></div>

        <div class="sub" id="status">Connecting…</div>
      </div>

      <script>
        function safeTheme(t) {
          const s = (t || "ninja").toString().toLowerCase();
          const allowed = ["ninja","viking","pirate","knight","cyborg","spartan"];
          return allowed.includes(s) ? s : "ninja";
        }

        function themeMeta(theme) {
          switch (theme) {
            case "viking":  return { emoji:"🪓", name:"Viking",  title:"Stream Running HUD" };
            case "pirate":  return { emoji:"🏴‍☠️", name:"Pirate",  title:"Stream Running HUD" };
            case "knight":  return { emoji:"🛡️", name:"Knight",  title:"Stream Running HUD" };
            case "cyborg":  return { emoji:"🤖", name:"Cyborg",  title:"Stream Running HUD" };
            case "spartan": return { emoji:"🏛️", name:"Spartan", title:"Stream Running HUD" };
            default:        return { emoji:"🥷", name:"Ninja",   title:"Stream Running HUD" };
          }
        }

        async function tick() {
          const hud = document.getElementById("hud");

          try {
            const base = window.location.origin;
            const r = await fetch(base + "/stats", { cache: "no-store" });
            const d = await r.json();

            // ✅ THEME
            const theme = safeTheme(d.theme);
            hud.setAttribute("data-theme", theme);

            const meta = themeMeta(theme);
            document.getElementById("titleText").textContent = `${meta.emoji} ${meta.name} ${meta.title}`;
            document.getElementById("badge").textContent = `${meta.name.toUpperCase()}PACE OVERLAY ✅`;

            // ✅ DATA
            document.getElementById("miles").textContent = (d.miles ?? 0).toFixed(2);
            document.getElementById("steps").textContent = (d.steps ?? 0).toLocaleString();
            document.getElementById("hr").textContent = (d.hr ?? 0) > 0 ? (d.hr + " bpm") : "—";
            document.getElementById("elapsed").textContent = d.elapsed ?? "00:00:00";
            document.getElementById("pace").textContent = d.pace ?? "—";

            const runningFlag = (d.workoutRunning ?? d.running ?? false);
            document.getElementById("status").textContent =
              (runningFlag ? "Workout live ✅" : "Workout stopped ⏸") + " · /stats OK";

          } catch (e) {
            document.getElementById("status").textContent = "Disconnected… retrying";
          }
        }

        tick();
        setInterval(tick, 1000);
      </script>
    </body>
    </html>
    """
}
