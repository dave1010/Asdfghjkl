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
    private var latestRect: GridRect
    private let defaultWindowSize = NSSize(width: 360, height: 320)

    init(zoomController: ZoomController) {
        self.zoomController = zoomController
        self.latestRect = zoomController.observedRect
        cancellable = zoomController.$observedRect
            .receive(on: RunLoop.main)
            .sink { [weak self] rect in
                self?.latestRect = rect
                self?.positionWindow(for: rect)
            }
    }

    func show() {
        if window == nil {
            window = makeWindow()
        }
        window?.orderFrontRegardless()
        positionWindow(for: latestRect)
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
        window.setContentSize(defaultWindowSize)
        return window
    }

    private func positionWindow(for rect: GridRect) {
        guard let window else { return }
        let targetPoint = GridPoint(x: rect.midX, y: rect.midY)

        guard let screen = screen(containing: targetPoint) else { return }
        let visibleFrame = screen.visibleFrame
        let bounds = GridRect(
            x: visibleFrame.origin.x,
            y: visibleFrame.origin.y,
            width: visibleFrame.width,
            height: visibleFrame.height
        )

        let origin = ZoomWindowPositioner.clampedOrigin(
            target: targetPoint,
            windowSize: GridPoint(x: window.frame.width, y: window.frame.height),
            bounds: bounds
        )

        window.setFrameOrigin(NSPoint(x: origin.x, y: origin.y))
    }

    private func screen(containing point: GridPoint) -> NSScreen? {
        let cocoaPoint = NSPoint(x: point.x, y: point.y)
        return NSScreen.screens.first { NSMouseInRect(cocoaPoint, $0.frame, false) } ?? NSScreen.main
    }
}
#endif
