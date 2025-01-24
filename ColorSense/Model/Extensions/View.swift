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
    
    func isProFeature(_ isProEnabled: Bool) -> some View {
        Group {
            if isProEnabled {
                self
            } else {
                PaywallPrompt()
            }
        }
    }
}

struct PaywallPrompt: View {
    var body: some View {
        Text("Hello")
    }
}
