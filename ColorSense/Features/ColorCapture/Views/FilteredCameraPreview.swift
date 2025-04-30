//
//  FilteredCameraPreview.swift
//  ColorSense
//
//  Created by Justin Wells on 4/29/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct FilteredCameraPreview: UIViewRepresentable {
    let source: PreviewSource
    let filterType: ColorVisionType
    let isFilterEnabled: Bool

    init(source: PreviewSource, filterType: ColorVisionType, isFilterEnabled: Bool) {
        self.source = source
        self.filterType = filterType
        self.isFilterEnabled = isFilterEnabled
    }

    func makeUIView(context: Context) -> FilteredPreviewView {
        let preview = FilteredPreviewView()
        source.connect(to: preview)
        return preview
    }

    func updateUIView(_ uiView: FilteredPreviewView, context: Context) {
        // Update filter settings when they change
        uiView.updateFilterSettings(type: filterType, enabled: isFilterEnabled)
    }

    static func dismantleUIView(_ uiView: FilteredPreviewView, coordinator: ()) {
        uiView.cleanup()
    }
}

class FilteredPreviewView: UIView, PreviewTarget {
    // Standard preview layer for when filter is disabled
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // Image view for displaying filtered frames
    private let filteredImageView = UIImageView()

    // Settings
    private var filterType: ColorVisionType = .normal
    private var isFilterEnabled: Bool = false

    // Session reference
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Set up the standard preview layer
        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.addSublayer(layer)
        previewLayer = layer

        // Set up the filtered image view (initially hidden)
        filteredImageView.contentMode = .scaleAspectFill
        filteredImageView.frame = bounds
        filteredImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        filteredImageView.isHidden = true
        addSubview(filteredImageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        filteredImageView.frame = bounds
    }

    func updateFilterSettings(type: ColorVisionType, enabled: Bool) {
        self.filterType = type
        self.isFilterEnabled = enabled

        // Show/hide appropriate view based on filter state
        previewLayer?.isHidden = enabled
        filteredImageView.isHidden = !enabled

        if let session = session {
            updateVideoOutput(for: session)
        }
    }

    nonisolated func setSession(_ session: AVCaptureSession) {
        Task { @MainActor in
            self.session = session
            previewLayer?.session = session

            if let existingLayer = layer.sublayers?.first as? AVCaptureVideoPreviewLayer,
               let connection = existingLayer.connection {
                previewLayer?.connection?.videoRotationAngle = connection.videoRotationAngle
            }

            updateVideoOutput(for: session)
        }
    }

    func setVideoRotationAngle(_ angle: CGFloat) {
        // Update rotation for both the preview layer and the filtered content
        previewLayer?.connection?.videoRotationAngle = angle

        // Apply rotation to the filtered image view
        Task { @MainActor in
            filteredImageView.transform = CGAffineTransform(rotationAngle: angle * .pi / 180)
        }
    }

    private func updateVideoOutput(for session: AVCaptureSession) {
        // Remove existing output if any
        if let existingOutput = videoOutput {
            session.removeOutput(existingOutput)
        }

        // Create new output if filtering is enabled
        if isFilterEnabled {
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.wells.justin.ColorSense.filterPreviewQueue"))
            output.alwaysDiscardsLateVideoFrames = true

            if session.canAddOutput(output) {
                session.addOutput(output)

                if let connection = output.connection(with: .video) {
                    // Get the rotation angle from the preview layer
                    if let previewLayerConnection = previewLayer?.connection {
                        connection.videoRotationAngle = previewLayerConnection.videoRotationAngle
                    }

                    // Enable video stabilization if supported
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }

                videoOutput = output
            } else {
                print("FilteredPreviewView: Could not add video output to session")
            }
        } else {
            videoOutput = nil
        }
    }

    func cleanup() {
        // Clean up resources
        if let session = session, let output = videoOutput {
            session.removeOutput(output)
        }
        videoOutput = nil
        session = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension FilteredPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isFilterEnabled, filterType != .normal,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Apply the filter
        if let filteredBuffer = ColorVisionUtility.applyFilter(to: pixelBuffer, type: filterType) {
            // Convert to UIImage
            let ciImage = CIImage(cvPixelBuffer: filteredBuffer)
            let context = CIContext()

            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let image = UIImage(cgImage: cgImage)

                // Update UI on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.filteredImageView.image = image
                }
            }
        }
    }
}
