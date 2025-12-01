import Foundation

public final class OverlayController {
    private var state: OverlayState
    private let gridLayout: GridLayout
    private let screenBoundsProvider: () -> [GridRect]
    private let zoomController: ZoomController?
    private let mouseActionPerformer: MouseActionPerforming
    private var gridSlices: [GridSlice] = []
    private var selectedSliceIndex: Int?
    private var refinementCount: Int = 0
    private var zoomScale: Double = 1.0
    private let baseZoomScale: Double = 2.0
    private let zoomIncrement: Double = 0.5
    private var history: [(rect: GridRect, sliceIndex: Int?, refinementCount: Int)] = []
    public var stateDidChange: ((OverlayState) -> Void)?

    public init(
        gridLayout: GridLayout = GridLayout(),
        screenBoundsProvider: @escaping () -> [GridRect] = { [.defaultScreen] },
        zoomController: ZoomController? = nil,
        mouseActionPerformer: MouseActionPerforming = SystemMouseActionPerformer()
    ) {
        self.gridLayout = gridLayout
        self.screenBoundsProvider = screenBoundsProvider
        self.zoomController = zoomController
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
        zoomScale = 1.0
        history = []
        updateZoom()
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
        }
    }
    
    private func refineGrid(for key: Character) -> GridRect? {
        if let sliceIndex = selectedSliceIndex, sliceIndex < gridSlices.count {
            return gridSlices[sliceIndex].layout.rect(for: key, in: state.gridRect)
        }
        return gridLayout.rect(for: key, in: state.gridRect)
    }
    
    private func applyRefinement(_ refined: GridRect) {
        history.append((rect: state.currentRect, sliceIndex: selectedSliceIndex, refinementCount: refinementCount))
        state.currentRect = refined
        state.gridRect = refined
        state.isZoomVisible = true
        refinementCount += 1
        zoomScale = baseZoomScale + Double(refinementCount - 1) * zoomIncrement
        updateZoom()
    }
    
    private func updateZoom() {
        let targetScreenRect = currentScreenRect()
        zoomController?.update(
            targetRect: state.currentRect,
            screenRect: targetScreenRect,
            desiredZoomFactor: zoomScale
        )
    }
    
    private func currentScreenRect() -> GridRect {
        if let sliceIndex = selectedSliceIndex, sliceIndex < gridSlices.count {
            return gridSlices[sliceIndex].screenRect
        }
        return state.rootRect
    }

    public func click() {
        guard state.isActive else { return }
        let target = state.targetPoint
        mouseActionPerformer.click(at: target)
        deactivate()
    }
    
    public func zoomOut() -> Bool {
        guard state.isActive else { return false }
        guard let previous = history.popLast() else { return false }
        
        state.currentRect = previous.rect
        state.gridRect = previous.rect
        selectedSliceIndex = previous.sliceIndex
        refinementCount = previous.refinementCount
        
        if refinementCount == 0 {
            state.isZoomVisible = false
            zoomScale = 1.0
        } else {
            zoomScale = baseZoomScale + Double(refinementCount - 1) * zoomIncrement
        }
        
        updateZoom()
        mouseActionPerformer.moveCursor(to: state.targetPoint)
        notifyStateChange()
        return true
    }

    private func notifyStateChange() {
        stateDidChange?(state)
    }

    private func deactivate() {
        guard state.isActive else { return }
        state.reset(rect: state.rootRect)
        selectedSliceIndex = gridSlices.count == 1 ? 0 : nil
        refinementCount = 0
        zoomScale = 1.0
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
