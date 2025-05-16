//
//  MetalCameraPreview.swift
//  ColorSense
//
//  Created by Justin Wells on 5/6/25.
//

import SwiftUI
import MetalKit
import AVFoundation

struct MetalCameraPreview: UIViewRepresentable {
    let source: PreviewSource
    let filterType: ColorVisionType
    let isFilterEnabled: Bool
    let isEnhancementEnabled: Bool

    func makeUIView(context: Context) -> MetalPreviewView {
        let view = MetalPreviewView()
        source.connect(to: view)

        // Add debug verification similar to regular CameraPreview
        if let session = (source as? DefaultPreviewSource)?.session {
            print("Connecting Metal preview to session: \(session)")
        }

        return view
    }

    func updateUIView(_ uiView: MetalPreviewView, context: Context) {
        uiView.updateFilterSettings(
            type: filterType,
            enabled: isFilterEnabled,
            enhance: isEnhancementEnabled
        )
    }

    static func dismantleUIView(_ uiView: MetalPreviewView, coordinator: ()) {
        uiView.cleanup()
    }
}

class MetalPreviewView: UIView, PreviewTarget {
    // Metal properties
    private let device: MTLDevice?
    private var metalLayer: CAMetalLayer?
    private var commandQueue: MTLCommandQueue?
    private var computePipelineState: MTLComputePipelineState?
    private var textureCache: CVMetalTextureCache?

    // Camera properties
    private var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // Filter settings
    private var filterType: ColorVisionType = .typical
    private var isFilterEnabled: Bool = false
    private var isEnhanceEnabled: Bool = false

    // Frame rate control
    private let targetFrameRate: Double = 60.0
    private var lastFrameTime: CFTimeInterval = 0

    var usesMetalRendering: Bool { return true }

    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    override init(frame: CGRect) {
        // Initialize Metal Device only if not in simulator
        #if targetEnvironment(simulator)
        self.device = nil
        #else
        self.device = MTLCreateSystemDefaultDevice()
        #endif

        super.init(frame: frame)

#if targetEnvironment(simulator)
        // The capture APIs require running on a real device
        let imageView = UIImageView(frame: bounds)
        imageView.image = UIImage(named: "video_mode")
        imageView.contentMode = .scaleAspectFit  // Change to .scaleAspectFit
        imageView.backgroundColor = .black       // Add background color
        addSubview(imageView)
        print("⚠️ Running in simulator - Metal preview will show a placeholder image")

        // Make sure the image view resizes properly
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Don't create the previewLayer in simulator
        self.previewLayer = nil
#else
        if device != nil {
            setupView()
        } else {
            print("⚠️ Metal device could not be created - falling back to standard preview")
            // Add a fallback view or warning
            let label = UILabel(frame: bounds)
            label.text = "Metal rendering not available"
            label.textAlignment = .center
            label.textColor = .white
            addSubview(label)
        }
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        guard let device = self.device else {
            print("⚠️ No Metal device available")
            return
        }

        let newPreviewLayer = AVCaptureVideoPreviewLayer()
        newPreviewLayer.videoGravity = .resizeAspectFill
        newPreviewLayer.frame = bounds
        layer.addSublayer(newPreviewLayer)
        self.previewLayer = newPreviewLayer
        print("Added preview layer")


        // Create the actual Metal layer
        metalLayer = CAMetalLayer()
        metalLayer!.device = device
        metalLayer!.pixelFormat = .bgra8Unorm
        metalLayer!.framebufferOnly = false
        metalLayer!.frame = bounds
        layer.addSublayer(metalLayer!)
        print("Added Metal layer")

        // Set up Metal components
        commandQueue = device.makeCommandQueue()
        if commandQueue == nil {
            print("⚠️ Failed to create Metal command queue")
        }

        setupTextureCache()
        setupComputePipeline()
        print("Metal setup complete")
    }

    func setVideoRotationAngle(_ angle: CGFloat) {
        previewLayer?.connection?.videoRotationAngle = angle
    }

    private func setupMetal() {
        guard device != nil else {
            print("⚠️ No Metal device available for processing")
            return
        }

        // Configure Metal Layer
        metalLayer = self.layer as? CAMetalLayer
        metalLayer!.device = device
        metalLayer!.pixelFormat = .bgra8Unorm
        metalLayer!.framebufferOnly = false

        // Create command queue
        commandQueue = device!.makeCommandQueue()

        // Create texture cache
        var textureCache: CVMetalTextureCache?
        let status = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            device!,
            nil,
            &textureCache
        )

