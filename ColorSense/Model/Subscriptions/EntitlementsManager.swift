//
//  EntitlementsManager.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "com.justinwells.ColorSense.app")!
    
    @AppStorage(
        "hasPro",
        store: userDefaults
    ) var hasPro: Bool = false
    
    @AppStorage(
        "isFirstLaunch",
        store: userDefaults
    ) var isFirstLaunch: Bool = true
    
    var shouldShowPaymentSheet: Bool {
        !hasPro && isFirstLaunch
    }
}
