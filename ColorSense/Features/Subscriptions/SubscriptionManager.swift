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
    
    let subscriptionProductIDs = ["colorsenseproplanweekly", "colorsenseproplanannual"]
    let nonConsumableProductIDs = ["dev.justinwells.ColorSense.lifetime"]

    var allProductIds: [String] {
        subscriptionProductIDs + nonConsumableProductIDs
    }

    var lifetimeProduct: Product? {
        products.first(where: { $0.id == nonConsumableProductIDs.first })
    }

    var shouldShowLifetimeOffer: Bool {
        guard let product = lifetimeProduct else { return false }
        return product.price == 0.0
    }

    var hasLifetimePurchase: Bool = false

    private var purchasedProductIDs: Set<String> = []
    private let entitlementManager: EntitlementManager
    private var transactionListenerTask: Task<Void, Never>?

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.transactionListenerTask = observeTransactionUpdates()

        Task {
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListenerTask?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                if case .verified(let transaction) = verificationResult {
                    await self?.handleVerifiedTransaction(transaction)

                    await transaction.finish()
                }
                await self?.updatePurchasedProducts()
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        if nonConsumableProductIDs.contains(transaction.productID) && transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
            hasLifetimePurchase = true
            entitlementManager.hasPro = true
            return
        }

        // Process the transaction
        if transaction.revocationDate == nil {
            if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                purchasedProductIDs.insert(transaction.productID)
                entitlementManager.hasPro = true
            }
        } else {
            // Transaction was revoked
            purchasedProductIDs.remove(transaction.productID)
            // Check if any active subscriptions remain
            entitlementManager.hasPro = !purchasedProductIDs.isEmpty
        }
    }
}

extension SubscriptionsManager {
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.products = try await Product.products(for: allProductIds)
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
                showThankYouAlert = true
            case let .success(.unverified(_, error)):
                // Successful purchase but transaction/receipt can't be verified
                // Could be a jailbroken phone
                print("Unverified purchase. Might be jailbroken. Error: \(error)")
                purchaseError = .verificationFailed
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or
                // approval from Ask to Buy
                print("Purchase pending approval")
            case .userCancelled:
                print("User cancelled!")
                break
            @unknown default:
                print("Failed to purchase the product!")
                purchaseError = .purchaseFailed
            }
        } catch {
            print("Failed to purchase the product!")
            purchaseError = .purchaseFailed
        }
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
                print("Restore successful")
                showThankYouAlert = true
            } else {
                print("Restore failed")
                purchaseError = .restoreFailed
            }
        } catch {
            print("Restore error: \(error)")
            purchaseError = .restoreFailed
        }
    }

    private func updatePurchasedProducts() async {
        purchasedProductIDs.removeAll()
        hasLifetimePurchase = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if nonConsumableProductIDs.contains(transaction.productID) && transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
                hasLifetimePurchase = true
                entitlementManager.hasPro = true
                continue
            }

            if let expirationDate = transaction.expirationDate {
                if expirationDate > Date() {
                    purchasedProductIDs.insert(transaction.productID)
                }
            }
        }

        entitlementManager.hasPro = hasLifetimePurchase || !purchasedProductIDs.isEmpty
    }
}
