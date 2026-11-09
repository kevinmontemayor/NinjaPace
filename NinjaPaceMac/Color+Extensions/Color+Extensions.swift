//
//  Color+Extensions.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 8/22/26.
//

import AppKit
import Foundation
import SwiftUI

extension Color {

    init(hudHex: String) {
        let cleaned = hudHex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))

        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            self = .white
            return
        }

        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }

    func hudHexString() -> String? {
        guard let rgb = NSColor(self).usingColorSpace(.sRGB) else { return nil }

        return String(
            format: "#%02X%02X%02X",
            Int((rgb.redComponent * 255).rounded()),
            Int((rgb.greenComponent * 255).rounded()),
            Int((rgb.blueComponent * 255).rounded())
        )
    }
}
