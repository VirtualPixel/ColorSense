//
//  ColorHarmonyTestHelper.swift
//  ColorSenseTests
//
//  Created by Justin Wells on 4/23/25.
//

import XCTest
import SwiftUI
@testable import ColorSense

extension XCTestCase {

    /// Tests color harmony with specific expected values
    /// - Parameters:
    ///   - color1: First color to test
    ///   - color2: Second color to test
    ///   - expectedScore: The exact expected score
    ///   - expectedType: The expected harmony type
    ///   - message: Optional test description
    func assertHarmony(
        color1: Color,
        color2: Color,
        expectedScore: Double,
        expectedType: HarmonyType?,
        message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = ColorHarmonyEngine.calculateHarmony(between: color1, and: color2)

        // If there's a custom message, print it
        if let message = message {
            print("ℹ️ \(message)")
        }

        // Check score with tolerance of 0.1
        XCTAssertEqual(
            result.score,
            expectedScore,
            accuracy: 0.1,
            "Expected score \(expectedScore), got \(result.score)",
            file: file,
            line: line
        )

        // Check type
        XCTAssertEqual(
            result.type,
            expectedType,
            "Expected type \(String(describing: expectedType)), got \(String(describing: result.type))",
            file: file,
            line: line
        )
    }

    /// Tests color harmony with flexibility
    /// - Parameters:
    ///   - color1: First color to test
    ///   - color2: Second color to test
    ///   - expectedTypes: An array of acceptable harmony types
    ///   - minScore: Minimum acceptable score
    ///   - message: Optional test description
    func assertFlexibleHarmony(
        color1: Color,
        color2: Color,
        expectedTypes: [HarmonyType?],
        minScore: Double = 0.5,
        message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = ColorHarmonyEngine.calculateHarmony(between: color1, and: color2)

        if let message = message {
            print("ℹ️ \(message)")
        }

        // Check if result type is among expected types
        XCTAssertTrue(
            expectedTypes.contains(result.type),
            "Expected type to be one of \(expectedTypes), got \(String(describing: result.type))",
            file: file,
            line: line
        )

        // Check if score is above minimum
        XCTAssertGreaterThanOrEqual(
            result.score,
            minScore,
            "Expected minimum score \(minScore), got \(result.score)",
            file: file,
            line: line
        )

        // Print actual result for debugging
        print("📊 Actual result: type=\(String(describing: result.type)), score=\(result.score)")
    }
}
