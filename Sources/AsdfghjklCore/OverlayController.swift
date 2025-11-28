import Foundation

public final class OverlayController {
    private var state: OverlayState
    private let gridLayout: GridLayout
    private let screenBoundsProvider: () -> GridRect
    private let zoomController: ZoomController?
    private let mouseActionPerformer: MouseActionPerforming
    public var stateDidChange: ((OverlayState) -> Void)?

    public init(
        gridLayout: GridLayout = GridLayout(),
        screenBoundsProvider: @escaping () -> GridRect = { .defaultScreen },
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
        let bounds = screenBoundsProvider()
        state.reset(rect: bounds)
        state.isActive = true
        zoomController?.update(rect: state.currentRect)
        notifyStateChange()
    }

    public func toggle() {
        isActive ? cancel() : start()
    }

    public func cancel() {
        state.isActive = false
        notifyStateChange()
    }

    @discardableResult
    public func handleKey(_ key: Character) -> GridRect? {
        guard state.isActive else { return nil }
        guard let refined = gridLayout.rect(for: key, in: state.currentRect) else { return nil }
        state.currentRect = refined
        zoomController?.update(rect: refined)
        notifyStateChange()
        return refined
    }

    public func click() {
        guard state.isActive else { return }
        let target = state.targetPoint
        mouseActionPerformer.moveAndClick(at: target)
        state.isActive = false
        notifyStateChange()
    }

    private func notifyStateChange() {
        stateDidChange?(state)
    }
}
