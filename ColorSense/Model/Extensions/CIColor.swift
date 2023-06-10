//
//  CIColor.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

extension CIColor {
    func toColor() -> Color {
        return Color(UIColor(ciColor: self))
    }
}
