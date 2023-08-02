//
//  Colors.swift
//  ColorSense
//
//  Created by Justin Wells on 7/19/23.
//

import SwiftUI
import SwiftData

@Model
class ColorStructure: Identifiable {
    @Relationship var pallet: Pallet?
    var id: UUID = UUID()
    var hex: String = "000000"
    var creationDate: Date = Date()
    
    var color: Color {
        Color.init(hex: hex)
    }
    
    init(id: UUID = UUID(), hex: String = "000000") {
        self.id = id
        self.hex = hex.replacingOccurrences(of: "#", with: "")
    }
}
