//
//  DataTypes.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import AVFoundation
import SwiftUI

enum CameraStatus {
    case unknown
    case unauthorized
    case failed
    case running
    case interrupted
}

enum CaptureActivity {
    case idle
    case photoCapture(willCapture: Bool = false, isLivePhoto: Bool = false)
    case movieCapture(duration: TimeInterval = 0.0)
    case colorCapture

    var isLivePhoto: Bool {
        if case .photoCapture(_, let isLivePhoto) = self {
            return isLivePhoto
        }
        return false
    }

    var willCapture: Bool {
        if case .photoCapture(let willCapture, _) = self {
            return willCapture
        }
        return false
    }

    var currentTime: TimeInterval {
        if case .movieCapture(let duration) = self {
            return duration
        }
        return .zero
    }

    var isRecording: Bool {
        if case .movieCapture(_) = self {
            return true
        }
        return false
    }

    var isColorCapture: Bool {
        if case .colorCapture = self {
            return true
        }
        return false
    }
}

enum CaptureMode: String, Identifiable, CaseIterable, Codable {
    var id: Self { self }
    case photo
    case video

    var systemName: String {
        switch self {
        case .photo:
            "camera.fill"
        case .video:
            "video.fill"
        }
    }
}

// Represents a captured photo
struct Photo: Sendable {
    let data: Data
    let isProxy: Bool
    let livePhotoMovieURL: URL?

    func withColorVisionFilter(type: ColorVisionType, enabled: Bool) -> Photo {
        // Skip processing if filter is disabled or normal
        guard enabled, type != .normal else {
            return self
        }

        // Convert Data to UIImage
        guard let image = UIImage(data: data) else {
            print("Failed to create image from photo data")
            return self
        }

        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return self
        }

        // Create a pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary

        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        if CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer) != kCVReturnSuccess {
            print("Failed to create pixel buffer")
            return self
        }

        guard let buffer = pixelBuffer else {
            return self
        }

        // Render CIImage to pixel buffer
        let ciContext = CIContext()
        ciContext.render(ciImage, to: buffer)

        // Apply the filter using your existing utility
        guard let filteredBuffer = ColorVisionUtility.applyFilter(to: buffer, type: type) else {
            print("Failed to apply filter to buffer")
            return self
        }

        // Convert filtered buffer back to image
        let filteredCIImage = CIImage(cvPixelBuffer: filteredBuffer)
        guard let cgImage = ciContext.createCGImage(filteredCIImage, from: filteredCIImage.extent) else {
            print("Failed to create CGImage from filtered CIImage")
            return self
        }

        let filteredImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Convert UIImage back to Data
        guard let filteredData = filteredImage.jpegData(compressionQuality: 0.9) else {
            print("Failed to create JPEG data from filtered image")
            return self
        }

        // Return new Photo with filtered data
        return Photo(data: filteredData, isProxy: isProxy, livePhotoMovieURL: livePhotoMovieURL)
    }

    func withSimplifiedColorVisionFilter(type: ColorVisionType, enabled: Bool) -> Photo {
        // Skip processing if filter is disabled or normal
        guard enabled, type != .normal else {
            print("Skipping filter (disabled or normal vision)")
            return self
        }

        print("Applying \(type) filter to photo")

        // Convert Data to UIImage
        guard let image = UIImage(data: data) else {
            print("Failed to create image from photo data")
            return self
        }

        // Test with our direct method
        print("Testing with direct method")
        if let filteredImage = ColorVisionUtility.testFilterOnImage(image: image, type: type),
           let filteredData = filteredImage.jpegData(compressionQuality: 0.9) {
            print("Direct filter test successful")
            return Photo(data: filteredData, isProxy: isProxy, livePhotoMovieURL: livePhotoMovieURL)
        }

        // If direct method fails, try a fallback approach with Core Image
        print("Direct method failed, trying Core Image fallback")
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage")
            return self
        }

        // Apply a simple color filter as fallback (invert colors to confirm it's working)
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter?.outputImage else {
            print("Failed to apply fallback filter")
            return self
        }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("Failed to create CGImage from filtered output")
            return self
        }

        let filteredImage = UIImage(cgImage: cgImage)
        guard let filteredData = filteredImage.jpegData(compressionQuality: 0.9) else {
            print("Failed to create JPEG data")
            return self
        }

        print("Fallback filter successful")
        return Photo(data: filteredData, isProxy: isProxy, livePhotoMovieURL: livePhotoMovieURL)
    }

    func withDebugSaveFilter(type: ColorVisionType, enabled: Bool) -> Photo {
        // Skip processing if filter is disabled or normal
        guard enabled, type != .normal else {
            print("Skipping filter (disabled or normal vision)")
            return self
        }

        print("Applying \(type) filter to photo")

        // Convert Data to UIImage
        guard let image = UIImage(data: data) else {
            print("Failed to create image from photo data")
            return self
        }

        // Apply filter directly
        guard let filteredImage = ColorVisionUtility.testFilterOnImage(image: image, type: type) else {
            print("Filter application failed")
            return self
        }

        // Save to temporary file to verify filtering worked
        let tempDir = FileManager.default.temporaryDirectory
        let filteredURL = tempDir.appendingPathComponent("filtered_\(UUID().uuidString).jpg")

        // Try saving with a specific compression quality
        if let filteredData = filteredImage.jpegData(compressionQuality: 0.95) {
            do {
                try filteredData.write(to: filteredURL)
                print("DEBUG: Filtered image saved to: \(filteredURL.path)")

                // Return a new Photo object with the filtered data
                return Photo(data: filteredData, isProxy: isProxy, livePhotoMovieURL: livePhotoMovieURL)
            } catch {
                print("ERROR: Failed to save filtered image: \(error)")
            }
        }

        print("WARNING: Using original photo as fallback")
        return self
    }
}

struct Movie: Sendable {
    // Temporary location of the file on disk
    let url: URL
}

struct PhotoFeatures {
    let isLivePhotoEnabled: Bool
    let qualityPrioritization: QualityPrioritization
}

// Structure that represents camera capabilities in it's current configuration.
struct CaptureCapabilities {
    let isLivePhotoCaptureSupported: Bool
    let isHDRSupported: Bool
    let isTorchSupported: Bool

    init(isLiveCaptureSupported: Bool = false,
         isHDRSupported: Bool = false,
         isTorchSupported: Bool = false) {
        self.isLivePhotoCaptureSupported = isLiveCaptureSupported
        self.isHDRSupported = isHDRSupported
        self.isTorchSupported = isTorchSupported
    }

    static let unknown = CaptureCapabilities()
}

enum QualityPrioritization: Int, Identifiable, CaseIterable, CustomStringConvertible, Codable {
    var id: Self { self }
    case speed = 1
    case balanced
    case quality
    var description: String {
        switch self {
        case .speed:
            "Speed"
        case .balanced:
            "Balanced"
        case .quality:
            "Quality"
        }
    }
}

enum CameraError: Error {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
}

protocol OutputService {
    associatedtype Output: AVCaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var capabilities: CaptureCapabilities { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        // Set the rotation angle on the output object's video connection.
        output.connection(with: .video)?.videoRotationAngle = angle
    }
    func updateConfiguration(for device: AVCaptureDevice) {}
}

