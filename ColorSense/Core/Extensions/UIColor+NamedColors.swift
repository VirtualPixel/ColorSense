//
//  Color Lists.swift
//  ColorSense
//
//  Created by Justin Wells on 5/7/23.
//

import SwiftUI

extension UIColor {
    static let colorNames: [String: UIColor] = {
        if let url = Bundle.main.url(forResource: "colornames", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let colorData = try decoder.decode([ColorData].self, from: data)
                var colorNames: [String: UIColor] = [:]
                
                for color in colorData {
                    guard let colorValues = color.hex.hexValues else { continue }
                    colorNames[color.name] = UIColor(red: colorValues.red, green: colorValues.green, blue: colorValues.blue, alpha: 1.0)
                }
                
                return colorNames
            } catch {
                print("Error loading color names JSON: \(error)")
                return [:]
            }
        }
        
        return [:]
    }()
    
    static let roundedColorNames: [String: UIColor] = [
        NSLocalizedString("Black", comment: "Color name for black"): .black,
        NSLocalizedString("Blue", comment: "Color name for blue"): .blue,
        NSLocalizedString("Light Blue", comment: "Color name for light blue"): .lightBlue,
        NSLocalizedString("Dark Blue", comment: "Color name for dark blue"): .darkBlue,
        NSLocalizedString("Brown", comment: "Color name for brown"): .brown,
        NSLocalizedString("Light Brown", comment: "Color name for light brown"): .lightBrown,
        NSLocalizedString("Dark Brown", comment: "Color name for dark brown"): .darkBrown,
        NSLocalizedString("Cyan", comment: "Color name for cyan"): .cyan,
        NSLocalizedString("Light Cyan", comment: "Color name for light cyan"): .lightCyan,
        NSLocalizedString("Dark Cyan", comment: "Color name for dark cyan"): .darkCyan,
        NSLocalizedString("Gray", comment: "Color name for gray"): .gray,
        NSLocalizedString("Light Gray", comment: "Color name for light gray"): .lightGray,
        NSLocalizedString("Dark Gray", comment: "Color name for dark gray"): .darkGray,
        NSLocalizedString("Green", comment: "Color name for green"): .green,
        NSLocalizedString("Light Green", comment: "Color name for light green"): .lightGreen,
        NSLocalizedString("Dark Green", comment: "Color name for dark green"): .darkGreen,
        NSLocalizedString("Magenta", comment: "Color name for magenta"): .magenta,
        NSLocalizedString("Light Magenta", comment: "Color name for light magenta"): .lightMagenta,
        NSLocalizedString("Dark Magenta", comment: "Color name for dark magenta"): .darkMagenta,
        NSLocalizedString("Orange", comment: "Color name for orange"): .orange,
        NSLocalizedString("Light Orange", comment: "Color name for light orange"): .lightOrange,
        NSLocalizedString("Dark Orange", comment: "Color name for dark orange"): .darkOrange,
        NSLocalizedString("Purple", comment: "Color name for purple"): .purple,
        NSLocalizedString("Light Purple", comment: "Color name for light purple"): .lightPurple,
        NSLocalizedString("Dark Purple", comment: "Color name for dark purple"): .darkPurple,
        NSLocalizedString("Red", comment: "Color name for red"): .red,
        NSLocalizedString("Dark Red", comment: "Color name for dark red"): .darkRed,
        NSLocalizedString("White", comment: "Color name for white"): .white,
        NSLocalizedString("Yellow", comment: "Color name for yellow"): .yellow,
        NSLocalizedString("Light Yellow", comment: "Color name for light yellow"): .lightYellow,
        NSLocalizedString("Dark Yellow", comment: "Color name for dark yellow"): .darkYellow,
        NSLocalizedString("Pink", comment: "Color name for pink"): .pink,
        NSLocalizedString("Light Pink", comment: "Color name for light pink"): .lightPink,
        NSLocalizedString("Dark Pink", comment: "Color name for dark pink"): .darkPink
    ]
}
