//
//  FocusCircleView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct FocusCircleView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    
    var body: some View {
        createFocusButton()
    }
    
    private func createFocusButton() -> some View {
        Circle()
            .strokeBorder(.white, lineWidth: (cameraFeed.region > 20 ? 3 : cameraFeed.region * 0.15))
            .frame(width: cameraFeed.region, height: cameraFeed.region)
    }
}

struct FocusCircleView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        FocusCircleView()
            .environmentObject(cameraFeed)
    }
}
