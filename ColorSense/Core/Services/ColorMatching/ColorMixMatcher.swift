//
//  ColorMixMatcher.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import UIKit
import SwiftUICore

/// Loads proprietary color blend data.
///
/// IMPORTANT: This data is © 2025 Justin Wells and is provided under a proprietary license.
/// Commercial use is prohibited without a license agreement.
class ColorMixMatcher {
    // Singleton pattern for app-wide access
    static let shared = ColorMixMatcher()

    // Color data storage
    private var colorMap: [String: [String: Any]] = [:]
    private(set) var isLoaded = false

    private init() {
        // Private initializer to ensure singleton usage
    }

    func initialize() {
        loadColorMap()
    }

    func loadColorMap() {
        // Guard against repeated loading
        guard !isLoaded else { return }

        if let url = Bundle.main.url(forResource: "colorMixes", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check if we have the new structure with _license field
                    if let _ = jsonObject["_license"] as? [String: Any],
                       let colorBlends = jsonObject["colorBlends"] as? [String: Any] {
                        parseAndStoreColorMap(colorBlends)
                    } else {
                        // Fall back to old format
                        parseAndStoreColorMap(jsonObject)
                    }

                    isLoaded = true
                    print("ColorMixMatcher: Successfully loaded color map with \(colorMap.count) colors")
                }
            } catch {
                print("ColorMixMatcher: Error loading color map: \(error)")
            }
        } else {
            print("ColorMixMatcher: Could not find colorMixes.json resource")
        }
    }

    private func parseAndStoreColorMap(_ sourceMap: [String: Any]) {
        // Clear existing data
        colorMap.removeAll()

        // Process each entry explicitly with type checking
        for (hexKey, value) in sourceMap {
            if let mixData = value as? [String: Any] {
                colorMap[hexKey] = mixData
            }
        }
    }

    func getColorMixString(for color: Color) -> String {
            let hex = color.toHex()

            // First try an exact match
            if let exactMatch = findExactMatch(for: hex) {
                return exactMatch
            }

            // Then try to find a close match
            if let closestMatch = findClosestMatch(for: hex) {
                return closestMatch
            }

            // If nothing is found, fall back to RGB
            return color.toSwiftUI()
        }

    func findExactMatch(for hexColor: String) -> String? {
        // Make sure data is loaded
        if !isLoaded {
            print("ColorMixMatcher: Warning - attempting to use before initialization")
            loadColorMap()
        }

        if let mixDict = colorMap[hexColor] {
            if let color1 = mixDict["color1"] as? String,
               let color2 = mixDict["color2"] as? String,
               let ratio = mixDict["ratio"] as? Double {
                return "Color.blend(\(color1), with: \(color2), ratio: \(ratio))"
            }
        }
        return nil
    }

    func findClosestMatch(for hexColor: String, threshold: CGFloat = 30.0) -> String? {
        // Make sure data is loaded
        if !isLoaded {
            print("ColorMixMatcher: Warning - attempting to use before initialization")
            loadColorMap()
        }

        // Make sure the UIColor extension is available
        guard let targetColor = UIColor(hexString: hexColor) else {
            print("ColorMixMatcher: Could not create UIColor from hex: \(hexColor)")
            return nil
        }

        var bestMatch: String? = nil
        var smallestDistance: CGFloat = .greatestFiniteMagnitude

        // Compare with all colors in the map
        for (mapHex, value) in colorMap {
            guard let mapColor = UIColor(hexString: mapHex) else {
                continue
            }

            // Calculate color distance - need to make sure this method exists
            let distance = mapColor.difference(to: targetColor)

            if distance < smallestDistance {
                smallestDistance = distance

                if let color1 = value["color1"] as? String,
                   let color2 = value["color2"] as? String,
                   let ratio = value["ratio"] as? Double {
                    bestMatch = "Color.blend(\(color1), with: \(color2), ratio: \(ratio))"
                }
            }
        }

        // Only return matches below the threshold
        return smallestDistance < threshold ? bestMatch : nil
    }
}
