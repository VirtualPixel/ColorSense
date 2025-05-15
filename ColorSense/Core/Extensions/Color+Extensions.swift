import SwiftUI

// Add a test method to validate UIColor hex parsing

extension Color: @retroactive Identifiable {

    public var id: UUID { UUID() }

    var uiColor: UIColor {
        UIColor(self)
    }

    // MARK: - Public Methods

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

    func toUIImage(width: Int = 1, height: Int = 1) -> UIImage {
        // Create a 1x1 image with the color
        let uiColor = UIColor(self)
        let size = CGSize(width: width, height: height)

        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(uiColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
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

    func difference(to othercolor: Color) -> CGFloat {
        UIColor(self).difference(to: UIColor(othercolor))
    }

    func toRGBComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
    
    static func blend(_ color1: Color, with color2: Color, ratio: CGFloat = 0.5) -> Color {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 * ratio + r2 * (1 - ratio)
        let g = g1 * ratio + g2 * (1 - ratio)
        let b = b1 * ratio + b2 * (1 - ratio)
        let a = a1 * ratio + a2 * (1 - ratio)

        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
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
}

// Add this extension since it seems to be referenced but not included
extension UIColor {
    convenience init?(hexString: String) {
        // Validate hex format
        // Valid formats: "#RRGGBB", "RRGGBB"
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        // Check length
        guard hexSanitized.count == 6 else {
            print("Invalid hex length: \(hexSanitized.count)")
            return nil
        }

        // Check valid hex characters
        let regex = try? NSRegularExpression(pattern: "^[0-9A-Fa-f]{6}$", options: [])
        let range = NSRange(location: 0, length: hexSanitized.utf16.count)
        if regex?.firstMatch(in: hexSanitized, options: [], range: range) == nil {
            print("Invalid hex characters in: \(hexSanitized)")
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
