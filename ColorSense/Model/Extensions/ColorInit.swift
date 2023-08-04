//
//  ColorInit.swift
//  ColorSense
//
//  Created by Justin Wells on 8/3/23.
//

import SwiftUI

// display colors
extension Color {
    // Hex triplet
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // RGB decimal
    init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    // CMYK
    init(c: Double, m: Double, y: Double, k: Double, a: Double = 1.0) {
        let r = (1 - c) * (1 - k)
        let g = (1 - m) * (1 - k)
        let b = (1 - y) * (1 - k)
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    // HSL
    init(h: Double, s: Double, l: Double, a: Double = 1.0) {
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        var r, g, b: Double
        
        switch h {
        case 0..<60:
            (r, g, b) = (c, x, 0)
        case 60..<120:
            (r, g, b) = (x, c, 0)
        case 120..<180:
            (r, g, b) = (0, c, x)
        case 180..<240:
            (r, g, b) = (0, x, c)
        case 240..<300:
            (r, g, b) = (x, 0, c)
        case 300..<360:
            (r, g, b) = (c, 0, x)
        default:
            (r, g, b) = (0, 0, 0)
        }
        
        self.init(.sRGB, red: r + m, green: g + m, blue: b + m, opacity: a)
    }
}
