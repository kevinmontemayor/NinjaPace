# 🥷 NinjaPace – Apple Watch App

> The real-time heartbeat of NinjaPace.
> Lightweight. Focused. Stream-ready.

---

# 1. Overview

The NinjaPace Watch App is responsible for:

- Running and managing workout sessions
- Collecting real-time HealthKit data
- Transmitting telemetry to iPhone
- Remaining responsive during wrist-lock
- Minimizing battery impact

The Watch is the **primary sensor device** in the NinjaPace system.

---

# 2. Core Responsibilities

## 🏃 Workout Execution
- Start / Stop workout session
- Handle paused state
- Track:
  - Distance (miles)
  - Steps
  - Heart Rate
  - Active Calories
  - Elapsed Time
  - Pace (optional)

## 📡 Data Streaming
- Send stats to iPhone via WatchConnectivity
- Push updates at ~1 second interval
- Send:
  - running
  - paused
  - miles
  - hr
  - steps
  - elapsedSeconds
  - activeCalories
  - totalCalories
  - goalMiles

## 🎯 Goal Sync
- Receive goal updates from iPhone
- Display goal locally
- Calculate progress ring locally
- Trigger “goalHit” state when achieved

---

# 3. Architecture Overview

## High-Level Flow

HKWorkoutSession  
↓  
HKLiveWorkoutBuilder  
↓  
HealthKit Data Samples  
↓  
WorkoutManager  
↓  
WatchConnectivity  
↓  
iPhone HealthStreamManager

---

# 4. Core Components

## WorkoutManager

**Responsibilities**
- Request HealthKit authorization
- Start HKWorkoutSession
- Collect live data
- Maintain workout state
- Transmit telemetry to iPhone
- Handle pause/resume

**Key State**
```swift
@Published var isRunning: Bool
@Published var isPaused: Bool
@Published var miles: Double
@Published var heartRate: Int
@Published var steps: Int
@Published var activeCalories: Double
@Published var elapsedSeconds: Int
@Published var goalMiles: Double

HealthKit Integration
Session Type

.running

Collected Metrics

.distanceWalkingRunning

.heartRate

.activeEnergyBurned

.stepCount

Data Collection Method

HKLiveWorkoutBuilder

Delegate-based updates

Statistics query per metric

WatchConnectivity Layer
Message Payload Example
[
  "running": true,
  "paused": false,
  "miles": 3.12,
  "hr": 152,
  "steps": 4821,
  "elapsedSeconds": 1783,
  "activeCalories": 412.3,
  "totalCalories": 520.0,
  "goalMiles": 6.21
]
Communication Strategy

WCSession.default.sendMessage()

Fallback to updateApplicationContext

Handle reachability changes

Resume transmission automatically

5. Background Behavior
Requirements

To ensure live streaming continues when:

Wrist locks

User lowers arm

Screen turns off

Enable:

Background Modes:

Workout processing

Background delivery (HealthKit)

HKWorkoutSession running state maintained

Important Note

Watch must:

Keep workout active

Continue builder updates

Continue WatchConnectivity pushes

Avoid suspending session prematurely

6. UI Design
Main View

Large distance display

Heart rate

Elapsed time

Progress ring

Goal display

Start/Stop button

State Colors
State    Color
Live    Red
Paused    Yellow
Idle    Gray
GoalHit    Green
7. Goal Hit Behavior

When:

miles >= goalMiles

Trigger:

goalHit = true

Haptic feedback

Visual celebration (optional)

Continue session if desired

8. Performance Strategy
Optimization Goals

Low CPU overhead

Efficient HealthKit querying

Throttled push rate (~1s)

Minimal UI redraws

Battery Protection

Avoid excessive animations

Avoid heavy timers

Prefer builder delegate updates

9. Failure Handling
iPhone Not Reachable

Continue collecting data

Queue latest payload

Retry transmission

Connectivity Restored

Resume real-time streaming

Send latest snapshot immediately

10. Future Enhancements

HR-zone aware glow trigger

On-watch confetti animation

Pace prediction

Interval mode

Multi-sport mode

Custom workout presets

Independent Watch-only mode

Direct WiFi push (advanced)

11. App Store Positioning
Category

Health & Fitness

Tagline

“Real-time workout telemetry for streamers.”

Unique Selling Points

Built for creators

Designed for treadmill gamers

Real-time sync to streaming overlay

Smart goal system integration

Minimal UI distraction
