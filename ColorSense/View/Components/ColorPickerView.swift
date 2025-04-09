//
//  ColorPickerView.swift
//  ColorSense
//
//  Created by Justin Wells on 4/8/25.
//

import SwiftUI

struct ColorPickerView: View {
    @State private var selectedColor: Color = .blue
    @State private var hexInput: String = ""
    @State private var showHexError: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var onColorSelected: (Color) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                colorPreviewSection

                ScrollView {
                    VStack(spacing: 24) {
                        hexInputSection

                        colorWheelSection

                        rgbSliderSection

                        presetColorsSection
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Select") {
                        onColorSelected(selectedColor)
                        dismiss()
                    }
                    .bold()
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Hex Code", isPresented: $showHexError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid hex color code (e.g. #FF5500 or FF5500)")
            }
            .onChange(of: selectedColor) { _, _ in
                updateHexFromColor()
            }
        }
    }

    private var colorPreviewSection: some View {
        ZStack {
            // Checkered background to show transparency
            if colorScheme == .light {
                checkerboardPattern(cellSize: 8, lightColor: .gray.opacity(0.1), darkColor: .gray.opacity(0.2))
            } else {
                checkerboardPattern(cellSize: 8, lightColor: .gray.opacity(0.2), darkColor: .gray.opacity(0.3))
            }

            // Color preview
            selectedColor

            // Color info overlay
            VStack {
                Spacer()
                HStack {
                    Text(UIColor(selectedColor).exactName)
                        .font(.headline)
                        .foregroundColor(selectedColor.isDark() ? .white : .black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .padding(.bottom, 12)
            }
        }
        .frame(height: 100)
    }

    private var hexInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hex Code")
                .font(.headline)

            HStack {
                TextField("e.g. #FF5500", text: $hexInput)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .monospacedDigit()

                Button(action: applyHexInput) {
                    Text("Apply")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }

    private var colorWheelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Wheel")
                .font(.headline)

            // Make the color picker bigger
            ColorPicker("", selection: $selectedColor)
                .labelsHidden()
                .scaleEffect(1.5)
                .frame(height: 70)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
        }
    }

    private var rgbSliderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RGB Values")
                .font(.headline)

            let rgb = selectedColor.toRGB()

            // Red slider
            colorSlider(
                value: Binding(
                    get: { Double(rgb.red) / 255.0 },
                    set: { updateColorFromRGB(r: Int($0 * 255), g: rgb.green, b: rgb.blue) }
                ),
                color: .red,
                label: "R",
                valueText: "\(rgb.red)"
            )

            // Green slider
            colorSlider(
                value: Binding(
                    get: { Double(rgb.green) / 255.0 },
                    set: { updateColorFromRGB(r: rgb.red, g: Int($0 * 255), b: rgb.blue) }
                ),
                color: .green,
                label: "G",
                valueText: "\(rgb.green)"
            )

            // Blue slider
            colorSlider(
                value: Binding(
                    get: { Double(rgb.blue) / 255.0 },
                    set: { updateColorFromRGB(r: rgb.red, g: rgb.green, b: Int($0 * 255)) }
                ),
                color: .blue,
                label: "B",
                valueText: "\(rgb.blue)"
            )
        }
    }

    private func colorSlider(value: Binding<Double>, color: Color, label: String, valueText: String) -> some View {
        HStack {
            Text(label)
                .bold()
                .frame(width: 20)

            Slider(value: value)
                .accentColor(color)
                .frame(height: 30)

            Text(valueText)
                .monospacedDigit()
                .frame(width: 40)
        }
    }

    private var presetColorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preset Colors")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 65), spacing: 12)], spacing: 12) {
                ForEach(presetColors, id: \.self) { color in
                    colorButton(color: color)
                }
            }
        }
    }

    private func colorButton(color: Color) -> some View {
        ZStack {
            if colorScheme == .light && color == .white {
                checkerboardPattern(cellSize: 4, lightColor: .gray.opacity(0.1), darkColor: .gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            color == selectedColor
                            ? Color.accentColor
                            : Color.primary.opacity(0.2),
                            lineWidth: color == selectedColor ? 2 : 1
                        )
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .foregroundColor(color.isDark() ? .white : .black)
                        .font(.system(size: 20, weight: .bold))
                        .opacity(color == selectedColor ? 1 : 0)
                )
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedColor = color
            }
        }
    }

    private func checkerboardPattern(cellSize: CGFloat, lightColor: Color, darkColor: Color) -> some View {
        Canvas { context, size in
            let columnCount = Int(size.width / cellSize) + 1
            let rowCount = Int(size.height / cellSize) + 1

            for row in 0..<rowCount {
                for column in 0..<columnCount {
                    let rect = CGRect(
                        x: CGFloat(column) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )

                    context.fill(
                        Path(rect),
                        with: .color((row + column) % 2 == 0 ? lightColor : darkColor)
                    )
                }
            }
        }
    }

    private func applyHexInput() {
        guard isValidHexColor(hex: hexInput) else {
            showHexError = true
            return
        }

        selectedColor = Color(hex: hexInput)
    }

    private func updateHexFromColor() {
        hexInput = selectedColor.toHex()
    }

    private func updateColorFromRGB(r: Int, g: Int, b: Int) {
        selectedColor = Color(r: Double(r) / 255, g: Double(g) / 255, b: Double(b) / 255)
    }

    private func isValidHexColor(hex: String) -> Bool {
        let pattern = "^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: hex)
    }

    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .indigo, .purple,
        .pink, .gray, .black, .white,
        Color(hex: "FF5733"), Color(hex: "102E50"), Color(hex: "F5C45E"),
        Color(hex: "E78B48"), Color(hex: "BE3D2A"), Color(hex: "9FB3DF"),
        Color(hex: "F7CFD8"), Color(hex: "F4F8D3"), Color(hex: "A6D6D6")
    ]
}

#Preview {
    NavigationStack {
        ColorPickerView(onColorSelected: { _ in })
    }
}
