//
//  ColorVisionFilterDelegate.swift
//  ColorSense
//
//  Created by Justin Wells on 4/28/25.
//

import Foundation
import AVFoundation
import CoreMedia

class ColorVisionFilterDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private weak var originalDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private let originalDelegateQueue: DispatchQueue

    private var filterType: ColorVisionType = .normal
    private var isFilterEnabled: Bool = false

    init(originalDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue) {
        self.originalDelegate = originalDelegate
        self.originalDelegateQueue = queue
        super.init()

        // Initialize Metal
        ColorVisionUtility.setupMetal()
    }

    func updateFilter(type: ColorVisionType, enabled: Bool) {
        self.filterType = type
        self.isFilterEnabled = enabled
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // If filter is disabled or set to normal, just pass through
        guard isFilterEnabled, filterType != .normal else {
            originalDelegate?.captureOutput?(output, didOutput: sampleBuffer, from: connection)
            return
        }

        // Apply the filter to the pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            originalDelegate?.captureOutput?(output, didOutput: sampleBuffer, from: connection)
            return
        }

        if let filteredBuffer = ColorVisionUtility.applyFilter(to: pixelBuffer, type: filterType) {
            // Create a new sample buffer with the filtered buffer
            if let filteredSampleBuffer = createFilteredSampleBuffer(from: sampleBuffer, withPixelBuffer: filteredBuffer) {
                // Pass the filtered buffer to the original delegate
                originalDelegate?.captureOutput?(output, didOutput: filteredSampleBuffer, from: connection)
                return
            }
        }

        // If we get here, filtering failed - pass the original buffer
        originalDelegate?.captureOutput?(output, didOutput: sampleBuffer, from: connection)
    }

    // Helper method to create a new sample buffer from a filtered pixel buffer
    private func createFilteredSampleBuffer(from original: CMSampleBuffer, withPixelBuffer filteredBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        // Get the format description from the filtered buffer
        var formatDescription: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: filteredBuffer,
            formatDescriptionOut: &formatDescription
        )

        if status != noErr || formatDescription == nil {
            print("Failed to create format description: \(status)")
            return nil
        }

        // Get timing info from the original buffer
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(original)
        let duration = CMSampleBufferGetDuration(original)

        var timingInfo = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: CMTime.invalid
        )

        // Create the new sample buffer
        var newBuffer: CMSampleBuffer?
        let createStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: filteredBuffer,
            formatDescription: formatDescription!,
            sampleTiming: &timingInfo,
            sampleBufferOut: &newBuffer
        )

        if createStatus != noErr {
            print("Failed to create sample buffer: \(createStatus)")
            return nil
        }

        return newBuffer
    }
}
