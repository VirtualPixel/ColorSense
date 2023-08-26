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
    @State private var colorToDisplay: ColorStructure?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cameraFeed)
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
                Pallet.self,
                ColorStructure.self
            ]
        )
    }
}
