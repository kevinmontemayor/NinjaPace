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

Field Notes

progress should be 0...1, but overlay can compute fallback as miles / goalMiles

pace may be "—" if not available

goalMiles is driven by iPhone Launch Pad settings

6. Overlay Runtime Architecture

The overlay is intentionally minimal:

Layers

HTML DOM: structure of the HUD

CSS Variables: theme + dynamic glow behavior

JS Poll Loop: fetch telemetry + update DOM

Update Loop

fetch /stats

parse JSON

compute state:

idle if running=false

paused if paused=true

live if running=true && paused=false

goalHit if progress >= 1 OR miles >= goalMiles

write values to DOM

update CSS variables (pulse intensity, goal glow)

update attributes (data-state, data-goal)

7. State Machine
State    Condition    Visual
Idle    running=false    gray theme, “Ready”
Live    running=true && paused=false    red theme, HR pulse glow
Paused    paused=true    yellow theme, “Paused”
Goal Hit    miles >= goalMiles OR progress >= 1    green glow + celebration

Goal Hit should override the state visuals.

8. Recommended DOM Contract

Keep IDs stable so themes can change without breaking JS:

#miles

#steps

#hr

#cals

#elapsed

#pace

#goal

#bar

#pct

#status

#stateTag

#root

9. Styling System
9.1 CSS Variables

Use CSS variables so JS doesn’t touch raw styles:

--glow

--glow2

--text

--muted

--barBg

--barFill

--pulse (0..1 intensity)

--pulseEff (effective pulse used by box-shadow)

--goalPulse (stronger pulse on goal)

9.2 Attribute-Based Theming

Root node:

<div class="ring" id="root" data-state="idle" data-goal="0">

CSS switches styles:

[data-state="idle"] { … }

[data-state="paused"] { … }

[data-goal="1"] { … }

10. Confetti Celebration System (Optional)

Goal celebration can run as:

10 second confetti burst

then disable (keep green glow)

Implementation options:

lightweight canvas confetti

simple particle DOM elements (less preferred)

“emoji confetti” (fastest + funny)

Rules:

only trigger once per goal event

don’t retrigger every poll tick

use a boolean guard:

let didCelebrate = false

11. Performance Guidelines

Poll interval: 500–1000ms

Avoid layout thrashing:

update DOM textContent only

Use CSS animations (GPU friendly)

Keep shadow blur reasonable

Avoid huge canvas sizes

12. Debugging Checklist
Overlay says “Disconnected”

Can OBS reach the Mac IP?

Try opening URL in Mac Safari: http://<MAC_IP>:8787/

Confirm /stats works: curl http://<MAC_IP>:8787/stats

Overlay not updating

Make sure iPhone is pushing:

Look for ✅ pushed

Confirm Mac relay is receiving:

verify stored stats change over time

Reduce poll interval only if needed

Overlay loads but looks wrong

OBS browser source dimensions mismatch

Increase browser source size, then scale in OBS

Ensure “Shutdown source when not visible” is OFF (optional)

13. Customization Guide (Safe Mods)
Safe to customize

✅ colors (CSS variables)
✅ fonts
✅ HUD layout spacing
✅ icons/emojis
✅ goal celebration animation
✅ add extra metrics (cadence, zone, etc)

Avoid (unless you know what you’re doing)

⚠️ changing DOM IDs used by JS
⚠️ changing /stats JSON keys without updating overlay JS
⚠️ heavy animations (performance cost)


