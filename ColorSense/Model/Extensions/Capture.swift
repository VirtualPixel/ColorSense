//
//  Capture.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import AVFoundation

extension CMVideoDimensions: @retroactive Equatable, @retroactive Comparable {

    static let zero = CMVideoDimensions()

    public static func == (lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }

    public static func < (lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        lhs.width < rhs.width && lhs.height < rhs.height
    }
}

extension AVCaptureDevice {
    var activeFormat10BitVariant: AVCaptureDevice.Format? {
        formats.filter {
            $0.maxFrameRate == activeFormat.maxFrameRate &&
            $0.formatDescription.dimensions == activeFormat.formatDescription.dimensions
        }
        .first(where: { $0.isTenBitFormat })
    }
}

extension AVCaptureDevice.Format {
    var isTenBitFormat: Bool {
        formatDescription.mediaSubType.rawValue == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
    }
    var maxFrameRate: Double {
        videoSupportedFrameRateRanges.last?.maxFrameRate ?? 0
    }
}
