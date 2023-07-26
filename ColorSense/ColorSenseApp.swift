//
//  ColorSenseApp.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

@main
struct ColorSenseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            //PalletListView()
        }
        .modelContainer(
            for: [Pallet.self, ColorStructure.self]
        )
    }
}
