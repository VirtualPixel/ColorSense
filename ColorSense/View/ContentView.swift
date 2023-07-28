//
//  ContentView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject private var viewModel = ViewModel()
    @EnvironmentObject private var cameraFeed: CameraFeed
    @State private var showingPalletView = false
    @State private var colorToDisplay: ColorStructure?
    
    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview(session: cameraFeed.captureSession)
                
                FocusCircleView()
                
                VStack {
                    TopBarView()
                    ColorCardView()
                    Spacer()
                    BottomBarView(showingPalletView: $showingPalletView)
                }
            }
        }
        .onAppear(perform: cameraFeed.start)
        .onDisappear(perform: cameraFeed.stop)
        .onChange(of: scenePhase) {
            if cameraFeed.isFlashOn {
                cameraFeed.isFlashOn = false
            }
        }
        .environmentObject(cameraFeed)
        .sheet(isPresented: $showingPalletView) {
            PalletListView()
                .presentationDetents([.large])
        }
        .onOpenURL { url in
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            if let colorHex = components?.queryItems?.first(where: { $0.name == "colorHex" })?.value {
                print("Hex: \(colorHex)")
                self.colorToDisplay = ColorStructure(hex: colorHex)
            }
        }
        .sheet(item: $colorToDisplay) { colorStructure in
            ColorDetailView(color: colorStructure.color)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ContentView()
            .environmentObject(cameraFeed)
    }
}
