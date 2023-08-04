//
//  Color.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

// return color variations
extension Color {
    func toPantone() -> [Pantone] {
        let url = Bundle.main.url(forResource: "pantone-colors", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let colorArrays = try! decoder.decode(PantoneColorArrays.self, from: data)
        
        var pantoneColors: [String: String] = [:]
        for (index, name) in colorArrays.names.enumerated() {
            pantoneColors[name] = colorArrays.values[index]
        }
        
        let rgb = self.toRGB()

        // Store all colors and their distances in an array
        var colorDistances: [(name: String, value: String, distance: Double)] = []
        
        for (name, hex) in pantoneColors {
            let color = Color(hex: hex)
            let rgb2 = color.toRGB()
            let distance = sqrt(pow(Double(rgb.red - rgb2.red), 2) +
                                pow(Double(rgb.green - rgb2.green), 2) +
                                pow(Double(rgb.blue - rgb2.blue), 2))

            colorDistances.append((name, hex, distance))
        }
        
        // Sort the array by distance (ascending) and get the first 3 elements
        let closestColors = Array(colorDistances.sorted { $0.distance < $1.distance }.prefix(3))
        
        // Return only the name and value of the closest colors
        return closestColors.map { Pantone(name: $0.name.replacingOccurrences(of: "-", with: " ").capitalized, value: $0.value) }
    }
    
    func toHex() -> String {
        let components = toRGBComponents()
        return String(
            format: "#%02X%02X%02X",
            Int(components.red * 255),
            Int(components.green * 255),
            Int(components.blue * 255)
        )
    }
    
    func toRGB() -> (red: Int, green: Int, blue: Int, alpha: Double) {
        let components = toRGBComponents()
        return (Int(components.red * 255), Int(components.green * 255), Int(components.blue * 255), components.alpha)
    }
    
    func toHSL() -> (hue: Int, saturation: Int, lightness: Int, alpha: Int) {
        let components = toRGBComponents()
        
        let r = components.red
        let g = components.green
        let b = components.blue
        let a = components.alpha
        
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        var hue: Double = 0
        var saturation: Double = 0
        let lightness = (max + min) / 2
        
        if delta != 0 {
            saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)
            
            switch max {
            case r:
                hue = (g - b) / delta + (g < b ? 6 : 0)
            case g:
                hue = (b - r) / delta + 2
            case b:
                hue = (r - g) / delta + 4
            default:
                break
            }
            
            hue /= 6
        }
        
        return (Int(hue * 360), Int(saturation * 100), Int(100 * lightness), Int(a))
    }
    
    func toCMYK() -> (cyan: Int, magenta: Int, yellow: Int, key: Int, alpha: Int) {
        let components = toRGBComponents()
        
        let r = components.red
        let g = components.green
        let b = components.blue
        let a = components.alpha
        
        let key = 1 - Swift.max(r, g, b)
        let cyan = key == 1 ? 0 : (1 - r - key) / (1 - key)
        let magenta = key == 1 ? 0 : (1 - g - key) / (1 - key)
        let yellow = key == 1 ? 0 : (1 - b - key) / (1 - key)
        
        return (Int(100 * cyan), Int(100 * magenta), Int(100 * yellow), Int(100 * key), Int(a))
    }
    
    private func toRGBComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let color = UIColor(self)
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return (Double(r), Double(g), Double(b), Double(a))
    }
}


