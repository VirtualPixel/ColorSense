//
//  Color Lists.swift
//  ColorSense
//
//  Created by Justin Wells on 5/7/23.
//

import UIKit

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
        "Black": .black,
        "Blue": .blue,
        "Light Blue": .lightBlue,
        "Dark Blue": .darkBlue,
        "Brown": .brown,
        "Light Brown": .lightBrown,
        "Dark Brown": .darkBrown,
        "Cyan": .cyan,
        "Light Cyan": .lightCyan,
        "Dark Cyan": .darkCyan,
        "Gray": .gray,
        "Light Gray": .lightGray,
        "Dark Gray": .darkGray,
        "Green": .green,
        "Light Green": .lightGreen,
        "Dark Green": .darkGreen,
        "Magenta": .magenta,
        "Light Magenta": .lightMagenta,
        "Dark Magenta": .darkMagenta,
        "Orange": .orange,
        "Light Orange": .lightOrange,
        "Dark Orange": .darkOrange,
        "Purple": .purple,
        "Light Purple": .lightPurple,
        "Dark Purple": .darkPurple,
        "Red": .red,
        "Dark Red": .darkRed,
        "White": .white,
        "Yellow": .yellow,
        "Light Yellow": .lightYellow,
        "Dark Yellow": .darkYellow,
        "Pink": .pink,
        "Light Pink": .lightPink,
        "Dark Pink": .darkPink
    ]
}
