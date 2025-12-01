import Foundation
#if os(macOS)
import CoreGraphics
#endif

public protocol MouseActionPerforming {
    func moveCursor(to point: GridPoint)
    func click(at point: GridPoint)
    func middleClick(at point: GridPoint)
    func rightClick(at point: GridPoint)
}

public struct SystemMouseActionPerformer: MouseActionPerforming {
    public init() {}

    public func moveCursor(to point: GridPoint) {
        #if os(macOS)
        let target = CGPoint(x: point.x, y: point.y)
        CGWarpMouseCursorPosition(target)
        #else
        print("SystemMouseActionPerformer: move to (\(point.x), \(point.y))")
        #endif
    }

    public func click(at point: GridPoint) {
        #if os(macOS)
        let target = CGPoint(x: point.x, y: point.y)

        if let down = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: target,
            mouseButton: .left
        ) {
            down.post(tap: .cghidEventTap)
        }

        if let up = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: target,
            mouseButton: .left
        ) {
            up.post(tap: .cghidEventTap)
        }
        #else
        print("SystemMouseActionPerformer: click at (\(point.x), \(point.y))")
        #endif
    }

    public func middleClick(at point: GridPoint) {
        #if os(macOS)
        let target = CGPoint(x: point.x, y: point.y)

        if let down = CGEvent(
            mouseEventSource: nil,
            mouseType: .otherMouseDown,
            mouseCursorPosition: target,
            mouseButton: .center
        ) {
            down.post(tap: .cghidEventTap)
        }

        if let up = CGEvent(
            mouseEventSource: nil,
            mouseType: .otherMouseUp,
            mouseCursorPosition: target,
            mouseButton: .center
        ) {
            up.post(tap: .cghidEventTap)
        }
        #else
        print("SystemMouseActionPerformer: middle click at (\(point.x), \(point.y))")
        #endif
    }

    public func rightClick(at point: GridPoint) {
        #if os(macOS)
        let target = CGPoint(x: point.x, y: point.y)

        if let down = CGEvent(
            mouseEventSource: nil,
            mouseType: .rightMouseDown,
            mouseCursorPosition: target,
            mouseButton: .right
        ) {
            down.post(tap: .cghidEventTap)
        }

        if let up = CGEvent(
            mouseEventSource: nil,
            mouseType: .rightMouseUp,
            mouseCursorPosition: target,
            mouseButton: .right
        ) {
            up.post(tap: .cghidEventTap)
        }
        #else
        print("SystemMouseActionPerformer: right click at (\(point.x), \(point.y))")
        #endif
    }
}

public extension MouseActionPerforming {
    func moveAndClick(at point: GridPoint) {
        moveCursor(to: point)
        click(at: point)
    }
}
