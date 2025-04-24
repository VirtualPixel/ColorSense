//
//  Color.swift
//  ColorSense
//
//  Created by Justin Wells on 7/19/23.
//

import SwiftUI
import SwiftData

@Model
final class Palette: Identifiable {
    @Relationship(inverse: \ColorStructure.palette) var colors: [ColorStructure]?
    var id: UUID?
    var name: String?
    var creationDate: Date?
    
    var wrappedName: String {
        self.name ?? "Palette"
    }
    var wrappedCreationDate: Date {
        self.creationDate ?? Date()
    }
    var wrappedColors: [ColorStructure] {
        self.colors?.sorted(by: { $0.wrappedCreationDate > $1.wrappedCreationDate }) ?? []
    }
    
    init(id: UUID = UUID(), name: String = "", colors: [ColorStructure]?) {
        self.id = id
        self.name = name
        self.colors = colors
    }

    static let defaultPalette = Palette(
        name: "House",
        colors: [
            ColorStructure(hex: "3D8D7A"),
            ColorStructure(hex: "B3D8A8"),
            ColorStructure(hex: "FBFFE4"),
            ColorStructure(hex: "A3D1C6")
        ]
    )
}
