//
//  MatchModeViewModel.swift
//  ColorSense
//
//  Created by Justin Wells on 4/22/25.
//

import SwiftUICore

@MainActor
    @Observable
    class MatchModeViewModel: ObservableObject {
        var selectedColorBox: Int = 1
        var color1: Color? = nil
        var color2: Color? = nil
        var isSwitchingBoxes = false

        func toggleSelectedColorBox() {
            if selectedColorBox == 1 {
                withAnimation {
                    selectedColorBox = 2
                }
            } else {
                withAnimation {
                    selectedColorBox = 1
                }
            }
        }
    }
