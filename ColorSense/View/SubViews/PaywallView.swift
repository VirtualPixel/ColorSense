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
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPlan: Plan = .monthly
    
    enum Plan {
        case monthly, yearly
        
        var title: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }
    
    private let features = [
        "Pro Color Details",
        "Advanced Color Naming",
        "Unlimited Color Palettes",
        "Color Accessibility Tools",
        "Export Palettes",
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    planToggleSection
                    featuresSection
                    purchaseButton
                    restoreButton
                }
                .padding()
            }
            .background(backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            await subscriptionsManager.loadProducts()
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(uiColor: .systemGroupedBackground)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Upgrade to Pro")
                .font(.system(size: 32, weight: .bold))
            Text("Unlock advanced color features")
                .foregroundColor(.secondary)
        }
        .foregroundColor(.primary)
    }
    
    private var planToggleSection: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach([Plan.monthly, .yearly], id: \.self) { plan in
                    Button(action: { selectedPlan = plan }) {
                        Text(plan.title)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(selectedPlan == plan ? Color.accentColor : Color.gray.opacity(0.1))
                            .foregroundColor(selectedPlan == plan ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            let monthlyProduct = subscriptionsManager.products.first { $0.id == "colorsenseproplan" }
            let yearlyProduct = subscriptionsManager.products.first { $0.id == "colorsenseproplanannual" }
            
            if selectedPlan == .monthly, let product = monthlyProduct {
                priceView(for: product)
            } else if selectedPlan == .yearly, let product = yearlyProduct {
                priceView(for: product)
            }
        }
    }
    
    private func priceView(for product: Product) -> some View {
        VStack(spacing: 4) {
            Text(product.displayPrice)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.primary)
            if selectedPlan == .yearly {
                Text("Save 33%")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(colorScheme == .dark ? Color.gray.opacity(0.2) : .white)
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 2)
            }
        }
    }
    
    private var purchaseButton: some View {
        Button(action: { handlePurchase() }) {
            Text("Continue")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await subscriptionsManager.restorePurchases()
                dismiss()
            }
        }
        .foregroundColor(.secondary)
    }
    
    private func handlePurchase() {
        let productId = selectedPlan == .monthly ? "colorsenseproplan" : "colorsenseproplanannual"
        guard let product = subscriptionsManager.products.first(where: { $0.id == productId }) else { return }
        Task {
            await subscriptionsManager.buyProduct(product)
            dismiss()
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
        .environmentObject(EntitlementManager())
        .preferredColorScheme(.dark)
}
