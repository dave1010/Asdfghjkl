import Foundation

public final class InputManager {
    private let overlayController: OverlayController
    private var commandRecognizer = CommandTapRecognizer()

    public init(overlayController: OverlayController) {
        self.overlayController = overlayController
    }

    public func start() {
        // Placeholder for CGEvent tap setup. The real implementation will listen for
        // .flagsChanged and .keyDown events to drive the recognizer and overlay.
        #if os(macOS)
        print("InputManager ready for CGEvent tap installation")
        #else
        print("InputManager stub active (non-macOS environment)")
        #endif
    }

    public func handleCommandDown() {
        commandRecognizer.handleCommandDown()
    }

    public func handleCommandUp() {
        commandRecognizer.handleCommandUp { [weak self] in
            self?.overlayController.toggle()
        }
    }

    public func markCommandAsModifier() {
        commandRecognizer.handleCommandModifierUse()
    }

    @discardableResult
    public func handleKeyPress(_ key: Character) -> GridRect? {
        overlayController.handleKey(key)
    }

    public func handleSpacebarClick() {
        overlayController.click()
    }

    public func cancelOverlay() {
        overlayController.cancel()
    }
}
