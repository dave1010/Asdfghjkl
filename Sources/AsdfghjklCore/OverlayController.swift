import Foundation

public final class OverlayController {
    private var state: OverlayState
    private let gridLayout: GridLayout
    private let screenBoundsProvider: () -> [GridRect]
    private let mouseActionPerformer: MouseActionPerforming
    private var gridSlices: [GridSlice] = []
    private var selectedSliceIndex: Int?
    private var refinementCount: Int = 0
    private var history: [(rect: GridRect, sliceIndex: Int?, refinementCount: Int)] = []
    public var stateDidChange: ((OverlayState) -> Void)?

    public init(
        gridLayout: GridLayout = GridLayout(),
        screenBoundsProvider: @escaping () -> [GridRect] = { [.defaultScreen] },
        mouseActionPerformer: MouseActionPerforming = SystemMouseActionPerformer()
    ) {
        self.gridLayout = gridLayout
        self.screenBoundsProvider = screenBoundsProvider
        self.mouseActionPerformer = mouseActionPerformer
        self.state = OverlayState()
    }

    public var isActive: Bool { state.isActive }
    public var targetRect: GridRect { state.currentRect }
    public var targetPoint: GridPoint? { isActive ? state.targetPoint : nil }
    public var stateSnapshot: OverlayState { state }

    public func start() {
        let screens = screenBoundsProvider()
        gridSlices = GridPartitioner.slices(for: screens, layout: gridLayout)
        if gridSlices.isEmpty {
            gridSlices = GridPartitioner.slices(for: [.defaultScreen], layout: gridLayout)
        }

        print("[OverlayController] ✓ ACTIVATED")
        print("[OverlayController] Screens: \(screens.count)")
        print("[OverlayController] Grid columns: \(gridLayout.columns), rows: \(gridLayout.rows)")
        print("[OverlayController] Keyboard split: \(gridSlices.count) slice(s)")
        for (index, slice) in gridSlices.enumerated() {
            print("[OverlayController]   Slice \(index): columns \(slice.columnRange), screen bounds: \(slice.screenRect)")
        }

        let bounds = combinedBounds(for: screens)
        resetState(to: bounds)
        notifyStateChange()
    }
    
    private func resetState(to bounds: GridRect) {
        state.reset(rect: bounds)
        state.gridRect = bounds
        state.isActive = true
        selectedSliceIndex = gridSlices.count == 1 ? 0 : nil
        refinementCount = 0
        history = []
    }
    
    private func combinedBounds(for screens: [GridRect]) -> GridRect {
        let rects = screens.isEmpty ? gridSlices.map { $0.screenRect } : screens
        return combinedRect(for: rects)
    }

    public func toggle() {
        isActive ? cancel() : start()
    }

    public func cancel() {
        deactivate()
    }

    @discardableResult
    public func handleKey(_ key: Character) -> GridRect? {
        guard state.isActive else { return nil }
        guard let coordinate = gridLayout.coordinate(for: key) else { return nil }

        selectScreenIfNeeded(for: coordinate)
        
        guard let refined = refineGrid(for: key) else { return nil }

        applyRefinement(refined)
        mouseActionPerformer.moveCursor(to: state.targetPoint)
        notifyStateChange()
        return refined
    }
    
    private func selectScreenIfNeeded(for coordinate: GridCoordinate) {
        guard selectedSliceIndex == nil, gridSlices.count > 1 else { return }
        
        selectedSliceIndex = gridSlices.firstIndex { $0.columnRange.contains(coordinate.column) }
        if let sliceIndex = selectedSliceIndex {
            let selectedScreen = gridSlices[sliceIndex].screenRect
            state.currentRect = selectedScreen
            state.gridRect = selectedScreen
            print("[OverlayController] Selected screen slice \(sliceIndex) for column \(coordinate.column)")
            print("[OverlayController]   Screen bounds: \(selectedScreen)")
        }
    }
    
    private func refineGrid(for key: Character) -> GridRect? {
        if let sliceIndex = selectedSliceIndex, sliceIndex < gridSlices.count {
            return gridSlices[sliceIndex].layout.rect(for: key, in: state.currentRect)
        }
        return gridLayout.rect(for: key, in: state.currentRect)
    }
    
    private func applyRefinement(_ refined: GridRect) {
        history.append((rect: state.currentRect, sliceIndex: selectedSliceIndex, refinementCount: refinementCount))
        
        let parentRect = state.currentRect
        state.currentRect = refined
        refinementCount += 1
        state.isGridVisible = refinementCount < 3
        
        // Calculate position within parent grid
        let relativeX = refined.origin.x - parentRect.origin.x
        let relativeY = refined.origin.y - parentRect.origin.y
        
        print("[OverlayController] Grid selection refined (depth \(refinementCount))")
        print("[OverlayController]   Parent grid: \(parentRect)")
        print("[OverlayController]   Selected section: \(refined)")
        print("[OverlayController]   Position in parent: (\(relativeX), \(relativeY))")
    }
    public func click() {
        guard state.isActive else { return }
        let target = state.targetPoint
        mouseActionPerformer.click(at: target)
        deactivate()
    }

