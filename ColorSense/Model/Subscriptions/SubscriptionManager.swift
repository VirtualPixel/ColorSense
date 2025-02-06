//
//  SubscriptionManager.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import Foundation
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
class SubscriptionsManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchaseError: SubscriptionError?
    @Published var isLoading = false
    
    private var purchasedProductIDs: Set<String> = []
    private let entitlementManager: EntitlementManager
    private var updates: Task<Void, Never>?
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        updates = observeTransactionUpdates()
    }
    
    deinit {
        updates?.cancel()
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let productIDs = ["colorsenseproplan", "colorsenseproplanannual"]
            products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price < $1.price })
        } catch {
            purchaseError = .noProductsAvailable
        }
    }
    
    func buyProduct(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedProducts()
                case .unverified:
                    purchaseError = .verificationFailed
                }
            case .userCancelled:
                return
            case .pending:
                return
            @unknown default:
                purchaseError = .purchaseFailed
            }
        } catch {
            purchaseError = .purchaseFailed
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
        } catch {
            purchaseError = .restoreFailed
        }
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await _ in Transaction.updates {
                await self?.updatePurchasedProducts()
            }
        }
    }
    
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        entitlementManager.hasPro = !purchasedProductIDs.isEmpty
    }
}
