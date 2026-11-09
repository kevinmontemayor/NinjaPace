//
//  AppTheme+WarriorProgression.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/24/26.
//

import SwiftUI

extension AppTheme {
    
    func warriorAsset(for level: WarriorProgressionLevel) -> String? {
        switch self {
            
        case .ninja:
            switch level {
            case .level1:
                return "ninja_lvl1"
                
            case .level2:
                return "ninja_lvl2"
                
            case .level3:
                return "ninja_lvl3"
                
            case .level4:
                return "ninja_lvl4"
            }
            
        case .viking:
            switch level {
            case .level1:
                return "viking_lvl1"
                
            case .level2:
                return "viking_lvl2"
                
            case .level3:
                return "viking_lvl3"
                
            case .level4:
                return "viking_lvl4"
            }
            
        case .knight:
            switch level {
            case .level1:
                return "knight_lvl1"
                
            case .level2:
                return "knight_lvl2"
                
            case .level3:
                return "knight_lvl3"
                
            case .level4:
                return "knight_lvl4"
            }
            
        case .pirate:
            switch level {
            case .level1:
                return "pirate_lvl1"
                
            case .level2:
                return "pirate_lvl2"
                
            case .level3:
                return "pirate_lvl3"
                
            case .level4:
                return "pirate_lvl4"
            }
            
        case .cyborg:
            switch level {
            case .level1:
                return "cyborg_lvl1"
                
            case .level2:
                return "cyborg_lvl2"
                
            case .level3:
                return "cyborg_lvl3"
                
            case .level4:
                return "cyborg_lvl4"
            }
            
        case .spartan:
            switch level {
            case .level1:
                return "spartan_lvl1"
                
            case .level2:
                return "spartan_lvl2"
                
            case .level3:
                return "spartan_lvl3"
                
            case .level4:
                return "spartan_lvl4"
            }
        }
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
