import XCTest
@testable import AsdfghjklCore

final class OverlayControllerTests: XCTestCase {
    func testStartResetsToScreenBounds() {
        let expectedRect = GridRect(x: 10, y: 20, width: 300, height: 200)
        let controller = OverlayController(screenBoundsProvider: { expectedRect })

        controller.start()

        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.targetRect, expectedRect)
    }

    func testRefinementUpdatesZoomController() {
        var updates: [GridRect] = []
        let zoom = ZoomController(initialRect: .defaultScreen)
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { GridRect(x: 0, y: 0, width: 100, height: 100) },
            zoomController: zoom
        )

        controller.start()
        controller.handleKey("q")
        updates.append(zoom.observedRect)

        controller.handleKey("w")
        updates.append(zoom.observedRect)

        XCTAssertEqual(updates.count, 2)
        XCTAssertEqual(updates[0], GridRect(x: 0, y: 25, width: 10, height: 25))
        XCTAssertEqual(updates[1], GridRect(x: 1, y: 31.25, width: 1, height: 6.25))
    }

    func testClickDelegatesToHandlerAndDeactivates() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { GridRect(x: 0, y: 0, width: 80, height: 40) },
            mouseActionPerformer: performer
        )

        controller.start()
        controller.handleKey("1")
        controller.click()

        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(performer.receivedPoint, GridPoint(x: 4, y: 5))
    }

    func testClickIgnoredWhenInactive() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(mouseActionPerformer: performer)

        controller.click()

        XCTAssertNil(performer.receivedPoint)
        XCTAssertFalse(controller.isActive)
    }

    func testStartRefreshesCurrentRectFromLatestScreenBounds() {
        let bounds = [
            GridRect(x: 0, y: 0, width: 100, height: 100),
            GridRect(x: 200, y: 300, width: 400, height: 500)
        ]
        var index = 0
        let controller = OverlayController(screenBoundsProvider: {
            defer { index += 1 }
            return bounds[min(index, bounds.count - 1)]
        })

        controller.start()
        controller.handleKey("1")
        controller.start()

        XCTAssertEqual(controller.targetRect, bounds[1])
    }
}

private final class StubMouseActionPerformer: MouseActionPerforming {
    private(set) var receivedPoint: GridPoint?

    func moveAndClick(at point: GridPoint) {
        receivedPoint = point
    }
}
