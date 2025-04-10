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
    @State private var paletteToDisplay: Palette?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cameraFeed)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionsManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .sheet(item: $colorToDisplay) { colorStructure in
                    ColorDetailView(color: colorStructure.color)
                        .environmentObject(cameraFeed)
                        .environmentObject(entitlementManager)
                        .environmentObject(subscriptionsManager)
                }
                .sheet(item: $paletteToDisplay) { palette in
                    SharedPaletteView(palette: palette)
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

    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        // Check the URL path to determine what type of content we're dealing with
        if url.host == "color" {
            if let colorHex = components.queryItems?.first(where: { $0.name == "colorHex" })?.value {
                print("Received color hex: \(colorHex)")
                self.colorToDisplay = ColorStructure(hex: colorHex)
            }
        } else if url.host == "palette" {
            if let paletteName = components.queryItems?.first(where: { $0.name == "name" })?.value,
               let colorsString = components.queryItems?.first(where: { $0.name == "colors" })?.value {

                print("Received palette: \(paletteName)")

                // Parse the comma-separated color hexes
                let colorHexes = colorsString.split(separator: ",").map(String.init)

                // Create color structures for each hex
                let colorStructures = colorHexes.map { ColorStructure(hex: $0) }

                // Create a temporary palette object to display
                let newPalette = Palette(id: UUID(), name: paletteName, colors: colorStructures)
                self.paletteToDisplay = newPalette
            }
        }
    }

    init() {
        let entitlementManager = EntitlementManager()
        let subscriptionsManager = SubscriptionsManager(entitlementManager: entitlementManager)
        
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._subscriptionsManager = StateObject(wrappedValue: subscriptionsManager)
    }
}
