//
//  ColorVisionUtility.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import SwiftUI

struct ColorVisionUtility {

    static let shared = ColorVisionUtility()

    private init() {
        // Initialize Metal during app startup
        Self.setupMetal()
    }

    // MARK: - Constants
    // LMS transformation matrices for simulating color deficiencies
    private static let rgbToLMS: [[Double]] = [
        [0.31399022, 0.63951294, 0.04649755],
        [0.15537241, 0.75789446, 0.08670142],
        [0.01775239, 0.10944209, 0.87256922]
    ]

    private static let lmsToRGB: [[Double]] = [
        [5.47221206, -4.6419601, 0.16963708],
        [-1.1252419, 2.29317094, -0.1678952],
        [0.02980165, -0.19318073, 1.16364789]
    ]

    // Missing M-cone (Deuteranopia)
    private static let deuteranopiaMatrix: [[Double]] = [
        [1.0, 0.0, 0.0],
        [0.625, 0.375, 0.0],
        [0.0, 0.25, 0.75]
    ]

    // Missing L-cone (Protanopia)
    private static let protanopiaMatrix: [[Double]] = [
        [0.567, 0.433, 0.0],
        [0.558, 0.442, 0.0],
        [0.0, 0.242, 0.758]
    ]

    // Missing S-cone (Tritanopia)
    private static let tritanopiaMatrix: [[Double]] = [
        [0.95, 0.05, 0.0],
        [0.0, 0.433, 0.567],
        [0.0, 0.475, 0.525]
    ]

    // MARK: - Public Methods

    /// Simulates how a color would appear to someone with the specified color vision type
    static func simulateColorVision(_ color: Color, type: ColorVisionType) -> Color {
        // For normal vision, just return the original color
        guard type != .normal else { return color }

        // Get RGB components and prepare for transformation
        let components = color.toRGBComponents()
        let rgb = [
            removeGamma(components.red),
            removeGamma(components.green),
            removeGamma(components.blue)
        ]

        // Select the appropriate matrix for the vision type
        let matrix: [[Double]]
        switch type {
        case .deuteranopia: //, .testing:
            matrix = deuteranopiaMatrix
        case .protanopia:
            matrix = protanopiaMatrix
        case .tritanopia:
            matrix = tritanopiaMatrix
        case .normal:
            return color // This should never be reached due to the guard above
        }

        // Perform the simulation
        return simulateDeficiency(rgb: rgb, matrix: matrix)
    }

    /// Simulates all possible color vision types for a given color
    static func simulateAllColorVisions(for color: Color) -> [ColorVision] {
        return ColorVisionType.allCases.map { visionType in
            let simulatedColor = simulateColorVision(color, type: visionType)
            return ColorVision(color: simulatedColor, type: visionType)
        }
    }

    static func applyFilterWithDebug(to image: UIImage, type: ColorVisionType) -> UIImage? {
        print("Applying \(type) filter to image: \(image.size.width) x \(image.size.height)")

        if let cgImage = image.cgImage {
            if let colorSpace = cgImage.colorSpace {
                print("Image color space: \(colorSpace.name ?? "Unknown" as CFString)")
            } else {
                print("Image has no color space")
            }
        }

        // Convert to pixel buffer at 1x scale to ensure we're not dealing with resolution issues
        guard let pixelBuffer = createPixelBufferFromUIImage(image) else {
            print("Failed to create pixel buffer from image")
            return nil
        }

        print("Created pixel buffer successfully")

        // Make sure Metal is initialized
        setupMetal()

        // Apply the filter
        guard let filteredBuffer = applyFilter(to: pixelBuffer, type: type) else {
            print("Failed to apply filter to buffer")
            return nil
        }

        print("Applied filter to buffer successfully")

        // Convert back to UIImage
        let ciImage = CIImage(cvPixelBuffer: filteredBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from filtered CIImage")
            return nil
        }

        // Create the final image with same dimensions and orientation as original
        let finalImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        print("Created filtered image: \(finalImage.size.width) x \(finalImage.size.height)")

        return finalImage
    }

