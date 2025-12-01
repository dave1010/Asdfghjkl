import Foundation
#if os(macOS)
import AppKit
import CoreGraphics
#endif

public final class InputManager {
    private let overlayController: OverlayController
    private var commandRecognizer = CommandTapRecognizer()
    #if os(macOS)
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var commandKeyIsDown = false
    #endif
    public var onToggle: (() -> Void)?

    public init(overlayController: OverlayController) {
        self.overlayController = overlayController
    }

    public func start() {
        #if os(macOS)
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<InputManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            Task { @MainActor in
                InputManager.presentMissingPermissionsAlert()
            }
            return
        }

        self.eventTap = eventTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        #else
        print("InputManager stub active (non-macOS environment)")
        #endif
    }

    public func stop() {
        #if os(macOS)
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        #endif
    }

    public func handleCommandDown() {
        commandRecognizer.handleCommandDown()
    }

    public func handleCommandUp() {
        commandRecognizer.handleCommandUp { [weak self] in
            self?.onToggle?()
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

    public func handleMiddleClick() {
        overlayController.middleClick()
    }

    public func handleRightClick() {
        overlayController.rightClick()
    }

    public func cancelOverlay() {
        overlayController.cancel()
    }

    /// Handles a key down event, performing refinement and click/cancel commands when the overlay is active.
    /// - Parameters:
    ///   - key: The pressed character.
    ///   - commandActive: Whether the Command modifier is currently held down.
    /// - Returns: `true` if the event was consumed by the overlay controller, `false` otherwise.
    @discardableResult
    public func handleKeyDown(_ key: Character, commandActive: Bool = false) -> Bool {
        if commandActive {
            markCommandAsModifier()
        }

        guard overlayController.isActive else { return false }

        if key == "\u{1b}" { // Escape
            cancelOverlay()
            return true
        }

        if key == " " { // Space
            handleSpacebarClick()
            return true
        }

        if key == "'" { // Apostrophe for middle click
            handleMiddleClick()
            return true
        }

        if key == "\\" { // Backslash for right click
            handleRightClick()
            return true
        }
        
        if key == "\u{7f}" { // Backspace/Delete
            return overlayController.zoomOut()
        }

        return handleKeyPress(key) != nil
    }

    #if os(macOS)
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        case .flagsChanged:
            let commandIsDown = event.flags.contains(.maskCommand)
            if commandIsDown && !commandKeyIsDown {
                handleCommandDown()
            } else if !commandIsDown && commandKeyIsDown {
                handleCommandUp()
            }
            commandKeyIsDown = commandIsDown
        case .keyDown:
            // Handle delete/backspace by keycode (51) since character extraction may not work reliably
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == 51 && overlayController.isActive {
                let consumed = overlayController.zoomOut()
                if consumed { return nil }
            }
            
            // Handle arrow keys by keycode when overlay is active
            if overlayController.isActive {
                let consumed = handleArrowKey(keyCode: keyCode)
                if consumed { return nil }
            }
            
            if let character = character(from: event) {
                let consumed = handleKeyDown(character, commandActive: commandKeyIsDown)
                if consumed { return nil }
            } else if commandKeyIsDown {
                markCommandAsModifier()
            }
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }
    
    private func handleArrowKey(keyCode: Int64) -> Bool {
        let direction: OverlayController.ArrowDirection?
        switch keyCode {
        case 126: // Up arrow
            direction = .up
        case 125: // Down arrow
            direction = .down
        case 123: // Left arrow
            direction = .left
        case 124: // Right arrow
            direction = .right
        default:
            return false
        }
        
        if let dir = direction {
            return overlayController.moveSelection(dir)
        }
        return false
    }

    private func character(from event: CGEvent) -> Character? {
        var length: Int = 0
        var buffer = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &length, unicodeString: &buffer)
        guard length > 0 else { return nil }
        return Character(String(utf16CodeUnits: buffer, count: length))
    }

    @MainActor
    private static func presentMissingPermissionsAlert() {
        let alert = NSAlert()
        alert.messageText = "Enable Input Monitoring and Accessibility"
        alert.informativeText = "Asdfghjkl needs Input Monitoring and Accessibility permissions to listen for the Cmd double-tap. Open System Settings > Privacy & Security, add Asdfghjkl under each section, then restart the app."
        alert.addButton(withTitle: "Open Input Monitoring")
        alert.addButton(withTitle: "OK")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    #endif
}
