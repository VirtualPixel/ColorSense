//
//  SharedPaletteView.swift
//  ColorSense
//
//  Created by Justin Wells on 4/9/25.
//

import SwiftUI

import SwiftUI
import SwiftData

struct SharedPaletteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cameraFeed: CameraFeed

    let palette: Palette
    @State private var paletteName: String
    @State private var showingSaveConfirmation = false

    init(palette: Palette) {
        self.palette = palette
        self._paletteName = State(initialValue: palette.wrappedName)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Shared Palette")
                    .font(.title)
                    .fontWeight(.bold)

                // Display palette colors
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(palette.wrappedColors) { colorStruct in
                            ColorItemView(colorStructure: colorStruct)
                                .frame(height: 60)
                        }
                    }
                }

                Divider()

                // Name field for saving
                TextField("Palette Name", text: $paletteName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // Save button
                Button {
                    showingSaveConfirmation = true
                } label: {
                    Text("Save to My Palettes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Save Palette?", isPresented: $showingSaveConfirmation) {
                Button("Save", role: .none) {
                    savePalette()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Save this palette as '\(paletteName)'?")
            }
        }
    }

    func savePalette() {
        // Create a new palette in SwiftData
        let newPalette = Palette(id: UUID(), name: paletteName, colors: [])
        modelContext.insert(newPalette)

        // Add colors to the palette
        for colorStruct in palette.wrappedColors {
            let newColor = ColorStructure(hex: colorStruct.wrappedHex)
            newColor.palette = newPalette
            modelContext.insert(newColor)
        }

        try? modelContext.save()
    }
}

// Helper view to display a color item
struct ColorItemView: View {
    let colorStructure: ColorStructure

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorStructure.color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading) {
                Text(colorStructure.wrappedHex)
                    .font(.headline)

                Text(colorStructure.color.uiColor.exactName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

#Preview {
    SharedPaletteView(palette: Palette.defaultPalette)
}
