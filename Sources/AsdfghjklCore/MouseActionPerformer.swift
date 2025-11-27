import Foundation
#if os(macOS)
import CoreGraphics
#endif

public protocol MouseActionPerforming {
    func moveAndClick(at point: GridPoint)
}

public struct SystemMouseActionPerformer: MouseActionPerforming {
    public init() {}

    public func moveAndClick(at point: GridPoint) {
        #if os(macOS)
        let target = CGPoint(x: point.x, y: point.y)
        CGWarpMouseCursorPosition(target)

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
}
