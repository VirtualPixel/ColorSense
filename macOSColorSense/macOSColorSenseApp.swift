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
        popover.contentSize = NSSize(width: 360, height: 360)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
}
