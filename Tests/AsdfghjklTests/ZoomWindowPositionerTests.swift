import XCTest
@testable import AsdfghjklCore

final class ZoomWindowPositionerTests: XCTestCase {
    func testOriginCentersAroundTarget() {
        let bounds = GridRect(x: 0, y: 0, width: 300, height: 300)
        let origin = ZoomWindowPositioner.clampedOrigin(
            target: GridPoint(x: 150, y: 150),
            windowSize: GridPoint(x: 100, y: 100),
            bounds: bounds,
            padding: 0
        )

        XCTAssertEqual(origin, GridPoint(x: 100, y: 100))
    }

    func testOriginClampsNearEdges() {
        let bounds = GridRect(x: 0, y: 0, width: 200, height: 200)
        let origin = ZoomWindowPositioner.clampedOrigin(
            target: GridPoint(x: 10, y: 10),
            windowSize: GridPoint(x: 80, y: 80),
            bounds: bounds,
            padding: 10
        )

        XCTAssertEqual(origin, GridPoint(x: 10, y: 10))
    }

    func testOriginClampsOnFarEdge() {
        let bounds = GridRect(x: 0, y: 0, width: 200, height: 200)
        let origin = ZoomWindowPositioner.clampedOrigin(
            target: GridPoint(x: 190, y: 190),
            windowSize: GridPoint(x: 80, y: 80),
            bounds: bounds,
            padding: 10
        )

        XCTAssertEqual(origin, GridPoint(x: 110, y: 110))
    }
}
