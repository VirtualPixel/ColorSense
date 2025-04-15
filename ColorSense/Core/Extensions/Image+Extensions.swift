//
//  Image.swift
//  ColorSense
//
//  Created by Justin Wells on 4/11/25.
//

import SwiftUI

extension Image {
    var iconStyle: some View {
        self.resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white)
            .padding(3)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .frame(width: 32, height: 32)
    }
}
