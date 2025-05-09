//
//  ColorVision.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUICore

enum ColorVisionType: String, CaseIterable, Identifiable {
    case typical = "Typical"
    case deuteranopia = "Deuteranopia"
    case protanopia = "Protanopia"
    case tritanopia = "Tritanopia"

    var id: Self { self }

    var description: String {
        switch self {
        case .typical:
            return "Natural color vision"
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
}
