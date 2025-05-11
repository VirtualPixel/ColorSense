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

    /// Calculate color difference using CIEDE2000 algorithm (perceptual difference)
    func difference(to color: UIColor) -> CGFloat {
        // Convert colors to CIELAB color space
        let lab1 = self.toCIELAB()
        let lab2 = color.toCIELAB()

        // Weighting factors
        let kL: CGFloat = 1.0
        let kC: CGFloat = 1.0
        let kH: CGFloat = 1.0

        // Calculate lightness difference
        let deltaL = lab2.L - lab1.L

        // Calculate chroma values
        let C1 = sqrt(lab1.A * lab1.A + lab1.B * lab1.B)
        let C2 = sqrt(lab2.A * lab2.A + lab2.B * lab2.B)
        let Cbar = (C1 + C2) / 2

        // Calculate G factor for perceptual adjustment
        let G = 0.5 * (1 - sqrt(pow(Cbar, 7) / (pow(Cbar, 7) + pow(25, 7))))

        // Calculate adjusted a' values
        let aPrime1 = lab1.A * (1 + G)
        let aPrime2 = lab2.A * (1 + G)

        // Calculate adjusted chroma values
        let CPrime1 = sqrt(aPrime1 * aPrime1 + lab1.B * lab1.B)
        let CPrime2 = sqrt(aPrime2 * aPrime2 + lab2.B * lab2.B)

        // Calculate hue angles with proper handling
        var hPrime1: CGFloat = 0
        if lab1.A == 0 && lab1.B == 0 {
            hPrime1 = 0 // Undefined, set to 0 by convention
        } else {
            hPrime1 = atan2(lab1.B, aPrime1) * 180 / .pi
            if hPrime1 < 0 { hPrime1 += 360 }
        }

        var hPrime2: CGFloat = 0
        if lab2.A == 0 && lab2.B == 0 {
            hPrime2 = 0 // Undefined, set to 0 by convention
        } else {
            hPrime2 = atan2(lab2.B, aPrime2) * 180 / .pi
            if hPrime2 < 0 { hPrime2 += 360 }
        }

        // Calculate chroma difference
        let deltaCPrime = CPrime2 - CPrime1

        // Calculate hue difference with proper wrap-around handling
        var deltaHPrime: CGFloat = 0
        if CPrime1 < 1e-4 || CPrime2 < 1e-4 {
            deltaHPrime = 0
        } else {
            let dhPrime = hPrime2 - hPrime1
            if abs(dhPrime) <= 180 {
                deltaHPrime = dhPrime
            } else if dhPrime > 180 {
                deltaHPrime = dhPrime - 360
            } else {
                deltaHPrime = dhPrime + 360
            }
        }

        // Calculate ΔH'
        let deltaHPrime2 = 2 * sqrt(CPrime1 * CPrime2) * sin((deltaHPrime * .pi) / 360)

        // Calculate mean hue angle
        var HPrimeMean: CGFloat = 0
        if CPrime1 < 1e-4 || CPrime2 < 1e-4 {
            HPrimeMean = hPrime1 + hPrime2
        } else {
            if abs(hPrime1 - hPrime2) <= 180 {
                HPrimeMean = (hPrime1 + hPrime2) / 2
            } else if hPrime1 + hPrime2 < 360 {
                HPrimeMean = (hPrime1 + hPrime2 + 360) / 2
            } else {
                HPrimeMean = (hPrime1 + hPrime2 - 360) / 2
            }
        }

        // Calculate T factor for hue rotation
        let T = 1 -
        0.17 * cos((HPrimeMean - 30) * .pi / 180) +
        0.24 * cos(2 * HPrimeMean * .pi / 180) +
        0.32 * cos((3 * HPrimeMean + 6) * .pi / 180) -
        0.20 * cos((4 * HPrimeMean - 63) * .pi / 180)

        // Calculate parametric weights
        let Lbar = (lab1.L + lab2.L) / 2
        let SL = 1 + (0.015 * pow(Lbar - 50, 2)) / sqrt(20 + pow(Lbar - 50, 2))
        let SC = 1 + 0.045 * ((CPrime1 + CPrime2) / 2)
        let SH = 1 + 0.015 * ((CPrime1 + CPrime2) / 2) * T

        // Calculate rotation term
        let deltaTheta = 30 * exp(-pow((HPrimeMean - 275) / 25, 2))
        let RC = 2 * sqrt(pow((CPrime1 + CPrime2) / 2, 7) / (pow((CPrime1 + CPrime2) / 2, 7) + pow(25, 7)))
        let RT = -RC * sin(2 * deltaTheta * .pi / 180)

        // Calculate final CIEDE2000 color difference
        let deltaE = sqrt(
            pow(deltaL / (kL * SL), 2) +
            pow(deltaCPrime / (kC * SC), 2) +
            pow(deltaHPrime2 / (kH * SH), 2) +
            RT * (deltaCPrime / (kC * SC)) * (deltaHPrime2 / (kH * SH))
        )

        return deltaE
    }

    func toCIELAB() -> (L: CGFloat, A: CGFloat, B: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        // Convert sRGB to linear RGB
        let linearR = r <= 0.04045 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let linearG = g <= 0.04045 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
        let linearB = b <= 0.04045 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)

        // Convert linear RGB to XYZ
        let x = linearR * 0.4124 + linearG * 0.3576 + linearB * 0.1805
        let y = linearR * 0.2126 + linearG * 0.7152 + linearB * 0.0722
        let z = linearR * 0.0193 + linearG * 0.1192 + linearB * 0.9505

        // Convert XYZ to Lab
        let xnorm = x / 0.950489
        let ynorm = y / 1.0
        let znorm = z / 1.088840

        let fx = xnorm > 0.008856 ? pow(xnorm, 1.0/3.0) : (7.787 * xnorm + 16.0/116.0)
        let fy = ynorm > 0.008856 ? pow(ynorm, 1.0/3.0) : (7.787 * ynorm + 16.0/116.0)
        let fz = znorm > 0.008856 ? pow(znorm, 1.0/3.0) : (7.787 * znorm + 16.0/116.0)

        let L = 116.0 * fy - 16.0
        let A = 500.0 * (fx - fy)
        let B = 200.0 * (fy - fz)

        return (L, A, B)
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
