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
    private var overlayWindows: [OverlayWindowController] = []
    private var screenRects: [GridRect] = [.defaultScreen]
    private var screenObserver: NSObjectProtocol?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        overlayController = OverlayController(
            gridLayout: gridLayout,
            screenBoundsProvider: { [weak self] in
                guard let self else { return [.defaultScreen] }
                return self.screenRects
            }
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
        inputManager.start()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "⌨️"
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(
            title: "About Asdfghjkl",
            action: #selector(showAbout),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
        
        statusItem?.menu = menu
    }
    
    @objc private func showAbout() {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        inputManager.stop()
        overlayWindows.forEach { $0.hide() }
    }

    private func handleStateChange(_ state: OverlayState) {
        overlayVisualModel.apply(state: state)
        updateWindowVisibility(for: state)
    }
    
    private func updateWindowVisibility(for state: OverlayState) {
        if state.isActive {
            overlayWindows.forEach { $0.show() }
        } else {
            overlayWindows.forEach { $0.hide() }
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
    }
}
#endif
