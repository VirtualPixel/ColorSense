//
//  ContentView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var camera: CameraModel
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @ObservedObject private var viewModel = ViewModel()

    var body: some View {
        NavigationStack {
            ZStack {

                PreviewContainer(camera: camera) {
                    MetalCameraPreview(
                        source: camera.previewSource,
                        filterType: camera.currentColorVisionType,
                        isFilterEnabled: camera.applyColorVisionFilter
                    )
                    .opacity(camera.shouldFlashScreen ? 0 : 1)
                }
                .offset(y: -20)

                GeometryReader { geometry in
                    FocusCircleView(bounds: geometry.frame(in: .local))
                }
                .offset(y: -60)

                CameraUI()
            }
            .onAppear {
                Task {
                    await subscriptionsManager.loadProducts()

                    for product in subscriptionsManager.products {
                            if let subscription = product.subscription,
                               let intro = subscription.introductoryOffer {
                                print("Product \(product.id) has intro offer:")
                                print("  - Type: \(intro.paymentMode)")
                                print("  - Period: \(intro.period.value) \(intro.period.unit)")
                                print("  - Price: \(intro.price)")
                            } else {
                                // No intro offer
                            }
                        }
                }
            }
            .background(Color.black)
        }
        .sheet(isPresented: .init(
            get: { entitlementManager.shouldShowPaymentSheet },
            set: { _ in entitlementManager.isFirstLaunch = false }
        )) {
            PaywallView()
        }
    }
}

#Preview {
    ContentView()
        // .environmentObject(PreviewCameraModel())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
        .environmentObject(EntitlementManager())
}
