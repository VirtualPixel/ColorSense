//
//  ContentView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager
    @EnvironmentObject private var cameraFeed: CameraFeed
        
    @ObservedObject private var viewModel = ViewModel()
        
    var body: some View {
        NavigationStack {
            cameraView
            .onAppear(perform: cameraFeed.start)
            .onAppear {
                Task {
                    await subscriptionsManager.loadProducts()
                }
            }
            .onDisappear(perform: cameraFeed.stop)
            .environmentObject(cameraFeed)
            .onChange(of: scenePhase) {
                handleScenePhaseChange()
            }
        }
    }
}

private extension ContentView {
    @ViewBuilder
    var cameraView: some View {
        VStack {
            flashAndSettingsButtons

            ZStack {
                CameraPreview(session: cameraFeed.captureSession)
                FocusCircleView()
                paletteAndBottomBar
            }
        }
    }
    
    @ViewBuilder
    var flashAndSettingsButtons: some View {
        HStack {
            flashButton
            Spacer()
            settingsButton
        }
        .padding(15)
        .background(.black)
    }
    
    @ViewBuilder
    var paletteAndBottomBar: some View {
        VStack {
            ColorCardView().padding(.top, 20)
            Spacer()
            BottomBarView()
        }
    }
    
    var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gear")
                .iconStyle
        }
    }
    
    var flashButton: some View {
        Button {
            cameraFeed.isFlashOn.toggle()
        } label: {
            Image(systemName: "bolt.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .padding(6)
                .background(
                    .yellow.opacity(cameraFeed.isFlashOn ? 1.0 : 0.0)
                )
                .background(.thinMaterial)
                .clipShape(Circle())
                .frame(width: 32, height: 32)
        }
    }
    
    func handleScenePhaseChange() {
        if cameraFeed.isFlashOn {
            cameraFeed.isFlashOn = false
        }
    }
}

extension Image {
    var iconStyle: some View {
        self.resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white)
            .padding(3)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .frame(width: 32, height: 32)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let subscriptionsManager = SubscriptionsManager(entitlementManager: EntitlementManager())
    static let entitlementManager = EntitlementManager()
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ContentView()
            .environmentObject(cameraFeed)
            .environmentObject(subscriptionsManager)
            .environmentObject(entitlementManager)
    }
}
