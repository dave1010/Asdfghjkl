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
        
        // Scale the entire screen content by the desired zoom factor
        // This mimics pinch-to-zoom behavior on mobile devices
        self.zoomScale = desiredZoomFactor
        
        // Calculate offset for true pinch-to-zoom: the target center stays at its screen position
        // The target center in screen-relative coordinates
        let targetCenterX = targetRect.midX - screenRect.minX
        let targetCenterY = targetRect.midY - screenRect.minY
        
        // When we scale from top-left by zoomScale, point (x,y) moves to (x*scale, y*scale)
        // To keep the target center at its original position, we need to offset by:
        // targetCenter * (scale - 1)
        // This compensates for the scaling displacement while keeping the point fixed
        let idealOffsetX = targetCenterX * (zoomScale - 1)
        let idealOffsetY = targetCenterY * (zoomScale - 1)
        
        // Clamp the offset to prevent zoomed content from going off-screen
        // We want the target rect boundaries to stay within screen bounds after zooming.
        // After transform: screen_pos = source_pos * scale - offset
        // Target edges in screen-relative coordinates:
        let targetLeftX = targetRect.minX - screenRect.minX
        let targetRightX = targetRect.minX + targetRect.width - screenRect.minX
        let targetTopY = targetRect.minY - screenRect.minY
        let targetBottomY = targetRect.minY + targetRect.height - screenRect.minY
        
        // Clamp constraints:
        // - Left edge: targetLeftX * scale - offset >= 0 → offset <= targetLeftX * scale
        // - Right edge: targetRightX * scale - offset <= screenWidth → offset >= targetRightX * scale - screenWidth
        let minOffsetX = targetRightX * zoomScale - screenRect.width
        let maxOffsetX = targetLeftX * zoomScale
        
        let minOffsetY = targetBottomY * zoomScale - screenRect.height
        let maxOffsetY = targetTopY * zoomScale
        
        self.zoomOffset = GridPoint(
            x: max(minOffsetX, min(idealOffsetX, maxOffsetX)),
            y: max(minOffsetY, min(idealOffsetY, maxOffsetY))
        )

        #if os(macOS)
        latestSnapshot = snapshotProvider.capture(screen: screenRect)
        #endif
    }
}
