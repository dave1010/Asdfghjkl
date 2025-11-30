import Foundation
#if os(macOS)
import SwiftUI
import AppKit
import Combine
import AsdfghjklCore

@MainActor
final class ZoomWindowController {
    private let zoomController: ZoomController
    private var window: NSWindow?
    private var cancellable: AnyCancellable?
    private var latestTargetRect: GridRect

    init(zoomController: ZoomController) {
        self.zoomController = zoomController
        self.latestTargetRect = zoomController.targetRect
        cancellable = zoomController.$targetRect
            .receive(on: RunLoop.main)
            .sink { [weak self] rect in
                self?.latestTargetRect = rect
                self?.updateWindowPosition(for: rect)
            }
    }

    func show() {
        if window == nil {
            window = makeWindow()
        }
        window?.orderFrontRegardless()
        updateWindowPosition(for: latestTargetRect)
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
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrame(.zero, display: false)
        return window
    }

    private func updateWindowPosition(for rect: GridRect) {
        guard let window else { return }
        let targetPoint = GridPoint(x: rect.midX, y: rect.midY)

        guard let screen = screen(containing: targetPoint) else { return }
        
        let screenFrame = screen.frame
        
        // The window should always fill the entire screen containing the target
        // The zoom controller's snapshot and transforms are updated by OverlayController
        // which has the correct screen rect from the grid partitioner
        window.setFrame(screenFrame, display: true, animate: false)
    }

    private func screen(containing point: GridPoint) -> NSScreen? {
        let cocoaPoint = NSPoint(x: point.x, y: point.y)
        return NSScreen.screens.first { NSMouseInRect(cocoaPoint, $0.frame, false) } ?? NSScreen.main
    }
}
#endif
