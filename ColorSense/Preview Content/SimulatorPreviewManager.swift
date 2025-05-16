//
//  SimulatorPreviewManager.swift
//  ColorSense
//
//  Created by Justin Wells on 5/16/25.
//

import SwiftUI
import SwiftData

/// Manages simulator-specific preview content for screenshots and demos
class SimulatorPreviewManager {
    static let shared = SimulatorPreviewManager()

    /// Whether the app is running in the simulator
    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Creates example palettes for the simulator environment
    func createExamplePalettes(in context: ModelContext) {
        // Only create examples in the simulator
        guard isSimulator else { return }

        // Check if we already have palettes (avoid duplicates)
        var descriptor = FetchDescriptor<Palette>()
        descriptor.fetchLimit = 1

        do {
            let existingPalettes = try context.fetch(descriptor)
            if !existingPalettes.isEmpty {
                print("Example palettes already exist, skipping creation")
                return
            }
        } catch {
            print("Error checking for existing palettes: \(error)")
        }

        print("Creating example palettes for simulator...")

        // Create example palettes
        let palettes = [
            createNaturePalette(),
            createSunsetPalette(),
            createOceanPalette(),
            createModernPalette(),
            createVintagePalette()
        ]

        // Insert palettes into the context
        for palette in palettes {
            context.insert(palette)
        }

        // Save changes
        do {
            try context.save()
            print("Successfully created \(palettes.count) example palettes")
        } catch {
            print("Error saving example palettes: \(error)")
        }
    }

    // MARK: - Example Palette Creators

    private func createNaturePalette() -> Palette {
        let palette = Palette(name: "Forest Greens", colors: [])

        let colors = [
            "#2D5A27", // Deep Forest Green
            "#4A7F3F", // Moss Green
            "#73AB59", // Leaf Green
            "#B5D8A1", // Soft Sage
            "#E2EDDF"  // Pale Mint
        ]

        for hex in colors {
            let colorStruct = ColorStructure(hex: hex)
            colorStruct.palette = palette
        }

        return palette
    }

    private func createSunsetPalette() -> Palette {
        let palette = Palette(name: "Sunset Glow", colors: [])

        let colors = [
            "#FF6B35", // Sunset Orange
            "#F7B267", // Golden Hour
            "#F25C54", // Warm Red
            "#662E9B", // Twilight Purple
            "#43BCCD"  // Sky Blue
        ]

        for hex in colors {
            let colorStruct = ColorStructure(hex: hex)
            colorStruct.palette = palette
        }

        return palette
    }

    private func createOceanPalette() -> Palette {
        let palette = Palette(name: "Ocean Depths", colors: [])

        let colors = [
            "#05445E", // Deep Blue
            "#189AB4", // Ocean Blue
            "#75E6DA", // Teal
            "#D4F1F9", // Pale Blue
            "#184E77"  // Navy
        ]

        for hex in colors {
            let colorStruct = ColorStructure(hex: hex)
            colorStruct.palette = palette
        }

        return palette
    }

    private func createModernPalette() -> Palette {
        let palette = Palette(name: "Modern Minimal", colors: [])

        let colors = [
            "#2B2D42", // Dark Slate
            "#8D99AE", // Steel Blue
            "#EDF2F4", // Off White
            "#EF233C", // Bright Red
            "#D90429"  // Deep Red
        ]

        for hex in colors {
            let colorStruct = ColorStructure(hex: hex)
            colorStruct.palette = palette
        }

        return palette
    }

    private func createVintagePalette() -> Palette {
        let palette = Palette(name: "Vintage Tones", colors: [])

        let colors = [
            "#D8B384", // Sand
            "#A7A284", // Sage Green
            "#7A6C5D", // Umber
            "#C17817", // Rust
            "#3A3238"  // Dark Plum
        ]

        for hex in colors {
            let colorStruct = ColorStructure(hex: hex)
            colorStruct.palette = palette
        }

        return palette
    }
}
