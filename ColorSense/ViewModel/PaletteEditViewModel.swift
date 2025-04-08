//
//  PaletteEditViewModel.swift
//  ColorSense
//
//  Created by Justin Wells on 4/7/25.
//

import Foundation
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
    }
}
