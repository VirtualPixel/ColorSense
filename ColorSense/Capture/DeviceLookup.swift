//
//  DeviceLookup.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import AVFoundation
import Combine

final class DeviceLookup {
    private let backCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let frontCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let externalCameraDiscoverySession: AVCaptureDevice.DiscoverySession

    init() {
        backCameraDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
                                                                       mediaType: .video,
                                                                       position: .back)
        frontCameraDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
                                                                       mediaType: .video,
                                                                       position: .front)
        externalCameraDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external],
                                                                       mediaType: .video,
                                                                       position: .unspecified)

        if AVCaptureDevice.systemPreferredCamera == nil {
            AVCaptureDevice.userPreferredCamera = backCameraDiscoverySession.devices.first
        }
    }

    var defaultCamera: AVCaptureDevice {
        get throws {
            guard let videoDevice = AVCaptureDevice.systemPreferredCamera else {
                throw CameraError.videoDeviceUnavailable
            }
            return videoDevice
        }
    }

    var defaultMic: AVCaptureDevice {
        get throws {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                throw CameraError.audioDeviceUnavailable
            }
            return audioDevice
        }
    }

    var cameras: [AVCaptureDevice] {
        var cameras: [AVCaptureDevice] = []
        if let backCamera = backCameraDiscoverySession.devices.first {
            cameras.append(backCamera)
        }
        if let frontCamera = frontCameraDiscoverySession.devices.first {
            cameras.append(frontCamera)
        }
        if let externalCamera = externalCameraDiscoverySession.devices.first {
            cameras.append(externalCamera)
        }

#if !targetEnvironment(simulator)
        if cameras.isEmpty {
            fatalError("No cameras found on this device.")
        }
#endif

        return cameras
    }
}
