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
                        isFilterEnabled: camera.applyColorVisionFilter,
                        isEnhancementEnabled: camera.isEnhancementEnabled
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
            .background(Color.black)
            .task {
                await camera.start()
                await subscriptionsManager.loadProducts()
            }
            .onDisappear {
                DispatchQueue.global(qos: .userInitiated).async {
                    Task {
                        await camera.stopCamera()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: .init(
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
