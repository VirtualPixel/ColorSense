//
//  BottomBarView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject private var camera: CameraModel

    var onCaptureButtonPressed: () -> Void

    var captureButtonIcon: String?
    var captureButtonText: String?

    var toggleProcessingButtonIcon: String {
        camera.isPausingColorProcessing ? "play.fill" : "stop.fill"
    }

    var body: some View {
        HStack {
            Spacer()
            swatchPaletteButton()
            Spacer()
            captureButton()
            Spacer()
            cameraSwapButton()
            Spacer()
        }
        .background(.black)
    }

    private func swatchPaletteButton() -> some View {
        NavigationLink(destination: PaletteListView()) {
            Image(systemName: "swatchpalette.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
        }
    }

    private func captureButton() -> some View {
        Button {
            onCaptureButtonPressed()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: 4)
                    .frame(width: 70, height: 70)
                    .foregroundColor(.white)

                Circle()
                    .frame(width: 55, height: 55)
                    .foregroundColor(.white)
                    .overlay(
                        Group {
                            if let text = captureButtonText {
                                Text(text)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            } else {
                                Image(systemName: captureButtonIcon ?? toggleProcessingButtonIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25)
                                    .foregroundColor(.black)
                            }
                        }
                    )
            }
        }
        .padding(.vertical)
    }

    private func cameraSwapButton() -> some View {
        Button {
            Task {
                await camera.switchVideoDevices()
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .padding(7)
                .background(
                    .thinMaterial
                )
                .clipShape(Circle())
        }
        .frame(width: 40, height: 40)
    }
}

extension BottomBarView {
    init() {
        self.onCaptureButtonPressed = {}
        self.captureButtonIcon = "pause.fill"
        self.captureButtonText = nil
    }
}

#Preview {
    BottomBarView()
        // .environmentObject(PreviewCameraModel())
}
