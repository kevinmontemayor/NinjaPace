# 🥷 NinjaPace – OBS HUD Overlay Architecture Template

> The OBS-facing layer of NinjaPace.  
> A browser-source HUD that renders workout telemetry in real time.

---

Browser HUD - 
---

<img width="347" height="283" alt="NinjaPace - HUD - Live" src="https://github.com/user-attachments/assets/998c2b6b-0c52-4a90-a66e-f132709966d9" />

<img width="348" height="281" alt="NinjaPace - HUD - Paused" src="https://github.com/user-attachments/assets/3d0bd156-87da-4bea-8bf1-5b1a68e468e5" />

<img width="353" height="287" alt="NinjaPace - HUD - Goal Completed" src="https://github.com/user-attachments/assets/a40d9047-e729-4adb-9555-ddc975b3bd00" />

---

https://github.com/user-attachments/assets/f86067ff-8f94-43e5-87e1-3e3e16b81827



https://github.com/user-attachments/assets/4185903e-729e-4bfc-99e5-66a0d034b9a2


---

Watch App - 

---
<img width="410" height="502" alt="NinjaPace - WatchApp" src="https://github.com/user-attachments/assets/f48aaf3a-e4d7-4981-a178-b01902e21411" />

<img width="410" height="502" alt="NinjaPace - WatchApp - Pause" src="https://github.com/user-attachments/assets/d3ded036-a26f-4d0b-a3eb-4326c0a2bfd4" />

---

Mac App - 

---
<img width="899" height="448" alt="NinjaPaceMac app" src="https://github.com/user-attachments/assets/70d2cfe1-c077-4c26-8ad9-bb3a83960b0c" />
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

