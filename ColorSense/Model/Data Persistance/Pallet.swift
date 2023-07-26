//
//  Color.swift
//  ColorSense
//
//  Created by Justin Wells on 7/19/23.
//

import SwiftUI
import SwiftData

@Model
final class Pallet: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var colors: [ColorStructure]
    
    init(id: UUID = UUID(), name: String, colors: [ColorStructure]) {
        self.id = id
        self.name = name
        self.colors = colors
    }
}
