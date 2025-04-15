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

    /// The exact name of the dominant color
    @Published private(set) var exactName: String?

    /// The simplified color family name
    @Published private(set) var simpleName: String?

    /// The size of the region used for color sampling
    @Published var region: CGFloat = 20

    /// Determines if color processing is paused
    @Published var pauseProcessing: Bool = false

    /// The capture output type for this service.
    let output = AVCaptureVideoDataOutput()

    /// Private buffer processing queue
    private var bufferQueue = DispatchQueue(label: "colorCaptureBufferQueue")

    /// Minimum time between processing frames to avoid excessive CPU usage
    private var lastProcessingTime: TimeInterval = 0
    private var processingInterval: TimeInterval = 0.4 // 4 frames per second

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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ColorCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !pauseProcessing else {
            return
        }

        // Throttle processing to avoid excessive CPU usage
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastProcessingTime < processingInterval {
            return
        }

        lastProcessingTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Process color on a background queue
        Task.detached {
            await self.updateDominantColor(for: ciImage)
        }

        captureActivity = .colorCapture
    }

    /// Updates the dominant color based on the provided CIImage.
    @MainActor
    private func updateDominantColor(for ciImage: CIImage) {
        guard let ciColor = ciImage.averageColor(region: self.region) else { return }
        let color = UIColor(ciColor: ciColor)

        self.dominantColor = ciColor.toColor()
        self.exactName = color.exactName
        self.simpleName = color.simpleName
    }
}
