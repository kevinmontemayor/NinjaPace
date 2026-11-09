//
//  IncrementButton.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/28/26.
//

import SwiftUI

struct IncrementButton: View {
    enum Kind { case minus, plus }

    let kind: Kind
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: kind == .minus ? "minus" : "plus")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 40, height: 40)
        }
        .background(
            Circle()
                .fill(tint.opacity(0.15))
        )
        .overlay(
            Circle()
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
        .foregroundStyle(tint)
        .contentShape(Circle())
    }
}

#Preview("IncrementButton - Plus") {
    IncrementButton(kind: .plus, tint: .blue) {}
}

#Preview("IncrementButton - Minus") {
    IncrementButton(kind: .minus, tint: .red) {}
}
