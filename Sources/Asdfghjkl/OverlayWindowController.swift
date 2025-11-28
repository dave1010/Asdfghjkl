import Foundation
#if os(macOS)
import SwiftUI
import AppKit
import AsdfghjklCore

final class OverlayWindowController {
    private let screen: NSScreen
    private let model: OverlayVisualModel
    private let gridLayout: GridLayout
    private var window: NSWindow?

    init(screen: NSScreen, model: OverlayVisualModel, gridLayout: GridLayout) {
        self.screen = screen
        self.model = model
        self.gridLayout = gridLayout
    }

    func show() {
        if window == nil {
            window = makeWindow()
        }
        window?.setFrame(screen.frame, display: true)
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        let overlayView = OverlayGridView(model: model, screen: screen, gridLayout: gridLayout)
        let hosting = NSHostingController(rootView: overlayView)
        let window = NSWindow(contentViewController: hosting)
        window.setFrame(screen.frame, display: true)
        window.styleMask = [.borderless]
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        return window
    }
}
#endif
