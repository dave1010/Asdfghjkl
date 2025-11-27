import Foundation

public final class ZoomController {
    public private(set) var observedRect: GridRect

    public init(initialRect: GridRect = .defaultScreen) {
        self.observedRect = initialRect
    }

    public func update(rect: GridRect) {
        observedRect = rect
        // TODO: Render a magnified snapshot of the rect once hooked into AppKit.
    }
}
