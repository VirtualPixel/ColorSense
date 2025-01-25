//
//  SubscriptionsManager.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import Foundation
import StoreKit

extension SubscriptionsManager {
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price > $1.price })
        } catch {
            print("Failed to fetch products!")
        }
    }
}
