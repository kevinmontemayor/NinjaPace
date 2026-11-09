# English (US) store metadata draft

Not submitted. Verify name availability and final features against the release candidate. Free pricing confirmed for both records.

## iPhone + Apple Watch

| Field | Draft |
|---|---|
| Name | NinjaPace |
| Subtitle | Run. Train. Become a legend. |
| SKU | NINJAPACE-IOS-001 |
| Primary category | Health & Fitness |
| Keywords | running,workout,mileage,goals,training,pace,fitness,watch,badges,history,trends |
| Promotional text | Choose your warrior, build your running routine, and follow your progress with Apple Watch workouts, training goals, trends, and achievements. |

### Description

Turn your running routine into a warrior's journey with NinjaPace.

TRACK FROM YOUR WRIST
Use the companion Apple Watch app to record workouts and follow distance, elapsed time, pace, heart rate, calories, steps, and your mileage goal. Your Watch owns the workout while your iPhone helps you plan and review.

TRAIN WITH PURPOSE
Set mileage goals, plan running and rest days, and enable local goal reminders. Choose a warrior theme and celebrate completed goals with optional animation and sound.

SEE YOUR PROGRESS
Review workout history and details, compare monthly and yearly trends, and follow your lifetime training totals. Earn milestone awards and work toward monthly challenges.

RECOVER AVAILABLE WORKOUT HISTORY
Restore eligible workouts from Apple Health when you grant access. Recovery depends on the workouts and metadata still available in Health; it is not a backup of every app setting.

BRING YOUR WORKOUT TO YOUR STREAM
The optional NinjaPace Relay app for Mac connects your workout to a customizable browser HUD for OBS. Streaming uses your local network. Mac and OBS are not needed for everyday training and history features.

Workout recording requires a compatible paired Apple Watch and Health permissions. Mac streaming additionally requires the separate Mac companion and compatible streaming software.

### Review notes draft

No NinjaPace account or sign-in is required. Pair a compatible Apple Watch to test live workout recording. Grant Health access when prompted; initiate a workout on Watch and review live metrics on iPhone. End the workout to save history. History recovery requires eligible workouts in Health and permission to read them.

Mac relay/OBS integration is optional. Both devices must be able to communicate on the local network, with relevant permissions granted. Relay addresses are protected by the app's unlock flow. Add exact production navigation steps and a demonstration video link before submission if needed for hardware-dependent review. Never supply DEBUG fixture launch flags as reviewer instructions.

## Mac

| Field | Draft |
|---|---|
| Name | NinjaPace Relay |
| Subtitle | Bring your workout to OBS |
| SKU | NINJAPACE-MAC-001 |
| Primary category | Health & Fitness (confirm) |
| Keywords | workout,stream,overlay,telemetry,fitness,running,broadcast,hud,customization |
| Promotional text | Bring NinjaPace workouts to your stream with a local Mac relay and customizable warrior HUDs. |

### Description

Bring your NinjaPace workout to your stream.

NinjaPace Relay is the optional Mac companion for NinjaPace on iPhone and Apple Watch. It receives workout telemetry over your local network and serves a browser HUD for OBS.

FOLLOW YOUR WORKOUT
View incoming workout status and metrics on your Mac while your Watch records the session.

MAKE THE HUD YOURS
Use HUD Studio to customize your overlay. Follow the warrior theme from your iPhone or choose a local theme for your stream.

CONNECT LOCALLY
Run the relay on your Mac, connect NinjaPace on iPhone, and add the HUD URL as a browser source in OBS. No cloud account is required for the streaming path.

Live workout telemetry requires NinjaPace on a compatible iPhone and Apple Watch. Broadcasting requires separate streaming software such as OBS. NinjaPace Relay does not record Watch workouts by itself.

### Review notes draft

This is a companion local-network relay. Start the relay, connect NinjaPace on iPhone, and initiate a workout on the paired Watch. HUD Studio configures the browser overlay. Include links to the corresponding iOS listing and hardware demonstration once available. Confirm exact controls, connection steps, sandbox permissions, and behavior without connected hardware using the signed candidate.

## TestFlight “What to Test” draft

Please test workout start/pause/resume/end on Watch, synchronization with iPhone, saved history and duplicate-free Health recovery, goal edits and completed-goal totals, monthly/yearly trends, achievements, reminders, and celebration settings. For Mac testing, check local discovery, reconnects, address unlocking, HUD customization, and OBS integration. Include device/OS, build number, steps, and expected result in feedback; avoid including private health records or network addresses.

## Required owner fields

Support URL, privacy policy URL, review contact name/email/phone, copyright owner, availability territories, and account/legal questionnaire responses remain unset. Do not paste this draft into Connect until placeholders are resolved. Verify title/subtitle/keywords limits and localizations before submission. [Apple app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/).
