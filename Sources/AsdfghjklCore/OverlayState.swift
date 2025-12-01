import Foundation

public struct OverlayState: Sendable {
    public var isActive: Bool = false
    public var rootRect: GridRect = .defaultScreen
    public var currentRect: GridRect = .defaultScreen
    public var gridRect: GridRect = .defaultScreen
    public var isZoomVisible: Bool = false
    public var isGridVisible: Bool = true

    public var targetPoint: GridPoint {
        GridPoint(x: currentRect.midX, y: currentRect.midY)
    }

    public mutating func reset(rect: GridRect) {
        rootRect = rect
        currentRect = rect
        gridRect = rect
        isZoomVisible = false
        isGridVisible = true
        isActive = false
    }
}
