//
//  ProFeature.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import Foundation
import SwiftUICore
import SwiftUI

struct ProFeature: ViewModifier {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false
    
    let shouldBlur: Bool
    
    init(shouldBlur: Bool = true) {
        self.shouldBlur = shouldBlur
    }
    
    func body(content: Content) -> some View {
        Group {
            if entitlementManager.hasPro {
                content
            } else {
                content
                    .allowsHitTesting(false)
                    .blur(radius: shouldBlur ? 10 : 0)
                    .overlay {
                        proOverlay
                    }
                    .fullScreenCover(isPresented: $showPaywall) {
                    #if !os(watchOS)
                        PaywallView()
                    #endif
                    }
            }
        }
    }
    
    private var proOverlay: some View {
        Button(action: { showPaywall = true }) {
            VStack {
                Image(systemName: "crown.fill")
                    .font(.title)
                Text("Pro Feature")
                    .font(.headline)
                Text("Tap to Unlock")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}
