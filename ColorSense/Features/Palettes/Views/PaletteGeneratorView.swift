//
//  PaletteGeneratorView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/14/25.
//

import SwiftUI

struct PaletteGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var selectedCategory: PaletteCategory = .standard
    @State private var numberOfColors: Int = 5
    @State private var generationMode: GenerationMode = .fromSeed
    @State private var harmonyStrength: Double = 0.5
    @State private var seedColor: Color = .blue
    @State private var showColorPicker = false
    @State private var generatedColors: [Color] = []
    @State private var isGenerating = false
    @State private var animatingColors: [Color] = []
    @State private var colorGenerationPhase = 0
    @State private var seedColorOptions: [Color] = []
    @State private var showingSeedExplorer = false
    @State private var animatedColorIndices: [Int] = []
    @State private var isExplorerExpanding = false
    @State private var isAnimating = false

    // Properties passed from parent view
    let existingColors: [Color]
    let onColorsGenerated: ([Color]) -> Void

    enum GenerationMode: String, CaseIterable {
        case fromSeed = "From Seed Color"
        case fromScratch = "From Scratch"
        // case enhance = "Enhance Existing"
        // case complement = "Add Complementary"
        // case variations = "Create Variations"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // Generation mode section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Generation Method")
                                .font(.headline)

                            Picker("Mode", selection: $generationMode) {
                                if existingColors.isEmpty {
                                    Text("From Seed Color").tag(GenerationMode.fromSeed)
                                    Text("From Scratch").tag(GenerationMode.fromScratch)
                                } /* else {
                                    Text("Enhance Existing").tag(GenerationMode.enhance)
                                    Text("Add Complementary").tag(GenerationMode.complement)
                                    Text("Create Variations").tag(GenerationMode.variations)
                                } */
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: generationMode) { oldValue, newValue in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if oldValue != newValue {
                                        generatedColors = []
                                    }
                                }
                            }

                            // Mode description
                            Text(descriptionForMode(generationMode))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                                .transition(.opacity)
                                .animation(.easeInOut, value: generationMode)
                        }
                    }

                    // Settings section
                    Section(header: Text("Settings")) {
                        // Category selection - always show
                        Picker("Style", selection: $selectedCategory) {
                            ForEach(PaletteCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }

                        // Number of colors - show for applicable modes
                        if generationMode == .fromScratch || generationMode == .fromSeed { // || generationMode == .complement {
                            Stepper("Number of Colors: \(numberOfColors)", value: $numberOfColors, in: 3...6)
                                .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
                        }

                        // Seed color picker - show only for fromSeed mode
                        if generationMode == .fromSeed {
                            VStack(alignment: .leading, spacing: 12) {
                                // Top section (remains static)
                                HStack {
                                    // Color swatch
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(seedColor)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                        )

                                    // Text label
                                    Text("Seed Color")
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: true, vertical: false)

                                    Spacer()

                                    // Buttons
                                    HStack(spacing: 8) {
                                        // Toggle button with disabled state during animation
                                        Button {
                                            // Prevent multiple animations from running simultaneously
                                            if !isAnimating {
                                                if showingSeedExplorer {
                                                    closeExplorerWithAnimation()
                                                } else {
                                                    generateSeedColorOptions()
                                                    startExplorerAnimation()
                                                }
                                            }
                                        } label: {
                                            Image(systemName: showingSeedExplorer ? "xmark" : "sparkles")
                                                .font(.system(size: 16))
                                                .frame(width: 36, height: 36)
                                                .opacity(isAnimating ? 0.6 : 1.0) // Visual feedback for disabled state
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(isAnimating) // Prevent interaction during animation

                                        Button {
                                            showColorPicker = true
                                        } label: {
                                            Image(systemName: "eyedropper")
                                                .font(.system(size: 16))
                                                .frame(width: 36, height: 36)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            // Color explorer section (animated)
                            if isExplorerExpanding || showingSeedExplorer {
                                VStack(alignment: .center, spacing: 12) {
                                    // Title
                                    Text("Choose a Seed Color")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .opacity(showingSeedExplorer ? 1 : 0)

                                    // Color grid
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 10) {
                                        ForEach(0..<9, id: \.self) { index in
                                            if index < seedColorOptions.count {
                                                Button {
                                                    if !isAnimating {
                                                        withAnimation(.spring()) {
                                                            seedColor = seedColorOptions[index]
                                                        }
                                                        closeExplorerWithAnimation()
                                                    }
                                                } label: {
                                                    colorExplorerCell(seedColorOptions[index])
                                                        .opacity(animatedColorIndices.contains(index) ? 1 : 0)
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(isAnimating) // Prevent interaction during animation
                                            } else {
                                                // Empty placeholder
                                                Color.clear
                                                    .frame(width: 60, height: 90)
                                            }
                                        }
                                    }

                                    // Refresh button
                                    Button {
                                        if !isAnimating {
                                            generateSeedColorOptions()
                                            animateColorsSequentially()
                                        }
                                    } label: {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .padding(8)
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top, 8)
                                    .opacity(showingSeedExplorer ? 1 : 0)
                                    .disabled(isAnimating) // Prevent interaction during animation
                                }
                                .drawingGroup()
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemBackground).opacity(0.5))
                                .cornerRadius(10)
                                .frame(height: showingSeedExplorer ? nil : 0)
                                .opacity(showingSeedExplorer ? 1 : 0)
                                .clipped()
                            }
                        }
                        /*
                        // Harmony strength - show only for enhance mode
                        if generationMode == .enhance {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Harmony Strength: \(Int(harmonyStrength * 100))%")
                                    Spacer()
                                }

                                Slider(value: $harmonyStrength, in: 0...1)

                                HStack {
                                    Text("Subtle")
                                        .font(.caption)
                                    Spacer()
                                    Text("Strong")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            .contentTransition(.opacity)
                        }*/
                    }
                    .animation(.easeInOut, value: generationMode)

                    // Preview section
                    Section {
                        VStack(alignment: .center, spacing: 16) {
                            // Only show the generate button if we don't have colors yet
                            if generatedColors.isEmpty {
                                Button {
                                    generateColorsWithAnimation()
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("Generate Palette")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain) // Use plain style to prevent iOS-specific styling
                                .padding(.vertical, 8)
                            }
                            else {
                                // Show a comparison if we're modifying existing colors
                                /* if generationMode == .enhance || generationMode == .complement || generationMode == .variations {
                                    paletteComparisonView
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                } else {*/
                                    // Just show generated colors for new palettes
                                    generatedPaletteView
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                // }

                                // Action buttons
                                HStack(spacing: 20) {
                                    Button {
                                        generateColorsWithAnimation()
                                    } label: {
                                        Label("Try Again", systemImage: "arrow.triangle.2.circlepath")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.primary)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        onColorsGenerated(generatedColors)

                                        withAnimation {
                                            dismiss()
                                        }
                                    } label: {
                                        Label("Apply", systemImage: "checkmark")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.accentColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 12)
                                .transition(.opacity)
                            }
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: generatedColors.isEmpty)
                }

                // Loading overlay
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            if colorGenerationPhase == 0 {
                                // "Thinking" phase
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)

                                    Text("Finding the perfect colors...")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                            } else {
                                // Color presentation phase
                                VStack(spacing: 16) {
                                    Text("Building your palette")
                                        .foregroundColor(.white)
                                        .font(.headline)

                                    // Animated color swatches appearing one by one
                                    HStack(spacing: 12) {
                                        ForEach(animatingColors.indices, id: \.self) { index in
                                            Circle()
                                                .fill(animatingColors[index])
                                                .frame(width: 40, height: 40)
                                                .shadow(color: animatingColors[index].opacity(0.6), radius: 8)
                                                .transition(.scale.combined(with: .opacity))
                                        }

                                        // Placeholder circles for colors yet to appear
                                        ForEach(0..<(numberOfColors - animatingColors.count), id: \.self) { _ in
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 40, height: 40)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.8))
                                .shadow(radius: 15)
                        )
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Generate Palette")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerView(onColorSelected: { color in
                    seedColor = color
                    showColorPicker = false
                })
            }
        }
    }

    // Shows before/after comparison
    private var paletteComparisonView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Original")
                    .font(.headline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(originalColorIds, id: \.self) { index in
                            colorSwatch(existingColors[index])
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            HStack {
                VStack {
                    Divider()
                }

                Image(systemName: "arrow.down")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                VStack {
                    Divider()
                }
            }

            /*VStack(alignment: .leading, spacing: 8) {
                Text("Enhanced")
                    .font(.headline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<generatedColors.count, id: \.self) { index in
                            colorSwatch(generatedColors[index])
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }*/
        }
    }

    // Shows just the generated palette for new palettes
    private var generatedPaletteView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated Palette")
                .font(.headline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<generatedColors.count, id: \.self) { index in
                        colorSwatch(generatedColors[index])
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // For showing only a subset of original colors in the preview
    private var originalColorIds: [Int] {
        if existingColors.count <= 6 {
            return Array(0..<existingColors.count)
        } else {
            return [0, 1, 2, existingColors.count-3, existingColors.count-2, existingColors.count-1]
        }
    }

    // Individual color swatch with animation
    private func colorSwatch(_ color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                )
                .shadow(radius: 1)

            Text(color.toHex())
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 60)
        .transition(.scale.combined(with: .opacity))
    }

    // Helper to create the seed color explorer cells
    private func colorExplorerCell(_ color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(color == seedColor ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .shadow(radius: 2)
                .padding(4)

            Text(color.toHex())
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    // Generate animation sequence
    private func generateColorsWithAnimation() {
        // Clear any existing animations
        animatingColors = []
        colorGenerationPhase = 0

        // Start the animation sequence
        withAnimation(.easeInOut(duration: 0.3)) {
            isGenerating = true
        }

        // First phase - "thinking"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            colorGenerationPhase = 1

            // Generate the actual colors behind the scenes
            let newColors = generateColorsBasedOnMode()

            // Second phase - display colors one by one
            for (index, color) in newColors.enumerated() {
                // Vary the timing slightly for more natural feel
                let baseDelay = 0.2
                let randomVariation = Double.random(in: -0.05...0.1)
                let delay = baseDelay + randomVariation

                DispatchQueue.main.asyncAfter(deadline: .now() + (delay * Double(index))) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animatingColors.append(color)
                    }

                    // Play a subtle sound if it's the last color
                    if index == newColors.count - 1 {
                        // Optional: play a subtle success sound
                        // AudioServicesPlaySystemSound(1001)

                        // After all colors are added, finish the animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isGenerating = false
                                generatedColors = newColors
                                colorGenerationPhase = 0
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper to generate seed color options
    private func generateSeedColorOptions() {
        seedColorOptions = []

        // Generate 9 different seed color options
        for _ in 0..<9 {
            let hue = Double.random(in: 0...1)
            let saturation = Double.random(in: selectedCategory.saturationRange)
            let brightness = Double.random(in: selectedCategory.lightnessRange)

            seedColorOptions.append(Color(
                hue: hue,
                saturation: saturation,
                brightness: brightness
            ))
        }
    }

    // Helper to call the right color generation service based on mode
    private func generateColorsBasedOnMode() -> [Color] {
        switch generationMode {
        case .fromScratch:
            return ColorPaletteService.generateRandomPalette(
                numberOfColors: numberOfColors,
                category: selectedCategory
            )

        case .fromSeed:
            return ColorPaletteService.generatePaletteFromSeed(
                seedColor: seedColor,
                numberOfColors: numberOfColors,
                category: selectedCategory
            )

        /*case .enhance:
            if !existingColors.isEmpty {
                return ColorPaletteService.enhanceColorsHarmony(
                    colors: existingColors,
                    strength: harmonyStrength
                )
            }
            return []

        case .complement:
            if !existingColors.isEmpty {
                let seed = existingColors.first!
                let complementaryColors = ColorPaletteService.generatePaletteFromSeed(
                    seedColor: seed,
                    numberOfColors: numberOfColors,
                    category: selectedCategory
                )

                // Filter out colors too similar to existing ones
                let newColors = complementaryColors.filter { newColor in
                    !existingColors.contains { existingColor in
                        newColor.difference(to: existingColor) < 15
                    }
                }

                return existingColors + newColors
            }
            return []

        case .variations:
            if !existingColors.isEmpty {
                let variations = ColorPaletteService.generateVariations(
                    fromColors: existingColors,
                    numberOfVariations: 1
                )

                if variations.count > 1 {
                    return variations[1]
                }
            }
            return []*/
        }
    }

    // Helper method to get description for each mode
    private func descriptionForMode(_ mode: GenerationMode) -> String {
        switch mode {
        case .fromScratch:
            return "Creates a new harmonious palette with balanced colors."
        case .fromSeed:
            return "Generates colors that complement the selected seed color."
        /*case .enhance:
            return "Adjusts existing colors to improve their harmony while preserving their character."
        case .complement:
            return "Adds complementary colors to your existing palette."
        case .variations:
            return "Creates alternative versions of your current palette with similar feel."*/
        }
    }

    private func startExplorerAnimation() {
        isAnimating = true
        animatedColorIndices = []
        isExplorerExpanding = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingSeedExplorer = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateColorsSequentially()
        }

        // Clear animation flag after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isAnimating = false
        }
    }

    // Animate colors appearing one by one
    private func animateColorsSequentially() {
        // Set animation in progress
        isAnimating = true

        // Reset current indices
        animatedColorIndices = []

        // Animate colors with consistent timing
        for i in 0..<min(9, seedColorOptions.count) {
            let delay = 0.05 * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    animatedColorIndices.append(i)
                }
            }
        }

        // Clear animation flag
        let totalDuration = 0.05 * Double(min(9, seedColorOptions.count)) + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            isAnimating = false
        }
    }

    // Close the explorer with reverse animation
    private func closeExplorerWithAnimation() {
        // Set animation flag
        isAnimating = true

        withAnimation(.easeOut(duration: 0.3)) {
            animatedColorIndices = []
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingSeedExplorer = false
            }

            // Reset state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isExplorerExpanding = false
                isAnimating = false
            }
        }
    }
}

// Preview provider
#Preview {
    PaletteGeneratorView(existingColors: [], onColorsGenerated: { _ in })
}

struct ColorComparisonView: View {
    let originalColors: [Color]
    let enhancedColors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before")
                .font(.headline)

            ColorSwatchPreview(colors: originalColors)
                .frame(height: 70)

            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 8)

            Text("After")
                .font(.headline)

            ColorSwatchPreview(colors: enhancedColors)
                .frame(height: 70)
        }
    }
}
