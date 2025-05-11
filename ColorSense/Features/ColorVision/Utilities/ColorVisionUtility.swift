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

    /// Returns color array simulating how the color appears to each colorblind variant
    static func colorAccessibilityVariants(for color: Color) -> [ColorVision] {
        // Start with normal vision
        var results = [ColorVision(color: color, type: .typical)]

        // Get our 1x1 image
        let img = color.toUIImage(width: 1, height: 1)

        // For each vision type, run it through the Metal pipeline
        for visionType in ColorVisionType.allCases where visionType != .typical {
            if let pixelBuffer = createPixelBuffer(from: img),
               let processedBuffer = applyFilter(to: pixelBuffer, type: visionType),
               let processedColor = extractColor(from: processedBuffer) {

                results.append(ColorVision(color: processedColor, type: visionType))
            }
        }

        return results
    }

    static func createPixelBufferFromUIImage(_ image: UIImage) -> CVPixelBuffer? {
        // For consistency, let's make sure we have the right dimensions
        let width = Int(image.size.width)
        let height = Int(image.size.height)

        // Create pixel buffer attributes dictionary
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        // Create the pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )

        // Check if creation was successful
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("Failed to create pixel buffer: \(status)")
            return nil
        }

        // Lock buffer for drawing
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }

        // Get buffer pointer
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("Failed to get pixel buffer base address")
            return nil
        }

        // Create drawing context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            print("Failed to create context")
            return nil
        }

        // Draw the image
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        return buffer
    }

    static func createUIImageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        // Create a CIImage from the pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Create a CIContext for rendering
        let context = CIContext(options: nil)

        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }

        // Create UIImage from CGImage
        let image = UIImage(cgImage: cgImage)
        return image
    }

    static func testFilterOnImage(image: UIImage, type: ColorVisionType) -> UIImage? {
        print("Testing \(type) filter on image: \(image.size.width) x \(image.size.height)")

        // Create a pixel buffer from the image
        guard let pixelBuffer = createPixelBufferFromUIImage(image) else {
            print("Failed to create pixel buffer from image")
            return nil
        }

        // Apply the filter
        guard let filteredBuffer = applyFilter(to: pixelBuffer, type: type) else {
            print("Failed to apply filter to buffer")
            return nil
        }

        // Convert back to UIImage
        return createUIImageFromPixelBuffer(filteredBuffer)
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
        for visionType in ColorVisionType.allCases where visionType != .typical {
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

    static func applyFilter(to pixelBuffer: CVPixelBuffer, type: ColorVisionType) -> CVPixelBuffer? {
        guard type != .typical else { return pixelBuffer }

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

    static private func createPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?

        // Use BGRA format which is more Metal-friendly
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.size.width),
            Int(image.size.height),
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            print("Failed to create pixel buffer: \(status)")
            return nil
        }

        // Lock before accessing
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

        // Make sure bitmapInfo matches BGRA format
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)

        guard let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }

        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

    static private func extractColor(from buffer: CVPixelBuffer) -> Color? {
        // Lock the buffer for reading
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) } // This ensures unlocking even if we return early

        // Get pointer to pixel data
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("Failed to get base address from pixel buffer")
            return nil
        }

        // Get pixel format
        let format = CVPixelBufferGetPixelFormatType(buffer)

        // Retrieve RGBA values based on the format
        let pixelData = baseAddress.assumingMemoryBound(to: UInt8.self)
        var red: UInt8 = 0
        var green: UInt8 = 0
        var blue: UInt8 = 0
        var alpha: UInt8 = 255

        switch format {
        case kCVPixelFormatType_32BGRA:
            blue = pixelData[0]
            green = pixelData[1]
            red = pixelData[2]
            alpha = pixelData[3]
        case kCVPixelFormatType_32RGBA:
            red = pixelData[0]
            green = pixelData[1]
            blue = pixelData[2]
            alpha = pixelData[3]
        case kCVPixelFormatType_32ARGB:
            alpha = pixelData[0]
            red = pixelData[1]
            green = pixelData[2]
            blue = pixelData[3]
        default:
            print("Unsupported pixel format: \(format)")
            return nil
        }

        // Convert to Color
        let normalizedRed = CGFloat(red) / 255.0
        let normalizedGreen = CGFloat(green) / 255.0
        let normalizedBlue = CGFloat(blue) / 255.0
        let normalizedAlpha = CGFloat(alpha) / 255.0

        let uiColor = UIColor(red: normalizedRed,
                            green: normalizedGreen,
                            blue: normalizedBlue,
                            alpha: normalizedAlpha)

        return Color(uiColor)
    }
}
