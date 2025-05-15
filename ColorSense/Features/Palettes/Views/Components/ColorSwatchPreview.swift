//
//  ColorSwatchPreview.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

struct ColorSwatchPreview: View {
    let colors: [Color]
    let maxSwatches: Int

    init(colors: [Color], maxSwatches: Int = 10) {
        self.colors = colors
        self.maxSwatches = maxSwatches
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<min(colors.count, maxSwatches), id: \.self) { index in
                    ColorSwatch(color: colors[index])
                }

                if colors.count > maxSwatches {
                    Text("+\(colors.count - maxSwatches)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct ColorSwatch: View {
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                )
                .shadow(radius: 1)

            Text(color.toHex())
                .font(.system(size: 8))
                .lineLimit(1)
        }
        .frame(width: 44)
    }
}
