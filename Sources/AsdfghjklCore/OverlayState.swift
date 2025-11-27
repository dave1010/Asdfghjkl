import Foundation

public struct OverlayState {
    public var isActive: Bool = false
    public var rootRect: GridRect = .defaultScreen
    public var currentRect: GridRect = .defaultScreen

    public var targetPoint: GridPoint {
        GridPoint(x: currentRect.midX, y: currentRect.midY)
    }

    public mutating func reset(rect: GridRect) {
        rootRect = rect
        currentRect = rect
        isActive = false
    }
}
