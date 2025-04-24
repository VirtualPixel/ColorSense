//
//  MatchMode.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct MatchMode: CameraModeProtocol {
    @ObservedObject private var viewModel = ViewModel()

    var name: String { "Match" }
    var iconName: String { "square.on.square" }
    let buttonWidth: CGFloat = 120
    let buttonHeight: CGFloat = 80

    func getContentView() -> AnyView {
        AnyView(
            VStack(spacing: 15) {
                HStack(spacing: 20) {
                    colorBox(number: 1, color: viewModel.color1)
                    colorBox(number: 2, color: viewModel.color2)
                }

                if let color1 = viewModel.color1, let color2 = viewModel.color2 {
                    matchPercentageView(color1: color1, color2: color2)
                        .padding(20)
                }
            }
                .padding(.top, 20)
        )
    }

    private func colorBox(number: Int, color: Color?) -> some View {
        VStack(spacing: 6) {
            Button {
                withAnimation(.spring()) {
                    viewModel.selectedColorBox = number
                }
            } label: {
                VStack {
                    Group {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color ?? Color.gray.opacity(0.3))
                            .frame(width: 120, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.selectedColorBox == number ? Color.white : Color.clear, lineWidth: 3)
                            )

                        // Show a helpful icon when no color is selected
                        if color == nil {
                            Image(systemName: "eyedropper")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }

                        // Show the color's hex value if available
                        if let selectedColor = color {
                            Text(selectedColor.toHex())
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .cornerRadius(4)
                        }
                    }
                    .contextMenu {
                        if let color = color {
                            Button {
                                UIPasteboard.general.string = color.toHex()
                            } label: {
                                Text("Copy to clipboard")
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }

    func onCaptureButtonPressed(camera: CameraModel) async {
        guard let currentColor = await camera.getCurrentColor(),
        !viewModel.isSwitchingBoxes else { return }

        viewModel.isSwitchingBoxes = true
        withAnimation(.spring()) {
            if viewModel.selectedColorBox == 1 {
                viewModel.color1 = currentColor
            } else {
                viewModel.color2 = currentColor
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring()) {
                viewModel.toggleSelectedColorBox()
            }
            viewModel.isSwitchingBoxes = false
        }
    }

    private func matchPercentageView(color1: Color, color2: Color) -> some View {
        let result = ColorHarmonyEngine.calculateHarmony(between: color1, and: color2)

        return VStack(spacing: 12) {
            // Score display with circular progress indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(result.score))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Percentage text
                Text("\(Int(result.score * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Harmony type indicator (if available)
            if let type = result.type {
                Text(type.localizedName)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .foregroundStyle(.white)
            }

            // Description text
            Text(result.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(), value: result.score)
    }

    private func matchDescription(percentage: Double) -> String {
        guard let color1 = viewModel.color1, let color2 = viewModel.color2 else {
            return "Select both colors to see harmony"
        }

        let result = ColorHarmonyEngine.calculateHarmony(between: color1, and: color2)
        return result.description
    }

    var captureButtonIcon: String? { "eyedropper" }
    var captureButtonText: String? { nil }
}
