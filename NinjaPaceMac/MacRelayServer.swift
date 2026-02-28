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
    
    private var listener: NWListener?
    nonisolated(unsafe) private var latestStats: Stats = .zero
    private let lock = NSLock()
    
    private var port: NWEndpoint.Port = 8787
    
    nonisolated struct Stats: Codable {
        var theme: String?
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
        
        static let zero = Stats(
            theme: "ninja", //Default
            miles: 0,
            steps: 0,
            hr: 0,
            elapsed: "00:00:00",
            elapsedSeconds: 0,
            pace: "—",
            activeCalories: 0,
            totalCalories: 0,
            goalMiles: 3.11,
            progress: 0,
            running: false,
            paused: false
        )
    }
    
    func start() {
        guard listener == nil else { return }

        for p in 8787...8795 {
            do {
                let params = NWParameters.tcp
                params.allowLocalEndpointReuse = true

                let candidate = NWEndpoint.Port(rawValue: UInt16(p))!
                let l = try NWListener(using: params, on: candidate)

                port = candidate
                listener = l

                let selectedPort = candidate
                l.stateUpdateHandler = { [weak self] state in
                    guard let self else { return }
                    if case .ready = state {
                        Task { @MainActor in self.isRunning = true }
                        print("✅ Mac relay running at http://localhost:\(selectedPort.rawValue)/")
                    }
                    if case .failed(let err) = state {
                        print("❌ Mac relay failed:", err)
                        Task { @MainActor in self.stop() }
                    }
                }

                l.newConnectionHandler = { [weak self] conn in
                    self?.handle(conn)
                }

                l.start(queue: .global(qos: .userInitiated))
                return
            } catch {
                // try next port
                continue
            }
        }

        print("❌ No free port found in 8787...8795")
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    nonisolated private func handle(_ conn: NWConnection) {
        conn.start(queue: .global(qos: .userInitiated))

        conn.receive(minimumIncompleteLength: 1, maximumLength: 128 * 1024) { [weak self] data, _, _, _ in
            guard let self, let data else { return }
            let raw = String(decoding: data, as: UTF8.self)
            let resp = self.route(raw, bodyData: data)
            conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
        }
    }
    
    nonisolated private func route(_ raw: String, bodyData: Data) -> Data {
        let first = raw.split(separator: "\n").first ?? ""
        let parts = first.split(separator: " ")
        let method = parts.count > 0 ? String(parts[0]) : "GET"
        let path = parts.count > 1 ? String(parts[1]) : "/"

        if method == "GET", path == "/" {
            return http(200, headers: [
                "Content-Type": "text/html; charset=utf-8",
                "Cache-Control": "no-store"
            ], body: Data(Self.overlayHTML.utf8))
        }

        if method == "GET", path == "/stats" {
            let stats = readStats()
            let json = (try? JSONEncoder().encode(stats)) ?? Data("{}".utf8)
            return http(200, headers: [
                "Content-Type": "application/json; charset=utf-8",
                "Cache-Control": "no-store",
                "Access-Control-Allow-Origin": "*"
            ], body: json)
        }

        if method == "POST", path == "/ingest" {
            let separator = Data("\r\n\r\n".utf8)

            guard let range = bodyData.range(of: separator) else {
                return http(400, headers: ["Content-Type": "text/plain"], body: Data("Bad Request".utf8))
            }

            let body = bodyData.subdata(in: range.upperBound..<bodyData.count)
            guard !body.isEmpty else {
                return http(204, headers: [
                    "Access-Control-Allow-Origin": "*",
                    "Cache-Control": "no-store"
                ], body: Data())
            }
            
            do {
                let decoded = try JSONDecoder().decode(Stats.self, from: body)
                writeStats(decoded)
                return http(204, headers: [
                    "Access-Control-Allow-Origin": "*",
                    "Cache-Control": "no-store"
                ], body: Data())
            } catch {
                let msg = "Bad JSON: \(error)".data(using: .utf8) ?? Data()
                return http(400, headers: [
                    "Content-Type": "text/plain; charset=utf-8",
                    "Access-Control-Allow-Origin": "*"
                ], body: msg)
            }
        }
        
        return http(404, headers: ["Content-Type": "text/plain"], body: Data("Not Found".utf8))
    }

    nonisolated private func readStats() -> Stats {
        lock.lock(); defer { lock.unlock() }
        return latestStats
    }

    nonisolated private func writeStats(_ s: Stats) {
        lock.lock(); defer { lock.unlock() }
        latestStats = s
    }
    
    nonisolated private func http(_ code: Int, headers: [String:String], body: Data) -> Data {
        var lines: [String] = []
        lines.append("HTTP/1.1 \(code) \(code == 200 ? "OK" : "HTTP")")
        lines.append("Content-Length: \(body.count)")
        headers.forEach { lines.append("\($0): \($1)") }
        lines.append("")
        let head = lines.joined(separator: "\r\n") + "\r\n"
        var d = Data(head.utf8)
        d.append(body)
        return d
    }
    
}

