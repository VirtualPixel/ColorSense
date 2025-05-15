//
//  ColorSenseApp.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI
import WishKit
import os

@main
struct ColorSenseApp: App {
    @Environment(\.scenePhase) var scenePhase
    @State private var camera = CameraModel()
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject var subscriptionsManager: SubscriptionsManager
    @State private var colorToDisplay: ColorStructure?
    @State private var paletteToDisplay: Palette?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(camera)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionsManager)
                .statusBarHidden(true)
                .task {
                    await camera.start()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard camera.status == .running, newPhase == .active else { return }
                    Task { @MainActor in
                        await camera.syncState()
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .sheet(item: $colorToDisplay) { colorStructure in
                    ColorDetailView(color: colorStructure.color)
                        .environmentObject(camera)
                        .environmentObject(entitlementManager)
                        .environmentObject(subscriptionsManager)
                }
                .sheet(item: $paletteToDisplay) { palette in
                    SharedPaletteView(palette: palette)
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
        UIApplication.shared.isIdleTimerDisabled = true
        WishKit.configure(with: EnvironmentValues.wishKitAPIKey)

        PhotoProcessor.initialize()
        ColorMixMatcher.shared.initialize()

        let entitlementManager = EntitlementManager()
        let subscriptionsManager = SubscriptionsManager(entitlementManager: entitlementManager)
        
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._subscriptionsManager = StateObject(wrappedValue: subscriptionsManager)
    }
}

let logger = Logger()
