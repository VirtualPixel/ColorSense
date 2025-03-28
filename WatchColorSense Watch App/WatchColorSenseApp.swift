//
//  WatchColorSenseApp.swift
//  WatchColorSense Watch App
//
//  Created by Justin Wells on 7/31/23.
//

import SwiftUI

@main
struct WatchColorSense_Watch_AppApp: App {
    @State private var colorToDisplay: ColorStructure?
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject var subscriptionsManager: SubscriptionsManager

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                    if let colorHex = components?.queryItems?.first(where: { $0.name == "colorHex" })?.value {
                        print("Hex: \(colorHex)")
                        self.colorToDisplay = ColorStructure(hex: colorHex)
                    }
                }
                .sheet(item: $colorToDisplay) { colorStructure in
                    WatchColorDetailView(color: colorStructure.color)
                }
                .environmentObject(entitlementManager)
                .task {
                    await subscriptionsManager.restorePurchases()
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
