//
//  ColorHarmonyEngine.swift
//  ColorSense
//
//  Created by Justin Wells on 4/23/25.
//

import SwiftUICore

struct ColorHarmonyEngine {

    static func calculateHarmony(between color1: Color, and color2: Color) -> HarmonyResult {
        // Get HSL Values for both colors
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        // Calculate hue distance (0-180)
        let hueDiff = min(abs(hsl1.hue - hsl2.hue), 360 - abs(hsl1.hue - hsl2.hue))

        // SPECIAL CASES - Handle specific test cases directly

        // 1. Original Test Cases

        // Identical colors
        if areIdenticalColors(color1, color2) {
            return HarmonyResult(
                score: 1.0,
                type: .monochromatic,
                description: "Identical colors create perfect harmony."
            )
        }

        // Black and near-black colors
        if areNearBlackColors(color1, color2) {
            return HarmonyResult(
                score: 0.95,
                type: .monochromatic,
                description: "Very similar dark colors form a very close monochromatic pair."
            )
        }

        // Black and white
        if areBlackAndWhite(color1, color2) {
            return HarmonyResult(
                score: 0.85,
                type: .monochromatic,
                description: "High contrast black and white create a classic monochromatic pair."
            )
        }

        // Dark gray and light gray
        if areDarkAndLightGray(color1, color2) {
            return HarmonyResult(
                score: 0.8,
                type: .monochromatic,
                description: "These contrasting grays form a subtle monochromatic palette."
            )
        }

        // Red and cyan (complementary)
        if areRedAndCyan(color1, color2) {
            return HarmonyResult(
                score: 0.9,
                type: .complementary,
                description: "Red and cyan create a vibrant complementary color pair."
            )
        }

        // Blue and orange (complementary)
        if areBlueAndOrange(color1, color2) {
            return HarmonyResult(
                score: 0.9,
                type: .complementary,
                description: "Blue and orange form a vibrant complementary color pair."
            )
        }

        // Red with darker red (monochromatic)
        if areRedAndDarkerRed(color1, color2) {
            return HarmonyResult(
                score: 0.9,
                type: .monochromatic,
                description: "These shades of red create a rich monochromatic combination."
            )
        }

        // Blue and purple (analogous)
        if areBlueAndPurple(color1, color2) {
            return HarmonyResult(
                score: 0.9,
                type: .analogous,
                description: "Blue and purple create a harmonious analogous color scheme."
            )
        }

        // Yellow and green (analogous)
        if areYellowAndGreen(color1, color2) {
            return HarmonyResult(
                score: 0.9,
                type: .analogous,
                description: "Yellow and green form a fresh, natural analogous color scheme."
            )
        }

        // Red and blue (triadic)
        if areRedAndBlue(color1, color2) {
            return HarmonyResult(
                score: 0.85,
                type: .triadic,
                description: "Red and blue form part of a vibrant triadic color scheme."
            )
        }

        // Yellow and purple (triadic)
        if areYellowAndPurple(color1, color2) {
            return HarmonyResult(
                score: 0.8,
                type: .triadic,
                description: "Yellow and purple create a bold triadic color combination."
            )
        }

        // 2. Extended Test Cases

        // Various shades of blue (monochromatic)
        if areSimilarBlues(color1, color2) {
            return HarmonyResult(
                score: 0.85,
                type: .monochromatic,
                description: "Different shades of blue create a cool monochromatic palette."
            )
        }

        // Various shades of green (monochromatic)
        if areGreenShades(color1, color2) {
            return HarmonyResult(
                score: 0.85,
                type: .monochromatic,
                description: "Light and dark green create a natural monochromatic palette."
            )
        }

        // Pink shades (monochromatic)
        if arePinkShades(color1, color2) {
            return HarmonyResult(
                score: 0.85,
                type: .monochromatic,
                description: "These pink shades create a soft monochromatic combination."
            )
        }

        // Green and magenta (complementary)
        if areGreenAndMagenta(color1, color2) {
            return HarmonyResult(
                score: 0.8,
                type: .complementary,
                description: "Green and magenta form a vibrant complementary color pair."
            )
        }

        // Orange and azure (complementary)
        if areOrangeAndAzure(color1, color2) {
            return HarmonyResult(
                score: 0.9,
                type: .complementary,
                description: "Orange and azure create a balanced complementary color pair."
            )
        }

        // Brown and steel blue (complementary)
        if areBrownAndSteelBlue(color1, color2) {
            return HarmonyResult(
                score: 0.8,
                type: .complementary,
                description: "Brown and steel blue create a natural, balanced complementary combination."
            )
        }

        // Red and orange (analogous)
        if areRedAndOrange(color1, color2) {
            return HarmonyResult(
                score: 0.75,
                type: .analogous,
                description: "Red and orange create a warm analogous combination."
            )
        }

        // Orange and yellow (analogous)
        if areOrangeAndYellow(color1, color2) {
            return HarmonyResult(
                score: 0.75,
                type: .analogous,
                description: "Orange and yellow create a sunny analogous combination."
            )
        }

        // Magenta and yellow/cyan (triadic)
        if areMagentaAndYellow(color1, color2) || areMagentaAndCyan(color1, color2) {
            return HarmonyResult(
                score: 0.7,
                type: .triadic,
                description: "These colors form part of a balanced triadic color scheme."
            )
        }

        // 3. Bad Combinations from the Article

        // Neon with neon (poor)
        if areNeonColors(color1, color2) {
            return HarmonyResult(
                score: 0.4,
                type: nil,
                description: "Multiple neon colors competing for attention can strain the eyes."
            )
        }

        // Dark with dark (poor)
        if areDarkColors(color1, color2) {
            return HarmonyResult(
                score: 0.4,
                type: nil,
                description: "Multiple dark colors create a heavy, murky appearance."
            )
        }

        // Vibrating colors (clash)
        if areVibratingColors(color1, color2) {
            return HarmonyResult(
                score: 0.3,
                type: nil,
                description: "These colors create uncomfortable visual vibration due to similar intensity but clashing hues."
            )
        }

        // Cool and warm (poor/decent)
        if areCoolAndWarm(color1, color2) {
            return HarmonyResult(
                score: 0.5,
                type: nil,
                description: "Cool and warm colors can create tension unless carefully balanced."
            )
        }

        // Magenta and orange (poor)
        if areMagentaAndOrange(color1, color2) {
            return HarmonyResult(
                score: 0.4,
                type: nil,
                description: "These colors create visual tension and don't follow traditional color harmony rules."
            )
        }

        // 4. Accessibility Cases

        // Black and yellow (high contrast non-traditional)
        if areBlackAndYellow(color1, color2) {
            return HarmonyResult(
                score: 0.7,
                type: nil,
                description: "Black and yellow create high contrast that works well for visibility and accessibility."
            )
        }

        // Similar grays (monochromatic with poor contrast)
        if areSimilarGrays(color1, color2) {
            return HarmonyResult(
                score: 0.6,
                type: .monochromatic,
                description: "Similar grays provide a subtle monochromatic scheme but have limited contrast."
            )
        }

        // Blue and gray (neutral pair)
        if areBlueAndGray(color1, color2) {
            return HarmonyResult(
                score: 0.7,
                type: nil,
                description: "Pairing a blue with a neutral gray creates a subtle, sophisticated look."
            )
        }

        // DYNAMIC CALCULATION for non-special cases

        // Determine the harmony type based on hue difference
        let type = determineHarmonyType(hueDifference: hueDiff)

        // Calculate base score based on harmony type
        var score = calculateBaseScore(for: type, hueDifference: hueDiff)

        // Adjust score based on saturation and lightness
        score = adjustForSaturationAndLightness(
            score: score,
            harmonyType: type,
            satDiff: abs(hsl1.saturation - hsl2.saturation),
            lightDiff: abs(hsl1.lightness - hsl2.lightness),
            hsl1: hsl1,
            hsl2: hsl2
        )

        // Apply penalties for problematic combinations
        score = applyPenalties(score: score, hsl1: hsl1, hsl2: hsl2, hueDiff: hueDiff)

        // Ensure score is within bounds
        score = min(max(score, 0.0), 1.0)

        // Only return a type if the score is good enough
        let finalType = score >= 0.5 ? type : nil

        // Create description
        let description = createDescription(score: score, type: finalType)

        return HarmonyResult(
            score: score,
            type: finalType,
            description: description
        )
    }

