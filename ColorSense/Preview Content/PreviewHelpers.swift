//
//  PreviewHelpers.swift
//  ColorSense
//
//  Created by Justin Wells on 5/13/25.
//

import SwiftUI

/**
 A simple preview helper for SubscriptionsManager that simulates StoreKit functionality
 without inheriting from the real classes, which doesn't work in previews.

 Usage:
 ```
 #Preview {
     PaywallView()
         .environmentObject(PreviewSubscriptionsManager())
         .environmentObject(PreviewEntitlementManager())
 }
 ```
 */
class PreviewSubscriptionsManager: ObservableObject {
    @Published var products: [PreviewProduct] = [
        PreviewProduct(id: "colorsenseproplan", price: 2.99, period: "month", hasFreeTrial: true),
        PreviewProduct(id: "colorsenseproplanannual", price: 24.99, period: "year", hasFreeTrial: true)
    ]
    @Published var purchaseError: SubscriptionError? = nil
    @Published var isLoading = false
    @Published var showThankYouAlert = false

    func loadProducts() async {
        // Simulated loading
    }

    func buyProduct(_ product: Any) async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
        showThankYouAlert = true
    }

    func restorePurchases() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
}

/**
 A simple preview helper for EntitlementManager
 */
class PreviewEntitlementManager: ObservableObject {
    @Published var hasPro: Bool = false
    @Published var isFirstLaunch: Bool = true

    var shouldShowPaymentSheet: Bool {
        !hasPro && isFirstLaunch
    }
}

/**
 A simplified product for previews that doesn't need to inherit from StoreKit's Product
 */
struct PreviewProduct: Identifiable {
    let id: String
    let price: Double
    let period: String
    let hasFreeTrial: Bool
    let displayName: String

    init(id: String, price: Double, period: String, hasFreeTrial: Bool, displayName: String? = nil) {
        self.id = id
        self.price = price
        self.period = period
        self.hasFreeTrial = hasFreeTrial
        self.displayName = displayName ?? "\(period.capitalized) Plan"
    }

    var displayPrice: String {
        return "$\(String(format: "%.2f", price))"
    }

    // Mock subscription data
    struct SubscriptionInfo {
        let hasIntroOffer: Bool
        let trialPeriod: String
    }

    var subscription: SubscriptionInfo? {
        return hasFreeTrial ? SubscriptionInfo(hasIntroOffer: true, trialPeriod: "7 DAYS") : nil
    }
}
