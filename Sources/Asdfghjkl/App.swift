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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlayVisualModel = OverlayVisualModel()
    private let gridLayout = GridLayout()
    private var overlayController: OverlayController!
    private var inputManager: InputManager!
    private var zoomController: ZoomController!
    private var overlayWindows: [OverlayWindowController] = []
    private var zoomWindow: ZoomWindowController?
    private var activeScreenRect: GridRect = .defaultScreen
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let snapshotProvider = CGWindowListSnapshotProvider()
        zoomController = ZoomController(initialRect: .defaultScreen, snapshotProvider: snapshotProvider)
        overlayController = OverlayController(
            gridLayout: gridLayout,
            screenBoundsProvider: { [weak self] in
                guard let self else { return .defaultScreen }
                return self.activeScreenRect
            },
            zoomController: zoomController
        )

        overlayController.stateDidChange = { [weak self] state in
            self?.handleStateChange(state)
        }

        inputManager = InputManager(overlayController: overlayController)
        inputManager.onToggle = { [weak self] in
            self?.prepareActiveScreen()
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }

        rebuildOverlayWindows()
        zoomWindow = ZoomWindowController(zoomController: zoomController)
        prepareActiveScreen()
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
        DispatchQueue.main.async {
            self.overlayVisualModel.apply(state: state)
            if state.isActive {
                self.overlayWindows.forEach { $0.show() }
                self.zoomWindow?.show()
            } else {
                self.overlayWindows.forEach { $0.hide() }
                self.zoomWindow?.hide()
            }
        }
    }

    private func prepareActiveScreen() {
        guard let screen = screenUnderCursor() ?? NSScreen.main else { return }
        activeScreenRect = gridRect(for: screen)
    }

    private func rebuildOverlayWindows() {
        overlayWindows.forEach { $0.hide() }
        overlayWindows = NSScreen.screens.map {
            OverlayWindowController(screen: $0, model: overlayVisualModel, gridLayout: gridLayout)
        }

        if overlayController.isActive {
            overlayWindows.forEach { $0.show() }
        }
    }

    private func handleScreenChange() {
        rebuildOverlayWindows()
        prepareActiveScreen()
    }

    private func screenUnderCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
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
