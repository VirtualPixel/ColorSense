//
//  CategoryModifier.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

class CategoryModifier {

    // Adjust a collection of colors to conform to a category
    static func applyCategory(to colors: [Color], category: PaletteCategory) -> [Color] {
        return colors.map { adjustColorToCategory($0, category: category) }
    }

    // Adjust a single color to match category constraints
    static func adjustColorToCategory(_ color: Color, category: PaletteCategory) -> Color {
        let hsl = color.toHSL()

        // Keep the hue, but adjust saturation and lightness to category constraints
        let newSaturation = constrainValue(
            hsl.saturation,
            to: Int(category.saturationRange.lowerBound * 100)...Int(category.saturationRange.upperBound * 100)
        )

        let newLightness = constrainValue(
            hsl.lightness,
            to: Int(category.lightnessRange.lowerBound * 100)...Int(category.lightnessRange.upperBound * 100)
        )

        return Color(
            hue: Double(hsl.hue) / 360.0,
            saturation: Double(newSaturation) / 100.0,
            brightness: Double(newLightness) / 100.0
        )
    }

    // Constrain a value to a range
    private static func constrainValue(_ value: Int, to range: ClosedRange<Int>) -> Int {
        if value < range.lowerBound {
            return range.lowerBound
        } else if value > range.upperBound {
            return range.upperBound
        }
        return value
    }
}
