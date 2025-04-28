import XCTest
import SwiftUI
@testable import ColorSense

final class ColorHarmonyTests: XCTestCase {

    // MARK: - Original Test Cases

    func testOriginalHarmonyCases() {
        // Identical colors (perfect monochromatic)
        assertHarmony(
            color1: .black,
            color2: .black,
            expectedScore: 1.0,
            expectedType: .monochromatic,
            message: "Identical colors should be excellent monochromatic"
        )

        // Near-black colors (excellent monochromatic)
        assertHarmony(
            color1: .black,
            color2: Color(hex: "#0A0A0A"),
            expectedScore: 0.95,
            expectedType: .monochromatic,
            message: "Very similar dark colors should be excellent monochromatic"
        )

        // Black and white (good monochromatic with contrast)
        assertHarmony(
            color1: .black,
            color2: .white,
            expectedScore: 0.85,
            expectedType: .monochromatic,
            message: "Black and white should be good monochromatic with high contrast"
        )

        // Dark gray and light gray (good monochromatic)
        assertHarmony(
            color1: Color(hex: "#222222"),
            color2: Color(hex: "#DDDDDD"),
            expectedScore: 0.8,
            expectedType: .monochromatic,
            message: "Dark gray and light gray should be good monochromatic"
        )

        // Red and cyan (excellent complementary)
        assertHarmony(
            color1: .red,
            color2: .cyan,
            expectedScore: 0.9,
            expectedType: .complementary,
            message: "Red and cyan should be excellent complementary"
        )
        
        // Blue and orange (excellent complementary)
        assertHarmony(
            color1: .blue,
            color2: .orange,
            expectedScore: 0.9,
            expectedType: .complementary,
            message: "Blue and orange should be excellent complementary"
        )

        // Blue and purple (good analogous)
        assertHarmony(
            color1: .blue,
            color2: .purple,
            expectedScore: 0.9,
            expectedType: .analogous,
            message: "Blue and purple should be good analogous"
        )

        // Yellow and green (good analogous)
        assertHarmony(
            color1: .yellow,
            color2: .green,
            expectedScore: 0.9,
            expectedType: .analogous,
            message: "Yellow and green should be good analogous"
        )

        // Red and blue (good triadic)
        assertHarmony(
            color1: .red,
            color2: .blue,
            expectedScore: 0.85,
            expectedType: .triadic,
            message: "Red and blue should be good triadic"
        )

        // Yellow and purple (good triadic)
        assertHarmony(
            color1: .yellow,
            color2: .purple,
            expectedScore: 0.8,
            expectedType: .triadic,
            message: "Yellow and purple should be good triadic"
        )

        // Red with darker red (excellent monochromatic)
        assertHarmony(
            color1: Color(hex: "#FF0000"),
            color2: Color(hex: "#880000"),
            expectedScore: 0.9,
            expectedType: .monochromatic,
            message: "Red with darker red should be excellent monochromatic"
        )

        // Magenta and orange (poor combination - from article)
        assertHarmony(
            color1: Color(hex: "#FF00FF"),
            color2: Color(hex: "#FF8000"),
            expectedScore: 0.4,
            expectedType: nil,
            message: "Magenta and orange should be a poor combination"
        )

        // Blue with gray (neutral - from original tests)
        assertHarmony(
            color1: .blue,
            color2: .gray,
            expectedScore: 0.7,
            expectedType: nil,
            message: "Blue with gray should be a neutral combination"
        )
    }

    // MARK: - Bad Combinations from Article

    func testBadCombinationsFromArticle() {
        // Neon colors together (poor - from article)
        assertHarmony(
            color1: Color(hex: "#15f4ee"), // neon cyan
            color2: Color(hex: "#ff08fc"), // neon pink
            expectedScore: 0.4,
            expectedType: nil,
            message: "Neon colors together should create a poor combination"
        )

        // Dark colors together (poor - from article)
        assertHarmony(
            color1: Color(hex: "#4b1223"), // dark burgundy
            color2: Color(hex: "#122423"), // dark swamp
            expectedScore: 0.4,
            expectedType: nil,
            message: "Dark with dark should create a poor combination"
        )

        // Cool and warm clash (poor - from article)
        assertFlexibleHarmony(
            color1: Color(hex: "#74ad5c"), // cool green
            color2: Color(hex: "#db8061"), // warm orange/sand
            expectedQualities: [.poor, .decent],
            expectedType: nil,
            message: "Cool and warm colors should create tension"
        )

        // Vibrating colors (poor - from article)
        assertHarmony(
            color1: Color(hex: "#5fa41c"), // vibrant green
            color2: Color(hex: "#ff1a00"), // vibrant red
            expectedScore: 0.3,
            expectedType: nil,
            message: "Vibrating colors should create a poor combination"
        )
    }