    static func testFilterOnImage(image: UIImage, type: ColorVisionType) -> UIImage? {
        // Print debug info
        print("Testing filter on image with type: \(type)")

        // Convert UIImage to pixel buffer
        guard let pixelBuffer = createPixelBufferFromUIImage(image) else {
            print("Failed to create pixel buffer from image")
            return nil
        }

        // Apply filter
        guard let filteredBuffer = applyFilter(to: pixelBuffer, type: type) else {
            print("Failed to apply filter to buffer")
            return nil
        }

        // Convert back to UIImage
        return createUIImageFromPixelBuffer(filteredBuffer)
    }

    // Helper to create pixel buffer from UIImage
    static func createPixelBufferFromUIImage(_ image: UIImage) -> CVPixelBuffer? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)

        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )

        if status != kCVReturnSuccess {
            print("Failed to create pixel buffer: \(status)")
            return nil
        }

        guard let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        guard let cgContext = context else {
            print("Failed to create CG context")
            return nil
        }

        UIGraphicsPushContext(cgContext)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        return buffer
    }

    // Helper to create UIImage from pixel buffer
    static func createUIImageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Private Helper Methods

    /// Removes gamma correction from a color component
    private static func removeGamma(_ value: Double) -> Double {
        if value <= 0.04045 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }

    /// Adds gamma correction to a color component
    private static func addGamma(_ value: Double) -> Double {
        if value <= 0.0031308 {
            return 12.92 * value
        }
        return 1.055 * pow(value, 1/2.4) - 0.055
    }

    /// Multiplies a matrix by a vector
    private static func multiply(matrix: [[Double]], vector: [Double]) -> [Double] {
        matrix.map { row in
            zip(row, vector).map(*).reduce(0, +)
        }
    }

    /// Simulates a color deficiency by transforming through LMS color space
    private static func simulateDeficiency(rgb: [Double], matrix: [[Double]]) -> Color {
        // Convert RGB to LMS color space
        let lms = multiply(matrix: rgbToLMS, vector: rgb)

        // Apply the color deficiency simulation
        let simLMS = multiply(matrix: matrix, vector: lms)

        // Convert back to RGB
        let simRGB = multiply(matrix: lmsToRGB, vector: simLMS)

        // Create a new color with the simulated RGB values
        return Color(
            r: addGamma(max(0, min(1, simRGB[0]))),
            g: addGamma(max(0, min(1, simRGB[1]))),
            b: addGamma(max(0, min(1, simRGB[2])))
        )
    }
}

// Helper extension to access RGB components
private extension Color {
    func toRGBComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}

// MARK: Metal implementation
extension ColorVisionUtility {

    private static let metalDevice = MTLCreateSystemDefaultDevice()
    private static var computePipelines: [ColorVisionType: MTLComputePipelineState] = [:]
    private static var commandQueue: MTLCommandQueue?
    private static var textureCache: CVMetalTextureCache?

    static func setupMetal() {
        guard let device = metalDevice else {
            print("Metal device unavailable!")
            return
        }

        // Only set up once
        if commandQueue != nil && !computePipelines.isEmpty {
            print("Metal already initialized, skipping setup")
            return
        }

        // Create command queue
        commandQueue = device.makeCommandQueue()

        // Create texture cache
        var cache: CVMetalTextureCache?
        let cacheResult = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        if cacheResult != kCVReturnSuccess {
            print("Failed to create Metal texture cache: \(cacheResult)")
            return
        }
        textureCache = cache

        // Load and compile shaders
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to load Metal shader library!")
            return
        }

