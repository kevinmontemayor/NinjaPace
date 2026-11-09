//
//  MacHUDConfigurationMode.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 8/22/26.
//

import Foundation

enum MacHUDConfigurationMode: String, Codable, CaseIterable, Identifiable {

    case followIPhone
    case localOverride

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .followIPhone:
            return "Follow iPhone"
            
        case .localOverride:
            return "Customize on This Mac"
        }
    }
}
