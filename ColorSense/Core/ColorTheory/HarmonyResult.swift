//
//  HarmonyType.swift
//  ColorSense
//
//  Created by Justin Wells on 4/23/25.
//

import Foundation

enum HarmonyType: String, CaseIterable {
    case complementary = "Complementary"
    case triadic = "Triadic"
    case analogous = "Analogous"
    case monochromatic = "Monochromatic"

    var degrees: Int {
        switch self {
        case .complementary: return 180
        case .triadic: return 120
        case .analogous: return 30
        case .monochromatic: return 0
        }
    }

    var description: String {
        switch self {
        case .complementary:
            return "Colors opposite on the color wheel"
        case .triadic:
            return "Three colors equally spaced around the color wheel"
        case .analogous:
            return "Colors adjacent on the color wheel"
        case .monochromatic:
            return "Colors with the same hue but different saturation/brightness"
        }
    }

    var localizedName: String {
        NSLocalizedString(rawValue, comment: "Color harmony type: \(rawValue)")
    }

    var localizedDescription: String {
        NSLocalizedString(description, comment: "Explanation of \(rawValue) harmony type")
    }
}

struct HarmonyResult: Equatable {
    let score: Double
    let type: HarmonyType?
    let description: String
        
    static func == (lhs: HarmonyResult, rhs: HarmonyResult) -> Bool {
        return lhs.score == rhs.score && lhs.type == rhs.type
    }
}
