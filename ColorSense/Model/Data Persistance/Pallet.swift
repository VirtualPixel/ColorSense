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
    @Relationship(.cascade, inverse: \ColorStructure.pallet) var colors: [ColorStructure]?
    var id: UUID = UUID()
    var name: String = ""
    var creationDate: Date = Date()
    
    init(id: UUID = UUID(), name: String, colors: [ColorStructure]?) {
        self.id = id
        self.name = name
        self.colors = colors
    }
}
