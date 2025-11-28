import Foundation
#if os(macOS)
import SwiftUI
import AppKit
import AsdfghjklCore

final class ZoomWindowController {
    private let zoomController: ZoomController
    private var window: NSWindow?

    init(zoomController: ZoomController) {
        self.zoomController = zoomController
    }

    func show() {
        if window == nil {
            window = makeWindow()
        }
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: ZoomPreviewView(zoomController: zoomController))
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.borderless]
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setContentSize(NSSize(width: 240, height: 180))
        window.center()
        return window
    }
}
#endif
