//
//  Color+Extensions.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/24/26.
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let clean = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        switch clean.count {
        case 3:
            red = Double((value >> 8) & 0xF) / 15
            green = Double((value >> 4) & 0xF) / 15
            blue = Double(value & 0xF) / 15

        default:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        }

        self.init(red: red, green: green, blue: blue)
    }

    func hexString() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }

        let red = components.count > 0 ? components[0] : 0
        let green = components.count > 1 ? components[1] : red
        let blue = components.count > 2 ? components[2] : red

        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
