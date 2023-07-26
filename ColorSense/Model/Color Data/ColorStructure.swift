//
//  Colors.swift
//  ColorSense
//
//  Created by Justin Wells on 7/19/23.
//

import SwiftUI
import SwiftData

@Model
class ColorStructure {
    var id = UUID()
    var hex: String
    
    var color: Color {
        Color.init(hex: hex)
    }
    
    init(id: UUID = UUID(), hex: String) {
        self.hex = hex
    }
}
