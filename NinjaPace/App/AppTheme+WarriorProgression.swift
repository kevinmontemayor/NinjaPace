//
//  AppTheme+WarriorProgression.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/24/26.
//

import SwiftUI

extension AppTheme {
    
    func warriorAsset(for level: WarriorProgressionLevel) -> String? {
        level.assetName(forThemeKey: rawValue)
    }

    var progressionPlaceholderSymbol: String {
        switch self {
        case .ninja:
            return "figure.martial.arts"
            
        case .viking:
            return "shield.fill"
            
        case .knight:
            return "shield.lefthalf.filled"
            
        case .pirate:
            return "helm"
            
        case .cyborg:
            return "cpu.fill"
            
        case .spartan:
            return "shield.fill"
        }
    }
}
