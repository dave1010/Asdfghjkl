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
    public init() {}

    public func capture(screen: GridRect) -> CGImage? {
        let cgRect = CGRect(x: screen.origin.x, y: screen.origin.y, width: screen.size.x, height: screen.size.y)
        return CGWindowListCreateImage(cgRect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming])
    }
}
#endif

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
        
        // Calculate zoom scale to make the target rectangle appear desiredZoomFactor times larger
        self.zoomScale = desiredZoomFactor
        
        // Calculate offset to center the target rectangle in the zoomed view
        // When zoomed, the target's center should remain at the same screen position
        let targetCenterX = targetRect.midX - screenRect.minX
        let targetCenterY = targetRect.midY - screenRect.minY
        
        // After scaling, we want the target center to stay in place
        // offset = (target_center * scale) - target_center
        self.zoomOffset = GridPoint(
            x: targetCenterX * (zoomScale - 1.0),
            y: targetCenterY * (zoomScale - 1.0)
        )

        #if os(macOS)
        latestSnapshot = snapshotProvider.capture(screen: screenRect)
        #endif
    }
}
