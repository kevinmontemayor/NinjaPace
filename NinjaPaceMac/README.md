# 🥷 NinjaPace – Mac Relay App

> The streaming bridge.
> Real-time telemetry relay for OBS overlays.

---

# 1. Overview

The NinjaPace Mac Relay App is a lightweight local HTTP server that:

- Receives telemetry from iPhone
- Stores the latest workout state
- Serves JSON to OBS browser sources
- Enables real-time streaming overlays

It acts as a stateless relay between:

iPhone → Mac → OBS → Stream

No cloud. No accounts. Pure local network performance.

---

# 2. Core Responsibilities

## Ingest Telemetry
- Receive HTTP POST requests from iPhone
- Validate JSON payload
- Store latest stats in memory

## Serve Stats to OBS
- Provide `/stats` endpoint
- Return latest workout JSON
- Enable polling from browser source

## Local Network Server
- Bind to port (default: 8787)
- Serve on LAN IP
- Allow CORS access

---

# 3. Architecture Overview

iPhone StatsPushClient  
↓ HTTP POST  
Mac Relay Server (`/ingest`)  
↓ In-memory store  
GET `/stats`  
↓  
OBS Browser Source  
↓  
Stream Overlay

---

# 4. HTTP Endpoints

## POST /ingest

Receives telemetry payload.

### Example Payload

```json
{
  "running": true,
  "paused": false,
  "miles": 3.12,
  "steps": 4821,
  "hr": 152,
  "elapsed": "00:27:43",
  "elapsedSeconds": 1663,
  "activeCalories": 412.3,
  "totalCalories": 520.0,
  "goalMiles": 6.21,
  "progress": 0.50,
  "pace": "8:55"
}

Response
200 OK
GET /stats

Returns latest stored telemetry.

Example Response
{
  "running": true,
  "paused": false,
  "miles": 3.12,
  "steps": 4821,
  "hr": 152,
  "elapsed": "00:27:43",
  "elapsedSeconds": 1663,
  "activeCalories": 412.3,
  "totalCalories": 520.0,
  "goalMiles": 6.21,
  "progress": 0.50,
  "pace": "8:55"
}
5. Core Components
WebServerManager

Responsibilities

Start/Stop HTTP server

Bind to selected port

Expose serverURLString

Log status

TelemetryStore

Responsibilities

Hold latest stats in memory

Thread-safe updates

Provide snapshot for /stats

Example:

final class TelemetryStore {
    private let queue = DispatchQueue(label: "telemetry.store")

    private var current: Payload = .idle

    func update(_ payload: Payload) {
        queue.sync { current = payload }
    }

    func snapshot() -> Payload {
        queue.sync { current }
    }
}
6. Server Implementation Options
Option A – SwiftNIO

High performance

Full control

Production-ready

Option B – GCDWebServer

Lightweight

Simple setup

Ideal for local relay use

Option C – Vapor (overkill)

Not recommended for this use case

7. OBS Integration
Browser Source Settings

URL:

http://192.xxx.x.xxx:8787/

Refresh interval:

500ms – 1000ms

HUD Fetch Example

JavaScript:

setInterval(async () => {
  const res = await fetch('/stats');
  const data = await res.json();
  updateHUD(data);
}, 1000);
8. State Logic

HUD states derived from payload:

Condition    HUD State
running == false    Idle
paused == true    Paused
running == true    Live
progress >= 1.0    Goal Hit
9. Performance Characteristics

Memory only (no persistence)

No database

No disk writes

Minimal CPU usage

Sub-10ms response time typical

10. Failure Modes
Port Already in Use

Error:

POSIXErrorCode(rawValue: 48): Address already in use

Solution:

Kill previous instance

Ensure single server binding

iPhone Cannot Connect

Verify LAN IP

Ensure firewall allows port

Avoid using localhost on iPhone

11. Security Model

Designed for local network use only.

No authentication

No HTTPS

Intended for trusted LAN environment

Future optional:

Token validation

LAN-only bind restriction

Auto-discovery via Bonjour

12. UI Design (Optional macOS App Shell)

Mac app may include:

Server start/stop toggle

IP address display

Port configuration

Live stats preview

Connection log

13. Future Enhancements

Multi-streamer support

Multiple stat profiles

WebSocket push instead of polling

Direct StreamElements integration

JSON schema validation

Auto-discover via Bonjour

LAN QR code pairing

14. App Store Positioning

If released separately:

Category

Developer Tools / Utilities

Tagline

“Local streaming telemetry relay for NinjaPace.”
