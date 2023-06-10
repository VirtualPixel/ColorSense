//
//  TopBarView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct TopBarView: View {
    @EnvironmentObject private var cameraFeed: CameraFeed
    
    var body: some View {
        HStack {
            Button {
                cameraFeed.isFlashOn.toggle()
            } label: {
                Image(systemName: "bolt.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        .yellow.opacity(cameraFeed.isFlashOn ? 1.0 : 0.0)
                    )
                    .background(
                        .thinMaterial
                    )
                    .clipShape(Circle())
            }
            .frame(width: 32, height: 32)
            .padding(.horizontal, 50)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background(.black.opacity(0.9))
    }
}

struct TopBarView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        TopBarView()
            .environmentObject(cameraFeed)
    }
}
