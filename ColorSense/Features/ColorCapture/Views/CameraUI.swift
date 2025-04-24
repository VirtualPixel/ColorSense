//
//  CameraUI.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import SwiftUI

struct CameraUI: View {
    @EnvironmentObject var camera: CameraModel
    @State private var modeManager = CameraModeManager()
    @State private var currentPage = 0

    var body: some View {
        ZStack {

            VStack(spacing: 0) {

                flashAndSettingsButtons

                ZStack {
                    VStack(spacing: 0) {
                        TabView(selection: $currentPage) {
                            ForEach(0..<modeManager.availableModes.count, id: \.self) { index in
                                VStack(alignment: .center) {
                                    modeManager.availableModes[index].getContentView()
                                    Spacer()
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: currentPage) { oldValue, newValue in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                modeManager.switchTo(mode: newValue)
                            }
                        }
                        .onChange(of: modeManager.currentModeIndex) { oldValue, newValue in
                            if currentPage != newValue {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage = newValue
                                }
                            }
                        }

                        VStack(spacing: 15) {
                            modeSelectorView
                                .padding(.bottom, 5)

                            BottomBarView(
                                onCaptureButtonPressed: {
                                    Task {
                                        await modeManager.currentMode.onCaptureButtonPressed(camera: camera)
                                    }
                                },
                                captureButtonIcon: modeManager.currentMode.captureButtonIcon,
                                captureButtonText: modeManager.currentMode.captureButtonText
                            )
                        }
                        .background(Color.black)
                    }
                }
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

    var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gear")
                .iconStyle
        }
    }

    var flashButton: some View {
        Button {
            Task {
                camera.isTorchEnabled.toggle()
            }
        } label: {
            Image(systemName: "bolt.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .padding(6)
                .background(
                    .yellow.opacity(camera.isTorchEnabled ? 1.0 : 0.0)
                )
                .background(.thinMaterial)
                .clipShape(Circle())
                .frame(width: 32, height: 32)
        }
    }

    var modeSelectorView: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        Spacer()
                            .frame(width: totalWidth / 2 - 50)

                        ForEach(0..<modeManager.availableModes.count, id: \.self) { index in
                            let mode = modeManager.availableModes[index]
                            VStack(spacing: 8) {
                                Text(mode.name)
                                    .font(.system(size: 16))
                                    .fontWeight(modeManager.currentModeIndex == index ? .bold : .regular)
                                    .foregroundColor(modeManager.currentModeIndex == index ? .white : .gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .frame(width: 120)

                                Rectangle()
                                    .frame(width: 40, height: 3)
                                    .foregroundColor(modeManager.currentModeIndex == index ? .white : .clear)
                            }
                            .id(index)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    modeManager.switchTo(mode: index)
                                }
                            }
                        }

                        Spacer()
                            .frame(width: totalWidth / 2 - 50)
                    }
                }
                .onChange(of: modeManager.currentModeIndex) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(modeManager.currentModeIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.top, 10)
    }

}

#Preview {
    CameraUI()
        .environmentObject(PreviewCameraModel())
}
