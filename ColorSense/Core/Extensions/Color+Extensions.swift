//
//  Color.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorVision: Identifiable {
    let id = UUID()
    let color: Color
    let type: String
    
    static let types = [
        NSLocalizedString("Normal Vision", comment: "Natural color vision"),
        NSLocalizedString("Deuteranopia", comment: "Red-green color blindness, absense of green sensitive cones"),  // ~6% of males
        NSLocalizedString("Protanopia", comment: "Red-green color blindness, absense of red sensitive cones"),    // ~1% of males
        NSLocalizedString("Tritanopia", comment: "Blue-yellow color blindness")     // Rare
    ]
}

extension Color: @retroactive Identifiable {
    public var id: UUID { UUID() }
    
    // MARK: - Constants
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
        [1, 0, 0],
        [0.494207, 0, 0.505793],
        [0, 0, 1]
    ]
    
    // Missing L-cone (Protanopia)
    private static let protanopiaMatrix: [[Double]] = [
        [0, 1.05118294, -0.05116099],
        [0, 1, 0],
        [0, 0, 1]
    ]
    
    // Missing S-cone (Tritanopia)
    private static let tritanopiaMatrix: [[Double]] = [
        [1, 0, -0.15],
        [0.05, 1, 1.05],
        [-0.86744736, 1.86727089, 0]
    ]

    var uiColor: UIColor {
        UIColor(self)
    }

    // MARK: - Public Methods
    func colorVisionSimulations() -> [ColorVision] {
        let components = toRGBComponents()
        let rgb = [
            removeGamma(components.red),
            removeGamma(components.green),
            removeGamma(components.blue)
        ]
        
        return [
            ColorVision(color: self, type: ColorVision.types[0]),
            ColorVision(color: simulateDeficiency(rgb: rgb, matrix: Color.deuteranopiaMatrix),
                       type: ColorVision.types[1]),
            ColorVision(color: simulateDeficiency(rgb: rgb, matrix: Color.protanopiaMatrix),
                       type: ColorVision.types[2]),
            ColorVision(color: simulateDeficiency(rgb: rgb, matrix: Color.tritanopiaMatrix),
                       type: ColorVision.types[3])
        ]
    }
    
    func isDark() -> Bool {
        let components = toRGBComponents()
        let luminance = 0.299 * components.red + 0.587 * components.green + 0.114 * components.blue
        return luminance < 0.5
    }
    
    func complimentaryColors() -> [Color] {
        let hsl = toHSL()
        return (0..<6).map { i in
            let adjustedHue = (hsl.hue + i * 60) % 360
            return Color(
                hue: Double(adjustedHue) / 360.0,
                saturation: Double(hsl.saturation) / 100.0,
                brightness: Double(hsl.lightness) / 100.0
            )
        }
    }

    func toImage(width: Int = 256, height: Int = 256) -> Image {
        // Create a 1x1 image with the color
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(self.uiColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        // Create a UIImage of the desired size by drawing the 1x1 image
        let finalSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(finalSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: finalSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        // Return a SwiftUI Image without modifiers
        return Image(uiImage: resizedImage)
    }

    func toPantone() -> [Pantone] {
        let url = Bundle.main.url(forResource: "pantone-colors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let colorArrays = try! decoder.decode(PantoneColorArrays.self, from: data)
        
        var pantoneColors: [String: String] = [:]
        for (index, name) in colorArrays.names.enumerated() {
            pantoneColors[name] = colorArrays.values[index]
        }
        
        let rgb = toRGB()
        var colorDistances: [(name: String, value: String, distance: Double)] = []
        
        for (name, hex) in pantoneColors {
            let color = Color(hex: hex)
            let rgb2 = color.toRGB()
            let distance = sqrt(
                pow(Double(rgb.red - rgb2.red), 2) +
                pow(Double(rgb.green - rgb2.green), 2) +
                pow(Double(rgb.blue - rgb2.blue), 2)
            )
            colorDistances.append((name, hex, distance))
        }
        
        let closestColors = Array(colorDistances.sorted { $0.distance < $1.distance }.prefix(3))
        return closestColors.map {
            Pantone(
                name: $0.name.replacingOccurrences(of: "-", with: " ").capitalized,
                value: $0.value
            )
        }
    }
    
    func toHex() -> String {
        let components = toRGBComponents()
        return String(
            format: "#%02X%02X%02X",
            Int(round(components.red * 255)),
            Int(round(components.green * 255)),
            Int(round(components.blue * 255))
        )
    }
    
    func toRGB() -> (red: Int, green: Int, blue: Int, alpha: Double) {
        let components = toRGBComponents()
        return (
            Int(round(components.red * 255)),
            Int(round(components.green * 255)),
            Int(round(components.blue * 255)),
            components.alpha
        )
    }
    
    func toHSL() -> (hue: Int, saturation: Int, lightness: Int, alpha: Int) {
        let components = toRGBComponents()
        let r = components.red
        let g = components.green
        let b = components.blue
        
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        var hue = 0.0
        var saturation = 0.0
        let lightness = (max + min) / 2
        
        if delta != 0 {
            saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)
            
            switch max {
            case r: hue = (g - b) / delta + (g < b ? 6 : 0)
            case g: hue = (b - r) / delta + 2
            case b: hue = (r - g) / delta + 4
            default: break
            }
            
            hue /= 6
        }
        
        return (
            Int(round(hue * 360)),
            Int(round(saturation * 100)),
            Int(round(lightness * 100)),
            Int(round(components.alpha * 100))
        )
    }
    
    func toCMYK() -> (cyan: Int, magenta: Int, yellow: Int, key: Int, alpha: Int) {
        let components = toRGBComponents()
        let key = 1 - Swift.max(components.red, components.green, components.blue)
        
        let cyan = key == 1 ? 0 : (1 - components.red - key) / (1 - key)
        let magenta = key == 1 ? 0 : (1 - components.green - key) / (1 - key)
        let yellow = key == 1 ? 0 : (1 - components.blue - key) / (1 - key)
        
        return (
            Int(round(cyan * 100)),
            Int(round(magenta * 100)),
            Int(round(yellow * 100)),
            Int(round(key * 100)),
            Int(round(components.alpha * 100))
        )
    }
    
    func toSwiftUI() -> String {
        let components = toRGBComponents()
        return "Color(red: \(String(format: "%.3f", components.red)), green: \(String(format: "%.3f", components.green)), blue: \(String(format: "%.3f", components.blue)))"
    }
    
    func toUIKit() -> String {
        let components = toRGBComponents()
        return "UIColor(red: \(String(format: "%.3f", components.red)), green: \(String(format: "%.3f", components.green)), blue: \(String(format: "%.3f", components.blue)), alpha: \(String(format: "%.3f", components.alpha))"
    }
    
    // MARK: - Private Methods
    private func toRGBComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
    
    private func removeGamma(_ value: Double) -> Double {
        if value <= 0.04045 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }
    
    private func addGamma(_ value: Double) -> Double {
        if value <= 0.0031308 {
            return 12.92 * value
        }
        return 1.055 * pow(value, 1/2.4) - 0.055
    }
    
    private func multiply(matrix: [[Double]], vector: [Double]) -> [Double] {
        matrix.map { row in
            zip(row, vector).map(*).reduce(0, +)
        }
    }
    
    private func simulateDeficiency(rgb: [Double], matrix: [[Double]]) -> Color {
        let lms = multiply(matrix: Color.rgbToLMS, vector: rgb)
        let simLMS = multiply(matrix: matrix, vector: lms)
        let simRGB = multiply(matrix: Color.lmsToRGB, vector: simLMS)
        
        return Color(
            r: addGamma(max(0, min(1, simRGB[0]))),
            g: addGamma(max(0, min(1, simRGB[1]))),
            b: addGamma(max(0, min(1, simRGB[2])))
        )
    }
}
