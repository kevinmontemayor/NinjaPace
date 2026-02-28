# 🥷 NinjaPace – OBS HUD Overlay Architecture Template

> The OBS-facing layer of NinjaPace.  
> A browser-source HUD that renders workout telemetry in real time.

---

# 1. Purpose

The NinjaPace OBS HUD Overlay is a web UI (HTML/CSS/JS) designed to run inside an **OBS Browser Source**.

It pulls telemetry from the **Mac Relay App** and renders a visual HUD:

- Miles, steps, heart rate
- Pace, elapsed time, calories
- Goal progress bar + percentage
- Status states (Idle / Live / Paused)
- Goal celebration (green glow + optional confetti burst)

The overlay is intentionally:
- **Local network only**
- **Low-latency**
- **Self-contained**
- **Easy to theme**

---

# 2. Data Flow

Apple Watch → iPhone (WatchConnectivity)
↓
iPhone → Mac Relay (`POST /ingest`)
↓
OBS Browser Source → Mac Relay (`GET /stats` polling)
↓
HUD DOM updates

---

# 3. OBS Setup

## 3.1 Add Browser Source
In OBS:

1. Sources → ➕ → **Browser**
2. Name: `NinjaPace HUD`
3. URL: http://<MAC_LAN_IP>:8787/
4. Width/Height:
- Recommended: `500 x 220` (adjust per theme)
5. FPS:
- `30` is fine (HUD is UI, not video)
6. Custom CSS:
- **Leave blank** (HUD owns styling)

Tip: If the overlay looks blurry, increase browser source width/height and scale down.

---

# 4. Endpoints Used

## GET /
Serves the overlay HTML page.

OBS Browser Source loads this URL directly.

## GET /stats
Returns latest telemetry as JSON.

Overlay polls this endpoint every N ms.

Recommended poll interval:
- **500–1000ms** (smooth, low CPU)

---

# 5. Telemetry Contract (JSON Schema)

The overlay expects this payload shape:

```json
{
"miles": 3.12,
"steps": 4800,
"hr": 152,
"elapsed": "00:27:43",
"elapsedSeconds": 1663,
"pace": "8:55",
"activeCalories": 412.3,
"totalCalories": 520.0,
"goalMiles": 6.21,
"progress": 0.50,
"running": true,
"paused": false
}

