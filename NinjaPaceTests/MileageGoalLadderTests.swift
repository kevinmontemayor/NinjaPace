//
//  MileageGoalLadderTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 9/18/26.
//

import Testing
@testable import NinjaPace

@Suite("Mileage Goal Ladder")
struct MileageGoalLadderTests {

    @Test("Race locks remain stable")
    func raceLocksAreExpectedValues() {

        #expect(
            MileageGoalLadder.raceLocks
            == [
                3.11,
                6.21,
                13.11,
                26.22
            ]
        )
    }

    @Test(
        "Upward mileage progression",
        arguments: [
            (3.11, 3.50),
            (3.50, 4.00),
            (4.00, 4.50),
            (4.50, 5.00),
            (5.00, 5.50),
            (5.50, 6.00),
            (6.00, 6.21),
            (6.21, 6.50),
            (13.00, 13.11),
            (13.11, 13.50),
            (26.00, 26.22),
            (26.22, 26.50)
        ]
    )
    func upwardProgression(
        current: Double,
        expected: Double
    ) {

        #expect(
            MileageGoalLadder.nextValue(
                from: current,
                direction: 1
            )
            == expected
        )
    }

    @Test(
        "Downward mileage progression",
        arguments: [
            (6.50, 6.21),
            (6.21, 6.00),
            (6.00, 5.50),
            (5.00, 4.50),
            (3.50, 3.11),
            (3.11, 3.00),
            (13.50, 13.11),
            (13.11, 13.00),
            (26.50, 26.22),
            (26.22, 26.00)
        ]
    )
    func downwardProgression(
        current: Double,
        expected: Double
    ) {

        #expect(
            MileageGoalLadder.nextValue(
                from: current,
                direction: -1
            )
            == expected
        )
    }

    @Test("An off-grid value joins the next half-mile rung when moving up")
    func offGridValueMovesUpCleanly() {

        #expect(
            MileageGoalLadder.nextValue(
                from: 4.23,
                direction: 1
            )
            == 4.50
        )
    }

    @Test("An off-grid value joins the previous half-mile rung when moving down")
    func offGridValueMovesDownCleanly() {

        #expect(
            MileageGoalLadder.nextValue(
                from: 4.23,
                direction: -1
            )
            == 4.00
        )
    }

    @Test("Mileage never goes below zero")
    func mileageIsClampedAtZero() {

        #expect(
            MileageGoalLadder.nextValue(
                from: 0,
                direction: -1
            )
            == 0
        )

        #expect(
            MileageGoalLadder.adjustedMiles(
                from: 0.25,
                steps: -20
            )
            == 0
        )
    }

    @Test("Multiple drag steps walk the ladder one rung at a time")
    func multipleStepsRespectIntermediateLocks() {

        #expect(
            MileageGoalLadder.adjustedMiles(
                from: 3.11,
                steps: 5
            )
            == 5.50
        )

        #expect(
            MileageGoalLadder.adjustedMiles(
                from: 6.50,
                steps: -2
            )
            == 6.00
        )
    }

    @Test("Zero steps preserves the starting mileage")
    func zeroStepsDoesNotChangeMileage() {

        #expect(
            MileageGoalLadder.adjustedMiles(
                from: 5.0,
                steps: 0
            )
            == 5.0
        )
    }

    @Test(
        "Race-distance recognition",
        arguments: [
            (3.11, true),
            (6.21, true),
            (13.11, true),
            (26.22, true),
            (5.0, false),
            (10.0, false)
        ]
    )
    func identifiesRaceDistances(
        miles: Double,
        expected: Bool
    ) {

        #expect(
            MileageGoalLadder.isRaceDistance(
                miles
            )
            == expected
        )
    }
}
