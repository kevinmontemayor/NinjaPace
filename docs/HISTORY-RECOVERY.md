# Recover NinjaPace history from Apple Health

If NinjaPace history is missing but its workouts still appear in Apple Fitness, use **History → Recover History → Find NinjaPace Workouts**. Allow Health read access, review the listed workouts, then tap **Recover Workouts**. This adds local history records; it never writes to or deletes from Apple Health.

Only running workouts whose source bundle identifier matches the NinjaPace iPhone or Watch app are included. Existing UUIDs and matching start/end times are skipped on repeated imports. The import saves in a separate SwiftData context and rolls back if saving fails.

Recovery restores available dates, distance, active duration, calories, steps, and heart-rate summaries. Original NinjaPace mileage goals, splits, heart-rate zones, and achievement unlocks were not stored by the current Watch app in HealthKit. Unknown goals are represented as 0 and do not count as completed goals. Missing distance or steps also show 0; this does not prove the actual value was zero. Other achievements may be recalculated from recovered history.

An empty search does not prove Health has no workouts: Health read permissions may limit results. Workouts recorded by Apple's Workout app or another source are intentionally excluded.

Use simulator previews while investigating physical-device data loss. This feature does not establish or fix the cause of the October 19 history loss. Keep a device backup or an exported app container before further device testing.

## Restore original goals

Open a recovered workout in History, scroll to **Goal Performance**, and tap **Set Original Goal** (or **Edit Goal**). Enter the original target in miles and save. NinjaPace recalculates completion, progress percentage, and miles over goal. History totals, Awards, and the Today warrior footer use those saved completion values. Raising a goal above the completed distance removes that workout from the completed-goal count. This does not recreate the historical list of achievements unlocked during that workout or change Apple Health.
