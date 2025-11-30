import Foundation
#if os(macOS)
import SwiftUI
import AppKit
import AsdfghjklCore

@MainActor
final class OverlayWindowController {
    private let screen: NSScreen
    private let model: OverlayVisualModel
    private let gridSlice: GridSlice
    private var window: NSWindow?
    
    var windowID: CGWindowID? {
        guard let window else { return nil }
        let windowNumber = window.windowNumber
        return windowNumber >= 0 ? CGWindowID(windowNumber) : nil
    }

    init(screen: NSScreen, model: OverlayVisualModel, gridSlice: GridSlice) {
        self.screen = screen
        self.model = model
        self.gridSlice = gridSlice
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
        let overlayView = OverlayGridView(model: model, screen: screen, gridSlice: gridSlice)
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
