//
//  ThemedDisclosureGroup.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/21/26.
//

import SwiftUI

struct ThemedDisclosureGroup<Label: View, Content: View>: View {

    @Binding var isExpanded: Bool

    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.smooth(duration: 0.35)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    label()
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(.top, 12)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(
                                with: .scale(scale: 0.98, anchor: .top)
                            ),
                            removal: .opacity
                        )
                    )
            }
        }
    }
}

private struct ThemedDisclosureGroupThemePreview: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @State private var isExpanded = true

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            VStack {
                ThemedDisclosureGroup(isExpanded: $isExpanded) {
                    Label("Appearance", systemImage: "slider.horizontal.3")
                        .fontWeight(.semibold)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                } content: {
                    VStack(spacing: 14) {
                        HStack {
                            Text("Text Size")
                            Spacer()
                            Text("1.00x")
                                .monospacedDigit()
                        }

                        Divider()

                        HStack {
                            Text("Glow Intensity")
                            Spacer()
                            Text("75%")
                                .monospacedDigit()
                        }

                        Divider()

                        Toggle("Example Setting", isOn: .constant(true))
                    }
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                .padding()
                .background(
                    themeStore.theme.hudEditorRowBackground,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

                Spacer()
            }
            .padding()
        }
        .tint(themeStore.theme.appPrimaryTextColor)
    }
}

#Preview("NinjaPace Theme") {
    ThemedDisclosureGroupThemePreview()
        .environmentObject(ThemeStore())
}
