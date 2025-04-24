//
//  ColorVisionUtility.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct ColorVisionUtility {

    // MARK: - Constants
    // LMS transformation matrices for simulating color deficiencies
    private static let rgbToLMS: [[Double]] = [
        [0.31399022, 0.63951294, 0.04649755],
        [0.15537241, 0.75789446, 0.08670142],
        [0.01775239, 0.10944209, 0.87256922]
    ]

    private static let lmsToRGB: [[Double]] = [
        [5.47221206, -4.6419601, 0.16963708],
        [-1.1252419, 2.29317094, -0.1678952],
        [0.02980165, -0.19318073, 1.16364789]
    ]

    // Missing M-cone (Deuteranopia)
    private static let deuteranopiaMatrix: [[Double]] = [
        [1, 0, 0],
        [0.494207, 0, 0.505793],
        [0, 0, 1]
    ]

    // Missing L-cone (Protanopia)
    private static let protanopiaMatrix: [[Double]] = [
        [0, 1.05118294, -0.05116099],
        [0, 1, 0],
        [0, 0, 1]
    ]

    // Missing S-cone (Tritanopia)
    private static let tritanopiaMatrix: [[Double]] = [
        [1, 0, -0.15],
        [0.05, 1, 1.05],
        [-0.86744736, 1.86727089, 0]
    ]

    // MARK: - Public Methods

    /// Simulates how a color would appear to someone with the specified color vision type
    static func simulateColorVision(_ color: Color, type: ColorVisionType) -> Color {
        // For normal vision, just return the original color
        guard type != .normal else { return color }

        // Get RGB components and prepare for transformation
        let components = color.toRGBComponents()
        let rgb = [
            removeGamma(components.red),
            removeGamma(components.green),
            removeGamma(components.blue)
        ]

        // Select the appropriate matrix for the vision type
        let matrix: [[Double]]
        switch type {
        case .deuteranopia:
            matrix = deuteranopiaMatrix
        case .protanopia:
            matrix = protanopiaMatrix
        case .tritanopia:
            matrix = tritanopiaMatrix
        case .normal:
            return color // This should never be reached due to the guard above
        }

        // Perform the simulation
        return simulateDeficiency(rgb: rgb, matrix: matrix)
    }

    /// Simulates all possible color vision types for a given color
    static func simulateAllColorVisions(for color: Color) -> [ColorVision] {
        return ColorVisionType.allCases.map { visionType in
            let simulatedColor = simulateColorVision(color, type: visionType)
            return ColorVision(color: simulatedColor, type: visionType)
        }
    }

    // MARK: - Private Helper Methods

    /// Removes gamma correction from a color component
    private static func removeGamma(_ value: Double) -> Double {
        if value <= 0.04045 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }

    /// Adds gamma correction to a color component
    private static func addGamma(_ value: Double) -> Double {
        if value <= 0.0031308 {
            return 12.92 * value
        }
        return 1.055 * pow(value, 1/2.4) - 0.055
    }

    /// Multiplies a matrix by a vector
    private static func multiply(matrix: [[Double]], vector: [Double]) -> [Double] {
        matrix.map { row in
            zip(row, vector).map(*).reduce(0, +)
        }
    }

    /// Simulates a color deficiency by transforming through LMS color space
    private static func simulateDeficiency(rgb: [Double], matrix: [[Double]]) -> Color {
        // Convert RGB to LMS color space
        let lms = multiply(matrix: rgbToLMS, vector: rgb)

        // Apply the color deficiency simulation
        let simLMS = multiply(matrix: matrix, vector: lms)

        // Convert back to RGB
        let simRGB = multiply(matrix: lmsToRGB, vector: simLMS)

        // Create a new color with the simulated RGB values
        return Color(
            r: addGamma(max(0, min(1, simRGB[0]))),
            g: addGamma(max(0, min(1, simRGB[1]))),
            b: addGamma(max(0, min(1, simRGB[2])))
        )
    }
}

// Helper extension to access RGB components
private extension Color {
    func toRGBComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
