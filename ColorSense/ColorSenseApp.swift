//
//  ColorSenseApp.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

@main
struct ColorSenseApp: App {
    @StateObject var cameraFeed = CameraFeed()
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject var subscriptionsManager: SubscriptionsManager
    @State private var colorToDisplay: ColorStructure?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cameraFeed)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionsManager)
                .onOpenURL { url in
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                    if let colorHex = components?.queryItems?.first(where: { $0.name == "colorHex" })?.value {
                        print("Hex: \(colorHex)")
                        self.colorToDisplay = ColorStructure(hex: colorHex)
                    }
                }
                .sheet(item: $colorToDisplay) { colorStructure in
                    ColorDetailView(color: colorStructure.color)
                        .environmentObject(cameraFeed)
                }
        }
        .modelContainer(
            for: [
                Palette.self,
                ColorStructure.self
            ]
        )
    }
    
    init() {
        let entitlementManager = EntitlementManager()
        let subscriptionsManager = SubscriptionsManager(entitlementManager: entitlementManager)
        
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._subscriptionsManager = StateObject(wrappedValue: subscriptionsManager)
    }
}
