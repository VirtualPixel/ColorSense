//
//  WatchColorDetailview-ViewModel.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 8/2/23.
//

import SwiftUI

extension WatchColorDetailView {
    @MainActor class ViewModel: ObservableObject {
        let color: Color
        let showAddToPallet: Bool
        
        var rbg: (red: Int, green: Int, blue: Int, alpha: Double) {
            self.color.toRGB()
        }
        
        var hex: String {
            self.color.toHex()
        }
        
        var hsl: (hue: Int, saturation: Int, lightness: Int, alpha: Int) {
            self.color.toHSL()
        }
        
        var cmyk: (cyan: Int, magenta: Int, yellow: Int, key: Int, alpha: Int) {
            self.color.toCMYK()
        }
        
        var pantone: [Pantone] {
            self.color.toPantone()
        }
        
        init(color: Color, showAddToPallet: Bool = true) {
            self.color = color
            self.showAddToPallet = showAddToPallet
        }
    }
}