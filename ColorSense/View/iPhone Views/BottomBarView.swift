//
//  BottomBarView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed

    var body: some View {
        HStack {
            Spacer()
            swatchPaletteButton()
            Spacer()
            pauseProcessingButton()
            Spacer()
            cameraSwapButton()
            Spacer()
        }
        .background(.black)
    }

    private func swatchPaletteButton() -> some View {
        NavigationLink(destination: PaletteListView(colorToAdd: cameraFeed.dominantColor?.toHex())) {
            Image(systemName: "swatchpalette.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
        }
    }

    private func pauseProcessingButton() -> some View {
        Button {
            withAnimation {
                cameraFeed.pauseProcessing.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: 4)
                    .frame(width: 70, height: 70)
                    .foregroundColor(.white)

                Circle()
                    .frame(width: 55, height: 55)
                    .foregroundColor(.white)
                    .overlay(
                        Image(systemName: "pause.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50)
                            .opacity(cameraFeed.pauseProcessing ? 1.0 : 0.0)
                            .foregroundColor(.black)
                            .padding()
                    )
            }
        }
        .padding(.vertical)
    }

    private func cameraSwapButton() -> some View {
        Button {
            cameraFeed.swapCamera()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .padding(7)
                .background(
                    .thinMaterial
                )
                .clipShape(Circle())
        }
        .frame(width: 40, height: 40)
    }
}

struct BottomBarView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        BottomBarView()
            .environmentObject(cameraFeed)
    }
}
