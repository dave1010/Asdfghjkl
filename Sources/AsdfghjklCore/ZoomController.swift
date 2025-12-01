import Foundation
#if canImport(Combine)
import Combine
#else
public protocol ObservableObject {}
#endif

#if os(macOS)
import CoreGraphics

public protocol ZoomSnapshotProviding {
    func capture(screen: GridRect) -> CGImage?
}

public struct CGWindowListSnapshotProvider: ZoomSnapshotProviding {
    private let excludedWindowIDsProvider: (() -> [CGWindowID])?
    
    public init(excludedWindowIDsProvider: (() -> [CGWindowID])? = nil) {
        self.excludedWindowIDsProvider = excludedWindowIDsProvider
    }

    public func capture(screen: GridRect) -> CGImage? {
        let cgRect = CGRect(x: screen.origin.x, y: screen.origin.y, width: screen.size.x, height: screen.size.y)
        
        // If we have window IDs to exclude, capture everything below the topmost excluded window
        // This automatically excludes all windows at or above that level
        if let windowIDs = excludedWindowIDsProvider?(), let topWindowID = windowIDs.first {
            return CGWindowListCreateImage(
                cgRect,
                .optionOnScreenBelowWindow,
                topWindowID,
                [.bestResolution, .boundsIgnoreFraming]
            )
        }
        
        // Fallback to capturing everything on screen
        return CGWindowListCreateImage(
            cgRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        )
    }
}
#endif

/// Controls zoom behavior for the overlay, implementing pinch-to-zoom semantics.
///
/// The zoom controller captures a snapshot of the entire screen and calculates
/// scale and offset transforms to create a pinch-to-zoom effect where the target
/// area appears centered and magnified. This is not a magnifier window but rather
/// scales the entire screen content as if you had zoomed into that portion.
public final class ZoomController: ObservableObject {
    #if canImport(Combine)
    @Published public private(set) var targetRect: GridRect
    @Published public private(set) var screenRect: GridRect
    @Published public private(set) var zoomScale: Double
    @Published public private(set) var zoomOffset: GridPoint
    #if os(macOS)
    @Published public private(set) var latestSnapshot: CGImage?
    #endif
    #else
    public private(set) var targetRect: GridRect
    public private(set) var screenRect: GridRect
    public private(set) var zoomScale: Double
    public private(set) var zoomOffset: GridPoint
    #endif

    #if os(macOS)
    private let snapshotProvider: ZoomSnapshotProviding

    public init(initialRect: GridRect = .defaultScreen, snapshotProvider: ZoomSnapshotProviding? = nil) {
        self.targetRect = initialRect
        self.screenRect = initialRect
        self.zoomScale = 1.0
        self.zoomOffset = GridPoint(x: 0, y: 0)
        self.snapshotProvider = snapshotProvider ?? CGWindowListSnapshotProvider()
    }
    #else
    public init(initialRect: GridRect = .defaultScreen) {
        self.targetRect = initialRect
        self.screenRect = initialRect
        self.zoomScale = 1.0
        self.zoomOffset = GridPoint(x: 0, y: 0)
    }
    #endif

    public func update(targetRect: GridRect, screenRect: GridRect, desiredZoomFactor: Double) {
        self.targetRect = targetRect
        self.screenRect = screenRect
        self.zoomScale = desiredZoomFactor
        self.zoomOffset = calculateZoomOffset()

        let targetCenter = targetCenterInScreenCoordinates()
        print("[ZoomController] Updated zoom")
        print("[ZoomController]   Target rect: \(targetRect)")
        print("[ZoomController]   Screen rect: \(screenRect)")
        print("[ZoomController]   Zoom anchor (target center in screen coords): (\(targetCenter.x), \(targetCenter.y))")
        print("[ZoomController]   Zoom level: \(zoomScale)x")
        print("[ZoomController]   Zoom offset: (\(zoomOffset.x), \(zoomOffset.y))")

        #if os(macOS)
        latestSnapshot = snapshotProvider.capture(screen: screenRect)
        #endif
    }
    
    /// Calculates zoom offset to keep target centered using pinch-to-zoom behavior.
    ///
    /// When scaling from top-left, point (x,y) moves to (x*scale, y*scale).
    /// To keep the target center fixed, we offset by: targetCenter * (scale - 1).
    /// We then clamp to prevent zoomed content from going off-screen.
    private func calculateZoomOffset() -> GridPoint {
        let targetCenter = targetCenterInScreenCoordinates()
        let idealOffset = GridPoint(
            x: targetCenter.x * (zoomScale - 1),
            y: targetCenter.y * (zoomScale - 1)
        )
        return clampOffset(idealOffset)
    }
    
    private func targetCenterInScreenCoordinates() -> GridPoint {
        GridPoint(
            x: targetRect.midX - screenRect.minX,
            y: targetRect.midY - screenRect.minY
        )
    }
    
    /// Clamps offset so target edges stay within screen bounds after zoom.
    /// Transform: screen_pos = source_pos * scale - offset
    private func clampOffset(_ offset: GridPoint) -> GridPoint {
        let targetEdges = targetEdgesInScreenCoordinates()
        
        // Clamping constraints:
        // Left edge: targetLeftX * scale - offset >= 0 → offset <= targetLeftX * scale
        // Right edge: targetRightX * scale - offset <= screenWidth → offset >= targetRightX * scale - screenWidth
        let xRange = (
            min: targetEdges.right * zoomScale - screenRect.width,
            max: targetEdges.left * zoomScale
        )
        let yRange = (
            min: targetEdges.bottom * zoomScale - screenRect.height,
            max: targetEdges.top * zoomScale
        )
        
        let clamped = GridPoint(
            x: max(xRange.min, min(offset.x, xRange.max)),
            y: max(yRange.min, min(offset.y, yRange.max))
        )
        
        if clamped.x != offset.x || clamped.y != offset.y {
            print("[ZoomController]   Offset clamped from (\(offset.x), \(offset.y)) to (\(clamped.x), \(clamped.y))")
        }
        
        return clamped
    }
    
    private func targetEdgesInScreenCoordinates() -> (left: Double, right: Double, top: Double, bottom: Double) {
        let left = targetRect.minX - screenRect.minX
        let right = targetRect.minX + targetRect.width - screenRect.minX
        let top = targetRect.minY - screenRect.minY
        let bottom = targetRect.minY + targetRect.height - screenRect.minY
        return (left, right, top, bottom)
    }
}
