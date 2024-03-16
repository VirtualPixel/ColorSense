//
//  macOSColorSenseApp.swift
//  macOSColorSense
//
//  Created by Justin Wells on 8/3/23.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct macOSColorSenseApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .modelContainer(
                    for: [
                        Palette.self,
                        ColorStructure.self
                    ]
                )
        } label: {
            Image("monochromeSmall")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_GnDsCnYqxOLXrcgxaUGIQiEWWHc")
    }
}

