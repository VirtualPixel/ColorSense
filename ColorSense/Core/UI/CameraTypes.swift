//
//  DataTypes.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import AVFoundation

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

