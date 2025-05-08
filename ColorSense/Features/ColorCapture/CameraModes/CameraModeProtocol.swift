//
//  CameraModeProtocol.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUICore

protocol CameraModeProtocol {
    /// Display name of the camera mode
    var name: String { get }
    /// Name of the icon to represent camera mode
    var iconName: String { get }

    /// Main view for the given camera mode
    func getContentView() -> AnyView
    /// What happens when the capture button is pressed
    func onCaptureButtonPressed(camera: CameraModel) async

    /// What text to displayu on the capture button (optional)
    var captureButtonText: String? { get }
    /// What icon to dislpay on the capture button (optional)
    var captureButtonIcon: String? { get }
}

extension CameraModeProtocol {
    /// Boolean to hide or show the retical
    var showRetical: Bool { true }
    var captureButtonText: String? { nil }
    var captureButtonIcon: String? { "" }
}
