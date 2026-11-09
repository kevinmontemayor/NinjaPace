NinjaPace Unit Test Starter

Add to the NinjaPace app target:
- MileageGoalLadder.swift

Add to the NinjaPaceTests unit-test target:
- GoalScheduleTests.swift
- MileageGoalLadderTests.swift
- WorkoutRecordTests.swift

The tests use Apple's Swift Testing framework:
    import Testing
    @testable import NinjaPace

After adding MileageGoalLadder.swift, replace the private drag-domain calls
inside StepperMiles with:

    MileageGoalLadder.adjustedMiles(from: dragStartMiles, steps: steps)
    MileageGoalLadder.isRaceDistance(roundedMiles)

Then delete the duplicated private dragAdjustedMiles, nextMileageValue,
isRaceDistance, and local snapTargets from StepperMiles.

History recovery and goal corrections
-------------------------------------
WorkoutHistoryRecoveryTests covers missing Health measurements, location metadata,
UUID and timestamp duplicate matching, repeat and mixed imports, and preservation
of existing goal edits. HistoricalGoalProgressTests covers saving corrected goals,
invalid values, and achievement/warrior thresholds at 10, 25, and 50 completed goals.
WorkoutRecordTests also covers goal calculations and other stored workout metrics.

Recovery tests construct in-memory RecoveryWorkout snapshots and use isolated in-memory
SwiftData containers. They do not request Health permissions or access device data.
HealthKit snapshot conversion and authorization/query integration and SwiftUI refresh behavior still require
separate UI or device verification.
