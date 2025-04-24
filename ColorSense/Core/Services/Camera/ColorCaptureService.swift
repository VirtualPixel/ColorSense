//
//  ColorCaptureService.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import AVFoundation
import SwiftUI
import Combine

final class ColorCaptureService: NSObject, OutputService {

    /// A value that indicates the current state of color capture.
    @Published private(set) var captureActivity: CaptureActivity = .idle
    /// The dominant color detected at the center region
    @Published private(set) var dominantColor: Color?
    /// The size of the region used for color sampling
    @Published var region: CGFloat = 20
    /// Determines if color processing is paused
    @Published var pauseProcessing: Bool = false

    private var cachedColor: UIColor?
    private var cachedColorTimestamp: TimeInterval = 0

    /// The capture output type for this service.
    let output = AVCaptureVideoDataOutput()
    private var bufferQueue = DispatchQueue(label: "colorCaptureBufferQueue")
    private var lastProcessingTime: TimeInterval = 0
    private var processingInterval: TimeInterval = 0.4 // 4 frames per second
    private let cacheInterval: TimeInterval = 0.1


    override init() {
        super.init()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: bufferQueue)
    }

    // MARK: - OutputService Protocol Requirements

    /// Returns the capabilities for this capture service.
    var capabilities: CaptureCapabilities {
        return CaptureCapabilities()
    }

    /// Reconfigures the color capture output for the specified device.
    func updateConfiguration(for device: AVCaptureDevice) {
        // No special configuration needed for color capture
    }

    // MARK: - Color Region Control

    /// Sets the size of the region used for color sampling.
    func setRegion(_ size: CGFloat) {
        self.region = size
    }

    /// Toggles the color processing state.
    func toggleProcessing() {
        self.pauseProcessing.toggle()
    }

    func getCurrentColor() -> Color? {
        // Return the cached color if we have a recent one (within 1 second)
        let currentTime = Date().timeIntervalSince1970
        if let cached = cachedColor, currentTime - cachedColorTimestamp < 1.0 {
            return cached.color
        }

        return dominantColor
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ColorCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date().timeIntervalSince1970

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        if currentTime - cachedColorTimestamp > cacheInterval {
            if let uiColor = ciImage.averageColor(region: self.region) {
                self.cachedColor = uiColor
                self.cachedColorTimestamp = currentTime
            }
        }

        guard !pauseProcessing,
              currentTime - lastProcessingTime > processingInterval else { return }

        lastProcessingTime = currentTime

        // Process color on a main thread
        Task { @MainActor in
            if let cachedColor = self.cachedColor {
                self.dominantColor = cachedColor.color
                self.captureActivity = .colorCapture
            }
        }
    }
}
