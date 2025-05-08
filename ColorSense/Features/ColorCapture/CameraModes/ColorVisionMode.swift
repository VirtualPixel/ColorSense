//
//  AccessibilityMode.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct ColorVisionMode: CameraModeProtocol {
    var name: String { "Color Vision" }
    var iconName: String { "eye" }

    func getContentView() -> AnyView {
        AnyView(AccessibilityModeView())
    }

    func onCaptureButtonPressed(camera: CameraModel) async {
        await camera.capturePhoto()
    }

    var captureButtonIcon: String? { "camera" }
    var captureButtonText: String? { nil }
}

struct AccessibilityModeView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject var camera: CameraModel
    @State private var showPaywall = false
    @State private var selectedDeficiency: ColorVisionType = .normal
    @State private var showingCompareView = false
    @State private var showingAnalyzeView = false

    var body: some View {
        VStack(spacing: 10) {
            // Title
            Text("Color Vision Simulation")
                .foregroundColor(.white)
                .font(.headline)

            // Vision type picker - FREE FOR ALL
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

            // Description text
            Text(selectedDeficiency.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer() // Push content to top, controls to bottom

            // Bottom controls section
            VStack {
                if selectedDeficiency != .normal {
                    Text("Use the camera button below to capture photos with this filter applied")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .padding(.bottom, 5)
        }
        .padding(.top, 20)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onDisappear {
            camera.applyColorVisionFilter = false
            selectedDeficiency = .normal
        }
    }

    // Pro teaser button
    private func proTeaseButton(icon: String, text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(text)
                .font(.caption)
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
                .foregroundColor(.yellow)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.3))
        .cornerRadius(10)
        .foregroundColor(.white.opacity(0.7))
        .onTapGesture {
            showPaywall = true
        }
    }
}
