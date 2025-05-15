//
//  HarmonyEnhancer.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

class HarmonyEnhancer {

    // Enhance the harmony of a color collection
    static func enhanceColors(_ colors: [Color], strength: Double = 0.5) -> [Color] {
        // First, identify the key colors
        let keyColors = extractKeyColors(from: colors)

        // Then, adjust each color to better fit within the harmony triangle
        var enhancedColors = [Color]()

        for color in colors {
            let enhancedColor = enhanceColor(color, keyColors: keyColors, strength: strength)
            enhancedColors.append(enhancedColor)
        }

        return enhancedColors
    }

    // Extract key colors that define the color space
    private static func extractKeyColors(from colors: [Color]) -> [Color] {
        guard colors.count >= 3 else {
            // If we have fewer than 3 colors, we need to generate additional ones
            var keyColors = colors

            if colors.count == 1 {
                // Add complementary and triadic colors
                let hsl = colors.first!.toHSL()
                let complementaryHue = (hsl.hue + 180) % 360
                let triadicHue = (hsl.hue + 120) % 360

                keyColors.append(Color(
                    hue: Double(complementaryHue) / 360.0,
                    saturation: Double(hsl.saturation) / 100.0,
                    brightness: Double(hsl.lightness) / 100.0
                ))

                keyColors.append(Color(
                    hue: Double(triadicHue) / 360.0,
                    saturation: Double(hsl.saturation) / 100.0,
                    brightness: Double(hsl.lightness) / 100.0
                ))
            } else if colors.count == 2 {
                // Add a third color
                let hsl1 = colors[0].toHSL()
                let hsl2 = colors[1].toHSL()

                // Create a color that's equidistant from the other two
                let hueDiff = abs(hsl1.hue - hsl2.hue)
                let thirdHue = (min(hsl1.hue, hsl2.hue) + hueDiff / 2) % 360

                let satAvg = (hsl1.saturation + hsl2.saturation) / 2
                let lightAvg = (hsl1.lightness + hsl2.lightness) / 2

                keyColors.append(Color(
                    hue: Double(thirdHue) / 360.0,
                    saturation: Double(satAvg) / 100.0,
                    brightness: Double(lightAvg) / 100.0
                ))
            }

            return keyColors
        }

        // Find the colors that are most distant from each other in the hue space
        var mostDistantColors = [colors[0], colors[1], colors[2]]
        var maxDistance = 0.0

        for i in 0..<colors.count {
            for j in (i+1)..<colors.count {
                for k in (j+1)..<colors.count {
                    let distance = calculateHueDistance(colors[i], colors[j], colors[k])
                    if distance > maxDistance {
                        maxDistance = distance
                        mostDistantColors = [colors[i], colors[j], colors[k]]
                    }
                }
            }
        }

        return mostDistantColors
    }

    // Calculate the total hue distance between three colors
    private static func calculateHueDistance(_ c1: Color, _ c2: Color, _ c3: Color) -> Double {
        let h1 = c1.toHSL().hue
        let h2 = c2.toHSL().hue
        let h3 = c3.toHSL().hue

        let d1 = min(abs(h1 - h2), 360 - abs(h1 - h2))
        let d2 = min(abs(h2 - h3), 360 - abs(h2 - h3))
        let d3 = min(abs(h3 - h1), 360 - abs(h3 - h1))

        return Double(d1 + d2 + d3)
    }

    // Enhance a color by moving it toward the harmony triangle
    private static func enhanceColor(_ color: Color, keyColors: [Color], strength: Double) -> Color {
        guard keyColors.count >= 3 else { return color }

        // Find the closest point within the harmony triangle
        let r1 = Double.random(in: 0...1)
        let r2 = Double.random(in: 0...1)

        let harmonicColor = HarmonyGenerator.sampleFromColorScheme(
            r1: r1,
            r2: r2,
            color1: keyColors[0],
            color2: keyColors[1],
            color3: keyColors[2]
        )

        // Blend between the original color and the harmonic color based on strength
        return blendColors(color, harmonicColor, blendFactor: strength)
    }

    // Blend two colors together
    private static func blendColors(_ c1: Color, _ c2: Color, blendFactor: Double) -> Color {
        let rgb1 = c1.toRGBComponents()
        let rgb2 = c2.toRGBComponents()

        let r = rgb1.red * (1 - blendFactor) + rgb2.red * blendFactor
        let g = rgb1.green * (1 - blendFactor) + rgb2.green * blendFactor
        let b = rgb1.blue * (1 - blendFactor) + rgb2.blue * blendFactor

        return Color(red: r, green: g, blue: b)
    }
}
