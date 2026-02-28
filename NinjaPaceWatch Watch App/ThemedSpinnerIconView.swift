//
//  ThemedSpinnerIconView.swift
//  NinjaPaceWatch Watch App
//
//  Created by Kevin Montemayor on 2/7/26.
//

import SwiftUI

struct ThemedSpinnerIconView: View {
    let systemName: String
    let tint: Color
    let size: CGFloat

    @State private var spinning = false

    init(systemName: String, tint: Color, size: CGFloat = 16) {
        self.systemName = systemName
        self.tint = tint
        self.size = size
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(tint)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(.linear(duration: 1.15).repeatForever(autoreverses: false), value: spinning)
            .onAppear { spinning = true }
            .shadow(radius: 2)
            .accessibilityHidden(true)
    }
}

#Preview("Spinner Preview") {
    ThemedSpinnerIconView(systemName: "arrow.triangle.2.circlepath", tint: .blue, size: 20)
        .padding()
        .background(Color.black.opacity(0.1))
}
