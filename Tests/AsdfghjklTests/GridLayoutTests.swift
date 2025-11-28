import XCTest
@testable import AsdfghjklCore

final class GridLayoutTests: XCTestCase {
    func testDefaultKeymapProvidesCoordinates() {
        let layout = GridLayout()
        XCTAssertEqual(layout.coordinate(for: "q"), GridCoordinate(row: 1, column: 0))
        XCTAssertEqual(layout.coordinate(for: "m"), GridCoordinate(row: 3, column: 6))
        XCTAssertNil(layout.coordinate(for: "!"))
    }

    func testRectSubdivisionMatchesGrid() {
        let layout = GridLayout()
        let root = GridRect(x: 0, y: 0, width: 100, height: 50)

        let qRect = layout.rect(for: "q", in: root)
        XCTAssertEqual(qRect, GridRect(x: 0, y: 12.5, width: 10, height: 12.5))

        let zeroRect = layout.rect(for: "0", in: root)
        XCTAssertEqual(zeroRect, GridRect(x: 90, y: 0, width: 10, height: 12.5))
    }

    func testRefinementChainIsDeterministic() {
        let layout = GridLayout()
        let controller = OverlayController(gridLayout: layout, screenBoundsProvider: { GridRect(x: 0, y: 0, width: 100, height: 100) })
        controller.start()

        _ = controller.handleKey("1")
        _ = controller.handleKey("a")

        XCTAssertEqual(controller.targetRect, GridRect(x: 0, y: 12.5, width: 1, height: 6.25))
        XCTAssertEqual(controller.targetPoint, GridPoint(x: 0.5, y: 15.625))
    }

    func testLabelsExposeKeyForEachCoordinate() {
        let layout = GridLayout()

        XCTAssertEqual(layout.label(forRow: 0, column: 0), Character("1"))
        XCTAssertEqual(layout.label(forRow: 1, column: 1), Character("w"))
        XCTAssertEqual(layout.label(forRow: 3, column: 9), Character("/"))

        XCTAssertNil(layout.label(forRow: -1, column: 0))
        XCTAssertNil(layout.label(forRow: 0, column: 20))
        XCTAssertNil(layout.label(forRow: 4, column: 0))
    }
}
