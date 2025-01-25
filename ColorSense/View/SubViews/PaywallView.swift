//
//  PaywallView.swift
//  ColorSense
//
//  Created by Justin Wells on 1/24/25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product? = nil
    
    private let features: [String] = [
        "Access Pantone Colors",
        "View Complementary Colors",
        "Advanced Color Analytics",
        "No Ads"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                featuresSection
                productsSection
                purchaseButtons
            }
            .padding()
            .navigationTitle("ColorSense Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await subscriptionsManager.loadProducts()
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(features, id: \.self) { feature in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                }
            }
        }
    }
    
    private var productsSection: some View {
        VStack {
            ForEach(subscriptionsManager.products, id: \.id) { product in
                productButton(product)
            }
        }
    }
    
    private var purchaseButtons: some View {
        VStack {
            if let selected = selectedProduct {
                Button(action: {
                    Task {
                        await subscriptionsManager.buyProduct(selected)
                        dismiss()
                    }
                }) {
                    Text("Subscribe")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Button("Restore Purchases") {
                Task {
                    await subscriptionsManager.restorePurchases()
                    dismiss()
                }
            }
        }
    }
    
    private func productButton(_ product: Product) -> some View {
        Button(action: { selectedProduct = product }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedProduct?.id == product.id ? Color.accentColor : Color.gray.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let subscriptionManager = SubscriptionsManager(entitlementManager: EntitlementManager())
    let entitlementManager = EntitlementManager()
    PaywallView()
        .environmentObject(subscriptionManager)
        .environmentObject(entitlementManager)
}
