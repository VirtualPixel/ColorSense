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
                    .frame(width: 330, height: 110)
                    .overlay(
                        HStack {
                            createColorCircle()
                            createColorText()
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
                    )
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .sheet(isPresented: $isAddingColor) {
                PalletListView(colorToAdd: cameraFeed.dominantColor?.toHex())
            }
        }
    }
    
    private func createColorCircle() -> some View {
        HStack {
            Spacer()
            Circle()
                .foregroundColor(cameraFeed.dominantColor ?? .black)
                .frame(width: 65, height: 65)
            Divider()
                .padding(.leading)
        }
    }
    
    private func createColorText() -> some View {
        VStack {
            Text("\(cameraFeed.exactName ?? "")")
                .font(.system(size: 500))
                .minimumScaleFactor(0.01)
                .padding(.top)
            Text("\(cameraFeed.simpleName ?? "") Family")
                .font(.system(size: 500).bold())
                .minimumScaleFactor(0.01)
                .padding(.bottom)
        }
        .padding(.vertical)
    }
}

struct ColorCardView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ColorCardView()
            .environmentObject(cameraFeed)
    }
}
