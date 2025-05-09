//
//  PhotoProcessor.swift
//  ColorSense
//
//  Created by Justin Wells on 5/6/25.
//

import Foundation
import UIKit
import Metal
import MetalKit

class PhotoProcessor {
    private static let device = MTLCreateSystemDefaultDevice()
    private static var computePipelines: [ColorVisionType: MTLComputePipelineState] = [:]
    private static var commandQueue: MTLCommandQueue?
    private static var textureCache: CVMetalTextureCache?
    private static var isInitialized = false

    // Initialize Metal resources once
    static func initialize() {
        // Skip if already initialized
        guard !isInitialized, let device = device else { return }

        // Create command queue
        commandQueue = device.makeCommandQueue()

        // Create texture cache
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        textureCache = cache

        // Load shader library
        guard let library = device.makeDefaultLibrary() else {
            print("PhotoProcessor: Failed to load Metal shader library")
            return
        }

        // Create compute pipelines for each color vision type
        for type in ColorVisionType.allCases where type != .typical {
            let functionName = "apply\(type.rawValue)Filter"

            guard let function = library.makeFunction(name: functionName) else {
                print("PhotoProcessor: Could not find shader function: \(functionName)")
                continue
            }

            do {
                let pipelineState = try device.makeComputePipelineState(function: function)
                computePipelines[type] = pipelineState
            } catch {
                print("PhotoProcessor: Failed to create compute pipeline for \(type.rawValue): \(error)")
            }
        }

        isInitialized = true
    }

    static func applyFilter(to photo: Photo, type: ColorVisionType) -> UIImage? {
        // Skip processing if normal vision
        guard type != .typical else {
            return UIImage(data: photo.data)
        }

        // Initialize if needed
        if !isInitialized {
            initialize()
        }

        // Convert photo data to UIImage
        guard let originalImage = UIImage(data: photo.data) else {
            print("PhotoProcessor: Failed to create image from photo data")
            return nil
        }

        // Get the CGImage
        guard let cgImage = originalImage.cgImage else {
            print("PhotoProcessor: Failed to get CGImage")
            return nil
        }

        // Create input pixel buffer
        guard let pixelBuffer = createPixelBufferFromCGImage(cgImage) else {
            print("PhotoProcessor: Failed to create pixel buffer from image")
            return nil
        }

        // Apply Metal shader
        guard let filteredBuffer = applyMetalShader(to: pixelBuffer, type: type) else {
            print("PhotoProcessor: Failed to apply Metal shader")
            return nil
        }

        // Convert filtered buffer back to UIImage
        guard let filteredImage = createUIImageFromPixelBuffer(filteredBuffer, orientation: originalImage.imageOrientation, scale: originalImage.scale) else {
            print("PhotoProcessor: Failed to create UIImage from filtered buffer")
            return nil
        }

        return filteredImage
    }

    // Helper method to create a pixel buffer from CGImage
    private static func createPixelBufferFromCGImage(_ cgImage: CGImage) -> CVPixelBuffer? {
        let width = cgImage.width
        let height = cgImage.height

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

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("PhotoProcessor: Failed to create pixel buffer: \(status)")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("PhotoProcessor: Failed to get pixel buffer base address")
            return nil
        }

        let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )

        guard let context = context else {
            print("PhotoProcessor: Failed to create CGContext")
            return nil
        }

        // Draw image into the context (buffer)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }

    // Apply Metal shader to pixel buffer
    private static func applyMetalShader(to pixelBuffer: CVPixelBuffer, type: ColorVisionType) -> CVPixelBuffer? {
        guard let _ = device,
              let commandQueue = commandQueue,
              let textureCache = textureCache,
              let pipelineState = computePipelines[type] else {
            print("PhotoProcessor: Metal resources not available")
            return nil
        }

        // Get dimensions
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Create output buffer
        var outputBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey: true
        ] as CFDictionary

        let createStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &outputBuffer
        )

        guard createStatus == kCVReturnSuccess, let outputBuffer = outputBuffer else {
            print("PhotoProcessor: Failed to create output buffer: \(createStatus)")
            return nil
        }

        // Create Metal textures
        var inputTexture: CVMetalTexture?
        var outputTexture: CVMetalTexture?

        let inputStatus = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &inputTexture
        )

        let outputStatus = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            outputBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &outputTexture
        )

        guard inputStatus == kCVReturnSuccess, outputStatus == kCVReturnSuccess else {
            print("PhotoProcessor: Failed to create Metal textures: \(inputStatus), \(outputStatus)")
            return nil
        }

        guard let inputTexture = inputTexture,
              let outputTexture = outputTexture,
              let metalInputTexture = CVMetalTextureGetTexture(inputTexture),
              let metalOutputTexture = CVMetalTextureGetTexture(outputTexture) else {
            print("PhotoProcessor: Failed to get Metal textures from CV textures")
            return nil
        }

        // Create command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            print("PhotoProcessor: Failed to create command buffer or encoder")
            return nil
        }

        // Set up compute pipeline
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(metalInputTexture, index: 0)
        encoder.setTexture(metalOutputTexture, index: 1)

        // Calculate thread group size
        let threadGroupSize = MTLSize(
            width: 16,
            height: 16,
            depth: 1
        )

        let threadGroups = MTLSize(
            width: (width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )

        // Dispatch compute command
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        // Submit command buffer and wait for completion
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let error = commandBuffer.error {
            print("PhotoProcessor: Metal command buffer error: \(error)")
            return nil
        }

        return outputBuffer
    }

    // Convert pixel buffer back to UIImage
    private static func createUIImageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation, scale: CGFloat) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("PhotoProcessor: Failed to create CGImage from CIImage")
            return nil
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
    }
}