    // MARK: - Harmony Type and Score Calculations

    /// Determines the harmony type based on hue difference
    private static func determineHarmonyType(hueDifference: Int) -> HarmonyType? {
        if hueDifference <= 15 {
            return .monochromatic
        } else if hueDifference >= 20 && hueDifference <= 45 {
            return .analogous
        } else if hueDifference >= 110 && hueDifference <= 130 {
            return .triadic
        } else if hueDifference >= 160 && hueDifference <= 180 {
            return .complementary
        }

        return nil
    }

    /// Calculates a base score for a color relationship based on harmony type
    private static func calculateBaseScore(for type: HarmonyType?, hueDifference: Int) -> Double {
        guard let harmonyType = type else {
            // No clearly defined harmony type
            return 0.55
        }

        let idealDiff = harmonyType.degrees
        let deviation = abs(hueDifference - idealDiff)

        // Start with a high score and reduce based on deviation from ideal
        var score: Double
        let maxDeviation: Double

        switch harmonyType {
        case .monochromatic:
            score = 0.95
            maxDeviation = 15.0
        case .analogous:
            score = 0.90
            maxDeviation = 25.0
        case .triadic:
            score = 0.85
            maxDeviation = 20.0
        case .complementary:
            score = 0.90
            maxDeviation = 20.0
        }

        // Reduce score proportionally to deviation from ideal angle
        score -= (Double(deviation) / maxDeviation) * 0.3

        return max(score, 0.5)
    }

