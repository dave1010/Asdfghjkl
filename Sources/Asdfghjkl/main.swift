import Foundation
import AsdfghjklCore

@main
struct AsdfghjklApp {
    static func main() {
        let overlayController = OverlayController()
        let inputManager = InputManager(overlayController: overlayController)

        // This is a placeholder entry point for the macOS app. In a full GUI build
        // this will be replaced by the AppKit/SwiftUI lifecycle that installs the
        // CGEvent tap described in PLAN.md. For now we set up the scaffolding
        // objects so they are ready for integration.
        inputManager.start()

        // Simulate a minimal run loop in debug contexts to keep the binary alive
        // long enough to test the state machine logic without UI.
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
