//
//  ColorCardView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorCardView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    @State private var isAddingColor = false
    
    var body: some View {
        HStack {
            NavigationLink {
                ColorDetailView(color: cameraFeed.dominantColor ?? .blue)
            } label: {
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
                                
                                Button(action: { isAddingColor = true }) {
                                    Image(systemName: "plus")
                                        .padding()
                                        .foregroundColor(.primary)
                                        .background(.ultraThinMaterial.opacity(0.3))
                                        .cornerRadius(6)
                                }
                                Spacer()
                            }
                            .position(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY)
                        }
                    )
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isAddingColor) {
                PaletteListView(colorToAdd: cameraFeed.dominantColor?.toHex())
            }
        }
    }
    
    private func createColorCircle() -> some View {
        HStack {
            Spacer()
            Circle()
                .foregroundColor(cameraFeed.dominantColor ?? .black)
            Divider()
        }
    }
    
    private func createColorText(geometry: GeometryProxy) -> some View {
            VStack {
                Text("\(cameraFeed.exactName ?? "The Geothermal blue")")
                    .font(.system(size: geometry.size.width * 0.04))
                    .minimumScaleFactor(0.5)
                Text("\(cameraFeed.simpleName ?? "Blue") Family")
                    .font(.system(size: geometry.size.width * 0.04).bold())  // Adjust as per your needs
                    .minimumScaleFactor(0.5)  // Allows the text to scale down to 50% of its original size
            }
        }
}

struct ColorCardView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ColorCardView()
            .environmentObject(cameraFeed)
    }
}
