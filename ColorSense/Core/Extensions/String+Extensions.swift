//
//  String.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import Foundation

extension String {
    var hexValues: (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        var hexString = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        guard hexString.count == 6 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        return (red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0)
    }

    // TODO: Fix this, it is not showing automatically in .xcstrings file
    var localized: String {
        return NSLocalizedString(self, comment: "This should be translated.")
    }

    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
