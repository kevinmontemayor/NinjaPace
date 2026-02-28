//
//  ThemeIconView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI


struct ThemeIconView: View {
    let icon: ThemeToolbarIcon
    let tint: Color
    var size: CGFloat = 18

    var body: some View {
        Group {
            if let system = icon.systemName {
                Image(systemName: system)
                    .font(.system(size: size, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
            } else if let asset = icon.assetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: size, weight: .semibold))
            }
        }
        .foregroundStyle(tint)
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

#Preview("Default") {
    ThemeIconView(icon: .init(systemName: "star.fill", assetName: nil), tint: .yellow)
}
