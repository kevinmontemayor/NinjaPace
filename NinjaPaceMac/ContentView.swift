//
//  ContentView.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 2/12/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var server = MacRelayServer()

    var body: some View {
        VStack(spacing: 12) {
            Text("NinjaPace Relay")
                .font(.title2).bold()

            Text(server.isRunning ? "RUNNING ✅" : "STOPPED")
                .foregroundStyle(server.isRunning ? .green : .secondary)

            Text("OBS URL: http://localhost:8787/")
                .font(.system(.body, design: .monospaced))

            HStack {
                Button("Start") { server.start() }
                Button("Stop") { server.stop() }
            }
        }
        .padding()
        .onAppear { server.start() }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
