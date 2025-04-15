//
//  SharePaletteView.swift
//  ColorSense
//
//  Created by Justin Wells on 4/9/25.
//

import SwiftUI

struct SharePalette<LabelContent: View>: View {
    let palette: Palette
    let labelContent: LabelContent

    var body: some View {
        // Create shareable URL content
        let colorHexCodes = palette.wrappedColors.map { $0.wrappedHex.replacingOccurrences(of: "#", with: "") }
        let colorsString = colorHexCodes.joined(separator: ",")

        // URL encode the palette name
        let encodedName = palette.wrappedName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let paletteURL = "ColorSense://palette?name=\(encodedName)&colors=\(colorsString)"

        // Create the share link with custom preview
        ShareLink(item: createPalettePreviewImage(),
                  subject: Text("Check out this color palette!"),
                  message: Text("\(palette.wrappedName)\nCheck out this palette in ColorSense:\n\(paletteURL)"),
                  preview: SharePreview("Palette: \(palette.wrappedName)",
                                       image: createPalettePreviewImage())) {
            labelContent
        }
    }

    // Create a preview image for the palette
    private func createPalettePreviewImage() -> Image {
        let renderer = ImageRenderer(
            content:
                VStack(spacing: 0) {
                    ForEach(palette.wrappedColors.prefix(5)) { colorStruct in
                        colorStruct.color
                            .frame(height: 50)
                    }
                }
                .frame(width: 200, height: min(50 * CGFloat(palette.wrappedColors.count), 250))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
        )

        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }

        return Image(systemName: "square.on.square")
    }

    init(palette: Palette, @ViewBuilder label: () -> LabelContent) {
        self.palette = palette
        self.labelContent = label()
    }
}

// Add style-based initializer
extension SharePalette where LabelContent == AnyView {
    init(palette: Palette, labelStyle: ShareColorLabelStyle = .withoutText) {
        self.palette = palette
        switch labelStyle {
        case .withText:
            self.labelContent = AnyView(
                HStack {
                    Text("Share Palette")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
            )
        case .withoutText:
            self.labelContent = AnyView(
                Image(systemName: "square.and.arrow.up")
            )
        }
    }
}

#Preview {
    SharePalette(palette: Palette.defaultPalette)
}
