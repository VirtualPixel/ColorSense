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
        AnyView(ColorVisionModeView())
    }

    func onCaptureButtonPressed(camera: CameraModel) async {
        await camera.capturePhoto()
    }

    var captureButtonIcon: String? { "camera" }
    var captureButtonText: String? { nil }
}

struct ColorVisionModeView: View {
    @AppStorage("hasSeenEnhancementFeature") private var hasSeenEnhancementFeature = false
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject var camera: CameraModel
    @State private var selectedDeficiency: ColorVisionType = .typical
    @State private var isEnhancementEnabled: Bool = false
    @State private var showPaywall = false
    @State private var showEnhancementCard = false
    @State private var isShowingEnhancementLabel = false
    @State private var enhancementButtonWidth: CGFloat = 50

    var body: some View {
        VStack(spacing: 10) {
            // Title
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

                if newValue == ColorVisionType.typical {
                    camera.applyColorVisionFilter = false
                    isEnhancementEnabled = false
                } else {
                    camera.applyColorVisionFilter = true
                }

                updateCameraEnhancement()
            }

            // Description text
            Text(selectedDeficiency.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if selectedDeficiency != .typical {
                enhancementControls
            }

            Spacer() // Push content to top, controls to bottom

            // Bottom controls section
            Text("Works best in good lighting, consider enabling flash.\nColors are being adjusted to help distinguish shades that might appear similar with \(selectedDeficiency.rawValue)")
                .font(.caption2)
                .foregroundStyle(.green)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 20)
                .opacity(selectedDeficiency != .typical && isEnhancementEnabled ? 1 : 0)
        }
        .padding(.top, 20)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .onDisappear {
            camera.applyColorVisionFilter = false
            camera.isEnhancementEnabled = false
            selectedDeficiency = .typical
            isEnhancementEnabled = false
        }
        .onChange(of: selectedDeficiency) { oldValue, newValue in
            if newValue != .typical &&
                oldValue == .typical &&
                !hasSeenEnhancementFeature &&
                !showEnhancementCard {

                // Slight delay feels more natural
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showEnhancementCard = true
                    }
                }
            }
        }
        .overlay(enhancementTipCard)
    }

    private var enhancementTipCard: some View {
        Group {
            if showEnhancementCard {
                // A floating card that appears over your content
                VStack(alignment: .leading, spacing: 12) {
                    // Header with icon
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.yellow)
                            .font(.system(size: 18))

                        Text("Enhancement Available")
                            .font(.headline)

                        Spacer()

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showEnhancementCard = false
                                hasSeenEnhancementFeature = true
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                    }

                    // Description
                    Text("Make colors easier to distinguish with \(selectedDeficiency.rawValue) vision.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Action button
                    Button {
                        withAnimation {
                            showEnhancementCard = false
                            hasSeenEnhancementFeature = true

                            if entitlementManager.hasPro {
                                isEnhancementEnabled = true
                                updateCameraEnhancement()
                            } else {
                                showPaywall = true
                            }
                        }
                    } label: {
                        Text("Try Enhancement")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Position it above your controls
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var enhancementControls: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    if entitlementManager.hasPro {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) {
                            isEnhancementEnabled.toggle()
                            showEnhancementLabel()
                            updateCameraEnhancement()

                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred(intensity: 0.7)
                        }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isEnhancementEnabled ?
                                  Color.yellow.opacity(0.2) :
                                  Color(UIColor.systemFill))
                            .frame(width: enhancementButtonWidth, height: 50)

                        HStack(spacing: 8) {
                            // The wand icon
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(isEnhancementEnabled ? .yellow : .white)

                            // This text only appears when isShowingEnhancementLabel is true
                            if isShowingEnhancementLabel {
                                Text(isEnhancementEnabled ? "Enhanced" : "Normal")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(isEnhancementEnabled ? .yellow : .white)
                                    .minimumScaleFactor(0.4)
                                    .transition(.opacity)
                            }
                        }

                        // Pro badge
                        if !entitlementManager.hasPro {
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.yellow)
                                )
                                .foregroundColor(.black)
                                .offset(x: isShowingEnhancementLabel ? 70 : 15, y: 15)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isEnhancementEnabled ?
                                    Color.yellow :
                                    Color.white.opacity(0.2),
                                    lineWidth: 1)
                    )
                    .shadow(
                        color: isEnhancementEnabled ?
                               Color.yellow.opacity(0.3) :
                               Color.black.opacity(0.1),
                        radius: 3,
                        x: 0,
                        y: 2
                    )
                }
                .buttonStyle(.plain)
                .padding(16)
            }
        }
    }

    private func showEnhancementLabel() {
        // First expand the button
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            enhancementButtonWidth = 150
            isShowingEnhancementLabel = true
        }

        // Then shrink it back after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                enhancementButtonWidth = 50
                isShowingEnhancementLabel = false
            }
        }
    }

    private func updateCameraEnhancement() {
        // We only want enhancement enabled when:
        // 1. The toggle is on
        // 2. A color vision type other than typical is selected
        // 3. The user has Pro
        let shouldEnhance = isEnhancementEnabled &&
        selectedDeficiency != .typical &&
        entitlementManager.hasPro

        camera.isEnhancementEnabled = shouldEnhance
    }
}
