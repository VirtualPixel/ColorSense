/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Camera implementation to use when working with SwiftUI previews.
*/

import Foundation
import SwiftUI

@Observable
class PreviewCameraModel: Camera, ObservableObject {
    var currentColorVisionType: ColorVisionType = .typical
    var applyColorVisionFilter: Bool = false
    var isEnhancementEnabled: Bool = false

    var isLivePhotoEnabled = true
    var prefersMinimizedUI = false
    var qualityPrioritization = QualityPrioritization.quality
    var shouldFlashScreen = false
    var isHDRVideoSupported = false
    var isHDRVideoEnabled = false
    var isTorchEnabled = false

    struct PreviewSourceStub: PreviewSource {
        // Stubbed out for test purposes.
        func connect(to target: PreviewTarget) {}
    }

    let previewSource: PreviewSource = PreviewSourceStub()

    private(set) var status = CameraStatus.unknown
    private(set) var captureActivity = CaptureActivity.idle
    var captureMode = CaptureMode.photo {
        didSet {
            isSwitchingModes = true
            Task {
                // Create a short delay to mimic the time it takes to reconfigure the session.
                try? await Task.sleep(until: .now + .seconds(0.3), clock: .continuous)
                self.isSwitchingModes = false
            }
        }
    }
    private(set) var isSwitchingModes = false
    private(set) var isVideoDeviceSwitchable = true
    private(set) var isSwitchingVideoDevices = false
    private(set) var thumbnail: CGImage?
    private(set) var dominantColor: Color? = .blue
    private(set) var exactColorName: String? = "Azure Blue"
    private(set) var simpleColorName: String? = "Blue"
    var colorRegion: CGFloat = 20
    var isPausingColorProcessing: Bool = false

    var error: Error?

    init(captureMode: CaptureMode = .photo, status: CameraStatus = .unknown) {
        self.captureMode = captureMode
        self.status = status
    }

    func start() async {
        if status == .unknown {
            status = .running
        }
    }

    func switchVideoDevices() {
        print("Device switching isn't implemented in PreviewCamera.")
    }

    func capturePhoto() {
        print("Photo capture isn't implemented in PreviewCamera.")
    }

    func toggleRecording() {
        print("Moving capture isn't implemented in PreviewCamera.")
    }

    func focusAndExpose(at point: CGPoint) {
        print("Focus and expose isn't implemented in PreviewCamera.")
    }

    var recordingTime: TimeInterval { .zero }

    private func capabilities(for mode: CaptureMode) -> CaptureCapabilities {
        switch mode {
        case .photo:
            return CaptureCapabilities(isLiveCaptureSupported: true,
                                       isTorchSupported: true)
        case .video:
            return CaptureCapabilities(isLiveCaptureSupported: false,
                                       isHDRSupported: true,
                                       isTorchSupported: true)
        }
    }

    func syncState() async {
        print("Syncing state isn't implemented in PreviewCamera.")
    }
}
