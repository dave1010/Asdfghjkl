import Foundation

public struct CommandTapRecognizer {
    public private(set) var cmdDown: Bool = false
    public private(set) var cmdUsedAsModifierSinceDown: Bool = false
    private var cmdLastTapTime: Date?
    public var doubleTapThreshold: TimeInterval
    private let currentTime: () -> Date

    public init(doubleTapThreshold: TimeInterval = 0.35, currentTime: @escaping () -> Date = Date.init) {
        self.doubleTapThreshold = doubleTapThreshold
        self.currentTime = currentTime
    }

    public mutating func handleCommandDown() {
        cmdDown = true
        cmdUsedAsModifierSinceDown = false
    }

    public mutating func handleCommandModifierUse() {
        if cmdDown {
            cmdUsedAsModifierSinceDown = true
        }
    }

    public mutating func handleCommandUp(onDoubleTap: () -> Void) {
        guard cmdDown else { return }
        defer { cmdDown = false }

        if cmdUsedAsModifierSinceDown {
            cmdLastTapTime = nil
            return
        }

        let now = currentTime()
        if let last = cmdLastTapTime, now.timeIntervalSince(last) < doubleTapThreshold {
            onDoubleTap()
        }
        cmdLastTapTime = now
    }
}
