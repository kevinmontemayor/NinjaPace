//
//  ThemeStore.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ThemeStore: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.ninja.rawValue

    @Published var theme: AppTheme = .ninja {
        didSet { selectedThemeRaw = theme.rawValue }
    }

    init() {
        theme = AppTheme(rawValue: selectedThemeRaw) ?? .ninja
    }
}
