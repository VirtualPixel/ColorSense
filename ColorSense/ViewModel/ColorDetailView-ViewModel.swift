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
        
        init(color: Color) {
            self.color = color
        }
    }
}
