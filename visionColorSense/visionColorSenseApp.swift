//
//  visionColorSenseApp.swift
//  visionColorSense
//
//  Created by Justin Wells on 8/4/23.
//

import SwiftUI
import RevenueCat

@main
struct visionColorSenseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_GnDsCnYqxOLXrcgxaUGIQiEWWHc")
    }
}
