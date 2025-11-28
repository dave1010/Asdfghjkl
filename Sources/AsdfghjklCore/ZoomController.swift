import Foundation
#if canImport(Combine)
import Combine
#else
public protocol ObservableObject {}
#endif

#if os(macOS)
import CoreGraphics

public protocol ZoomSnapshotProviding {
    func capture(rect: GridRect) -> CGImage?
}

public struct CGWindowListSnapshotProvider: ZoomSnapshotProviding {
    public init() {}

    public func capture(rect: GridRect) -> CGImage? {
        let cgRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.x, height: rect.size.y)
        return CGWindowListCreateImage(cgRect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming])
    }
}
#endif

public final class ZoomController: ObservableObject {
    #if canImport(Combine)
    @Published public private(set) var observedRect: GridRect
    #if os(macOS)
    @Published public private(set) var latestSnapshot: CGImage?
    #endif
    #else
    public private(set) var observedRect: GridRect
    #endif

    #if os(macOS)
    private let snapshotProvider: ZoomSnapshotProviding?

    public init(initialRect: GridRect = .defaultScreen, snapshotProvider: ZoomSnapshotProviding? = nil) {
        self.observedRect = initialRect
        self.snapshotProvider = snapshotProvider
    }
    #else
    public init(initialRect: GridRect = .defaultScreen) {
        self.observedRect = initialRect
    }
    #endif

    public func update(rect: GridRect) {
        observedRect = rect

        #if os(macOS)
        latestSnapshot = snapshotProvider?.capture(rect: rect)
        #endif
    }
}
