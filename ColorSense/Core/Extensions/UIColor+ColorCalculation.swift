//
//  UIColor.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

// Color names and difference calculation
extension UIColor {
    var color: Color {
        Color(uiColor: self)
    }

    var exactName: String {
        let colorDiff = UIColor.colorNames.map { (name, color) -> (String, CGFloat) in
            let colorDiff = color.difference(to: self)
            return (name, colorDiff)
        }
        
        if let (colorName, _) = colorDiff.min(by: { $0.1 < $1.1 }) {
            return colorName
        } else {
            return "Unknown"
        }
    }
    
    var simpleName: String {
        let roundedColorDiff = UIColor.roundedColorNames.map { (name, color) -> (String, CGFloat) in
            let colorDiff = color.difference(to: self)
            return (name, colorDiff)
        }
        
        if let (colorName, _) = roundedColorDiff.min(by: { $0.1 < $1.1 }) {
            return colorName
        } else {
            return "Unknown"
        }
    }
    
    func difference(to color: UIColor) -> CGFloat {
        return cieDe2000(to: color)
    }
    
    func cieDe2000(to color: UIColor) -> CGFloat {
        let lab1 = self.toCIELAB()
        let lab2 = color.toCIELAB()
        
        let kL = CGFloat(1)
        let kC = CGFloat(1)
        let kH = CGFloat(1)
        
        let deltaL = lab1.L - lab2.L
        let Lmean = (lab1.L + lab2.L) / 2
        
        let C1 = sqrt(pow(lab1.A, 2) + pow(lab1.B, 2))
        let C2 = sqrt(pow(lab2.A, 2) + pow(lab2.B, 2))
        let Cmean = (C1 + C2) / 2
        
        let a1Prime = lab1.A + (lab1.A / 2) * (1 - sqrt(pow(Cmean, 7) / (pow(Cmean, 7) + pow(CGFloat(25), 7))))
        let a2Prime = lab2.A + (lab2.A / 2) * (1 - sqrt(pow(Cmean, 7) / (pow(Cmean, 7) + pow(CGFloat(25), 7))))
        
        let C1Prime = sqrt(pow(a1Prime, 2) + pow(lab1.B, 2))
        let C2Prime = sqrt(pow(a2Prime, 2) + pow(lab2.B, 2))
        let deltaC = C1Prime - C2Prime
        
        let h1Prime = (atan2(lab1.B, a1Prime) * 180 / .pi).truncatingRemainder(dividingBy: 360)
        let h2Prime = (atan2(lab2.B, a2Prime) * 180 / .pi).truncatingRemainder(dividingBy: 360)
        let deltahPrime: CGFloat
        if abs(h1Prime - h2Prime) <= 180 {
            deltahPrime = h2Prime - h1Prime
        } else {
            deltahPrime = (h2Prime <= h1Prime) ? h2Prime - h1Prime + 360 : h2Prime - h1Prime - 360
        }
        
        let deltaH = 2 * sqrt(C1Prime * C2Prime) * sin(deltahPrime * .pi / 180 / 2)
        
        let T = 1 - 0.17 * cos(.pi / 180 * (h1Prime - 30)) + 0.24 * cos(2 * .pi / 180 * h1Prime) + 0.32 * cos(3 * .pi / 180 * h1Prime + 6) - 0.20 * cos(4 * .pi / 180 * h1Prime - 63)
        let SL = 1 + (0.015 * pow(Lmean - 50, 2)) / sqrt(20 + pow(Lmean - 50, 2))
        let SC = 1 + 0.045 * Cmean
        let SH = 1 + 0.015 * Cmean * T
        
        let deltaTheta = 30 * exp(-pow((h1Prime - 275) / 25, 2))
        let RC = 2 * sqrt(pow(Cmean, 7) / (pow(Cmean, 7) + pow(CGFloat(25), 7)))
        let RT = -RC * sin(2 * .pi / 180 * deltaTheta)
        
        let deltaE = sqrt(
            pow(deltaL / (kL * SL), 2) +
            pow(deltaC / (kC * SC), 2) +
            pow(deltaH / (kH * SH), 2) +
            RT * (deltaC / (kC * SC)) * (deltaH / (kH * SH))
        )
        
        return deltaE
    }
    
    func toCIELAB() -> (L: CGFloat, A: CGFloat, B: CGFloat) {
        func toXYZ(_ component: CGFloat) -> CGFloat {
            return (component > 0.04045) ? pow((component + 0.055) / 1.055, 2.4) : (component / 12.92)
        }
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var bl: CGFloat = 0
        self.getRed(&r, green: &g, blue: &bl, alpha: nil)
        
        let x = toXYZ(r) * 0.4124 + toXYZ(g) * 0.3576 + toXYZ(bl) * 0.1805
        let y = toXYZ(r) * 0.2126 + toXYZ(g) * 0.7152 + toXYZ(bl) * 0.0722
        let z = toXYZ(r) * 0.0193 + toXYZ(g) * 0.1192 + toXYZ(bl) * 0.9505
        
        let xNormalized = x / 0.95047
        let yNormalized = y
        let zNormalized = z / 1.08883
        
        func toLAB(_ component: CGFloat) -> CGFloat {
            return (component > 0.008856) ? pow(component, 1 / 3) : (7.787 * component) + (16 / 116)
        }
        
        let l = (116 * toLAB(yNormalized)) - 16
        let a = 500 * (toLAB(xNormalized) - toLAB(yNormalized))
        let b = 200 * (toLAB(yNormalized) - toLAB(zNormalized))
        
        return (l, a, b)
    }
}

// Hex color handling
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
