# 🥷 NinjaPace – iPhone App

> Real-time workout telemetry for streamers.
> Built for runners. Designed for creators.

---

# 1. Overview

**NinjaPace (iPhone)** is the central control hub of the NinjaPace ecosystem.

It:
- Receives workout data from Apple Watch
- Manages daily/weekly mileage goals
- Applies intelligent schedule logic
- Pushes live telemetry to a Mac relay server
- Powers a real-time OBS/Twitch HUD overlay

The iPhone app is the “Launch Pad” for the entire system.

---

# 2. Core Responsibilities

## Workout Control
- Start / Stop workout
- Track:
  - Miles
  - Steps
  - Heart Rate
  - Active Calories
  - Elapsed Time
  - Pace
- Sync goal to watch

## Telemetry Push Engine
- Pushes workout stats every 1 second
- POST → Mac Relay `/ingest`
- Connection test & status feedback
- Persists relay base URL

## Smart Goal Engine
- Manual goal selection (presets + fine tuning)
- Weekly schedule system
- Auto-apply daily schedule
- Manual override (per-day logic)
- Adaptive increment logic
- Canonical distance locks:
  - 1 mile
  - 2 miles
  - 5K
  - 10K
  - Half
  - Full

---

# 3. Architecture Overview

## High-Level Flow

Apple Watch  
↓  
HealthStreamManager  
↓  
StatsPushClient  
↓  
Mac Relay (HTTP)  
↓  
OBS Browser Source  
↓  
Live Stream Overlay

---

# 4. Key Components

## HealthStreamManager
**Responsibilities**
- HealthKit authorization
- Workout session lifecycle
- Real-time metric updates
- Goal syncing to watch
- Daily schedule auto-apply logic

**State**
- `goalMiles`
- `useScheduleDefault`
- `isManualOverrideToday`
- `progress`
- `elapsedSeconds`

---

## StatsPushClient
**Responsibilities**
- Persist relay base URL
- Normalize URL input
- Push telemetry payload
- Expose connection status
- Provide testConnection()

**Payload Model**
```swift
struct Payload {
    miles: Double
    steps: Int
    hr: Int
    elapsed: String
    elapsedSeconds: Int
    pace: String
    activeCalories: Double
    totalCalories: Double
    goalMiles: Double
    progress: Double
    running: Bool
    paused: Bool
}

GoalScheduleStore

Responsibilities

Persist weekly schedule (Codable + UserDefaults)

Manage:

milesByWeekday

useScheduleDefaults

GoalLaunchPad

UI for:

Quick presets

Fine tuning

Adaptive stepping

Manual override

Applying schedule default

GoalScheduleSettingsView

Weekly editor:

Per-day adaptive stepping

Snap-to-lock logic

Canonical thresholds

Batch weekly adjustments

Templates

5. Smart Goal Logic
Auto-Apply Rules

On App Launch:

IF useScheduleDefault == true
AND user has NOT manually overridden today
AND schedule not yet applied today
→ Apply today’s scheduled miles

If user manually sets goal:
→ Mark manual override for today only

Next day:
→ Schedule resumes automatically

6. Adaptive Step Logic

Step size adjusts dynamically:

Current Miles    Step Size
< 3    0.25 mi
3 – 10    0.5 mi
10 – 20    1.0 mi
20+    2.0 mi

Canonical lock distances:

1.0

2.0

3.10686 (5K)

6.21371 (10K)

13.1094 (Half)

26.2188 (Full)

Within snap window → auto-lock to exact canonical value.

7. Settings
Relay Setup

Mac relay base URL

Test connection

Persist configuration

Goal Schedule

Weekly edit

Use schedule toggle

Quick templates

Reset defaults

8. App Store Positioning
Target Audience

Fitness streamers

Treadmill gamers

Twitch creators

Runners who broadcast

Hybrid athlete-creators

Unique Value

Real-time broadcast telemetry

Goal-aware overlays

Schedule intelligence

Snap-to-distance logic

Creator-focused workflow

9. Future Enhancements (Phone)

Multiple saved schedules

Metric/Imperial toggle

Goal streak tracking

Historical goal analytics

Push to StreamElements directly

Auto-discover Mac via Bonjour

HR-zone glow integration in-app
