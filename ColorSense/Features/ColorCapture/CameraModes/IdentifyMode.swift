//
//  IdentifyMode.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct IdentifyMode: CameraModeProtocol {
    var name: String { "Identify" }
    var iconName: String { "eyedropper" }

    func getContentView() -> AnyView {
        AnyView(
            ColorCardView()
                .padding(.top, 20)
        )
    }
    
    func onCaptureButtonPressed(camera: CameraModel) async {
        DispatchQueue.main.async {
            camera.isPausingColorProcessing.toggle()
        }
    }

    @MainActor func captureButtonIcon(for camera: CameraModel) -> String {
        camera.isPausingColorProcessing ? "play.fill" : "stop.fill"
    }

    var captureButtonIcon: String? { nil }
}