extension MacRelayServer {
    static let overlayHTML: String = """
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Streaming HUD</title>

  <style>
    html, body { margin:0; padding:0; background: transparent; overflow:hidden; }

    :root {
      /* default (LIVE = red) */
      --glow: rgba(255, 0, 80, 0.55);
      --glow2: rgba(255, 0, 80, 0.35);
      --text: rgba(255, 30, 60, 0.95);
      --muted: rgba(255, 30, 60, 0.70);
      --barBg: rgba(255, 0, 80, 0.15);
      --barFill: rgba(255, 0, 80, 0.95);

      /* pulse control */
      --pulse: 0.35;                 /* 0..1 */
      --pulseEff: var(--pulse);      /* what ring actually uses */
      --goalPulse: 0.90;             /* celebratory pulse strength */
    }

    /* state-driven theme overrides */
    .ring[data-state="paused"] {
      --glow: rgba(255, 204, 0, 0.55);
      --glow2: rgba(255, 204, 0, 0.32);
      --text: rgba(255, 220, 60, 0.95);
      --muted: rgba(255, 220, 60, 0.70);
      --barBg: rgba(255, 204, 0, 0.16);
      --barFill: rgba(255, 204, 0, 0.95);
    }

    .ring[data-state="idle"] {
      --glow: rgba(180, 180, 180, 0.45);
      --glow2: rgba(180, 180, 180, 0.25);
      --text: rgba(210, 210, 210, 0.95);
      --muted: rgba(210, 210, 210, 0.70);
      --barBg: rgba(200, 200, 200, 0.14);
      --barFill: rgba(220, 220, 220, 0.92);
    }

    /* ✅ GOAL achieved overrides EVERYTHING */
    .ring[data-goal="1"] {
      --glow: rgba(0, 255, 120, 0.70);
      --glow2: rgba(0, 255, 120, 0.40);
      --text: rgba(140, 255, 190, 0.98);
      --muted: rgba(140, 255, 190, 0.78);
      --barBg: rgba(0, 255, 120, 0.22);
      --barFill: rgba(0, 255, 120, 0.98);

      /* swap pulse driver to celebratory pulse */
      --pulseEff: var(--goalPulse);
    }

    /* wrapper = glowing ring */
    .ring {
      position:absolute;
      top:0; left:0;
      width: 360px;
      border-radius: 20px;
      padding: 2px;
      background: black;

      box-shadow:
        0 0 calc(10px + (var(--pulseEff) * 16px)) var(--glow),
        0 0 calc(18px + (var(--pulseEff) * 30px)) var(--glow2);
    }

    /* the animated border */
    .ring::before {
      content: "";
      position: absolute;
      inset: 0;
      border-radius: 20px;
      padding: 2px;

      background: linear-gradient(135deg,
        rgba(255,255,255,0.0),
        var(--text),
        rgba(255,255,255,0.0)
      );

      -webkit-mask:
        linear-gradient(#000 0 0) content-box,
        linear-gradient(#000 0 0);
      -webkit-mask-composite: xor;
      mask-composite: exclude;

      opacity: calc(0.55 + (var(--pulseEff) * 0.45));
      animation: pulse 2.0s ease-in-out infinite;
      pointer-events: none;
    }

    @keyframes pulse {
      0%, 100% { opacity: 0.65; filter: blur(0.35px); transform: scale(1.00); }
      50%      { opacity: 1.00; filter: blur(0.0px);  transform: scale(1.00); }
    }

    /* ✅ celebratory goal pulse (faster + slightly larger) */
    .ring[data-goal="1"]::before {
      animation: goalPulse 1.10s ease-in-out infinite;
    }

    @keyframes goalPulse {
      0%   { opacity: 0.45; filter: blur(0.45px); transform: scale(1.000); }
      45%  { opacity: 1.00; filter: blur(0.00px); transform: scale(1.012); }
      100% { opacity: 0.60; filter: blur(0.25px); transform: scale(1.000); }
    }

    /* HUD inner */
    .hud {
      position: relative;
      width: 340px;
      padding: 8px 10px;
      border-radius: 18px;

      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;

      color: var(--text);
      font-weight: 900;
      background: rgba(0,0,0,0.0);

      text-shadow:
        0 0 6px var(--glow2),
        0 2px 10px rgba(0,0,0,0.35);
    }

    .titleRow {
      display:flex;
      justify-content:space-between;
      align-items:baseline;
      margin-bottom: 8px;
    }

    .title {
      font-size: 13px;
      letter-spacing: 0.3px;
      opacity: 0.95;
    }

    .stateTag {
      font-size: 11px;
      font-weight: 950;
      opacity: 0.9;
    }

    .row {
      display:flex;
      align-items:center;
      justify-content:space-between;
      gap: 6px;
      margin: 3px 0;
    }

    .label {
      flex: 0 0 auto;
      min-width: 58px;
      font-size: 16px;
      font-weight: 850;
      opacity: 0.8;
    }

    .value {
      flex: 0 0 auto;
      text-align: right;
      font-size: 20px;
      font-weight: 950;
      letter-spacing: 0.3px;
    }

    .barWrap {
      height: 8px;
      background: var(--barBg);
      border-radius: 999px;
      overflow: hidden;
      margin-top: 8px;
    }

    .barFill {
      height: 100%;
      width: 0%;
      background: var(--barFill);
      box-shadow: 0 0 10px var(--glow2);
    }

    .small {
      font-size: 11px;
      opacity: 0.75;
      margin-top: 6px;
      font-weight: 850;
      color: var(--muted);
    }

    .sub {
      font-size: 11px;
      opacity: 0.8;
      margin-top: 8px;
      font-weight: 850;
      color: var(--muted);
    }
  </style>
</head>

<body>
  <div class="ring" id="root" data-state="idle" data-goal="0">
    <div class="hud">
      <div class="titleRow">
        <div class="title">STREAMING HUD</div>
        <div class="stateTag" id="stateTag">IDLE</div>
      </div>

      <div class="row"><div class="label">Miles</div><div class="value" id="miles">—</div></div>
      <div class="row"><div class="label">Steps</div><div class="value" id="steps">—</div></div>
      <div class="row"><div class="label">Heart Rate</div><div class="value" id="hr">—</div></div>
      <div class="row"><div class="label">Cals</div><div class="value" id="cals">—</div></div>
      <div class="row"><div class="label">Elapsed</div><div class="value" id="elapsed">—</div></div>
      <div class="row"><div class="label">Pace</div><div class="value" id="pace">—</div></div>

      <div class="row"><div class="label">Goal</div><div class="value" id="goal">—</div></div>
      <div class="barWrap"><div class="barFill" id="bar"></div></div>
      <div class="small" id="pct"></div>

      <div class="sub" id="status">Connecting…</div>
    </div>
  </div>

<script>
  function clamp01(x) { return Math.max(0, Math.min(1, x)); }

  function hrToPulse(hr) {
    if (!hr || hr <= 0) return 0.20;
    // map 80..170 bpm => 0.25..1.0
    const t = (hr - 80) / (170 - 80);
    return Math.max(0.25, Math.min(1.0, 0.25 + t * 0.75));
  }

  function setState(root, running, paused, goalHit) {
    const tag = document.getElementById("stateTag");

    let state = "idle";
    let text  = "IDLE";

    if (goalHit) {
      state = "live";   // keep layout “live”
      text = "GOAL ✅";
    } else if (running) {
      if (paused) { state = "paused"; text = "PAUSED"; }
      else { state = "live"; text = "LIVE"; }
    }

    root.setAttribute("data-state", state);
    tag.textContent = text;
  }

  async function tick() {
    const root = document.getElementById("root");

    try {
      const base =
        (location && location.origin && location.origin.startsWith("http"))
          ? location.origin
          : "http://localhost:8787";

      const r = await fetch(base + "/stats", { cache: "no-store" });
      const d = await r.json();

      const miles = Number(d.miles ?? 0);
      const steps = Number(d.steps ?? 0);
      const hr    = Number(d.hr ?? 0);

      const activeCals = Number(d.activeCalories ?? 0);
      const elapsed = d.elapsed ?? "00:00:00";
      const pace    = d.pace ?? "—";

      const running = !!d.running;
      const paused  = !!d.paused;

      let goalMiles = Number(d.goalMiles ?? 8.0);
      if (!isFinite(goalMiles) || goalMiles <= 0) goalMiles = 8.0;

      const progressRaw = (d.progress != null) ? Number(d.progress) : (miles / goalMiles);
      const progress = clamp01(isFinite(progressRaw) ? progressRaw : 0);

      const goalHit = (miles >= goalMiles) || (progress >= 1.0);

      // ✅ set attributes
      root.setAttribute("data-goal", goalHit ? "1" : "0");
      setState(root, running, paused, goalHit);

      // ✅ swap pulse driver:
      // - goalHit: celebratory pulse (handled by CSS via --pulseEff)
      // - else: pulse = HR (so ring intensity tracks HR)
      if (!goalHit) {
        document.documentElement.style.setProperty("--pulse", hrToPulse(hr).toFixed(3));
      }

      // ✅ paint UI
      document.getElementById("miles").textContent = miles.toFixed(2);
      document.getElementById("steps").textContent = steps.toLocaleString();
      document.getElementById("hr").textContent    = hr > 0 ? (hr + " bpm") : "—";
      document.getElementById("cals").textContent  = `${Math.round(activeCals)} kcal`;
      document.getElementById("elapsed").textContent = elapsed;
      document.getElementById("pace").textContent    = pace;

      document.getElementById("goal").textContent = `${miles.toFixed(2)} / ${goalMiles.toFixed(2)}`;
      document.getElementById("bar").style.width  = `${Math.round(progress * 100)}%`;
      document.getElementById("pct").textContent  =
        goalHit ? "COMPLETED" : `${Math.round(progress * 100)}%`;

      document.getElementById("status").textContent =
        (goalHit ? "Goal achieved 🟢" :
         running ? (paused ? "Paused ⏸" : "Live ✅") : "Ready") + " · /stats OK";

    } catch (e) {
      document.getElementById("status").textContent = "Disconnected…";
    }
  }

  tick();
  setInterval(tick, 1000);
</script>
</body>
</html>
"""
}
