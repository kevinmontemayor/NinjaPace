//
//  ThemeCard.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/26/26.
//

import SwiftUI

struct ThemeCard: View {

    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geometry in
                Image(theme.cardArtAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(theme.displayName)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? theme.tint : .clear, lineWidth: 3)
        }
        .shadow(radius: isSelected ? 8 : 2)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}
#Preview {
    ThemeCard(theme: .ninja, isSelected: true)
}
