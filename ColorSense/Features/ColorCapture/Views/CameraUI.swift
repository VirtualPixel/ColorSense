//
//  CameraUI.swift
//  ColorSense
//
//  Created by Justin Wells on 4/14/25.
//

import SwiftUI

enum CameraMode: String, CaseIterable, Identifiable {
    case color = "Color"
    case match = "Match"
    case accessibility = "Accessibility"

    var id: String { self.rawValue }

    var localizedName: String {
        return String(localized: String.LocalizationValue(self.rawValue))
    }
}

struct CameraUI: View {
    @EnvironmentObject var camera: CameraModel
    @State private var selectedMode: CameraMode = .color
    @State private var currentPage = 0

    var body: some View {
        ZStack {

            VStack(spacing: 0) {

                flashAndSettingsButtons

                ZStack {
                    
                    VStack(spacing: 0) {
                        TabView(selection: $currentPage) {
                            VStack(alignment: .center) {
                                
                                ColorCardView()
                                    .padding(.top, 20)
                                
                                Spacer()
                            }
                            .tag(0)

                            VStack(alignment: .center) {
                                matchView
                                    .padding(.top, 20)

                                Spacer()
                            }
                            .tag(1)

                            VStack(alignment: .center) {
                                accessibilityView
                                    .padding(.top, 20)

                                Spacer()
                            }
                            .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: currentPage) { oldValue, newValue in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedMode = CameraMode.allCases[newValue]
                            }
                        }
                        .onChange(of: selectedMode) { oldValue, newValue in
                            if let index = CameraMode.allCases.firstIndex(where: { $0 == newValue }) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage = index
                                }
                            }
                        }

                        // rearCameraSelectorView
                        //    .padding(.bottom, 8)

                        VStack(spacing: 15) {
                            modeSelectorView
                                .padding(.bottom, 5)

                            BottomBarView()
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

                        ForEach(Array(CameraMode.allCases.enumerated()), id: \.element.id) { index, mode in
                            VStack(spacing: 8) {
                                Text("\(mode.localizedName)")
                                    .font(.system(size: 16))
                                    .fontWeight(selectedMode == mode ? .bold : .regular)
                                    .foregroundColor(selectedMode == mode ? .white : .gray)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .frame(width: 120)

                                Rectangle()
                                    .frame(width: 40, height: 3)
                                    .foregroundColor(selectedMode == mode ? .white : .clear)
                            }
                            .id(mode)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedMode = mode
                                    currentPage = index
                                }
                            }
                        }

                        Spacer()
                            .frame(width: totalWidth / 2 - 50)
                    }
                }
                .onChange(of: selectedMode) { oldValue, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        proxy.scrollTo(selectedMode, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.top, 10)
    }

    var matchView: some View {
        VStack(spacing: 10) {
            Text("Match Mode")
                .foregroundColor(.white)
                .font(.headline)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 300, height: 90)
                .overlay(
                    Text("You can match colors here")
                        .foregroundColor(.white)
                )
        }
    }

    var accessibilityView: some View {
        VStack(spacing: 10) {
            Text("Accessibility View")
                .foregroundColor(.white)
                .font(.headline)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 300, height: 90)
                .overlay(
                    Text("Color accessibility details will appear here")
                        .foregroundColor(.white)
                )
        }
    }
}

#Preview {
    CameraUI()
        .environmentObject(PreviewCameraModel())
}
