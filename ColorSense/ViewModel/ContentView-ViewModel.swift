//
//  ContentView-ViewModel.swift
//  ColorSense
//
//  Created by Justin Wells on 5/8/23.
//

import Foundation

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var lastInteractionTime = Date()
        @Published var showingSizeSlider = false
        @Published var showingPaletteView = false
    }
}
