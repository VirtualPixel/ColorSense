//
//  ContentView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel = ViewModel()
    @EnvironmentObject private var cameraFeed: CameraFeed
    @State private var isShowingPaletteView = false
    
    var body: some View {
        NavigationStack {
            cameraView
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    flashButton
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // settingsButton
                }
            }
            .preferredColorScheme(.dark)
            .onAppear(perform: cameraFeed.start)
            .onDisappear(perform: cameraFeed.stop)
            .environmentObject(cameraFeed)
            .sheet(isPresented: $isShowingPaletteView) {
                PaletteListView().presentationDetents([.large])
            }
            .onChange(of: scenePhase) {
                handleScenePhaseChange()
            }
        }
    }
}

private extension ContentView {
    @ViewBuilder
    var cameraView: some View {
        ZStack {
            CameraPreview(session: cameraFeed.captureSession)
            FocusCircleView()
            paletteAndBottomBar
        }
    }
    
    @ViewBuilder
    var paletteAndBottomBar: some View {
        VStack {
            ColorCardView().padding(.top, 20)
            Spacer()
            BottomBarView(showingPaletteView: $isShowingPaletteView)
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
            .padding(5)
            .background(.thinMaterial)
            .clipShape(Circle())
            .frame(width: 32, height: 32)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ContentView()
            .environmentObject(cameraFeed)
    }
}
