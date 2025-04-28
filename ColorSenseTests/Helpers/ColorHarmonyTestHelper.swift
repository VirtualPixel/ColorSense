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
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = ColorHarmonyEngine.calculateHarmony(between: color1, and: color2)

        // Check if the score falls within the expected quality range
        let expectedQuality = HarmonyQuality.forScore(expectedScore)
        let resultQuality = HarmonyQuality.forScore(result.score)

        XCTAssertEqual(
            resultQuality,
            expectedQuality,
            "\(message) Expected quality: \(expectedQuality.rawValue), got: \(resultQuality.rawValue) with score: \(result.score)",
            file: file,
            line: line
        )

        // Check the harmony type
        XCTAssertEqual(
            result.type,
            expectedType,
            "\(message) Expected type: \(String(describing: expectedType)), got: \(String(describing: result.type))",
            file: file,
            line: line
        )
    }

    /// Tests color harmony with a flexible approach allowing multiple possible quality categories
    /// - Parameters:
    ///   - color1: First color to test
    ///   - color2: Second color to test
    ///   - expectedQualities: Array of accepted quality categories
    ///   - expectedType: The expected harmony type
    ///   - message: Optional test description
    func assertFlexibleHarmony(
        color1: Color,
        color2: Color,
        expectedQualities: [HarmonyQuality],
        expectedType: HarmonyType?,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let result = ColorHarmonyEngine.calculateHarmony(between: color1, and: color2)
        let resultQuality = HarmonyQuality.forScore(result.score)

        XCTAssertTrue(
            expectedQualities.contains(resultQuality),
            "\(message) Expected one of qualities: \(expectedQualities.map { $0.rawValue }.joined(separator: ", ")), got: \(resultQuality.rawValue) with score: \(result.score)",
            file: file,
            line: line
        )

        XCTAssertEqual(
            result.type,
            expectedType,
            "\(message) Expected type: \(String(describing: expectedType)), got: \(String(describing: result.type))",
            file: file,
            line: line
        )
    }
}
