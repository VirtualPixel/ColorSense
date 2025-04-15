//
//  URL.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import Foundation

extension URL {
    static var movieFileURL: URL {
        URL.temporaryDirectory.appending(component: UUID().uuidString).appendingPathExtension(for: .quickTimeMovie)
    }
}
