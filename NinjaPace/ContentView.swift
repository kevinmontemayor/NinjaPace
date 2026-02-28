//
//  ContentView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ThemeWelcomeView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeStore())
}
