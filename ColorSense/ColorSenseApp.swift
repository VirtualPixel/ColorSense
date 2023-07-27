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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cameraFeed)
        }
        .modelContainer(
            for: [Pallet.self, ColorStructure.self]
        )
    }
}
   
