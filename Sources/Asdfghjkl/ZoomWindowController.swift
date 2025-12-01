import Foundation
#if os(macOS)
import SwiftUI
import AppKit
import Combine
import AsdfghjklCore

/// Manages a borderless window that displays the zoom preview.
/// The window fills the entire screen containing the target point.
@MainActor
final class ZoomWindowController {
    private let zoomController: ZoomController
    private var window: NSWindow?
    private var cancellable: AnyCancellable?

    init(zoomController: ZoomController) {
        self.zoomController = zoomController
        self.cancellable = zoomController.$targetRect
            .receive(on: RunLoop.main)
            .sink { [weak self] rect in
                self?.updateWindowFrame(for: rect)
            }
    }

    func show() {
        if window == nil {
            window = createWindow()
        }
        updateWindowFrame(for: zoomController.targetRect)
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func createWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: ZoomPreviewView(zoomController: zoomController))
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.borderless]
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrame(.zero, display: false)
        return window
    }

    private func updateWindowFrame(for targetRect: GridRect) {
        guard let window else { return }
        guard let screen = screenContaining(targetRect.center) else { return }
        
        // Window fills entire screen containing the target
        window.setFrame(screen.frame, display: true, animate: false)
    }

    private func screenContaining(_ point: GridPoint) -> NSScreen? {
        let nsPoint = NSPoint(x: point.x, y: point.y)
        return NSScreen.screens.first { NSMouseInRect(nsPoint, $0.frame, false) } ?? NSScreen.main
    }
}
#endif
