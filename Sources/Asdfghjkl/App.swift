#if os(macOS)
import SwiftUI
import AppKit
import AsdfghjklCore

@main
struct AsdfghjklApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlayVisualModel = OverlayVisualModel()
    private let gridLayout = AsdfghjklCore.GridLayout()
    private var overlayController: OverlayController!
    private var inputManager: InputManager!
    private var zoomController: ZoomController!
    private var overlayWindows: [OverlayWindowController] = []
    private var zoomWindow: ZoomWindowController?
    private var screenRects: [GridRect] = [.defaultScreen]
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let snapshotProvider = CGWindowListSnapshotProvider(
            excludedWindowIDsProvider: { [weak self] in
                self?.overlayWindows.compactMap { $0.windowID } ?? []
            }
        )
        zoomController = ZoomController(initialRect: .defaultScreen, snapshotProvider: snapshotProvider)
        overlayController = OverlayController(
            gridLayout: gridLayout,
            screenBoundsProvider: { [weak self] in
                guard let self else { return [.defaultScreen] }
                return self.screenRects
            },
            zoomController: zoomController
        )

        overlayController.stateDidChange = { [weak self] state in
            Task { @MainActor in
                self?.handleStateChange(state)
            }
        }

        inputManager = InputManager(overlayController: overlayController)
        inputManager.onToggle = { [weak self] in
            Task { @MainActor in
                self?.rebuildOverlayWindows()
            }
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChange()
            }
        }

        rebuildOverlayWindows()
        zoomWindow = ZoomWindowController(zoomController: zoomController)
        inputManager.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        inputManager.stop()
        overlayWindows.forEach { $0.hide() }
        zoomWindow?.hide()
    }

    private func handleStateChange(_ state: OverlayState) {
        overlayVisualModel.apply(state: state)
        updateWindowVisibility(for: state)
    }
    
    private func updateWindowVisibility(for state: OverlayState) {
        if state.isActive {
            overlayWindows.forEach { $0.show() }
            if state.isZoomVisible {
                zoomWindow?.show()
            } else {
                zoomWindow?.hide()
            }
        } else {
            overlayWindows.forEach { $0.hide() }
            zoomWindow?.hide()
        }
    }

    private func rebuildOverlayWindows() {
        overlayWindows.forEach { $0.hide() }
        let screens = NSScreen.screens
        screenRects = screens.map { gridRect(for: $0) }
        let slices = GridPartitioner.slices(for: screenRects, layout: gridLayout)
        let gridSlices = slices.isEmpty ? GridPartitioner.slices(for: [.defaultScreen], layout: gridLayout) : slices

        overlayWindows = zip(screens, gridSlices).map {
            OverlayWindowController(
                screen: $0.0,
                model: overlayVisualModel,
                zoomController: zoomController,
                gridSlice: $0.1
            )
        }

        if overlayController.isActive {
            overlayWindows.forEach { $0.show() }
        }
    }

    private func handleScreenChange() {
        rebuildOverlayWindows()
    }

    private func gridRect(for screen: NSScreen) -> GridRect {
        let frame = screen.frame
        return GridRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height)
    }
}
#else
import Foundation
import AsdfghjklCore

@main
struct AsdfghjklApp {
    static func main() {
        let overlayController = OverlayController()
        let inputManager = InputManager(overlayController: overlayController)
        inputManager.start()

        if ProcessInfo.processInfo.environment["ASDFGHJKL_DEMO"] == "1" {
            runDemo(using: overlayController, inputManager: inputManager)
        }
    }

    private static func runDemo(using overlayController: OverlayController, inputManager: InputManager) {
        print("Asdfghjkl overlay skeleton initialised. Double-tap Cmd to toggle the overlay once event taps are wired up.")
        overlayController.start()
        _ = overlayController.handleKey("q")
        _ = overlayController.handleKey("w")
        if let target = overlayController.targetPoint {
            print("Refined target ready at: (\(target.x), \(target.y))")
        }
        inputManager.cancelOverlay()
    }
}
#endif
