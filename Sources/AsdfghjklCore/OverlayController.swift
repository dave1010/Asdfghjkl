import Foundation

public final class OverlayController {
    private var state: OverlayState
    private let gridLayout: GridLayout
    private let screenBoundsProvider: () -> [GridRect]
    private let zoomController: ZoomController?
    private let mouseActionPerformer: MouseActionPerforming
    private var gridSlices: [GridSlice] = []
    private var selectedSliceIndex: Int?
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

        let bounds = combinedRect(for: screens.isEmpty ? gridSlices.map { $0.screenRect } : screens)
        state.reset(rect: bounds)
        selectedSliceIndex = gridSlices.count == 1 ? 0 : nil
        state.isActive = true
        zoomController?.update(rect: state.currentRect)
        notifyStateChange()
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

        if selectedSliceIndex == nil, gridSlices.count > 1 {
            selectedSliceIndex = gridSlices.firstIndex { $0.columnRange.contains(coordinate.column) }
            if let sliceIndex = selectedSliceIndex {
                state.currentRect = gridSlices[sliceIndex].screenRect
            }
        }

        let refined: GridRect?
        if let sliceIndex = selectedSliceIndex, sliceIndex < gridSlices.count {
            refined = gridSlices[sliceIndex].layout.rect(for: key, in: state.currentRect)
        } else {
            refined = gridLayout.rect(for: key, in: state.currentRect)
        }

        guard let refined else { return nil }

        state.currentRect = refined
        zoomController?.update(rect: refined)
        notifyStateChange()
        return refined
    }

    public func click() {
        guard state.isActive else { return }
        let target = state.targetPoint
        mouseActionPerformer.moveAndClick(at: target)
        deactivate()
    }

    private func notifyStateChange() {
        stateDidChange?(state)
    }

    private func deactivate() {
        guard state.isActive else { return }
        state.reset(rect: state.rootRect)
        selectedSliceIndex = gridSlices.count == 1 ? 0 : nil
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
