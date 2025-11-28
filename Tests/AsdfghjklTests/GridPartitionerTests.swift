import XCTest
@testable import AsdfghjklCore

final class GridPartitionerTests: XCTestCase {
    func testColumnRangesDistributeEvenlyAcrossScreens() {
        let twoScreens = GridPartitioner.columnRanges(totalColumns: 10, screenCount: 2)
        XCTAssertEqual(twoScreens, [0...4, 5...9])

        let threeScreens = GridPartitioner.columnRanges(totalColumns: 10, screenCount: 3)
        XCTAssertEqual(threeScreens, [0...3, 4...6, 7...9])
    }

    func testSlicesShiftLayoutToColumnRange() {
        let layout = GridLayout()
        let slice = GridSlice(
            screenRect: GridRect(x: 0, y: 0, width: 100, height: 100),
            columnRange: 5...9,
            baseLayout: layout
        )

        XCTAssertEqual(slice.layout.columns, 5)
        XCTAssertEqual(slice.layout.coordinate(for: "y"), GridCoordinate(row: 1, column: 0))
        XCTAssertNil(slice.layout.coordinate(for: "q"))
    }
}
