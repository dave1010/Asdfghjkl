import Foundation
#if os(macOS)
import Combine
import AsdfghjklCore

@MainActor
final class OverlayVisualModel: ObservableObject {
    @Published var isActive: Bool = false
    @Published var rootRect: GridRect = .defaultScreen
    @Published var currentRect: GridRect = .defaultScreen
    @Published var isZoomVisible: Bool = false

    func apply(state: OverlayState) {
        isActive = state.isActive
        rootRect = state.rootRect
        currentRect = state.currentRect
        isZoomVisible = state.isZoomVisible
    }
}
#endif
