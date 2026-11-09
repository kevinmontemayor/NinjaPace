//
//  WatchGoalCelebrationSoundPlayer.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 10/4/26.
//

import AVFoundation

final class WatchGoalCelebrationSoundPlayer: @unchecked Sendable {
    static let shared = WatchGoalCelebrationSoundPlayer()
    
    private let audioQueue = DispatchQueue(
        label: "com.ninjapace.watch.goal-celebration-audio"
    )
    
    private var player: AVAudioPlayer?
    
    private init() {}
    
    func play(assetName: String) {
#if DEBUG
        guard ProcessInfo.processInfo.environment["NINJAPACE_UI_TEST_STATE"] == nil else {
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
                try session.setCategory(.ambient, mode: .default, options: [])
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 1.0
                player.prepareToPlay()
                self.player = player
                player.play()
            } catch {
                // Celebration audio is non-critical.
            }
        }
    }
}
