//
//  AccessibilityMode.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct AccessibilityMode: CameraModeProtocol {
    private var selectedDeficiency: ColorVisionType = .normal

    var name: String { "Accessibility" }
    var iconName: String { "eye" }

    func getContentView() -> AnyView {
        AnyView(AccessibilityContentView())
    }

    func onCaptureButtonPressed(camera: CameraModel) async {
        await camera.capturePhoto()
    }

    var captureButtonIcon: String? { "camera" }
    var captureButtonText: String? { nil }
}

struct AccessibilityContentView: View {
    @State private var selectedDeficiency: ColorVisionType = .normal

    var body: some View {
        VStack(spacing: 10) {
            Text("Color Vision Simulation")
                .foregroundColor(.white)
                .font(.headline)

            // Vision type picker
            Picker("Vision Type", selection: $selectedDeficiency) {
                ForEach(ColorVisionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Optionally add a description
            Text(selectedDeficiency.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
    }
}
