//
//  ThemedToggleStyle.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/21/26.
//

import SwiftUI

struct ThemedToggleStyle: ToggleStyle {

    let theme: AppTheme

    private var onTrackColor: Color {
        theme == .viking ? .white : theme.appAccentTextColor
    }

    private var offTrackColor: Color {
        theme.appSecondaryTextColor.opacity(0.28)
    }

    private var thumbColor: Color {
        theme == .viking || theme == .knight ? .gray : .white
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    configuration.isOn.toggle()
                }
            } label: {
                ZStack {
                    Capsule()
                        .fill(configuration.isOn ? onTrackColor : offTrackColor)
                        .frame(width: 51, height: 31)

                    Circle()
                        .fill(thumbColor)
                        .frame(width: 27, height: 27)
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        .offset(x: configuration.isOn ? 10 : -10)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Ninja Toggle") {
    @Previewable @State var isEnabled = true

    Toggle("Schedule Defaults", isOn: $isEnabled)
        .toggleStyle(ThemedToggleStyle(theme: .ninja))
        .padding()
}

#Preview("Viking Toggle") {
    @Previewable @State var isEnabled = true

    Toggle("Schedule Defaults", isOn: $isEnabled)
        .toggleStyle(ThemedToggleStyle(theme: .viking))
        .padding()
}
