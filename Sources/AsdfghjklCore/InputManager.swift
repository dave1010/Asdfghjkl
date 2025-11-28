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
            print("Failed to create CGEvent tap; missing permissions?")
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

    private func character(from event: CGEvent) -> Character? {
        var length: Int = 0
        var buffer = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &length, unicodeString: &buffer)
        guard length > 0 else { return nil }
        return Character(String(utf16CodeUnits: buffer, count: length))
    }
    #endif
}
