//
//  FocusCircleView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct FocusCircleView: View {
    @EnvironmentObject var camera: CameraModel
    var bounds: CGRect

    var body: some View {
        Circle()
            .strokeBorder(.white, lineWidth: camera.colorRegion * 0.15)
            .frame(width: camera.colorRegion, height: camera.colorRegion)
            .position(x: bounds.midX, y: bounds.midY)
    }
}

struct FocusCircleView_Previews: PreviewProvider {
    static var previews: some View {
        FocusCircleView(bounds: CGRect(x: 0, y: 0, width: 0, height: 0))
            .environmentObject(PreviewCameraModel())
    }
}
