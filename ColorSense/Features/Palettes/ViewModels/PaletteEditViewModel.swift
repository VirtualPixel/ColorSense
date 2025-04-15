//
//  PaletteEditViewModel.swift
//  ColorSense
//
//  Created by Justin Wells on 4/7/25.
//

import SwiftUI
import SwiftData

extension PaletteEditView {
    @MainActor class ViewModel: ObservableObject {
        @Published var paletteName: String
        @Published var colors: [ColorStructure]
        let selectedColor: Color?
        let palette: Palette
        var isNewPalette: Bool

        init(palette: Palette? = nil, selectedColor: Color? = nil) {
            if let existingPalette = palette {
                self.isNewPalette = false
                self.palette = existingPalette
                self.paletteName = existingPalette.wrappedName
                self.colors = existingPalette.wrappedColors
            } else {
                self.isNewPalette = true
                self.palette = Palette(name: "", colors: [])
                self.paletteName = ""
                self.colors = []
            }

            self.selectedColor = selectedColor
            if let selectedColor = selectedColor {
                addColor(hex: selectedColor.toHex())
            }
        }

        func addColor(hex: String ) {
            let cleanHex = hex.replacingOccurrences(of: "#", with: "")
            let newColor = ColorStructure(hex: cleanHex)
            colors.append(newColor)

            if palette.colors != nil {
                palette.colors?.append(newColor)
            } else {
                palette.colors = [newColor]
            }
            palette.name = paletteName
        }

        func removeColor(_ color: ColorStructure) {
            if let index = colors.firstIndex(where: { $0.id == color.id }) {
                colors.remove(at: index)
            }
        }

        func removeColors(at offsets: IndexSet) {
            // Remove from our local copy first
            let colorsToRemove = offsets.map { colors[$0] }
            colors.remove(atOffsets: offsets)

            // Then update the actual model
            for color in colorsToRemove {
                palette.colors?.removeAll { $0.id == color.id }
            }
            palette.name = paletteName
        }

        func moveColors(from source: IndexSet, to destination: Int) {
            colors.move(fromOffsets: source, toOffset: destination)

            palette.colors = colors
            palette.name = paletteName
        }

        func savePalette(context: ModelContext) {
            guard !paletteName.isEmpty else { return }

            palette.name = paletteName
            palette.colors = colors

            if isNewPalette {
                context.insert(palette)
            }

            try? context.save()
        }

        func deletePalette(context: ModelContext) {
            context.delete(palette)

            try? context.save()
        }
    }
}
