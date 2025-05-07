//
//  AccessibilityMode.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct AccessibilityMode: CameraModeProtocol {
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
    @EnvironmentObject var camera: CameraModel

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
            .padding(2)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedDeficiency) { _, newValue in
                camera.currentColorVisionType = newValue
                if newValue == ColorVisionType.normal {
                    camera.applyColorVisionFilter = false
                } else {
                    camera.applyColorVisionFilter = true
                }
            }

            Text(selectedDeficiency.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 20)
        .onDisappear {
            camera.applyColorVisionFilter = false
            selectedDeficiency = .normal
        }
    }
}
