//
//  ColorDetailView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct ColorDetailView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    @ObservedObject private var viewModel: ViewModel
    
    var body: some View {
        VStack {
            Circle()
                .foregroundColor(viewModel.color)
                .padding(.horizontal, 50)
                .padding(.top)
            Text("\(UIColor(viewModel.color).exactName)")
                .font(.title)
            Text("\(UIColor(viewModel.color).simpleName) Family")
                .font(.title3)
                .foregroundColor(.secondary)
            Spacer()
            Text("RGB: R: \(viewModel.rbg.red) G: \(viewModel.rbg.green) B: \(viewModel.rbg.blue)")
                .padding()
            Text("Hex: \(viewModel.hex)")
                .padding()
            Text("HSL: Hue: \(viewModel.hsl.hue) Saturation: \(viewModel.hsl.saturation) Lightness: \(viewModel.hsl.lightness)")
                .padding()
            Text("CMYK: Cyan: \(viewModel.cmyk.cyan) Magenta: \(viewModel.cmyk.magenta) Yellow: \(viewModel.cmyk.yellow) Key: \(viewModel.cmyk.key)")
            
        }
        .onAppear {
            cameraFeed.stop()
        }
        .onDisappear {
            cameraFeed.start()
        }
    }
    
    init(color: Color) {
        _viewModel = ObservedObject(initialValue: ViewModel(color: color))
    }
}

struct ColorDetailView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        ColorDetailView(color: .blue)
            .environmentObject(cameraFeed)
    }
}
