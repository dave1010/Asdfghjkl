import Foundation

public final class OverlayController {
    private var state: OverlayState
    private let gridLayout: GridLayout
    private let screenBoundsProvider: () -> GridRect
    private let zoomController: ZoomController?
    private let clickHandler: (GridPoint) -> Void

    public init(
        gridLayout: GridLayout = GridLayout(),
        screenBoundsProvider: @escaping () -> GridRect = { .defaultScreen },
        zoomController: ZoomController? = nil,
        clickHandler: @escaping (GridPoint) -> Void = { _ in }
    ) {
        self.gridLayout = gridLayout
        self.screenBoundsProvider = screenBoundsProvider
        self.zoomController = zoomController
        self.clickHandler = clickHandler
        self.state = OverlayState()
    }

    public var isActive: Bool { state.isActive }
    public var targetRect: GridRect { state.currentRect }
    public var targetPoint: GridPoint? { isActive ? state.targetPoint : nil }

    public func start() {
        let bounds = screenBoundsProvider()
        state.reset(rect: bounds)
        state.isActive = true
        zoomController?.update(rect: state.currentRect)
    }

    public func toggle() {
        isActive ? cancel() : start()
    }

    public func cancel() {
        state.isActive = false
    }

    @discardableResult
    public func handleKey(_ key: Character) -> GridRect? {
        guard state.isActive else { return nil }
        guard let refined = gridLayout.rect(for: key, in: state.currentRect) else { return nil }
        state.currentRect = refined
        zoomController?.update(rect: refined)
        return refined
    }

    public func click() {
        guard state.isActive else { return }
        let target = state.targetPoint
        clickHandler(target)
        state.isActive = false
    }
}
