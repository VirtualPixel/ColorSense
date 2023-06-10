//
//  PalletView.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import SwiftUI

struct PalletView: View {
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        Text("Pallet View")
    }
}

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PalletView()
    }
}
