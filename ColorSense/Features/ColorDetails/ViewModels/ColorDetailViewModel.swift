//
//  ColorDetailView-ViewModel.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

extension ColorDetailView {
    class ViewModel: ObservableObject {
        let color: Color
        let showAddToPalette: Bool
        
        var rgb: (red: Int, green: Int, blue: Int, alpha: Double) {
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

        var swiftUI: String {
            ColorMixMatcher.shared.getColorMixString(for: color)
        }

        var uiKit: String {
            self.color.toUIKit()
        }
        
        var pantone: [Pantone] {
            self.color.toPantone()
        }
        
        var complimentaryColors: [Color] {
            self.color.complimentaryColors()
        }
        
        var colorVisionsSimulations: [ColorVision] {
            return ColorVisionUtility.colorAccessibilityVariants(for: self.color)
        }
        
        init(color: Color, showAddToPalette: Bool = true) {
            self.color = color
            self.showAddToPalette = showAddToPalette
        }
    }
}
