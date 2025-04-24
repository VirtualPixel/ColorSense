//
//  Pantone.swift
//  ColorSense
//
//  Created by Justin Wells on 7/19/23.
//

import Foundation

struct Pantone: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    
    static let examples: [Pantone] = [
        Pantone(name: "Something", value: "28dj4j"),
        Pantone(name: "Something", value: "j84hfj"),
        Pantone(name: "Something", value: "fj48dg"),
    ]
}

struct PantoneColorArrays: Decodable {
    let names: [String]
    let values: [String]
}
