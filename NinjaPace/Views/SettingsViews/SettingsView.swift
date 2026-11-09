//
//  SettingsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/18/26.
//

import SwiftUI
import Combine

struct SettingsView<Client: StatsPushClientProtocol>: View {
    @AppStorage(GoalCelebrationSettings.enabledKey)
    private var goalCelebrationsEnabled = true
    
    @EnvironmentObject private var sensitiveInfoUnlockManager: SensitiveInfoUnlockManager
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var pushClient: Client

    @FocusState private var isRelayFieldFocused: Bool

    @State private var showsGoalAlerts = false
    @State private var draft = ""
    @State private var lastAutoConnectedRelayID: String?
    @State private var isAutomaticDiscoveryExpanded = false
    
    @StateObject private var bonjourBrowser = NinjaPaceBonjourBrowser()

    private var isRelayAddressComplete: Bool {
        normalizedRelayAddress(from: draft) != nil
    }

    private var isUITesting: Bool {
#if DEBUG
        ProcessInfo.processInfo.environment["NINJAPACE_IPHONE_UI_TEST_STATE"] != nil
#else
        false
#endif
    }

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            ScrollViewReader { proxy in
                Form {
                    trainingSettingsSection
                    nearbyRelaysSection
                    relayAddressSection

                    Section("Status") {
                        statusRow
                    }
                    .listRowBackground(
                        themeStore.theme.hudEditorRowBackground
                    )
                    .foregroundStyle(
                        themeStore.theme.appPrimaryTextColor
                    )

                    helpSection
                }
                .scrollContentBackground(.hidden)
                .onChange(of: isRelayFieldFocused) { _, isFocused in
                    if isFocused {
                        withAnimation {
                            proxy.scrollTo("relayAddressField", anchor: .center)
                        }
                    }
                }
            }
        }
        .tint(themeStore.theme.tint)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigateBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    appendPeriod()
                } label: {
                    Text(".")
                        .font(.title2.bold())
                }
                .disabled(!canAppendPeriod)

                Button {
                    appendColon()
                } label: {
                    Text(":")
                        .font(.title2.bold())
                }
                .disabled(!canAppendColon)

                Spacer()

                Button("Save") {
                    saveRelayAddress()
                }
                .fontWeight(.semibold)
                .disabled(!isRelayAddressComplete)
            }
        }
        .onAppear {
            if !isUITesting {
                bonjourBrowser.startBrowsing()
            }
            draft = sensitiveInfoUnlockManager.isUnlocked ? pushClient.macBaseURL : ""
        }
        .onChange(of: bonjourBrowser.discoveredRelays) { _, relays in
            guard relays.count == 1 else { return }
            autoConnectToSingleRelayIfPossible()
        }
        .onChange(of: sensitiveInfoUnlockManager.isUnlocked) { _, isUnlocked in
            draft = isUnlocked ? pushClient.macBaseURL : ""
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                lockRelayAddress()
            }
        }
        .onDisappear {
            isRelayFieldFocused = false
            if !isUITesting {
                bonjourBrowser.stopBrowsing()
            }
        }
        .navigationDestination(
            isPresented: $showsGoalAlerts
        ) {
            GoalAlertsSettingsView()
        }
    }

    // MARK: - Sections
    
    private var trainingSettingsSection: some View {
        Section("Training") {
            Button {
                showsGoalAlerts = true
            } label: {
                HStack(spacing: 12) {
                    Label("Goal Alerts", systemImage: "bell.badge.fill")
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("goalAlertsButton")
            
            Toggle(isOn: $goalCelebrationsEnabled) {
                Label("Goal Celebrations", systemImage: "sparkles")
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            }
            .tint(themeStore.theme.tint)
            .accessibilityIdentifier("goalCelebrationsToggle")
        }
        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }
    
    private var nearbyRelaysSection: some View {
        Section("Nearby NinjaPace Macs") {
            if bonjourBrowser.discoveredRelays.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Searching for NinjaPace Relay…")
                            .fontWeight(.semibold)
                        
                        Text("Make sure NinjaPaceMac is running and both devices are on the same Wi-Fi network.")
                            .font(.caption)
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                }
            } else {
                ForEach(bonjourBrowser.discoveredRelays) { relay in
                    Button {
                        Task {
                            draft = sensitiveInfoUnlockManager.isUnlocked ? relay.address : ""
                            pushClient.macBaseURL = relay.address
                            await pushClient.testConnection()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "desktopcomputer")
                                .font(.title3)
                                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(relay.name)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                                
                                if sensitiveInfoUnlockManager.isUnlocked {
                                    Text(relay.address)
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                                        .privacySensitive()
                                } else {
                                    Label("Address hidden", systemImage: "lock.fill")
                                        .font(.footnote)
                                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                                }
                            }

                            Spacer()

                            Image(
                                systemName: pushClient.macBaseURL == relay.address
                                    ? "checkmark.circle.fill"
                                    : "arrow.right.circle"
                            )
                            .foregroundStyle(
                                pushClient.macBaseURL == relay.address
                                    ? .green
                                    : themeStore.theme.appSecondaryTextColor
                            )
                        }
                    }
                }
            }

            if let errorMessage = bonjourBrowser.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }

    private var relayAddressSection: some View {
        Section("Mac Relay Address") {
            if sensitiveInfoUnlockManager.isUnlocked {
                Label {
                    Text("Address Unlocked")
                } icon: {
                    Image(systemName: "lock.open.fill")
                }
                .font(.footnote)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                TextField("Mac name or IP address", text: $draft)
                    .id("relayAddressField")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .focused($isRelayFieldFocused)
                    .privacySensitive()
                    .onChange(of: draft) { _, newValue in
                        let sanitized = sanitizeRelayAddressInput(newValue)
                        if sanitized != newValue {
                            draft = sanitized
                        }
                    }

                Text("Port 8787 is used automatically for manual addresses. Auto-discovery uses the relay's actual port.")
                    .font(.caption2)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                if let message = relayAddressValidationMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button {
                    saveRelayAddress()
                } label: {
                    Label("Save Relay Address", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
                .disabled(!isRelayAddressComplete)

                Button {
                    Task {
                        saveRelayAddress()
                        await pushClient.testConnection()
                    }
                } label: {
                    Label("Test Connection", systemImage: "network")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
                .disabled(!isRelayAddressComplete)

                Button {
                    lockRelayAddress()
                } label: {
                    Label("Hide Relay Address", systemImage: "lock.fill")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Relay Address Hidden")
                            .fontWeight(.semibold)
                            .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                        Text(maskedRelayAddress)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }

                    Spacer()
                }

                Button {
                    Task {
                        let authenticated = await sensitiveInfoUnlockManager.unlock()
                        if authenticated {
                            draft = pushClient.macBaseURL
                        }
                    }
                } label: {
                    Label("Unlock to Reveal and Edit", systemImage: "faceid")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }

                if let errorMessage = sensitiveInfoUnlockManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }

    private var helpSection: some View {
        Section("Help") {
            ThemedDisclosureGroup(isExpanded: $isAutomaticDiscoveryExpanded) {
                Label(
                    "Automatic Discovery",
                    systemImage: "dot.radiowaves.left.and.right"
                )
                .fontWeight(.semibold)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            } content: {
                VStack(alignment: .leading, spacing: 10) {
                    Text("NinjaPace automatically searches for a running NinjaPace Mac relay on your local network.")
                        .font(.footnote)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                    Text("If no Mac appears, make sure NinjaPaceMac is open, the relay is running, and your iPhone and Mac are connected to the same Wi-Fi network.")
                        .font(.footnote)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                    Text("You can still enter the Mac address manually if needed.")
                        .font(.footnote)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                .padding(.vertical, 6)
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusRow: some View {
        if let status = pushClient.status as? StatsPushClient.Status {
            switch status {
            case .idle:
                Label("Idle", systemImage: "pause.circle")
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

            case .pushing:
                Label("Pushing…", systemImage: "arrow.up.circle")
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

            case .success:
                Label("Connected ✅", systemImage: "checkmark.circle")
                    .foregroundStyle(
                        themeStore.theme == .ninja
                            ? .green
                            : themeStore.theme.appPrimaryTextColor
                    )

            case .failed(let message):
                // Connection errors can include the relay host or URL.
                Label(
                    sensitiveInfoUnlockManager.isUnlocked
                        ? "Error: \(message)"
                        : "Connection failed. Unlock to view details.",
                    systemImage: "xmark.octagon"
                )
                    .foregroundStyle(.red)
            }
        } else {
            Label("Status", systemImage: "questionmark.circle")
        }
    }

    // MARK: - Relay Setup Helpers

    private var maskedRelayAddress: String {
        let address = pushClient.macBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else { return "Not configured" }

        if let colon = address.lastIndex(of: ":") {
            let port = address[address.index(after: colon)...]

            if Int(port) != nil {
                return "••••••••••••:\(port)"
            }
        }

        return "••••••••••••"
    }

    private func lockRelayAddress() {
        isRelayFieldFocused = false
        draft = ""
        sensitiveInfoUnlockManager.lock()
    }

    private func saveRelayAddress() {
        guard let normalized = normalizedRelayAddress(from: draft) else { return }

        pushClient.macBaseURL = normalized
        draft = normalized
        isRelayFieldFocused = false
    }

    private func normalizedRelayAddress(from value: String) -> String? {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !trimmed.isEmpty else { return nil }

        let host: String
        let port: Int

        if let colonIndex = trimmed.lastIndex(of: ":") {
            let possibleHost = String(trimmed[..<colonIndex])
            let possiblePort = String(trimmed[trimmed.index(after: colonIndex)...])

            guard !possibleHost.isEmpty,
                  !possiblePort.isEmpty,
                  let parsedPort = Int(possiblePort),
                  (8787...8795).contains(parsedPort)
            else {
                return nil
            }

            host = possibleHost
            port = parsedPort
        } else {
            host = trimmed
            port = 8787
        }

        guard isValidRelayHost(host) else { return nil }
        return "\(host):\(port)"
    }

    private func sanitizeRelayAddressInput(_ value: String) -> String {
        let allowedCharacters = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-.:"
        )

        var result = ""
        var hasColon = false
        var portDigitCount = 0

        for scalar in value.unicodeScalars {
            guard allowedCharacters.contains(scalar) else { continue }

            let character = Character(String(scalar))

            if character == ":" {
                guard !hasColon, !result.isEmpty else { continue }

                result.append(character)
                hasColon = true
                portDigitCount = 0
                continue
            }

            if hasColon {
                guard character.isNumber, portDigitCount < 5 else { continue }

                result.append(character)
                portDigitCount += 1
                continue
            }

            result.append(character)
        }

        return result
    }

    private func autoConnectToSingleRelayIfPossible() {
        guard bonjourBrowser.discoveredRelays.count == 1,
              let relay = bonjourBrowser.discoveredRelays.first,
              lastAutoConnectedRelayID != relay.id
        else {
            return
        }

        lastAutoConnectedRelayID = relay.id
        draft = sensitiveInfoUnlockManager.isUnlocked ? relay.address : ""
        pushClient.macBaseURL = relay.address
    }

    private func navigateBack() {
        guard isRelayFieldFocused else {
            dismiss()
            return
        }

        isRelayFieldFocused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
        }
    }

    // MARK: - Formatting Helpers

    private var hostPart: String {
        draft
            .split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? ""
    }

    private var periodCount: Int {
        hostPart.filter { $0 == "." }.count
    }

    private var currentOctet: String {
        hostPart
            .split(separator: ".", omittingEmptySubsequences: false)
            .last
            .map(String.init) ?? ""
    }

    private var canAppendPeriod: Bool {
        guard !draft.contains(":"),
              periodCount < 3,
              !currentOctet.isEmpty,
              let value = Int(currentOctet)
        else {
            return false
        }

        return (0...255).contains(value)
    }

    private var canAppendColon: Bool {
        guard !draft.contains(":"),
              periodCount == 3,
              !currentOctet.isEmpty,
              let value = Int(currentOctet)
        else {
            return false
        }

        return (0...255).contains(value)
    }

    private func appendPeriod() {
        guard canAppendPeriod else { return }
        draft.append(".")
    }

    private func appendColon() {
        guard canAppendColon else { return }
        draft.append(":")
    }

    // MARK: - Validation

    private var relayAddressValidationMessage: String? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if normalizedRelayAddress(from: trimmed) != nil {
            return nil
        }

        if let colonIndex = trimmed.lastIndex(of: ":") {
            let portText = String(trimmed[trimmed.index(after: colonIndex)...])

            if portText.isEmpty {
                return "Enter a port number, or remove ':' to use port 8787 automatically."
            }

            if Int(portText) == nil {
                return "The relay port must contain numbers only."
            }

            if let port = Int(portText), !(8787...8795).contains(port) {
                return "Relay ports range from 8787 to 8795."
            }
        }

        return "Enter your Mac's Bonjour name or local IP address."
    }

    private func isValidRelayHost(_ host: String) -> Bool {
        guard !host.isEmpty else { return false }

        // IPv4
        let octets = host.split(separator: ".", omittingEmptySubsequences: false)

        if octets.count == 4,
           octets.allSatisfy({ octet in
               guard let value = Int(octet) else { return false }
               return (0...255).contains(value)
           }) {
            return true
        }

        // Bonjour / DNS hostname
        let allowed = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."
        )

        guard host.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return false
        }

        guard !host.hasPrefix("."),
              !host.hasSuffix("."),
              !host.contains("..")
        else {
            return false
        }

        let labels = host.split(separator: ".", omittingEmptySubsequences: false)

        return labels.allSatisfy {
            !$0.isEmpty &&
            !$0.hasPrefix("-") &&
            !$0.hasSuffix("-")
        }
    }
}

#if DEBUG

private final class PreviewStatsPushClient: StatsPushClientProtocol {
    typealias StatusType = StatsPushClient.Status

    @Published var macBaseURL = "<MAC_IP>:8787"
    @Published var status: StatsPushClient.Status = .idle

    @MainActor
    func testConnection() async {
        status = .pushing
        try? await Task.sleep(for: .milliseconds(400))
        status = .success
    }
}

#Preview("Relay Settings (Idle)") {
    NavigationStack {
        SettingsView(pushClient: PreviewStatsPushClient())
            .environmentObject(SensitiveInfoUnlockManager())
            .environmentObject(ThemeStore())
            .environmentObject(HealthStreamManager())
    }
}

#endif
