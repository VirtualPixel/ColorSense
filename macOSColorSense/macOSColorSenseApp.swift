//
//  macOSColorSenseApp.swift
//  macOSColorSense
//
//  Created by Justin Wells on 8/3/23.
//

import SwiftUI

@main
struct macOSColorSenseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            ContentView()
        }
        .modelContainer(
            for: [
                Pallet.self,
                ColorStructure.self
            ]
        )
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover = NSPopover.init()
    var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
        popover.contentSize = NSSize(width: 512, height: 512)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        statusBar = StatusBarController.init(popover)
    }
}

class StatusBarController {
    var popover: NSPopover
    var statusBar: NSStatusItem

    init(_ popover: NSPopover) {
        self.popover = popover
        statusBar = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = statusBar.button {
            if let image = NSImage(named: "monochrome") {
                image.size = NSSize(width: 19, height: 19)
                button.image = image
            }
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusBar.button {
            let screenRect = button.window!.screen!.frame
            let buttonRect = button.frame
            let buttonWindowRect = button.window!.convertToScreen(buttonRect)
            let posX = buttonWindowRect.origin.x + (buttonWindowRect.width / 2) - (popover.contentSize.width / 2)
            let posY = screenRect.height - buttonWindowRect.origin.y - buttonWindowRect.height
            popover.show(relativeTo: NSRect(x: posX, y: posY, width: 0, height: 0), of: button.window!.contentView!, preferredEdge: NSRectEdge.minY)
        }
    }


    func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
}
