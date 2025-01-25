//
//  SubscriptionManager.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import Foundation
import SwiftUICore
import StoreKit

@MainActor
class SubscriptionsManager: ObservableObject {
    let productIDs: [String] = ["colorsenseproplan", "colorsenseproplanannual"]
    var purchasedProductIDs: Set<String> = []
    
    @Published var products: [Product] = []
    
    private var entitlementManager: EntitlementManager? = nil
    private var updates: Task<Void, Never>? = nil
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
    }
    
    deinit {
        updates?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        self.entitlementManager?.hasPro = !self.purchasedProductIDs.isEmpty
    }
    
    func buyProduct(_ product: Product) async {
        Task {
            do {
                let result = try await product.purchase()
                
                switch result {
                case let .success(.verified(transaction)):
                    // Successful purhcase
                    await transaction.finish()
                case let .success(.unverified(_, error)):
                    // Successful purchase but transaction/receipt can't be verified
                    // Could be a jailbroken phone
                    print("Unverified purchase. Might be jailbroken. Error: \(error)")
                    break
                case .pending:
                    // Transaction waiting on SCA (Strong Customer Authentication) or
                    // approval from Ask to Buy
                    break
                case .userCancelled:
                    // ^^^
                    print("User Cancelled!")
                    break
                @unknown default:
                    print("Failed to purchase the product!")
                    break
                }
            } catch {
                print("Failed to purchase the product!")
            }
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print(error)
        }
    }
}
