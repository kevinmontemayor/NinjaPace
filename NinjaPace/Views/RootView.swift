//
//  RootView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        NavigationStack {
            ThemeWelcomeView()
        }
    }
}

#Preview {
    RootView()
}
