//
//  ContentView.swift
//  NinjaPaceWatch Watch App
//
//  Created by Kevin Montemayor on 2/6/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = WatchWorkoutManager()
    
    private var theme: WatchTheme { .from(manager.themeKey) }
    
    @MainActor
    init(manager: WatchWorkoutManager? = nil) {
        let instance = manager ?? WatchWorkoutManager()
        _manager = StateObject(wrappedValue: instance)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                header
                statsGrid
                progressBar
                controlsRow
                serverRow
                Color.clear.frame(height: 8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
        }
        .scrollIndicators(.hidden)
        .onAppear { manager.activate() }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: manager.running ? "figure.run" : "figure.walk")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(theme.emoji) \(theme.headerTitle)")
                    .font(.headline)

                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
                    .overlay(alignment: .trailing) {
                        if manager.running && !manager.paused {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                                .shadow(radius: 2)
                                .offset(x: 10)
                        }
                    }
            }
            Spacer()
            
            Image(systemName: theme.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.tint)
        }
    }

    // MARK: - Stats
    private var statsGrid: some View {
        VStack(spacing: 6) {
            statRow(label: "Steps", value: "\(manager.steps)")
            statRow(label: "Pace", value: manager.paceString)
            statRow(label: "Miles", value: String(format: "%.2f", manager.miles))
            statRow(label: "Heart Rate", value: manager.hr > 0 ? "\(manager.hr)" : "—")
        }
        .font(.system(.footnote, design: .monospaced))
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var statusText: String {
        if manager.running {
            return manager.paused ? "PAUSED" : "LIVE"
        } else {
            return "READY"
        }
    }
    
    private var statusColor: Color {
        if manager.running {
            return manager.paused ? .yellow : .green
        } else {
            return .secondary
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label).opacity(0.7)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack {
            VStack(spacing: 4) {
                HStack {
                    Text("GOAL")
                        .font(.caption2)
                        .opacity(0.7)
                    Spacer()
                    Text("\(manager.miles, specifier: "%.2f") / \(manager.goalMiles, specifier: "%.2f")")
                        .font(.caption2)
                        .fontDesign(.monospaced)
                        .opacity(0.9)
                }
                ProgressView(value: manager.progress)
                    .tint(theme.tint)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Controls
    private var controlsRow: some View {
        HStack(spacing: 8) {
            Button {
                manager.toggleStartPause()
            } label: {
                primaryActionLabel
            }
            .buttonStyle(.borderedProminent)
            .tint(manager.running && !manager.paused ? .yellow : theme.tint)
            
            Button(role: .destructive) {
                manager.stop()
            } label: {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!manager.running)
        }
    }

    // MARK: - “Server”
    private var serverRow: some View {
        Button {
            manager.toggleStreaming()
        } label: {
            HStack {
                Image(systemName: manager.streamingEnabled ? "dot.radiowaves.left.and.right" : "dot.radiowaves.left.and.right.slash")
                Text(manager.streamingEnabled ? "Streaming ON" : "Streaming OFF")
                Spacer()
            }
        }
        .buttonStyle(.bordered)
        .tint(manager.streamingEnabled ? theme.tint : .gray)
    }
    
    @ViewBuilder
    private var primaryActionLabel: some View {
        if manager.running && !manager.paused {
            HStack(spacing: 6) {
                ThemedSpinnerIconView(systemName: theme.symbol, tint: theme.tint, size: 16)
                Text("Pause")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        } else {
            Label("Start", systemImage: "play.fill")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private struct PreviewHost: View {
    let configure: (WatchWorkoutManager) -> Void

    var body: some View {
        let m = WatchWorkoutManager()
        configure(m)
        return ContentView(manager: m)
    }
}

#Preview("NinjaPace — LIVE") {
    PreviewHost { m in
        m.miles = 3.14
        m.steps = 6240
        m.hr = 142
        m.running = true
        m.paused = false
        m.streamingEnabled = true
        m.elapsedSeconds = 28 * 60 + 10
    }
}

#Preview("NinjaPace — PAUSED") {
    PreviewHost { m in
        m.miles = 9.50
        m.steps = 10500
        m.hr = 120
        m.running = true
        m.paused = true
        m.streamingEnabled = false
        m.elapsedSeconds = 90 * 60 + 5
    }
}
