//
//  Camera.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import SwiftUI

@MainActor
protocol Camera: AnyObject {

    /// The dominant color currently detected by the camera
    var dominantColor: Color? { get }

    /// The size of the region used for color sampling
    var colorRegion: CGFloat { get set }

    /// Whether color processing is paused
    var isPausingColorProcessing: Bool { get set }

    /// Which colorblindness filter is currently selected in AccessibilityMode
    var currentColorVisionType: ColorVisionType { get set }

    /// Whether or not the colorblindness filter should be applied to the preview
    var applyColorVisionFilter: Bool { get set }

    /// Provides the current camera status
    var status: CameraStatus { get }

    /// Camera's current activity state. e.x., Photo capture, Movie capture, idle
    var captureActivity: CaptureActivity { get }

    /// Source of video content for a camera preview
    var previewSource: PreviewSource { get }

    /// Start camera capture pipeline
    func start() async

    // Stop camera capture pipeline
    func stopCamera() async

    // Restart Camera
    func restartCamera() async

    /// The capture mode, which can be photo or video.
    var captureMode: CaptureMode { get set }

    /// A Boolean value that indicates whether the camera is currently switching capture modes.
    var isSwitchingModes: Bool { get }

    /// A Boolean value that indicates whether the camera prefers showing a minimized set of UI controls.
    var prefersMinimizedUI: Bool { get }

    /// Switches between video devices available on the host system.
    func switchVideoDevices() async

    /// A Boolean value that indicates whether the camera is currently switching video devices.
    var isSwitchingVideoDevices: Bool { get }

    /// Performs a one-time automatic focus and exposure operation.
    func focusAndExpose(at point: CGPoint) async

    /// A Boolean value that indicates whether to capture Live Photos when capturing stills.
    var isLivePhotoEnabled: Bool { get set }

    /// A value that indicates how to balance the photo capture quality versus speed.
    var qualityPrioritization: QualityPrioritization { get set }

    /// Captures a photo and writes it to the user's photo library.
    func capturePhoto() async

    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    var shouldFlashScreen: Bool { get }

    /// A boolean value that indicates whether or not the flash is enabled
    var isTorchEnabled: Bool { get set }

    /// A Boolean that indicates whether the camera supports HDR video recording.
    var isHDRVideoSupported: Bool { get }

    /// A Boolean value that indicates whether camera enables HDR video recording.
    var isHDRVideoEnabled: Bool { get set }

    /// Starts or stops recording a movie, and writes it to the user's photo library when complete.
    func toggleRecording() async

    /// A thumbnail image for the most recent photo or video capture.
    var thumbnail: CGImage? { get }

    /// An error if the camera encountered a problem.
    var error: Error? { get }

    /// Colorblind simulation enhancement boolean
    var isEnhancementEnabled: Bool { get set }

    /// Synchronize the state of the camera with the persisted values.
    func syncState() async
}
