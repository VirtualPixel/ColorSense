//
//  ColorPaletteService.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

class ColorPaletteService {
    private static let minimumColorDifference: CGFloat = 15.0

    // Generate a completely random palette
    static func generateRandomPalette(
        numberOfColors: Int = 5,
        category: PaletteCategory = .standard
    ) -> [Color] {
        let rawColors = HarmonyGenerator.generateHarmoniousPalette(
            numberOfColors: numberOfColors,
            category: category
        )

        return ensureColorDistinction(rawColors)
    }

    // Generate a palette starting with one seed color
    static func generatePaletteFromSeed(
        seedColor: Color,
        numberOfColors: Int = 5,
        category: PaletteCategory = .standard
    ) -> [Color] {
        let rawColors = HarmonyGenerator.generateHarmoniousPalette(
            keyColor1: seedColor,
            numberOfColors: numberOfColors,
            category: category
        )

        return ensureColorDistinction(rawColors)
    }

    // Convert colors to a specific category
    static func convertColorsToCategory(
        colors: [Color],
        category: PaletteCategory
    ) -> [Color] {
        return CategoryModifier.applyCategory(to: colors, category: category)
    }

    // Enhance the harmony of colors
    static func enhanceColorsHarmony(
        colors: [Color],
        strength: Double = 0.5
    ) -> [Color] {
        return HarmonyEnhancer.enhanceColors(colors, strength: strength)
    }

    // Generate a set of related color variations
    static func generateVariations(
        fromColors: [Color],
        numberOfVariations: Int = 3
    ) -> [[Color]] {
        var variations: [[Color]] = [fromColors]

        // Extract key colors to use as a basis
        let keyColors = fromColors.prefix(3).map { color -> Color in
            // Slightly adjust each key color to create variation
            let hsl = color.toHSL()
            let newHue = (hsl.hue + Int.random(in: -15...15)) % 360
            return Color(
                hue: Double(newHue) / 360.0,
                saturation: Double(hsl.saturation) / 100.0,
                brightness: Double(hsl.lightness) / 100.0
            )
        }

        // Ensure we have 3 key colors
        var keys = Array(keyColors)
        while keys.count < 3 {
            keys.append(Color(
                hue: Double.random(in: 0...1),
                saturation: Double.random(in: 0.3...0.8),
                brightness: Double.random(in: 0.3...0.8)
            ))
        }

        // Generate variations
        for i in 1...numberOfVariations {
            // Slightly adjust key colors for each variation
            let adjustedKeys = keys.map { adjustColorSlightly($0, amount: Double(i) * 0.15) }

            // Generate the same number of colors as the input
            var newVariation: [Color] = []
            for _ in 0..<fromColors.count {
                let r1 = Double.random(in: 0...1)
                let r2 = Double.random(in: 0...1)

                let newColor = HarmonyGenerator.sampleFromColorScheme(
                    r1: r1, r2: r2,
                    color1: adjustedKeys[0],
                    color2: adjustedKeys[1],
                    color3: adjustedKeys[2]
                )

                newVariation.append(newColor)
            }

            variations.append(newVariation)
        }

        return variations
    }

    // Helper to slightly adjust a color
    private static func adjustColorSlightly(_ color: Color, amount: Double) -> Color {
        let hsl = color.toHSL()

        // Make small adjustments
        let hueAdjustment = Int.random(in: -30...30)
        let satAdjustment = Int.random(in: -10...10)
        let lightAdjustment = Int.random(in: -10...10)

        let newHue = (hsl.hue + hueAdjustment) % 360
        let newSat = max(0, min(100, hsl.saturation + satAdjustment))
        let newLight = max(0, min(100, hsl.lightness + lightAdjustment))

        return Color(
            hue: Double(newHue) / 360.0,
            saturation: Double(newSat) / 100.0,
            brightness: Double(newLight) / 100.0
        )
    }

    // Calculate difference
    private static func ensureColorDistinction(_ generatedColors: [Color]) -> [Color] {
            var distinctColors: [Color] = []

            for color in generatedColors {
                // Check if this color is sufficiently different from all existing ones
                let isSufficientlyDistinct = !distinctColors.contains { existingColor in
                    return color.difference(to: existingColor) < minimumColorDifference
                }

                if isSufficientlyDistinct || distinctColors.isEmpty {
                    distinctColors.append(color)
                }
            }

            // If we filtered out too many colors, we need to generate replacements
            while distinctColors.count < generatedColors.count {
                // Create a new color with more randomness to increase chances of being distinct
                let newColor = Color(
                    hue: Double.random(in: 0...1),
                    saturation: Double.random(in: 0.3...0.9),
                    brightness: Double.random(in: 0.3...0.9)
                )

                // Only add if it's distinct from existing colors
                if !distinctColors.contains(where: { newColor.difference(to: $0) < minimumColorDifference }) {
                    distinctColors.append(newColor)
                }
            }

            return distinctColors
        }
}