        // Create pipelines for each color vision type
        for visionType in ColorVisionType.allCases where visionType != .normal {
            let functionName = "apply\(visionType.rawValue)Filter"

            guard let function = library.makeFunction(name: functionName) else {
                print("ERROR: Couldn't find Metal function: \(functionName)")
                continue
            }

            do {
                let pipelineState = try device.makeComputePipelineState(function: function)
                computePipelines[visionType] = pipelineState
            } catch {
                print("ERROR: Failed to create pipeline for \(visionType.rawValue): \(error)")
            }
        }
    }

    private static func loadMetalShaders() {
        guard let device = metalDevice else { return }

        guard let library = device.makeDefaultLibrary() else {
            print("Couldn't find the metal shader library - be sure to add the .metal file to the target!")
            return
        }

        for visionType in ColorVisionType.allCases where visionType != .normal {
            let functionName = "apply\(visionType.rawValue)Filter"

            guard let function = library.makeFunction(name: functionName) else {
                print("Couldn't find the Metal function: \(functionName)")
                continue
            }

            do {
                let pipelineState = try device.makeComputePipelineState(function: function)
                computePipelines[visionType] = pipelineState
            } catch {
                print("Failed to create pipeline for \(visionType.rawValue): \(error)")
            }
        }
    }

    static func applyFilter(to pixelBuffer: CVPixelBuffer, type: ColorVisionType) -> CVPixelBuffer? {
        guard type != .normal else { return pixelBuffer }

        if computePipelines.isEmpty {
            setupMetal()
        }

        guard let _ = metalDevice,
              let commandQueue = commandQueue,
              let textureCache = textureCache,
              let pipelineState = computePipelines[type] else {
            print("Metal setup incomplete for \(type.rawValue)")
            return pixelBuffer
        }

        // Get important properties from input buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

        // Create output buffer with matching format
        var outputBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            pixelFormat,
            attributes as CFDictionary,
            &outputBuffer
        )

        guard let outputBuffer = outputBuffer else {
            print("Failed to create output pixel buffer")
            return pixelBuffer
        }
        
        // Create textures from the pixel buffers
        var inputTexture: CVMetalTexture?
        var outputTexture: CVMetalTexture?

        // Determine the Metal pixel format based on the CVPixelBuffer format
        let metalFormat: MTLPixelFormat
        switch pixelFormat {
        case kCVPixelFormatType_32BGRA:
            metalFormat = .bgra8Unorm
        case kCVPixelFormatType_32RGBA:
            metalFormat = .rgba8Unorm
        default:
            metalFormat = .bgra8Unorm  // Default to BGRA
        }

        // Create input texture
        let inputResult = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            metalFormat,
            width,
            height,
            0,
            &inputTexture
        )

        // Create output texture
        let outputResult = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            outputBuffer,
            nil,
            metalFormat,
            width,
            height,
            0,
            &outputTexture
        )

        // Check for errors in texture creation
        if inputResult != kCVReturnSuccess || outputResult != kCVReturnSuccess {
            print("Failed to create Metal textures: \(inputResult), \(outputResult)")
            return pixelBuffer
        }

        guard let inputMTLTexture = CVMetalTextureGetTexture(inputTexture!),
              let outputMTLTexture = CVMetalTextureGetTexture(outputTexture!) else {
            print("Failed to get Metal textures from CV textures")
            return pixelBuffer
        }

        // Create command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Failed to create command buffer or encoder")
            return pixelBuffer
        }

        // Set up and dispatch compute pipeline
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(inputMTLTexture, index: 0)
        encoder.setTexture(outputMTLTexture, index: 1)

        // Calculate threadgroup sizes
        let threadsPerThreadgroup = MTLSize(
            width: min(pipelineState.threadExecutionWidth, 16),
            height: min(pipelineState.maxTotalThreadsPerThreadgroup / pipelineState.threadExecutionWidth, 16),
            depth: 1
        )

        let threadgroupsPerGrid = MTLSize(
            width: (width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
            height: (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
            depth: 1
        )

        // Dispatch the compute work
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()

        // Execute the commands and wait for completion
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let error = commandBuffer.error {
            print("Metal command buffer execution failed: \(error)")
            return pixelBuffer
        }

        return outputBuffer
    }

    static private func comparePixelBuffers(original: CVPixelBuffer, filtered: CVPixelBuffer) -> Bool {
        if original === filtered {
            return false
        }

        let width = CVPixelBufferGetWidth(original)
        let height = CVPixelBufferGetHeight(original)

        CVPixelBufferLockBaseAddress(original, .readOnly)
        CVPixelBufferLockBaseAddress(filtered, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(original, .readOnly)
            CVPixelBufferUnlockBaseAddress(filtered, .readOnly)
        }

        guard let originalBase = CVPixelBufferGetBaseAddress(original),
              let filteredBase = CVPixelBufferGetBaseAddress(filtered) else {
            return false
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(original)
        var isDifferent = false

        let centerX = width / 2
        let centerY = height / 2
        let centerOffset = centerY * bytesPerRow * centerX * 4 // This is for 4 bytes per pixel

        let originalCenter = originalBase.load(fromByteOffset: centerOffset, as: UInt32.self)
        let filteredCenter = filteredBase.load(fromByteOffset: centerOffset, as: UInt32.self)

        if originalCenter != filteredCenter {
            isDifferent = true
        }

        return isDifferent
    }
}
