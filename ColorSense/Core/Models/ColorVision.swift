//
//  ColorVision.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUICore

enum ColorVisionType: String, CaseIterable, Identifiable {
    case normal = "Normal Vision"
    // case testing = "Testing"
    case deuteranopia = "Deuteranopia"
    case protanopia = "Protanopia"
    case tritanopia = "Tritanopia"

    var id: Self { self }

    var description: String {
        switch self {
        case .normal:
            return "Natural color vision"
        // case .testing:
        //    return "This is for testing purposes"
        case .deuteranopia:
            return "Red-green color blindness, absence of green sensitive cones (~6% of males and ~0.04% of females)"
        case .protanopia:

            return "Red-green color blindness, absence of red sensitive cones (~2% of males and ~0.39% of females)"
        case .tritanopia:
            return "Blue-yellow color blindness, absence of S-cones (~0.002% of males and ~0.0001% of females)"
        }
    }

    var localizedName: String {
        NSLocalizedString(rawValue, comment: description)
    }
}

struct ColorVision: Identifiable {
    let id = UUID()
    let color: Color
    let type: ColorVisionType

    static func createAllSimulations(for originalColor: Color) -> [ColorVision] {
        return ColorVisionUtility.simulateAllColorVisions(for: originalColor)
    }
}
