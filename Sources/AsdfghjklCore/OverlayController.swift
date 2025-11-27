import Foundation

public final class OverlayController {
    private var state: OverlayState
    private let gridLayout: GridLayout
    private let screenBoundsProvider: () -> GridRect

    public init(gridLayout: GridLayout = GridLayout(), screenBoundsProvider: @escaping () -> GridRect = { .defaultScreen }) {
        self.gridLayout = gridLayout
        self.screenBoundsProvider = screenBoundsProvider
        self.state = OverlayState()
    }

    public var isActive: Bool { state.isActive }
    public var targetRect: GridRect { state.currentRect }
    public var targetPoint: GridPoint? { isActive ? state.targetPoint : nil }

    public func start() {
        let bounds = screenBoundsProvider()
        state.reset(rect: bounds)
        state.isActive = true
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
        return refined
    }

    public func click() {
        guard state.isActive else { return }
        // TODO: Integrate CGEvent-based click once the macOS target is wired up.
        // The skeleton keeps this as a no-op so we can build and test the state machine independently.
        state.isActive = false
    }
}
