# Monthly challenges

Awards now includes the current mission, a twelve-month collection, and a Monthly Hall of Legends. Monthly rewards are separate from `Achievement.allCases` and do not change Grandmaster eligibility.

- Goal Alerts has an independent monthly notification toggle. Twelve repeating local requests announce each month's challenge at 9 AM local time on its first day.
- Notification taps open the current challenge, including cold launches. Tapping an old announcement also opens the current month.
- Challenges become available at midnight. Workout completion time determines the month; the next month's midnight is excluded. Positive-distance, positive-duration saved workouts contribute regardless of whether their daily goal was completed.
- Workout-count, total-mileage, and longest-single-workout challenges use the twelve definitions in `MonthlyChallengeManager.swift`.
- Rewards are stored locally in UserDefaults under `MonthlyChallenges.earnedRewards`, identified by year and month. History is evaluated on workout saves, history changes, foregrounding, and day changes. Eligible historical months are recovered without replaying past-month celebrations. Earned rewards survive workout deletion and edits; they are not a cross-device sync feature.
- A newly earned current-month reward uses the existing goal celebration animation and sound, respecting the celebration preference. Lifetime achievement presentations take priority.

## Badge artwork

The twelve original transparent PNG badges are included in `NinjaPace/Assets.xcassets/Badges`, in image sets named `achievement_month_1` through `achievement_month_12`. Each month uses its matching image in the challenge screen and Awards collection. Images preserve their original color and resolution; locked challenges apply grayscale and a lock overlay, while earned challenges show the full-color artwork. A shield fallback remains available if an asset is ever missing.

## Validation

`MonthlyChallengeTests` covers notification timing/payloads, exclusive month boundaries, future-workout exclusion, the different metrics, invalid workouts, persistence after deletion, and annual reset. `testMonthlyChallengeOpensFromAwards` covers navigation into and out of the mission screen.

On a device, enable Monthly Challenge Alerts under Goal Alerts and verify notification authorization. Verify a monthly announcement tap opens the mission after both a cold launch and a foreground launch. Local notification delivery and sound remain subject to system notification settings.
