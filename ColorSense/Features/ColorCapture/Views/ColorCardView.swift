//
//  ColorCardView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorCardView: View {
    @EnvironmentObject private var camera: CameraModel
    @State private var isAddingColor = false
    @State private var simpleName = "The Geothermal blue"
    @State private var exactName = "Blue"
    let isDisabled: Bool

    var body: some View {
        HStack {
            displayColorCard()
            .buttonStyle(.plain)
            .sheet(isPresented: $isAddingColor) {
                PaletteListView(colorToAdd: camera.dominantColor?.toHex())
                    .onAppear {
                        camera.isPausingColorProcessing = true
                    }
            }
        }
        .onChange(of: camera.dominantColor) {
            if let dominantColor = camera.dominantColor?.uiColor {
                self.simpleName = dominantColor.simpleName
                self.exactName = dominantColor.exactName
            }
        }
    }
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    private func createColorCircle() -> some View {
        HStack {
            Spacer()
            Circle()
                .foregroundStyle(camera.dominantColor ?? .black)
            Divider()
        }
    }

    private func createColorText(geometry: GeometryProxy) -> some View {
        VStack {
            Text("\(exactName)")
                .font(.system(size: geometry.size.width * 0.04))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Text("\(simpleName) Family")
                .font(.system(size: geometry.size.width * 0.04).bold())
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
    }

    private func rightThird() -> some View {
        Group {
            if !isDisabled {
                Button(action: { isAddingColor = true }) {
                    Image(systemName: "bookmark")
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.3))
                        .cornerRadius(6)
                        .foregroundStyle(.white)
                }
            } else {
                Text("Selected\nColor")
                    .minimumScaleFactor(0.2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .bold()
                    .foregroundStyle(.white)
            }
        }
    }

    private func colorCard() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .frame(width: 300, height: 90)
            .overlay(
                GeometryReader { geo in
                    HStack {
                        createColorCircle()
                        createColorText(geometry: geo)
                            .frame(width: 110, height: 100)
                            .padding()

                        Spacer()

                        rightThird()

                        Spacer()
                    }
                    .position(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY)
                }
            )
            .background(isDisabled ? .ultraThickMaterial : .thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func displayColorCard() -> some View {
        Group {
            if isDisabled {
                colorCard()
            } else {
                NavigationLink {
                    ColorDetailView(color: camera.dominantColor ?? .blue)
                } label: {
                    colorCard()
                }
            }
        }
    }
}

struct ColorCardView_Previews: PreviewProvider {
    static var previews: some View {
        ColorCardView()
            // .environmentObject(PreviewCameraModel())
    }
}
