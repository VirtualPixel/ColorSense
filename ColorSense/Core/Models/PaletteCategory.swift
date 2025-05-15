//
//  PaletteCategory.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

enum PaletteCategory: String, CaseIterable {
    case standard = "Balanced"
    case pastel = "Pastel"
    case earthy = "Earthy"
    case vibrant = "Vibrant"
    case monochromatic = "Monochromatic"
    case analogous = "Analogous"
    case complementary = "Complementary"
    case triadic = "Triadic"
    case neutral = "Neutral"
    case dark = "Dark"
    case light = "Light"
    case vintage = "Vintage"
    case neon = "Neon"

    var saturationRange: ClosedRange<Double> {
        switch self {
        case .pastel: return 0.15...0.40
        case .earthy: return 0.20...0.55
        case .vibrant: return 0.70...1.0
        case .neon: return 0.80...1.0
        case .dark: return 0.40...0.80
        case .light: return 0.30...0.70
        case .neutral: return 0.05...0.30
        default: return 0.0...1.0
        }
    }

    var lightnessRange: ClosedRange<Double> {
        switch self {
        case .pastel: return 0.65...0.90
        case .earthy: return 0.30...0.60
        case .dark: return 0.05...0.40
        case .light: return 0.75...0.95
        case .neutral: return 0.40...0.70
        case .vibrant: return 0.40...0.70
        case .neon: return 0.60...0.80
        default: return 0.20...0.80
        }
    }
}
