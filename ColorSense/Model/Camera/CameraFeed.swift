//
//  CameraFeed.swift
//  ColorSense
//
//  Created by Justin Wells on 5/7/23.
//

import SwiftUI
import AVFoundation

class CameraFeed: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var dominantColor: Color?
    @Published var exactName: String?
    @Published var simpleName: String?
    @Published var croppedUIImage: UIImage?
    @Published var region: CGFloat = 20
    @Published var pauseProcessing = false
    @Published var cameraPosition: CameraPosition = .back
    @Published var cameraType: CameraType = .wide
    @Published var availableCameraTypes: [CameraType] = []
    @Published var isFlashOn = false {
        didSet {
            toggleFlash()
        }
    }
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var bufferQueue = DispatchQueue(label: "cameraBufferQueue")
    private var lastProcessingTime: TimeInterval = 0
    
    override init() {
        super.init()
        setupCaptureSession(cameraType: self.cameraType, cameraPosition: self.cameraPosition)
    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !pauseProcessing else {
            return
        }
        
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastProcessingTime < 0.35 {
            return
        }
        
        lastProcessingTime = currentTime
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateDominantColor(for: ciImage)
            self.updateCroppedUIImage(for: ciImage)
        }
    }
    
    func swapCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            
            self.setupCaptureSession(cameraType: self.cameraType, cameraPosition: self.cameraPosition)
            self.captureSession.startRunning()
        }
    }
    
    func setCamera(type: CameraType) {
        cameraType = type

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()

            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }

            self.setupCaptureSession(cameraType: self.cameraType, cameraPosition: self.cameraPosition)
            self.captureSession.startRunning()
        }
    }
    
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    private func setupCaptureSession(cameraType: CameraType? = nil, cameraPosition: CameraPosition) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified)
        
        let devices = deviceDiscoverySession.devices

        var captureDevice: AVCaptureDevice?
        
        for device in devices {
            DispatchQueue.main.async {
                if device.deviceType == .builtInUltraWideCamera {
                    self.availableCameraTypes.append(.ultrawide)
                } else if device.deviceType == .builtInWideAngleCamera {
                    self.availableCameraTypes.append(.wide)
                } else if device.deviceType == .builtInTelephotoCamera {
                    self.availableCameraTypes.append(.telephoto)
                }
            }
            
            if cameraPosition == .front && device.position == .front {
                    captureDevice = device
                    break
                } else if cameraPosition == .back && device.position == .back {
                    switch cameraType {
                    case .ultrawide where device.deviceType == .builtInUltraWideCamera:
                        captureDevice = device
                    case .wide where device.deviceType == .builtInWideAngleCamera:
                        captureDevice = device
                    case .telephoto where device.deviceType == .builtInTelephotoCamera:
                        captureDevice = device
                    default:
                        continue
                    }
                    
                    if captureDevice != nil {
                        break
                    }
                }
        }
        
        guard let camera = captureDevice else {
            print("Failed to get camera device")
            return
        }
                
        do {
            try camera.lockForConfiguration()
            
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            
            camera.unlockForConfiguration()
        } catch {
            print("Failed to configure device: \(error)")
            return
        }
        
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: camera) else {
            print("Failed to create capture device input")
            return
        }
        
        captureSession.beginConfiguration()
        
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
                
        captureSession.commitConfiguration()
    }
    
    private func updateDominantColor(for ciImage: CIImage) {
        guard let ciColor = ciImage.averageColor(region: self.region) else { return }
        let color = UIColor(ciColor: ciColor)
        
        DispatchQueue.main.async {
            self.dominantColor = ciColor.toColor()
            self.exactName = color.exactName
            self.simpleName = color.simpleName
        }
    }
    
    private func updateCroppedUIImage(for ciImage: CIImage) {
        DispatchQueue.main.async {
            self.croppedUIImage = ciImage.croppedUIImage(region: self.region)
        }
    }
    
    // colorblind filters
    private func applyDeuteranopiaFilter(to ciImage: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return ciImage }
        // matrix values
        let rVector = CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0)
        let gVector = CIVector(x: 0.494207, y: 0.0, z: 1.24827, w: 0.0)
        let bVector = CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0)
        let aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(rVector, forKey: "inputRVector")
        filter.setValue(gVector, forKey: "inputGVector")
        filter.setValue(bVector, forKey: "inputBVector")
        filter.setValue(aVector, forKey: "inputAVector")
        return filter.outputImage ?? ciImage
    }

    private func applyProtanopiaFilter(to ciImage: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return ciImage }
        // matrix values
        let rVector = CIVector(x: 0.0, y: 2.02344, z: -2.52581, w: 0.0)
        let gVector = CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
        let bVector = CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0)
        let aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(rVector, forKey: "inputRVector")
        filter.setValue(gVector, forKey: "inputGVector")
        filter.setValue(bVector, forKey: "inputBVector")
        filter.setValue(aVector, forKey: "inputAVector")
        return filter.outputImage ?? ciImage
    }

    private func applyTritanopiaFilter(to ciImage: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return ciImage }
        // matrix values
        let rVector = CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0)
        let gVector = CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0)
        let bVector = CIVector(x: -0.395913, y: 2.2857, z: 0.0, w: 0.0)
        let aVector = CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0)
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(rVector, forKey: "inputRVector")
        filter.setValue(gVector, forKey: "inputGVector")
        filter.setValue(bVector, forKey: "inputBVector")
        filter.setValue(aVector, forKey: "inputAVector")
        return filter.outputImage ?? ciImage
    }
}

enum CameraPosition {
    case front, back
}

enum CameraType {
    case ultrawide, wide, telephoto
}
