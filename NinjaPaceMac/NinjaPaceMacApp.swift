//
//  NinjaPaceMacApp.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 2/12/26.
//

import SwiftUI
import SwiftData

@main
struct NinjaPaceMacApp: App {
    @StateObject private var server = MacRelayServer()
    
    var body: some Scene {
        WindowGroup {
            ContentView(server: server)
        }
        Window("HUD Studio", id: "hud-studio") {
            MacHUDCustomizationView(server: server)
        }
        .defaultSize(width: 1_100, height: 760)
    }
}
