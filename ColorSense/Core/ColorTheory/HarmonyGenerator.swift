//
//  HarmonyGenerator.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

class HarmonyGenerator {

    // Generate a palette with 3 key colors and sample additional colors
    static func generateHarmoniousPalette(
        keyColor1: Color? = nil,
        keyColor2: Color? = nil,
        keyColor3: Color? = nil,
        numberOfColors: Int = 5,
        category: PaletteCategory = .standard
    ) -> [Color] {

        // If keyColor1 is provided, use it, otherwise generate a random one
        let color1 = keyColor1 ?? generateRandomColor(for: category)

        // If keyColor2 is provided, use it, otherwise generate based on color1
        let color2 = keyColor2 ?? generateComplementaryColor(for: color1, category: category)

        // If keyColor3 is provided, use it, otherwise generate based on color1 and color2
        let color3 = keyColor3 ?? generateThirdKeyColor(color1: color1, color2: color2, category: category)

        // Sample colors from the triangle formed by the key colors
        var paletteColors: [Color] = [color1, color2, color3]

        // Add more colors by sampling between the key colors
        for _ in 0..<(numberOfColors - 3) {
            let r1 = Double.random(in: 0...1)
            let r2 = Double.random(in: 0...1)
            let sampledColor = sampleFromColorScheme(r1: r1, r2: r2, color1: color1, color2: color2, color3: color3)
            paletteColors.append(sampledColor)
        }

        return paletteColors
    }

    // Sample a color from the triangle formed by three key colors
    static func sampleFromColorScheme(r1: Double, r2: Double, color1: Color, color2: Color, color3: Color) -> Color {
        let c1Components = color1.toRGBComponents()
        let c2Components = color2.toRGBComponents()
        let c3Components = color3.toRGBComponents()

        // Modified version with more variation
        let factor1 = 1.0 - sqrt(r1)
        let factor2 = sqrt(r1) * (1.0 - r2)
        let factor3 = r2 * sqrt(r1)

        // Add a small random variation to increase diversity
        let variation = Double.random(in: -0.1...0.1)

        let red = min(1.0, max(0.0, factor1 * c1Components.red + factor2 * c2Components.red + factor3 * c3Components.red + variation))
        let green = min(1.0, max(0.0, factor1 * c1Components.green + factor2 * c2Components.green + factor3 * c3Components.green + variation))
        let blue = min(1.0, max(0.0, factor1 * c1Components.blue + factor2 * c2Components.blue + factor3 * c3Components.blue + variation))

        return Color(red: red, green: green, blue: blue)
    }

    // Helper methods for generating key colors
    private static func generateRandomColor(for category: PaletteCategory) -> Color {
        let hue = Double.random(in: 0...1)
        let saturation = Double.random(in: category.saturationRange)
        let lightness = Double.random(in: category.lightnessRange)

        return Color(hue: hue, saturation: saturation, brightness: lightness)
    }

    private static func generateComplementaryColor(for color: Color, category: PaletteCategory) -> Color {
        let hsl = color.toHSL()
        // Complementary color is 180 degrees across the color wheel
        let complementaryHue = (hsl.hue + 180) % 360

        // Maintain category constraints
        let saturation = Double.random(in: category.saturationRange)
        let lightness = Double.random(in: category.lightnessRange)

        return Color(
            hue: Double(complementaryHue) / 360.0,
            saturation: saturation,
            brightness: lightness
        )
    }

    private static func generateThirdKeyColor(color1: Color, color2: Color, category: PaletteCategory) -> Color {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        // For a third color, we have options:
        // 1. Create a triadic harmony (120 degrees apart)
        // 2. Create an analogous harmony (30-60 degrees apart)
        // 3. Pick something equidistant between the two

        // Let's go with triadic as default
        let hue1 = hsl1.hue
        let hue2 = hsl2.hue

        // Find the midpoint between the two hues, then offset by 120 degrees
        let midpointHue = (hue1 + hue2) / 2
        let triadicOffset = 120
        let thirdHue = (Int(midpointHue) + triadicOffset) % 360

        // Maintain category constraints
        let saturation = Double.random(in: category.saturationRange)
        let lightness = Double.random(in: category.lightnessRange)

        return Color(
            hue: Double(thirdHue) / 360.0,
            saturation: saturation,
            brightness: lightness
        )
    }
}