        if status != kCVReturnSuccess {
            print("Failed to create texture cache")
        } else {
            self.textureCache = textureCache
        }

        setupComputePipeline()
    }

    private func setupTextureCache() {
        guard let device = self.device else {
            print("⚠️ No Metal device available for texture cache")
            return
        }
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        self.textureCache = textureCache
    }

    private func setupComputePipeline() {
        guard let device = self.device else {
            print("⚠️ No Metal device available for compute pipeline")
            return
        }

        guard let library = device.makeDefaultLibrary() else {
            print("Failed to load default Metal library")
            return
        }

        let functionName: String
        if !isFilterEnabled || filterType == .typical {
            functionName = "passThroughFilter" // Use a simple pass-through filter
        } else if isEnhanceEnabled {
            switch filterType {
            case .deuteranopia:
                functionName = "enhanceDeuteranopia"
            case .protanopia:
                functionName = "enhanceProtanopia"
            case .tritanopia:
                functionName = "enhanceTritanopia"
            default:
                functionName = "passThroughFilter"
            }
        } else {
            switch filterType {
            case .protanopia:
                functionName = "applyProtanopiaFilter"
            case .deuteranopia:
                functionName = "applyDeuteranopiaFilter"
            case .tritanopia:
                functionName = "applyTritanopiaFilter"
            default:
                functionName = "passThroughFilter"
            }
        }

        guard let function = library.makeFunction(name: functionName) else {
            print("Failed to find shader function: \(functionName)")
            print("Available functions: \(library.functionNames)")
            return
        }

        do {
            computePipelineState = try device.makeComputePipelineState(function: function)
        } catch {
            print("Failed ot create compute pipeline: \(error)")
        }
    }

    func updateFilterSettings(type: ColorVisionType, enabled: Bool, enhance: Bool) {
        let needsUpdate = (type != filterType ||
                           enabled != isFilterEnabled ||
                           isEnhanceEnabled != enhance)

        filterType = type
        isFilterEnabled = enabled
        isEnhanceEnabled = enhance

        if needsUpdate {
            setupComputePipeline()
        }
    }

    nonisolated func setSession(_ session: AVCaptureSession) {
        Task { @MainActor in
            self.session = session

            // Safely unwrap the previewLayer
            if let previewLayer = self.previewLayer {
                previewLayer.session = session
                print("Successfully set session on preview layer")
            }

            #if targetEnvironment(simulator)
            // Skip setting up video output in the simulator
            print("Skipping video output setup in simulator")
            #else
            // Clean up existing output
            if let existingOutput = videoOutput {
                session.removeOutput(existingOutput)
            }

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.wells.justin.ColorSense.metalQueue"))

            if session.canAddOutput(output) {
                session.addOutput(output)
                videoOutput = output
                print("Added video output to session")
            } else {
                print("Could not add video output to session")
            }
            #endif
        }
    }

    func cleanup() {
        if let session = session, let output = videoOutput {
            session.removeOutput(output)
        }
        videoOutput = nil
        session = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard metalLayer != nil else {
            // Skip layout for metal layer when it doesn't exist
            return
        }

        // Position and size the Metal layer to account for rotation
        let layerFrame = CGRect(
            x: bounds.midX - bounds.height/2,
            y: bounds.midY - bounds.width/2,
            width: bounds.height,
            height: bounds.width
        )

        metalLayer!.frame = layerFrame

        // Set drawable size to match the layer size
        metalLayer!.drawableSize = CGSize(
            width: layerFrame.width * UIScreen.main.scale,
            height: layerFrame.height * UIScreen.main.scale
        )

        // Apply rotation transform
        let rotation = CATransform3DMakeRotation(CGFloat.pi/2, 0, 0, 1)
        metalLayer!.transform = rotation
    }
}

extension MetalPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer from sample buffer")
            return
        }

        processWithMetal(pixelBuffer: pixelBuffer)
    }

    private func processWithMetal(pixelBuffer: CVPixelBuffer) {
        guard let metalLayer = self.metalLayer,
              let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let computePipelineState = computePipelineState,
              let textureCache = textureCache else {
            return
        }

        // Create textures
        var cvInputTexture: CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvInputTexture
        )

        guard let inputTexture = cvInputTexture,
              let texture = CVMetalTextureGetTexture(inputTexture) else {
            return
        }

        // Create compute encoder
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        encoder.setComputePipelineState(computePipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setTexture(drawable.texture, index: 1)

        // Calculate threads
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()

        // Present and commit
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
