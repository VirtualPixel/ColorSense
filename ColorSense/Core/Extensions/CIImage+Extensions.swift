//
//  CIImage.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import UIKit

extension CIImage {
    func averageColor(region: CGFloat) -> CIColor? {
        // Calculate the coordinates of region in the middle
        let centerX = self.extent.width / 2
        let centerY = self.extent.height / 2
        let regionSize: CGFloat = region
        let regionOriginX = centerX - regionSize / 2
        let regionOriginY = centerY - regionSize / 2
        let region = CGRect(x: regionOriginX, y: regionOriginY, width: regionSize, height: regionSize)

        // Crop the CIImage to the middle region
        let croppedImage = self.cropped(to: region)

        let extentVector = CIVector(x: croppedImage.extent.origin.x, y: croppedImage.extent.origin.y, z: croppedImage.extent.size.width, w: croppedImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: croppedImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return CIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
    }
    
    func croppedUIImage(region: CGFloat) -> UIImage? {
        let centerX = self.extent.width / 2
        let centerY = self.extent.height / 2
        let regionSize: CGFloat = region
        let regionOriginX = centerX - regionSize / 2
        let regionOriginY = centerY - regionSize / 2
        let region = CGRect(x: regionOriginX, y: regionOriginY, width: regionSize, height: regionSize)
        let croppedImage = self.cropped(to: region)
        let context = CIContext(options: nil)
        
        if let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
}
