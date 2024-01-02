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
    @State private var showingPaletteView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview(session: cameraFeed.captureSession)
                
                FocusCircleView()
                
                VStack {
                    TopBarView()
                    Spacer()
                    BottomBarView(showingPaletteView: $showingPaletteView)
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
        .sheet(isPresented: $showingPaletteView) {
            PaletteListView()
                .presentationDetents([.large])
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
