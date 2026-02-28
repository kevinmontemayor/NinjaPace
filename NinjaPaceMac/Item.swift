//
//  Item.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 2/12/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
