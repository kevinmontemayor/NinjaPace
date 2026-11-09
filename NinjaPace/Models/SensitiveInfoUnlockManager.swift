//
//  SensitiveInfoUnlockManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import Combine
import Foundation
import LocalAuthentication

@MainActor
final class SensitiveInfoUnlockManager: ObservableObject {

    @Published private(set) var isUnlocked = false
    @Published private(set) var errorMessage: String?

    private var relockTask: Task<Void, Never>?
    private let unlockDuration: Duration = .seconds(120)

    func unlock() async -> Bool {
        errorMessage = nil

        let context = LAContext()
        context.localizedCancelTitle = "Keep Locked"

        var authenticationError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authenticationError) else {
            errorMessage = authenticationError?.localizedDescription
                ?? "Device authentication is unavailable."
            isUnlocked = false
            return false
        }

        do {
            let authenticated = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Reveal and edit your private network addresses."
            )

            guard authenticated else {
                isUnlocked = false
                return false
            }

            isUnlocked = true
            scheduleAutomaticRelock()
            return true

        } catch {
            isUnlocked = false

            switch (error as? LAError)?.code {
            case .userCancel, .appCancel, .systemCancel:
                errorMessage = nil

            default:
                errorMessage = error.localizedDescription
            }

            return false
        }
    }

    func lock() {
        relockTask?.cancel()
        relockTask = nil
        isUnlocked = false
        errorMessage = nil
    }

    private func scheduleAutomaticRelock() {
        relockTask?.cancel()
        relockTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: unlockDuration)
                guard !Task.isCancelled else { return }
                lock()
            } catch {
                // Cancellation is expected when locking or authenticating again.
            }
        }
    }
}
