//
//  Colors.swift
//  ColorSense
//
//  Created by Justin Wells on 7/19/23.
//

import SwiftUI

struct ColorStructure {
    let hex: String
    
    var color: Color {
        Color.init(hex: hex)
    }
}
