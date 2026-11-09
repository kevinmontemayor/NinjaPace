//
//  NinjaPaceUITests.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 2/4/26.
//

import XCTest

final class NinjaPaceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testWelcomeAllowsWarriorSelectionAndBeginsTraining() {
        let welcome = launchWelcome()
        XCTAssertTrue(welcome.warrior(.pirate).exists)
        XCTAssertEqual(welcome.warrior(.pirate).value as? String, "Not Selected")
        welcome.selectWarrior(.pirate)
        XCTAssertEqual(welcome.warrior(.pirate).value as? String, "Selected")
        let today = welcome.beginTraining()
        XCTAssertTrue(today.title.waitForExistence(timeout: 3), "Training Home did not appear after Begin Training.")
    }

    @MainActor
    func testMainTabsNavigateAcrossApp() {
        let today = launchTraining()
        let history = today.showHistory()
        XCTAssertTrue(history.title.waitForExistence(timeout: 2))
        XCTAssertTrue(history.emptyState.exists)
        let awards = history.showAwards()
        XCTAssertTrue(awards.title.waitForExistence(timeout: 2))
        XCTAssertTrue(awards.currentStreak.exists)
        XCTAssertTrue(awards.milestones.exists)
        XCTAssertTrue(awards.badges.exists)
        XCTAssertTrue(awards.showToday().title.waitForExistence(timeout: 2))
    }

    @MainActor
    func testMonthlyChallengeOpensFromAwards() {
        let awards = launchTraining().showAwards()
        let challenges = awards.openMonthlyChallenges()
        XCTAssertTrue(challenges.navigationBar.waitForExistence(timeout: 5), "Monthly Challenges did not open from Awards.")
        XCTAssertTrue(challenges.currentChallenge.waitForExistence(timeout: 5))

        let detail = challenges.openCurrentChallenge()
        XCTAssertTrue(detail.title.waitForExistence(timeout: 5))
        XCTAssertTrue(detail.lockedStatus.waitForExistence(timeout: 3))
        XCTAssertTrue(detail.continueTrainingButton.exists)

        let returnedChallenges = detail.continueTraining()
        XCTAssertTrue(returnedChallenges.navigationBar.waitForExistence(timeout: 5), "Monthly Challenges did not return after Continue Training.")
        XCTAssertTrue(returnedChallenges.currentChallenge.waitForExistence(timeout: 5))
        let returnedAwards = returnedChallenges.backToAwards()
        XCTAssertTrue(returnedAwards.title.waitForExistence(timeout: 3), "Awards did not return after leaving Monthly Challenges.")
    }

    @MainActor
    func testGoalPresetUpdatesMileage() {
        let goal = launchTraining().openGoal()
        XCTAssertTrue(goal.mileage.waitForExistence(timeout: 2))
        XCTAssertEqual(goal.mileage.label, "3.11 mi")
        goal.selectPreset(.tenK)
        XCTAssertTrue(goal.mileage.waitForLabel("6.21 mi"), "10K preset did not update the mileage goal.")
    }

    @MainActor
    func testTrainingScheduleOpensAndReturns() {
        let schedule = launchTraining().openSchedule()
        XCTAssertTrue(schedule.navigationBar.waitForExistence(timeout: 2), "Goal Schedule did not open.")
        XCTAssertTrue(schedule.backToTraining().title.waitForExistence(timeout: 2))
    }

    @MainActor
    func testHUDCustomizationOpensAndReturns() {
        let hud = launchTraining().openHUD()
        XCTAssertTrue(hud.navigationBar.waitForExistence(timeout: 2), "HUD customization did not open.")
        XCTAssertTrue(hud.backToTraining().title.waitForExistence(timeout: 2))
    }

    @MainActor
    func testRelaySetupOpensAndReturns() {
        let relay = launchTraining().openSettings()
        XCTAssertTrue(relay.navigationBar.waitForExistence(timeout: 2), "Relay Setup did not open.")
        XCTAssertTrue(relay.backToTraining().title.waitForExistence(timeout: 2))
    }

    @MainActor
    func testLiveTelemetryShowsDeterministicMetrics() {
        let telemetry = launchTraining(live: true).openTelemetry()
        XCTAssertTrue(telemetry.miles.waitForExistence(timeout: 2))
        XCTAssertEqual(telemetry.miles.label, "3.14")
        XCTAssertEqual(telemetry.steps.label, "6,240")
        XCTAssertEqual(telemetry.heartRate.label, "142 bpm")
        XCTAssertEqual(telemetry.elapsed.label, "00:28:10.00")
        XCTAssertEqual(telemetry.progress.label, "63%")
        XCTAssertEqual(telemetry.goal.label, "5.00 mi")
    }

    @MainActor
    func testGoalCannotDropBelowZero() {
        let goal = launchTraining().openGoal()
        XCTAssertTrue(goal.mileage.waitForExistence(timeout: 2))
        goal.selectPreset(.oneMile)
        XCTAssertTrue(goal.mileage.waitForLabel("1.00 mi"))
        for _ in 0..<4 { goal.subtractQuarterMile() }
        XCTAssertTrue(goal.mileage.waitForLabel("0.00 mi"), "Goal did not reach the valid 0.00-mile rest-day value.")
        goal.subtractQuarterMile()
        XCTAssertEqual(goal.mileage.label, "0.00 mi", "Mileage goal dropped below the rest-day floor.")
    }

    @MainActor
    func testGoalFineTuningAndRounding() {
        let goal = launchTraining().openGoal()
        XCTAssertTrue(goal.mileage.waitForExistence(timeout: 2))
        goal.selectPreset(.fiveK)
        XCTAssertTrue(goal.mileage.waitForLabel("3.11 mi"))
        goal.addQuarterMile()
        XCTAssertTrue(goal.mileage.waitForLabel("3.36 mi"), "Quarter-mile adjustment did not update the displayed goal.")
        goal.roundToQuarterMile()
        XCTAssertTrue(goal.mileage.waitForLabel("3.25 mi"), "Round did not snap the goal to the nearest quarter mile.")
    }

    @MainActor
    func testTodaySectionsBehaveLikeAccordion() {
        let today = launchTraining()
        let goal = today.openGoal()
        XCTAssertTrue(goal.preset(.tenK).waitForExistence(timeout: 2), "Today's Goal section did not expand.")
        let telemetry = today.openTelemetry()
        XCTAssertTrue(telemetry.title.waitForExistence(timeout: 2), "Telemetry section did not expand.")
        XCTAssertTrue(goal.preset(.tenK).waitUntilAbsent(), "Today's Goal content remained visible after Telemetry expanded.")
    }

    @MainActor
    func testHUDPreviewAndEditorSectionsCollapseAndExpand() {
        let hud = openHUD()
        XCTAssertTrue(hud.collapsePreviewButton.waitForExistence(timeout: 2))
        hud.collapsePreview()
        XCTAssertTrue(hud.expandPreviewButton.waitForExistence(timeout: 2), "HUD preview did not collapse.")
        hud.openAppearance()
        XCTAssertTrue(hud.textSize.waitForExistence(timeout: 2), "Appearance controls did not expand.")
        hud.openVisibleMetrics()
        XCTAssertTrue(hud.milesSwitch.waitForExistence(timeout: 2), "Visible Metrics controls did not expand.")
        XCTAssertTrue(hud.textSize.waitUntilAbsent(), "Appearance controls remained visible after Visible Metrics expanded.")
        hud.expandPreview()
        XCTAssertTrue(hud.collapsePreviewButton.waitForExistence(timeout: 3), "HUD preview did not expand again.")
    }

    @MainActor
    func testWelcomeCanOpenHUDCustomizationAndReturn() {
        let hud = launchWelcome().openHUD()
        XCTAssertTrue(hud.navigationBar.waitForExistence(timeout: 2), "HUD customization did not open from the welcome screen.")
        XCTAssertTrue(hud.backToWelcome().title.waitForExistence(timeout: 2), "Welcome screen did not return after leaving HUD customization.")
    }

    @MainActor
    func testHUDPreviewStateSelectorUpdatesCollapsedStatus() {
        let hud = openHUD()
        hud.selectPreview(.idle)
        hud.collapsePreview()
        XCTAssertTrue(hud.collapsedStatus("IDLE ⏳").waitForExistence(timeout: 2), "Collapsed preview did not reflect the Idle state.")
        hud.expandPreview()
        hud.selectPreview(.goal)
        hud.collapsePreview()
        XCTAssertTrue(hud.collapsedStatus("GOAL 🟢").waitForExistence(timeout: 2), "Collapsed preview did not reflect the Goal state.")
    }

    @MainActor
    func testHUDVisibleMetricTogglePersistsAfterReopeningEditor() {
        let hud = openHUD()
        hud.openVisibleMetrics()
        XCTAssertTrue(hud.stepsSwitch.waitForExistence(timeout: 2))
        XCTAssertTrue(hud.stepsSwitch.isSwitchOn, "Steps should begin enabled in the default HUD preset.")
        hud.toggleSteps()
        XCTAssertTrue(hud.stepsSwitch.waitForSwitchState(false), "Steps toggle did not turn off.")
        let today = hud.backToTraining()
        XCTAssertTrue(today.title.waitForExistence(timeout: 3))
        let reopened = today.openHUD()
        XCTAssertTrue(reopened.navigationBar.waitForExistence(timeout: 2))
        reopened.openVisibleMetrics()
        XCTAssertTrue(reopened.stepsSwitch.waitForExistence(timeout: 2))
        XCTAssertFalse(reopened.stepsSwitch.isSwitchOn, "Steps visibility did not persist after leaving and reopening HUD customization.")
    }

    @MainActor
    func testHUDResetConfirmationRestoresLivePresetState() {
        let hud = openHUD()
        hud.selectPreview(.paused)
        let dialog = hud.requestNinjaPresetReset()
        XCTAssertTrue(dialog.title.waitForExistence(timeout: 2), "Reset confirmation did not appear.")
        XCTAssertTrue(dialog.confirmButton.waitForExistence(timeout: 2), "Reset confirmation action did not appear.")
        let resetHUD = dialog.confirm()
        XCTAssertTrue(resetHUD.collapsePreviewButton.waitForExistence(timeout: 2), "HUD preview was not available after reset.")
        resetHUD.collapsePreview()
        XCTAssertTrue(resetHUD.collapsedStatus("LIVE ✅").waitForExistence(timeout: 2), "Confirmed reset did not restore the preview to Live.")
    }

    @MainActor
    func testSelectedWarriorAppliesMatchingHUDPreset() {
        let welcome = launchWelcome()
        welcome.selectWarrior(.pirate)
        XCTAssertEqual(welcome.warrior(.pirate).value as? String, "Selected", "Pirate theme was not selected.")
        let today = welcome.beginTraining()
        XCTAssertTrue(today.title.waitForExistence(timeout: 3), "Training Home did not appear.")
        let hud = today.openHUD()
        XCTAssertTrue(hud.navigationBar.waitForExistence(timeout: 2))
        hud.openIdentity()
        XCTAssertTrue(hud.titleField.waitForExistence(timeout: 2), "HUD Title field did not appear.")
        XCTAssertEqual(hud.titleField.value as? String, "🏴‍☠️ PIRATEPACE HUD 🏴‍☠️", "Selecting Pirate did not apply the Pirate HUD preset.")
    }

    @MainActor
    func testHUDTitleEditPersistsAfterReopeningEditor() {
        let hud = openHUD()
        hud.openIdentity()
        XCTAssertTrue(hud.titleField.waitForExistence(timeout: 2))
        hud.replaceTitle(with: "NINJAPACE UI TEST HUD")
        XCTAssertEqual(hud.titleField.value as? String, "NINJAPACE UI TEST HUD")
        let today = hud.backToTraining()
        XCTAssertTrue(today.title.waitForExistence(timeout: 3))
        let reopened = today.openHUD()
        XCTAssertTrue(reopened.navigationBar.waitForExistence(timeout: 2))
        reopened.openIdentity()
        XCTAssertTrue(reopened.titleField.waitForExistence(timeout: 2))
        XCTAssertEqual(reopened.titleField.value as? String, "NINJAPACE UI TEST HUD", "HUD title did not persist after leaving and reopening the editor.")
    }

    @MainActor
    func testGoalPersistsAcrossTabNavigation() {
        let today = launchTraining()
        let goal = today.openGoal()
        XCTAssertTrue(goal.mileage.waitForExistence(timeout: 2))
        goal.selectPreset(.tenK)
        XCTAssertTrue(goal.mileage.waitForLabel("6.21 mi"), "10K preset did not update the goal.")
        let history = today.showHistory()
        XCTAssertTrue(history.title.waitForExistence(timeout: 2))
        let returnedToday = history.showToday()
        XCTAssertTrue(returnedToday.title.waitForExistence(timeout: 2))
        let restoredGoal = returnedToday.openGoal()
        XCTAssertTrue(restoredGoal.mileage.waitForExistence(timeout: 2))
        XCTAssertEqual(restoredGoal.mileage.label, "6.21 mi", "Mileage goal was lost after navigating away from Today.")
    }

    @MainActor
    func testSettingsStartsLockedAndProtectsRelayAddress() {
        let settings = launchTraining().openSettings()
        XCTAssertTrue(settings.navigationBar.waitForExistence(timeout: 2))
        XCTAssertTrue(settings.hiddenAddress.waitForExistence(timeout: 2), "Relay address was not protected on entry.")
        XCTAssertTrue(settings.unlockButton.exists, "Unlock action was not available while the relay address was hidden.")
        XCTAssertFalse(settings.addressField.exists, "Editable relay address field was exposed while locked.")
        XCTAssertFalse(settings.saveButton.exists, "Save Relay Address should not be available while locked.")
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = NinjaPaceTestApp.configured(in: .ready)
            app.launch()
            app.terminate()
        }
    }
    
    @MainActor
    func testSettingsOpensGoalAlertsAndReturns() {
        let settings = launchTraining().openSettings()
        XCTAssertTrue(settings.navigationBar.exists)
        let alerts = settings.openGoalAlerts()
        XCTAssertTrue(alerts.dailyReminderSwitch.waitForExistence(timeout: 2))
        XCTAssertTrue(alerts.reminderTimePicker .waitForExistence(timeout: 2))
        let returned = alerts.backToSettings()
        XCTAssertTrue(returned.navigationBar.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testGoalCelebrationsTogglePersistsAfterReopeningSettings() {
        let settings = launchTraining().openSettings()
        XCTAssertTrue(settings.goalCelebrationsSwitch.waitForExistence(timeout: 2))
        settings.setGoalCelebrations(true)
        XCTAssertTrue(settings.goalCelebrationsSwitch.waitForSwitchState(true))
        let today = settings.backToTraining()
        XCTAssertTrue(today.title.waitForExistence(timeout: 2))
        let reopened = today.openSettings()
        XCTAssertTrue(reopened.goalCelebrationsSwitch.waitForSwitchState(true), "Goal Celebrations setting did not persist.")
    }
    
    @MainActor
    func testHistoryNewestYearStartsExpandedAndCanCollapse() {
        let history = launchTraining(seededHistory: true).showHistory()
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let yearHeader = history.year(year)
        XCTAssertTrue(yearHeader.waitForExistence(timeout: 3))
        XCTAssertEqual(yearHeader.value as? String, "Expanded")
        let monthHeader = history.month(year: year, month: month)
        XCTAssertTrue(monthHeader.waitForExistence(timeout: 2), "Newest year's month was not visible.")
        yearHeader.tap()
        XCTAssertTrue(monthHeader.waitUntilAbsent(), "Month remained visible after collapsing its year.")
        yearHeader.tap()
        XCTAssertTrue(monthHeader.waitForExistence(timeout: 2), "Month did not return after reopening its year.")
    }
    
    @MainActor
    func testWorkoutTrendsShowsCoreAnalytics() {
        let trends = launchTraining(seededHistory: true).showHistory().openWorkoutTrends()
        XCTAssertTrue(trends.scopePicker.waitForExistence(timeout: 2))
        XCTAssertTrue(trends.trainingIntel.waitForExistence(timeout: 2))
        XCTAssertTrue(trends.metricMenu.waitForExistence(timeout: 2))
        XCTAssertTrue(trends.chart.waitForExistence(timeout: 2))
        XCTAssertTrue(trends.summary.waitForExistence(timeout: 2))
        XCTAssertTrue(trends.battleRecord.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testWorkoutTrendsCanSwitchScopeAndMetric() {
        let trends = launchTraining(seededHistory: true).showHistory().openWorkoutTrends()
        XCTAssertTrue(trends.scopeButton("Monthly").waitForExistence(timeout: 3), "Monthly trend scope button did not appear.")
        XCTAssertEqual(trends.scopeButton("Monthly").value as? String, "Selected")
        trends.selectScope("Yearly")
        XCTAssertEqual(trends.scopeButton("Yearly").value as? String, "Selected")
        trends.selectScope("Monthly")
        XCTAssertEqual(trends.scopeButton("Monthly").value as? String, "Selected")
        trends.selectMetric("Avg Heart Rate")
        XCTAssertTrue(trends.summary.waitForExistence(timeout: 2), "Trend summary disappeared after changing metrics.")
        XCTAssertTrue(trends.waitForSummaryValue("142 bpm", timeout: 8), "Avg Heart Rate did not update the focused summary to 142 bpm.")
    }
    
    @MainActor
    func testDebugWarriorFooterDeploysWeaponizedConfetti() {
        let today = launchTraining()
        XCTAssertTrue(today.warriorProgressFooter.waitForExistence(timeout: 3))
        today.triggerDebugGoalCelebration()
        XCTAssertTrue(today.goalCelebration.waitForExistence(timeout: 1), "WEAPONIZED CONFETTI WAS NOT DEPLOYED.")
        XCTAssertEqual(today.goalCelebration.label, "GOAL COMPLETED")
    }
    
    @MainActor
    func testLockedAchievementOpensDetailAndReturnsToAwards() {
        let awards = launchTraining().showAwards()
        XCTAssertTrue(awards.title.waitForExistence(timeout: 2), "Awards screen did not appear.")
        let detail = awards.openAchievement("firstWorkout")
        XCTAssertTrue(detail.status.waitForExistence(timeout: 3), "Achievement detail sheet did not appear.")
        XCTAssertEqual( detail.status.label, "ACHIEVEMENT LOCKED")
        XCTAssertTrue(detail.title.waitForExistence(timeout: 2))
        XCTAssertEqual(detail.title.label, "First Steps")
        XCTAssertTrue(detail.returnButton.waitForExistence(timeout: 2), "Return to Awards button did not appear.")
        let returnedAwards = detail.close()
        XCTAssertTrue(returnedAwards.title.waitForExistence(timeout: 3), "Awards screen did not return after dismissing achievement details.")
    }
    
    @MainActor
    func testUnlockedAchievementShowsUnlockedDetail() {
        let awards = launchTraining(seededHistory: true).showAwards()
        XCTAssertTrue(awards.title.waitForExistence(timeout: 3), "Awards screen did not appear.")
        let detail = awards.openAchievement("firstWorkout")
        XCTAssertTrue(detail.status.waitForExistence(timeout: 3), "Achievement detail sheet did not appear.")
        XCTAssertEqual(detail.status.label, "ACHIEVEMENT UNLOCKED")
        XCTAssertEqual(detail.title.label, "First Steps")
        XCTAssertTrue(detail.returnButton.waitForExistence(timeout: 2))
        let returnedAwards = detail.close()
        XCTAssertTrue(returnedAwards.badges.waitForExistence(timeout: 3), "Awards content was not restored after closing achievement details.")
    }
    
    @MainActor
    func testAwardsCanOpenAchievementBelowInitialViewport() {
        let awards = launchTraining().showAwards()
        let detail = awards.openAchievement("thousandMiles")
        XCTAssertTrue(detail.status.waitForExistence(timeout: 3), "1,000 Mile achievement detail did not appear.")
        XCTAssertEqual(detail.title.label, "1,000 Mile Legend")
        XCTAssertEqual(detail.status.label, "ACHIEVEMENT LOCKED")
        let returnedAwards = detail.close()
        XCTAssertTrue(returnedAwards.title.waitForExistence(timeout: 3))
    }
    
    // Scenario setup keeps launch/readiness assertions out of the page objects.
    @MainActor
    private func launchWelcome(file: StaticString = #filePath, line: UInt = #line) -> WelcomePage {
        let page = NinjaPaceTestApp.launchWelcome()
        XCTAssertTrue(page.title.waitForExistence(timeout: 5), "NinjaPace did not reach welcome.", file: file, line: line)
        return page
    }
    
    @MainActor
    private func launchTraining(live: Bool = false, seededHistory: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> TrainingHomePage {
        let page = NinjaPaceTestApp.launchTraining(live: live, seededHistory: seededHistory)
        XCTAssertTrue(page.title.waitForExistence(timeout: 5), "NinjaPace did not reach Training Home.", file: file, line: line)
        return page
    }
    
    @MainActor
    private func openHUD(file: StaticString = #filePath, line: UInt = #line) -> HUDCustomizationPage {
        let hud = launchTraining(file: file, line: line).openHUD(file: file, line: line)
        XCTAssertTrue(hud.navigationBar.waitForExistence(timeout: 2), "HUD customization did not open.", file: file, line: line)
        return hud
    }
}