    // MARK: - Extended Monochromatic Tests

    func testExtendedMonochromaticCases() {
        // Various shades of blue
        assertHarmony(
            color1: Color(hex: "#0000FF"),
            color2: Color(hex: "#000099"),
            expectedScore: 0.85,
            expectedType: .monochromatic,
            message: "Different shades of blue should be good monochromatic"
        )

        // Various shades of green
        assertHarmony(
            color1: Color(hex: "#00FF00"),
            color2: Color(hex: "#003300"),
            expectedScore: 0.85,
            expectedType: .monochromatic,
            message: "Light and dark green should be good monochromatic"
        )

        // Light pink and hot pink
        assertHarmony(
            color1: Color(hex: "#FFB6C1"),
            color2: Color(hex: "#FF69B4"),
            expectedScore: 0.85,
            expectedType: .monochromatic,
            message: "Light pink and hot pink should be good monochromatic"
        )
    }

    // MARK: - Extended Complementary Tests

    func testExtendedComplementaryCases() {
        // Green and magenta
        assertHarmony(
            color1: Color(hex: "#00FF00"),
            color2: Color(hex: "#FF00FF"),
            expectedScore: 0.8,
            expectedType: .complementary,
            message: "Green and magenta should be good complementary"
        )

        // Orange and azure
        assertHarmony(
            color1: Color(hex: "#FF8000"),
            color2: Color(hex: "#0080FF"),
            expectedScore: 0.9,
            expectedType: .complementary,
            message: "Orange and azure should be excellent complementary"
        )

        // Earth tone complementary
        assertHarmony(
            color1: Color(hex: "#8B4513"), // brown
            color2: Color(hex: "#4682B4"), // steel blue
            expectedScore: 0.8,
            expectedType: .complementary,
            message: "Brown and steel blue should be good complementary"
        )
    }

    // MARK: - Extended Analogous Tests

    func testExtendedAnalogousCases() {
        // Red and orange
        assertFlexibleHarmony(
            color1: Color(hex: "#FF0000"),
            color2: Color(hex: "#FF8000"),
            expectedQualities: [.good, .decent],
            expectedType: .analogous,
            message: "Red and orange should be decent to good analogous"
        )

        // Orange and yellow
        assertFlexibleHarmony(
            color1: Color(hex: "#FF8000"),
            color2: Color(hex: "#FFFF00"),
            expectedQualities: [.good, .decent],
            expectedType: .analogous,
            message: "Orange and yellow should be decent to good analogous"
        )

        // Blue and indigo
        assertFlexibleHarmony(
            color1: Color(hex: "#0000FF"),
            color2: Color(hex: "#4B0082"),
            expectedQualities: [.excellent, .good],
            expectedType: .analogous,
            message: "Blue and indigo should be good to excellent analogous"
        )
    }

    // MARK: - Extended Triadic Tests

    func testExtendedTriadicCases() {
        // Magenta, yellow, cyan triad parts
        assertFlexibleHarmony(
            color1: Color(hex: "#FF00FF"), // magenta
            color2: Color(hex: "#FFFF00"), // yellow
            expectedQualities: [.good, .decent],
            expectedType: .triadic,
            message: "Magenta and yellow should be decent to good triadic"
        )

        assertFlexibleHarmony(
            color1: Color(hex: "#FF00FF"), // magenta
            color2: Color(hex: "#00FFFF"), // cyan
            expectedQualities: [.good, .decent],
            expectedType: .triadic,
            message: "Magenta and cyan should be decent to good triadic"
        )
    }

    // MARK: - Accessibility-Focused Tests

    func testAccessibilityCombinations() {
        // High contrast combinations (good for accessibility)
        assertHarmony(
            color1: .black,
            color2: .yellow,
            expectedScore: 0.7,
            expectedType: nil, // Not a traditional harmony type
            message: "Black and yellow should have good contrast"
        )

        // Low contrast combinations (poor for accessibility)
        assertHarmony(
            color1: Color(hex: "#999999"),
            color2: Color(hex: "#777777"),
            expectedScore: 0.6,
            expectedType: .monochromatic,
            message: "Similar grays should be monochromatic with fair contrast"
        )
    }
}
