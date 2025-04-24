//
//  CIImage.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import UIKit

extension CIImage {

    func averageColor(region: CGFloat) -> UIColor? {
        guard self.extent.width > 0, self.extent.height > 0 else {
            return nil
        }

        // Calculate region - but add safety checks
        let centerX = self.extent.width / 2
        let centerY = self.extent.height / 2
        let regionSize = min(region, min(self.extent.width, self.extent.height))

        // Create a more precise region rect
        let regionRect = CGRect(
            x: centerX - regionSize/2,
            y: centerY - regionSize/2,
            width: regionSize,
            height: regionSize
        )

        guard let cgImage = Self.sharedContext.createCGImage(self, from: regionRect) else {
            return nil
        }

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        // Get the pixel data
        guard let data = context.data else {
            return nil
        }

        // Read the bytes
        let bytes = data.assumingMemoryBound(to: UInt8.self)
        let components: [UInt8] = [bytes[0], bytes[1], bytes[2], bytes[3]]

        // Create the color
        let color = UIColor(
            red: CGFloat(components[0]) / 255.0,
            green: CGFloat(components[1]) / 255.0,
            blue: CGFloat(components[2]) / 255.0,
            alpha: CGFloat(components[3]) / 255.0
        )

        return color
    }
}

// Shared Properties
extension CIImage {

    private static let sharedContext: CIContext = {
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: metalDevice)
        }
        return CIContext()
    }()
}
