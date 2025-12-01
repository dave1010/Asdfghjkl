import Foundation
#if os(macOS)
import Combine
import AsdfghjklCore

/// Bridges OverlayState to SwiftUI's ObservableObject for reactive UI updates.
@MainActor
final class OverlayVisualModel: ObservableObject {
    @Published var isActive: Bool = false
    @Published var rootRect: GridRect = .defaultScreen
    @Published var currentRect: GridRect = .defaultScreen
    @Published var gridRect: GridRect = .defaultScreen
    @Published var isGridVisible: Bool = true

    func apply(state: OverlayState) {
        isActive = state.isActive
        rootRect = state.rootRect
        currentRect = state.currentRect
        gridRect = state.gridRect
        isGridVisible = state.isGridVisible
    }
}
#endif
