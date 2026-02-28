//
//  RelaySettingsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/18/26.
//

import SwiftUI
import Combine

protocol UsesScheduleDefaults {
    var useScheduleDefaults: Bool { get set }
}

protocol GoalScheduleStoring: ObservableObject {
    associatedtype Schedule
    var schedule: Schedule { get set }
}

struct RelaySettingsView<Client: StatsPushClientProtocol, Store: GoalScheduleStoring>: View where Store.Schedule: UsesScheduleDefaults {
    @ObservedObject var pushClient: Client
    @ObservedObject var scheduleStore: Store
    
    @State private var draft: String = ""
    
    var body: some View {
        Form {
            Section("Mac Relay Address") {
                TextField("###.###.#.###:8787", text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button("Save") {
                    pushClient.macBaseURL = draft
                }
                
                Button("Test Connection") {
                    Task { await pushClient.testConnection() }
                }
            }
            
            Section("Status") {
                statusRow
            }
            
            Section("Goal Schedule") {
                if let concreteStore = scheduleStore as? GoalScheduleStore {
                    NavigationLink("Edit Weekly Schedule") {
                        GoalScheduleSettingsView(store: concreteStore)
                    }
                }

                Toggle("Use Schedule Defaults", isOn: Binding(
                    get: { scheduleStore.schedule.useScheduleDefaults },
                    set: { scheduleStore.schedule.useScheduleDefaults = $0 }
                ))
            }
            
            Section("Help") {
                Text("Use your Mac’s LAN IP (not localhost).\nExample: ###.###.#.###:8787")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Relay Setup")
        .onAppear {
            draft = pushClient.macBaseURL
        }
    }
    
    @ViewBuilder
    private var statusRow: some View {
        // Try to handle known status enums via type casting
        if let status = pushClient.status as? PreviewStatsPushClient.Status {
            switch status {
            case .idle:
                Label("Idle", systemImage: "pause.circle")
            case .pushing:
                Label("Pushing…", systemImage: "arrow.up.circle")
            case .success:
                Label("Connected ✅", systemImage: "checkmark.circle")
            case .failed(let msg):
                Label("Error: \(msg)", systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
            }
        } else if let status = pushClient.status as? StatsPushClient.Status {
            switch status {
            case .idle:
                Label("Idle", systemImage: "pause.circle")
            case .pushing:
                Label("Pushing…", systemImage: "arrow.up.circle")
            case .success:
                Label("Connected ✅", systemImage: "checkmark.circle")
            case .failed(let msg):
                Label("Error: \(msg)", systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
            }
        } else {
            // Fallback generic rendering
            Label("Status", systemImage: "questionmark.circle")
        }
    }
}

#if DEBUG
private struct PreviewGoalSchedule: UsesScheduleDefaults {
    var useScheduleDefaults: Bool = true
}

private final class PreviewGoalScheduleStore: ObservableObject, GoalScheduleStoring {
    @Published var schedule: PreviewGoalSchedule = .init()
}

private final class PreviewStatsPushClient: StatsPushClientProtocol {
    typealias StatusType = Status

    enum Status {
        case idle
        case pushing
        case success
        case failed(String)
    }

    @Published var macBaseURL: String = "<MAC_IP>:8787"
    @Published var status: Status = .idle

    @MainActor
    func testConnection() async {
        // Simulate a quick success
        self.status = .pushing
        try? await Task.sleep(nanoseconds: 400_000_000)
        self.status = .success
    }
}

#Preview("Relay Settings (Idle)") {
    NavigationStack {
        RelaySettingsView<PreviewStatsPushClient, PreviewGoalScheduleStore>(pushClient: PreviewStatsPushClient(), scheduleStore: PreviewGoalScheduleStore())
    }
}
#endif

