//
//  View.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
    
    func isProFeature(shouldBlur: Bool = true) -> some View {
        modifier(ProFeature(shouldBlur: shouldBlur))
    }
}
