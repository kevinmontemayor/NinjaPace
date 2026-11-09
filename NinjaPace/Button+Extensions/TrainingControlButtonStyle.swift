//
//  TrainingControlButtonStyle.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/10/26.
//

import Foundation
import SwiftUI

struct TrainingControlButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(foregroundColor.opacity(0.22), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("TrainingControlButtonStyle Samples") {
    VStack(spacing: 12) {
        Button("Start Training") {}
            .buttonStyle(
                TrainingControlButtonStyle(
                    backgroundColor: .blue,
                    foregroundColor: .white
                )
            )

        Button("Stop Training") {}
            .buttonStyle(
                TrainingControlButtonStyle(
                    backgroundColor: .red,
                    foregroundColor: .white
                )
            )

        Button("Custom") {}
            .buttonStyle(
                TrainingControlButtonStyle(
                    backgroundColor: .black,
                    foregroundColor: .red
                )
            )
    }
    .padding()
}
