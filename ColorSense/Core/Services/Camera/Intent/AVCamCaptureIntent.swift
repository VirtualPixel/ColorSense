//
//  AVCamCaptureIntent.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import LockedCameraCapture
import AppIntents
import os

struct AVCamCaptureIntent: CameraCaptureIntent {

    /// The context object for the capture intent.
    typealias AppContext = CameraState

    static let title: LocalizedStringResource = "AVCamCaptureIntent"
    static let description: IntentDescription = IntentDescription("Capture photos and videos with AVCam.")

    @MainActor
    func perform() async throws -> some IntentResult {
        os.Logger().debug("AVCam capture intent performed successfully.")
        // The return type of this intent is None; the success status isn't user-visible.
        return .result()
    }
}