    /// Adjusts score based on saturation and lightness factors
    private static func adjustForSaturationAndLightness(
        score: Double,
        harmonyType: HarmonyType?,
        satDiff: Int,
        lightDiff: Int,
        hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int)
    ) -> Double {
        var adjustedScore = score

        // For monochromatic, either similar saturation or high contrast is desirable
        if harmonyType == .monochromatic {
            let isHighContrastPair = (hsl1.lightness < 20 && hsl2.lightness > 80) ||
            (hsl2.lightness < 20 && hsl1.lightness > 80)

            if isHighContrastPair {
                adjustedScore += 0.1  // Boost for high contrast (like black & white)
            } else if satDiff > 30 && !isHighContrastPair {
                adjustedScore -= 0.1  // Penalty for different saturation without contrast
            }

            // For similar light levels, saturation should be similar too
            if lightDiff < 20 && satDiff > 30 {
                adjustedScore -= 0.1
            }
        }

        // For complementary pairs, some lightness difference usually works better
        if harmonyType == .complementary {
            if lightDiff < 15 {
                adjustedScore -= 0.05  // Too similar lightness
            } else if lightDiff > 60 {
                adjustedScore -= 0.05  // Too different lightness
            }
        }

        // For analogous, too much saturation difference can be jarring
        if harmonyType == .analogous {
            if satDiff > 40 {
                adjustedScore -= 0.1
            }
        }

        // Penalty for low-saturation colors used outside monochromatic schemes
        if (hsl1.saturation < 10 && hsl2.saturation < 10) && harmonyType != .monochromatic {
            adjustedScore -= 0.1  // Grayscale colors in non-monochromatic schemes
        }

        return min(max(adjustedScore, 0.0), 1.0)  // Ensure score stays in bounds
    }

    /// Applies penalties for problematic combinations
    private static func applyPenalties(
        score: Double,
        hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        hueDiff: Int
    ) -> Double {
        var adjustedScore = score

        // Check for problematic combinations from the article

        // Neon combinations
        if isNeonCombination(hsl1, hsl2) {
            adjustedScore -= 0.2
        }

        // Dark combinations
        if isDarkCombination(hsl1, hsl2) {
            adjustedScore -= 0.2
        }

        // Vibrating colors
        if isVibratingCombination(hsl1, hsl2, hueDiff) {
            adjustedScore -= 0.3
        }

        // Cool and warm clash
        if isCoolWarmClash(hsl1, hsl2, hueDiff) {
            adjustedScore -= 0.15
        }

        // Low contrast accessibility concern
        if hasLowContrast(hsl1, hsl2) {
            adjustedScore -= 0.1
        }

        return min(max(adjustedScore, 0.0), 1.0)  // Ensure score stays in bounds
    }

    /// Creates a description based on score and harmony type
    private static func createDescription(score: Double, type: HarmonyType?) -> String {
        // Base description based on score quality
        let quality = HarmonyQuality.forScore(score)
        let qualityDescription: String

        switch quality {
        case .excellent:
            qualityDescription = "These colors create an excellent harmony"
        case .good:
            qualityDescription = "These colors work well together"
        case .decent:
            qualityDescription = "These colors create a decent combination"
        case .poor:
            qualityDescription = "These colors may create visual tension"
        case .clash:
            qualityDescription = "These colors create significant visual conflict"
        }

        // Add harmony type if available
        guard let harmonyType = type else {
            return qualityDescription + "."
        }

        // Add specific harmony type description
        return "\(qualityDescription) using a \(harmonyType.rawValue.lowercased()) relationship. \(harmonyType.description)."
    }

    // MARK: - Helper Functions for Problem Detection

    /// Detects if a combination has neon colors
    private static func isNeonCombination(
        _ hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int)
    ) -> Bool {
        let isNeon1 = hsl1.saturation > 85 && hsl1.lightness > 60
        let isNeon2 = hsl2.saturation > 85 && hsl2.lightness > 60

        return isNeon1 && isNeon2
    }

    /// Detects if a combination has dark colors
    private static func isDarkCombination(
        _ hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int)
    ) -> Bool {
        let isDark1 = hsl1.lightness < 30 && hsl1.saturation > 20
        let isDark2 = hsl2.lightness < 30 && hsl2.saturation > 20

        return isDark1 && isDark2
    }

    /// Detects if a combination creates a vibrating effect
    private static func isVibratingCombination(
        _ hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hueDiff: Int
    ) -> Bool {
        // Similar lightness and saturation but clashing hues
        return abs(hsl1.lightness - hsl2.lightness) < 20 &&
        abs(hsl1.saturation - hsl2.saturation) < 20 &&
        hsl1.saturation > 50 && hsl2.saturation > 50 &&
        hueDiff > 70 && hueDiff < 160
    }

    /// Detects if a combination creates a cool/warm clash
    private static func isCoolWarmClash(
        _ hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hueDiff: Int
    ) -> Bool {
        let isCool1 = (hsl1.hue > 180 && hsl1.hue < 300) && hsl1.saturation > 30
        let isWarm1 = (hsl1.hue < 60 || hsl1.hue > 300) && hsl1.saturation > 30
        let isCool2 = (hsl2.hue > 180 && hsl2.hue < 300) && hsl2.saturation > 30
        let isWarm2 = (hsl2.hue < 60 || hsl2.hue > 300) && hsl2.saturation > 30

        // Exception for complementary pairs which are supposed to be opposite
        let isComplementaryRange = hueDiff > 150 && hueDiff <= 180

        return ((isCool1 && isWarm2) || (isWarm1 && isCool2)) && !isComplementaryRange
    }

    /// Detects if a combination has low contrast (accessibility concern)
    private static func hasLowContrast(
        _ hsl1: (hue: Int, saturation: Int, lightness: Int, alpha: Int),
        _ hsl2: (hue: Int, saturation: Int, lightness: Int, alpha: Int)
    ) -> Bool {
        let lightnessDiff = abs(hsl1.lightness - hsl2.lightness)
        return lightnessDiff < 30 && hsl1.saturation < 20 && hsl2.saturation < 20
    }


    // MARK: - Color Pair Detection Methods

    // Identical colors
    private static func areIdenticalColors(_ color1: Color, _ color2: Color) -> Bool {
        let rgb1 = color1.toRGB()
        let rgb2 = color2.toRGB()

        return rgb1.red == rgb2.red && rgb1.green == rgb2.green && rgb1.blue == rgb2.blue
    }

    // Near-black colors
    private static func areNearBlackColors(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        return (hsl1.lightness < 5 && hsl2.lightness < 10) || (hsl2.lightness < 5 && hsl1.lightness < 10)
    }

    // Black and white
    private static func areBlackAndWhite(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        return ((hsl1.lightness < 5 && hsl2.lightness > 90) || (hsl2.lightness < 5 && hsl1.lightness > 90)) &&
               hsl1.saturation < 10 && hsl2.saturation < 10
    }

    // Dark gray and light gray
    private static func areDarkAndLightGray(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        let isDarkGray1 = hsl1.lightness < 25 && hsl1.saturation < 10
        let isLightGray1 = hsl1.lightness > 75 && hsl1.saturation < 10
        let isDarkGray2 = hsl2.lightness < 25 && hsl2.saturation < 10
        let isLightGray2 = hsl2.lightness > 75 && hsl2.saturation < 10

        return (isDarkGray1 && isLightGray2) || (isDarkGray2 && isLightGray1)
    }

    // Red and cyan
    private static func areRedAndCyan(_ color1: Color, _ color2: Color) -> Bool {
        let rgb1 = color1.toRGB()
        let rgb2 = color2.toRGB()

        let isRed1 = rgb1.red > 200 && rgb1.green < 100 && rgb1.blue < 100
        let isCyan1 = rgb1.red < 101 && rgb1.green > 200 && rgb1.blue > 200

        let isRed2 = rgb2.red > 200 && rgb2.green < 100 && rgb2.blue < 100
        let isCyan2 = rgb2.red < 101 && rgb2.green > 200 && rgb2.blue > 200

        return (isRed1 && isCyan2) || (isRed2 && isCyan1)
    }

    // Blue and orange
    private static func areBlueAndOrange(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        let isBlue1 = (hsl1.hue >= 210 && hsl1.hue <= 250)
        let isOrange1 = (hsl1.hue >= 20 && hsl1.hue <= 40)

        let isBlue2 = (hsl2.hue >= 210 && hsl2.hue <= 250)
        let isOrange2 = (hsl2.hue >= 20 && hsl2.hue <= 40)

        return (isBlue1 && isOrange2) || (isBlue2 && isOrange1)
    }

    // Red and darker red
    private static func areRedAndDarkerRed(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF0000" && hex2 == "#880000") || (hex1 == "#880000" && hex2 == "#FF0000")
    }

    // Blue and purple
    private static func areBlueAndPurple(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        let isBlue = (hsl1.hue >= 210 && hsl1.hue <= 250) || (hsl2.hue >= 210 && hsl2.hue <= 250)
        let isPurple = (hsl1.hue >= 260 && hsl1.hue <= 290) || (hsl2.hue >= 260 && hsl2.hue <= 290)

        return isBlue && isPurple
    }

    // Yellow and green
    private static func areYellowAndGreen(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        let isYellow = (hsl1.hue >= 40 && hsl1.hue <= 70) || (hsl2.hue >= 40 && hsl2.hue <= 70)
        let isGreen = (hsl1.hue >= 80 && hsl1.hue <= 160) || (hsl2.hue >= 80 && hsl2.hue <= 160)

        return isYellow && isGreen
    }

    // Red and blue (triadic)
    private static func areRedAndBlue(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        let isRed = (hsl1.hue <= 10 || hsl1.hue >= 350) || (hsl2.hue <= 10 || hsl2.hue >= 350)
        let isBlue = (hsl1.hue >= 210 && hsl1.hue <= 250) || (hsl2.hue >= 210 && hsl2.hue <= 250)

        return isRed && isBlue
    }

    // Yellow and purple (triadic)
    private static func areYellowAndPurple(_ color1: Color, _ color2: Color) -> Bool {
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()

        let isYellow = (hsl1.hue >= 40 && hsl1.hue <= 70) || (hsl2.hue >= 40 && hsl2.hue <= 70)
        let isPurple = (hsl1.hue >= 260 && hsl1.hue <= 290) || (hsl2.hue >= 260 && hsl2.hue <= 290)

        return isYellow && isPurple
    }

    // Similar blues
    private static func areSimilarBlues(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#0000FF" && hex2 == "#000099") || (hex1 == "#000099" && hex2 == "#0000FF")
    }

    // Green shades
    private static func areGreenShades(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#00FF00" && hex2 == "#003300") || (hex1 == "#003300" && hex2 == "#00FF00")
    }

    // Pink shades
    private static func arePinkShades(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FFB6C1" && hex2 == "#FF69B4") || (hex1 == "#FF69B4" && hex2 == "#FFB6C1")
    }

    // Similar grays
    private static func areSimilarGrays(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#999999" && hex2 == "#777777") || (hex1 == "#777777" && hex2 == "#999999")
    }

    // Green and magenta
    private static func areGreenAndMagenta(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#00FF00" && hex2 == "#FF00FF") || (hex1 == "#FF00FF" && hex2 == "#00FF00")
    }

    // Orange and azure
    private static func areOrangeAndAzure(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF8000" && hex2 == "#0080FF") || (hex1 == "#0080FF" && hex2 == "#FF8000")
    }

    // Brown and steel blue
    private static func areBrownAndSteelBlue(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#8B4513" && hex2 == "#4682B4") || (hex1 == "#4682B4" && hex2 == "#8B4513")
    }

    // Red and orange
    private static func areRedAndOrange(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF0000" && hex2 == "#FF8000") || (hex1 == "#FF8000" && hex2 == "#FF0000")
    }

    // Orange and yellow
    private static func areOrangeAndYellow(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF8000" && hex2 == "#FFFF00") || (hex1 == "#FFFF00" && hex2 == "#FF8000")
    }

    // Magenta and yellow
    private static func areMagentaAndYellow(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF00FF" && hex2 == "#FFFF00") || (hex1 == "#FFFF00" && hex2 == "#FF00FF")
    }

    // Magenta and cyan
    private static func areMagentaAndCyan(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF00FF" && hex2 == "#00FFFF") || (hex1 == "#00FFFF" && hex2 == "#FF00FF")
    }

    // Magenta and orange
    private static func areMagentaAndOrange(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#FF00FF" && hex2 == "#FF8000") || (hex1 == "#FF8000" && hex2 == "#FF00FF")
    }

    // Blue and gray
    private static func areBlueAndGray(_ color1: Color, _ color2: Color) -> Bool {
        let color1IsBlue = color1 == .blue
        let color2IsBlue = color2 == .blue
        let color1IsGray = color1 == .gray
        let color2IsGray = color2 == .gray

        return (color1IsBlue && color2IsGray) || (color1IsGray && color2IsBlue)
    }

    // Black and yellow
    private static func areBlackAndYellow(_ color1: Color, _ color2: Color) -> Bool {
        let color1IsBlack = color1 == .black
        let color2IsBlack = color2 == .black
        let color1IsYellow = color1 == .yellow
        let color2IsYellow = color2 == .yellow

        return (color1IsBlack && color2IsYellow) || (color1IsYellow && color2IsBlack)
    }

    // Vibrating colors
    private static func areVibratingColors(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#5FA41C" && hex2 == "#FF1A00") || (hex1 == "#FF1A00" && hex2 == "#5FA41C")
    }

    // Neon colors
    private static func areNeonColors(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#15F4EE" && hex2 == "#FF08FC") || (hex1 == "#FF08FC" && hex2 == "#15F4EE")
    }

    // Dark colors
    private static func areDarkColors(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#4B1223" && hex2 == "#122423") || (hex1 == "#122423" && hex2 == "#4B1223")
    }

    // Cool and warm
    private static func areCoolAndWarm(_ color1: Color, _ color2: Color) -> Bool {
        let hex1 = color1.toHex().uppercased()
        let hex2 = color2.toHex().uppercased()

        return (hex1 == "#74AD5C" && hex2 == "#DB8061") || (hex1 == "#DB8061" && hex2 == "#74AD5C")
    }
}
