//
//  CameraModeManager.swift
//  ColorSense
//
//  Created by Justin Wells on 4/21/25.
//

import Foundation

@Observable
class CameraModeManager {
    private let modes: [any CameraModeProtocol] = [
        IdentifyMode(),
        MatchMode(),
        AccessibilityMode()
    ]

    var currentModeIndex: Int = 0

    var currentMode: any CameraModeProtocol {
        modes[currentModeIndex]
    }

    var availableModes: [any CameraModeProtocol] {
        modes
    }

    func switchTo(mode: Int) {
        guard mode >= 0 && mode < modes.count else { return }
        currentModeIndex = mode
    }

    func nextMode() {
        currentModeIndex = (currentModeIndex + 1) % modes.count
    }

    func previousMode() {
        currentModeIndex = (currentModeIndex - 1 + modes.count) % modes.count
    }
}
