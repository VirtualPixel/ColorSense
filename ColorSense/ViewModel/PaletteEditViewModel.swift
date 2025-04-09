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

        var isNewPalette: Bool {
            originalPalette == nil
        }

        private var originalPalette: Palette?
        private let context: ModelContext?

        init(palette: Palette? = nil, context: ModelContext? = nil) {
            self.originalPalette = palette
            self.context = context

            if let palette = palette {
                self.paletteName = palette.name ?? ""
                self.colors = palette.colors?.sorted(by: {
                    $0.creationDate ?? Date() > $1.creationDate ?? Date()
                }) ?? []
            } else {
                self.paletteName = ""
                self.colors = []
            }
        }

        func addColor(hex: String ) {
            let cleanHex = hex.replacingOccurrences(of: "#", with: "")
            let newColor = ColorStructure(hex: cleanHex)
            colors.append(newColor)
        }

        func removeColor(_ color: ColorStructure) {
            if let index = colors.firstIndex(where: { $0.id == color.id }) {
                colors.remove(at: index)
            }
        }

        func removeColors(at offsets: IndexSet) {
            colors.remove(atOffsets: offsets)
        }

        func moveColors(from source: IndexSet, to destination: Int) {
            colors.move(fromOffsets: source, toOffset: destination)
        }

        func savePalette() {
            guard let context = context ?? (originalPalette?.modelContext) else { return }

            if let palette = originalPalette {
                palette.name = paletteName

                palette.colors?.forEach { color in
                    context.delete(color)
                }

                palette.colors = colors
            } else {
                let newPalette = Palette(name: paletteName, colors: colors)
                context.insert(newPalette)
            }

            do {
                try context.save()
            } catch {
                print("Error saving palette \(error.localizedDescription)")
            }
        }

        func deletePalette() {
            guard let palette = originalPalette, let context = context ?? palette.modelContext else { return }

            context.delete(palette)

            do {
                try context.save()
            } catch {
                print("Error saving model context: \(error.localizedDescription)")
            }
        }
    }
}
