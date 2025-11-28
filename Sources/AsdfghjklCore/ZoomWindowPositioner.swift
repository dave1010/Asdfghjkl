import Foundation

public enum ZoomWindowPositioner {
    public static func clampedOrigin(
        target: GridPoint,
        windowSize: GridPoint,
        bounds: GridRect,
        padding: Double = 8
    ) -> GridPoint {
        let halfWidth = windowSize.x / 2
        let halfHeight = windowSize.y / 2

        let desiredX = target.x - halfWidth
        let desiredY = target.y - halfHeight

        let minX = bounds.minX + padding
        let minY = bounds.minY + padding
        let maxX = bounds.minX + bounds.width - windowSize.x - padding
        let maxY = bounds.minY + bounds.height - windowSize.y - padding

        let clampedX = max(minX, min(desiredX, maxX))
        let clampedY = max(minY, min(desiredY, maxY))

        return GridPoint(x: clampedX, y: clampedY)
    }
}
