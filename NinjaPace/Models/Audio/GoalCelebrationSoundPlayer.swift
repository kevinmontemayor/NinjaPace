//
//  GoalCelebrationSoundPlayer.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 10/4/26.
//

import AVFoundation

final class GoalCelebrationSoundPlayer: @unchecked Sendable {
    static let shared = GoalCelebrationSoundPlayer()

    private let audioQueue = DispatchQueue(
        label: "com.ninjapace.goal-celebration-audio"
    )

    private var player: AVAudioPlayer?

    private init() {}

    func play(assetName: String) {
#if DEBUG
        guard ProcessInfo.processInfo.environment["NINJAPACE_IPHONE_UI_TEST_STATE"] == nil else {
            return
        }
#endif

        guard let url = Bundle.main.url(
            forResource: assetName,
            withExtension: "wav"
        ) else {
            return
        }

        audioQueue.async { [self] in
            do {
                let session = AVAudioSession.sharedInstance()

                try session.setCategory(
                    .ambient,
                    mode: .default,
                    options: []
                )

                let player = try AVAudioPlayer(contentsOf: url)

                player.volume = 1.0
                player.prepareToPlay()

                self.player = player
                player.play()
            } catch {
                // Goal celebration audio is non-critical.
            }
        }
    }
}