    public func middleClick() {
        guard state.isActive else { return }
        let target = state.targetPoint
        mouseActionPerformer.middleClick(at: target)
        deactivate()
    }

    public func rightClick() {
        guard state.isActive else { return }
        let target = state.targetPoint
        mouseActionPerformer.rightClick(at: target)
        deactivate()
    }
    
    public func zoomOut() -> Bool {
        guard state.isActive else { return false }
        
        // If we're already at the initial state (no history), cancel the overlay
        guard let previous = history.popLast() else {
            cancel()
            return true
        }
        
        state.currentRect = previous.rect
        selectedSliceIndex = previous.sliceIndex
        refinementCount = previous.refinementCount
        state.isGridVisible = refinementCount < 3
        
        if refinementCount == 0 {
            // Zooming out to the initial full-screen state
            // Reset to show overlay on all screens
            selectedSliceIndex = gridSlices.count == 1 ? 0 : nil
            let screens = screenBoundsProvider()
            let bounds = combinedBounds(for: screens)
            state.currentRect = bounds
            state.gridRect = bounds
            print("[OverlayController] Zoomed out to full-screen overlay on all screens")
        }
        
        print("[OverlayController] Zoomed out to depth \(refinementCount)")
        print("[OverlayController]   Current rect: \(state.currentRect)")
        
        mouseActionPerformer.moveCursor(to: state.targetPoint)
        notifyStateChange()
        return true
    }
    
    public enum ArrowDirection {
        case up, down, left, right
    }
    
    public func moveSelection(_ direction: ArrowDirection) -> Bool {
        guard state.isActive else { return false }
        
        // Don't allow movement before a selection has been made
        // For multi-screen: need a selected slice
        // For single screen: need at least one refinement
        if gridSlices.count > 1 && selectedSliceIndex == nil {
            return false
        }
        if refinementCount == 0 {
            return false
        }
        
        let halfWidth = state.currentRect.width / 2
        let halfHeight = state.currentRect.height / 2
        
        let newRect: GridRect
        switch direction {
        case .up:
            newRect = GridRect(
                x: state.currentRect.origin.x,
                y: state.currentRect.origin.y - halfHeight,
                width: state.currentRect.width,
                height: state.currentRect.height
            )
        case .down:
            newRect = GridRect(
                x: state.currentRect.origin.x,
                y: state.currentRect.origin.y + halfHeight,
                width: state.currentRect.width,
                height: state.currentRect.height
            )
        case .left:
            newRect = GridRect(
                x: state.currentRect.origin.x - halfWidth,
                y: state.currentRect.origin.y,
                width: state.currentRect.width,
                height: state.currentRect.height
            )
        case .right:
            newRect = GridRect(
                x: state.currentRect.origin.x + halfWidth,
                y: state.currentRect.origin.y,
                width: state.currentRect.width,
                height: state.currentRect.height
            )
        }
        
        // Check if the new rect would be completely within the grid bounds
        let bounds = state.gridRect
        guard newRect.minX >= bounds.minX,
              newRect.minY >= bounds.minY,
              newRect.minX + newRect.width <= bounds.minX + bounds.width,
              newRect.minY + newRect.height <= bounds.minY + bounds.height else {
            return false
        }
        
        state.currentRect = newRect
        mouseActionPerformer.moveCursor(to: state.targetPoint)
        notifyStateChange()
        
        print("[OverlayController] Moved selection \(direction)")
        print("[OverlayController]   New rect: \(state.currentRect)")
        
        return true
    }

    private func notifyStateChange() {
        stateDidChange?(state)
    }

    private func deactivate() {
        guard state.isActive else { return }
        print("[OverlayController] ✗ DEACTIVATED")
        state.reset(rect: state.rootRect)
        selectedSliceIndex = gridSlices.count == 1 ? 0 : nil
        refinementCount = 0
        history = []
        notifyStateChange()
    }

    private func combinedRect(for rects: [GridRect]) -> GridRect {
        guard let first = rects.first else { return .defaultScreen }
        let minX = rects.map { $0.minX }.min() ?? first.minX
        let minY = rects.map { $0.minY }.min() ?? first.minY
        let maxX = rects.map { $0.minX + $0.width }.max() ?? (first.minX + first.width)
        let maxY = rects.map { $0.minY + $0.height }.max() ?? (first.minY + first.height)

        return GridRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
