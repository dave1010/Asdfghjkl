import Foundation
#if os(macOS)
import Combine
import AsdfghjklCore

@MainActor
final class OverlayVisualModel: ObservableObject {
    @Published var isActive: Bool = false
    @Published var rootRect: GridRect = .defaultScreen
    @Published var currentRect: GridRect = .defaultScreen
    @Published var gridRect: GridRect = .defaultScreen
    @Published var isZoomVisible: Bool = false
    @Published var zoomScale: Double = 1.0
    @Published var zoomOffset: GridPoint = GridPoint(x: 0, y: 0)
    @Published var zoomScreenRect: GridRect = .defaultScreen

    func apply(state: OverlayState) {
        isActive = state.isActive
        rootRect = state.rootRect
        currentRect = state.currentRect
        gridRect = state.gridRect
        isZoomVisible = state.isZoomVisible
    }
    
    func updateZoom(scale: Double, offset: GridPoint, screenRect: GridRect) {
        zoomScale = scale
        zoomOffset = offset
        zoomScreenRect = screenRect
    }
}
#endif
