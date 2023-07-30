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
        VStack {
            GeometryReader { geo in
                VStack {
                    HStack {
                        Button {
                            cameraFeed.isFlashOn.toggle()
                        } label: {
                            Image(systemName: "bolt.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(
                                    .yellow.opacity(cameraFeed.isFlashOn ? 1.0 : 0.0)
                                )
                                .background(
                                    .thinMaterial
                                )
                                .clipShape(Circle())
                                .frame(width: 32, height: 32)
                        }
                        .padding(.leading, 30)
                        
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: 40)
                    .background(.black)
                    .padding(.bottom, 5)
                
                    ColorCardView()
                    Spacer()
                }
            }
        }
    }
}



struct TopBarView_Previews: PreviewProvider {
    static let cameraFeed = CameraFeed()
    
    static var previews: some View {
        TopBarView()
            .environmentObject(cameraFeed)
    }
}
