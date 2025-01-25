//
//  EntitlementsManager.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "group.demo.app")!
    
    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false
}
