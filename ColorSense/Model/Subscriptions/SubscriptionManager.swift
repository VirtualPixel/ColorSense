//
//  SubscriptionManager.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import SwiftUICore
import StoreKit

enum SubscriptionError: LocalizedError {
    case purchaseFailed
    case verificationFailed
    case noProductsAvailable
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return "Unable to complete the purchase"
        case .verificationFailed:
            return "Purchase verification failed"
        case .noProductsAvailable:
            return "No subscription products available"
        case .restoreFailed:
            return "Unable to restore purchases"
        }
    }
}

@MainActor
class SubscriptionsManager: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var purchaseError: SubscriptionError?
    @Published var isLoading = false
    @Published var showThankYouAlert = false
    
    let productIDs = ["colorsenseproplan", "colorsenseproplanannual"]
    
    private var purchasedProductIDs: Set<String> = []
    private let entitlementManager: EntitlementManager
    private var updates: Task<Void, Never>? = nil
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        updates?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await _ in Transaction.updates {
                await self?.updatePurchasedProducts()
            }
        }
    }
}

extension SubscriptionsManager {
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price < $1.price })
        } catch {
            print("Failed to fetch products! Error: \(error)")
            purchaseError = .noProductsAvailable
        }
    }
    
    func buyProduct(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(.verified(transaction)):
                // Successful purhcase
                await transaction.finish()
                await self.updatePurchasedProducts()
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                print("Unverified purchase. Might be jailbroken. Error: \(error)")
                purchaseError = .verificationFailed
                break
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or
                // approval from Ask to Buy
                break
            case .userCancelled:
                print("User cancelled!")
                break
            @unknown default:
                print("Failed to purchase the product!")
                purchaseError = .purchaseFailed
                break
            }
        } catch {
            print("Failed to purchase the product!")
        }
    }
    
    private func updatePurchasedProducts() async {
        purchasedProductIDs.removeAll()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
                        
            if let expirationDate = transaction.expirationDate {
                if expirationDate > Date() {
                    purchasedProductIDs.insert(transaction.productID)
                }
            }
        }
        
        entitlementManager.hasPro = !purchasedProductIDs.isEmpty
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            var restoredCount = 0
            
            for await verification in Transaction.currentEntitlements {
                if case .verified(let transaction) = verification {
                    if !transaction.isUpgraded && transaction.revocationDate == nil {
                        purchasedProductIDs.insert(transaction.productID)
                        entitlementManager.hasPro = true
                        restoredCount += 1
                    }
                }
            }
            
            if restoredCount > 0 {
                showThankYouAlert = true
            } else {
                purchaseError = .restoreFailed
            }
        } catch {
            purchaseError = .restoreFailed
        }
    }
}

extension SubscriptionsManager: @preconcurrency SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
}
