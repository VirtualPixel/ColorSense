//
//  ColorCardView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorCardView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    
    var body: some View {
        NavigationLink {
            ColorDetailView(color: cameraFeed.dominantColor ?? .blue)
        } label: {
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 300, height: 110)
                .overlay(
                    HStack {
                        createColorCircle()
                        createColorText()
                            .frame(width: 110, height: 100)
                            .padding()
                    }
                )
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private func createColorCircle() -> some View {
        HStack {
            Circle()
                .foregroundColor(cameraFeed.dominantColor ?? .black)
                .frame(width: 75, height: 75)
            Divider()
                .padding()
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
