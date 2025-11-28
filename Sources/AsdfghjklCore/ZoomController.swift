import Foundation
#if canImport(Combine)
import Combine
#else
public protocol ObservableObject {}
#endif

public final class ZoomController: ObservableObject {
    #if canImport(Combine)
    @Published public private(set) var observedRect: GridRect
    #else
    public private(set) var observedRect: GridRect
    #endif

    public init(initialRect: GridRect = .defaultScreen) {
        self.observedRect = initialRect
    }

    public func update(rect: GridRect) {
        observedRect = rect
        // TODO: Render a magnified snapshot of the rect once hooked into AppKit.
    }
}
