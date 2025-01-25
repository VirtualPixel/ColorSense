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
    
    func body(content: Content) -> some View {
        Group {
            if entitlementManager.hasPro {
                content
            } else {
                content
                    .allowsHitTesting(false)
                    .blur(radius: 10)
                    .overlay {
                        proOverlay
                    }
                    .sheet(isPresented: $showPaywall) {
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
