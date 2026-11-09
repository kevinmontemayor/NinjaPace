//
//  MonthlyChallengesScreen.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/29/26.
//

import SwiftUI
#if DEBUG
import SwiftData
#endif

struct MonthlyChallengesScreen: View {

    @EnvironmentObject private var themeStore: ThemeStore

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        ZStack {

            WarriorBackgroundView()

            ScrollView {

                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Header

                    VStack(spacing: 12) {

                        Image(MonthlyChallenge.current?.badgeAsset ?? "achievement_month_1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 110)
                            .shadow(
                                color: themeStore.theme.tint.opacity(0.4),
                                radius: 18
                            )

                        Text("MONTHLY CHALLENGES")
                            .font(.title.bold())
                            .tracking(1)
                            .foregroundStyle(
                                themeStore.theme.appPrimaryTextColor
                            )

                        Text(
                            "Twelve months. Twelve legendary trials. " +
                            "A new challenge awaits every month."
                        )
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            themeStore.theme.appSecondaryTextColor
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                    // MARK: - Monthly Challenge Collection

                    MonthlyChallengeVault()
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Monthly Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {

                Button {
                    dismiss()
                } label: {
                    Label(
                        "Back",
                        systemImage: "chevron.left"
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .tint(themeStore.theme.tint)
    }
}

#if DEBUG
@MainActor
private struct MonthlyChallengesScreenPreview: View {
    @StateObject private var themeStore = ThemeStore()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: WorkoutRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Monthly Challenges preview failed: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            MonthlyChallengesScreen()
        }
        .modelContainer(container)
        .environmentObject(themeStore)
    }
}

#Preview("Monthly Challenges") {
    MonthlyChallengesScreenPreview()
}
#endif
