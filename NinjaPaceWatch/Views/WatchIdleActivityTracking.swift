//
//  WatchIdleActivityTracking.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

/// Tracks input without replacing native taps, scrolling, or Crown navigation.
struct WatchIdleActivityTracking: ViewModifier {
    let onActivity: () -> Void
    let onInteractionChanged: (Bool) -> Void
    // Native list navigation handles its own taps. Observe those through actions
    // and destination appearances instead of attaching an ancestor gesture.
    var tracksTouches = true
    @GestureState private var isTouching = false
    @State private var isScrolling = false

    func body(content: Content) -> some View {
        touchTracking(content)
            .onScrollPhaseChange { _, phase in
                isScrolling = phase != .idle
                onActivity()
            }
            .onChange(of: isTouching || isScrolling) { _, interacting in
                onInteractionChanged(interacting)
                onActivity()
            }
            .onAppear { onActivity() }
            .onDisappear { onInteractionChanged(false) }
    }

    @ViewBuilder
    private func touchTracking(_ content: Content) -> some View {
        if tracksTouches {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isTouching) { _, touching, _ in touching = true }
                        .onEnded { _ in onActivity() }
                )
        } else {
            content
        }
    }
}
