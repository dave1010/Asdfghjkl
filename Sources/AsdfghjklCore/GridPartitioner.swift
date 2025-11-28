import Foundation

public struct GridSlice {
    public let screenRect: GridRect
    public let columnRange: ClosedRange<Int>
    public let layout: GridLayout

    public init(screenRect: GridRect, columnRange: ClosedRange<Int>, baseLayout: GridLayout) {
        self.screenRect = screenRect
        self.columnRange = columnRange

        let adjustedKeymap = baseLayout.keymap.compactMap { key, coordinate -> (Character, GridCoordinate)? in
            guard columnRange.contains(coordinate.column) else { return nil }
            let shiftedCoordinate = GridCoordinate(row: coordinate.row, column: coordinate.column - columnRange.lowerBound)
            return (key, shiftedCoordinate)
        }

        self.layout = GridLayout(
            rows: baseLayout.rows,
            columns: columnRange.count,
            keymap: Dictionary(uniqueKeysWithValues: adjustedKeymap)
        )
    }
}

public enum GridPartitioner {
    public static func slices(for screens: [GridRect], layout: GridLayout) -> [GridSlice] {
        let ranges = columnRanges(totalColumns: layout.columns, screenCount: screens.count)
        guard !ranges.isEmpty else { return [] }

        let count = min(ranges.count, screens.count)
        return (0..<count).map { index in
            GridSlice(screenRect: screens[index], columnRange: ranges[index], baseLayout: layout)
        }
    }

    public static func columnRanges(totalColumns: Int, screenCount: Int) -> [ClosedRange<Int>] {
        guard totalColumns > 0, screenCount > 0 else { return [] }

        let clampedScreens = min(screenCount, totalColumns)
        let baseWidth = totalColumns / clampedScreens
        let remainder = totalColumns % clampedScreens

        var ranges: [ClosedRange<Int>] = []
        var start = 0

        for index in 0..<clampedScreens {
            let width = baseWidth + (index < remainder ? 1 : 0)
            let end = start + max(width - 1, 0)
            ranges.append(start...end)
            start = end + 1
        }

        return ranges
    }
}

private extension ClosedRange where Bound == Int {
    var count: Int { upperBound - lowerBound + 1 }
}
