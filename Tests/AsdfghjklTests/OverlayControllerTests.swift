import XCTest
@testable import AsdfghjklCore

final class OverlayControllerTests: XCTestCase {
    func testStartResetsToScreenBounds() {
        let expectedRect = GridRect(x: 10, y: 20, width: 300, height: 200)
        let controller = OverlayController(screenBoundsProvider: { [expectedRect] })

        controller.start()

        XCTAssertTrue(controller.isActive)
        XCTAssertEqual(controller.targetRect, expectedRect)
    }

    func testRefinementUpdatesZoomController() {
        var updates: [GridRect] = []
        let zoom = ZoomController(initialRect: .defaultScreen)
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            zoomController: zoom
        )

        controller.start()
        controller.handleKey("q")
        updates.append(zoom.targetRect)

        controller.handleKey("w")
        updates.append(zoom.targetRect)

        XCTAssertEqual(updates.count, 2)
        XCTAssertEqual(updates[0], GridRect(x: 0, y: 25, width: 10, height: 25))
        XCTAssertEqual(updates[1], GridRect(x: 1, y: 31.25, width: 1, height: 6.25))
    }

    func testClickDelegatesToHandlerAndDeactivates() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 80, height: 40)] },
            mouseActionPerformer: performer
        )

        controller.start()
        controller.handleKey("1")
        controller.click()

        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(performer.clickedPoints.last, GridPoint(x: 4, y: 5))
        XCTAssertEqual(controller.targetRect, GridRect(x: 0, y: 0, width: 80, height: 40))
    }

    func testClickIgnoredWhenInactive() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(mouseActionPerformer: performer)

        controller.click()

        XCTAssertTrue(performer.clickedPoints.isEmpty)
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
            return [bounds[min(index, bounds.count - 1)]]
        })

        controller.start()
        controller.handleKey("1")
        controller.start()

        XCTAssertEqual(controller.targetRect, bounds[1])
    }

    func testCancelResetsRectAndNotifiesListeners() {
        let bounds = GridRect(x: 10, y: 20, width: 300, height: 200)
        let controller = OverlayController(screenBoundsProvider: { [bounds] })

        var observedStates: [OverlayState] = []
        controller.stateDidChange = { state in
            observedStates.append(state)
        }

        controller.start()
        controller.handleKey("q")
        controller.cancel()

        XCTAssertEqual(observedStates.count, 3, "start, refinement, and cancel should all notify listeners")
        XCTAssertEqual(observedStates.last?.currentRect, bounds)
        XCTAssertFalse(observedStates.last?.isActive ?? true)
    }

    func testFirstKeySelectsScreenSlice() {
        let screens = [
            GridRect(x: 0, y: 0, width: 100, height: 100),
            GridRect(x: 200, y: 0, width: 100, height: 100)
        ]
        let controller = OverlayController(screenBoundsProvider: { screens })

        controller.start()
        let firstRefinement = controller.handleKey("y")

        XCTAssertEqual(firstRefinement, GridRect(x: 200, y: 25, width: 20, height: 25))

        let secondRefinement = controller.handleKey("h")

        XCTAssertEqual(secondRefinement, GridRect(x: 200, y: 37.5, width: 4, height: 6.25))
    }

    func testFirstRefinementShowsZoomAndMovesCursor() {
        let performer = StubMouseActionPerformer()
        let zoom = ZoomController()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            zoomController: zoom,
            mouseActionPerformer: performer
        )

        controller.start()
        XCTAssertFalse(controller.stateSnapshot.isZoomVisible)

        let refined = controller.handleKey("q")

        XCTAssertEqual(refined, GridRect(x: 0, y: 25, width: 10, height: 25))
        XCTAssertEqual(performer.movedPoints.last, GridPoint(x: 5, y: 37.5))
        XCTAssertTrue(controller.stateSnapshot.isZoomVisible)
        XCTAssertEqual(zoom.zoomScale, 1.5)
    }

    func testSubsequentRefinementsIncreaseZoomScale() {
        let performer = StubMouseActionPerformer()
        let zoom = ZoomController()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            zoomController: zoom,
            mouseActionPerformer: performer
        )

        controller.start()
        _ = controller.handleKey("q")
        _ = controller.handleKey("w")

        XCTAssertEqual(zoom.zoomScale, 2.0)
        XCTAssertEqual(performer.movedPoints.count, 2)
    }

    func testClickDoesNotMoveCursorAgain() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 40, height: 20)] },
            mouseActionPerformer: performer
        )

        controller.start()
        controller.handleKey("0")
        performer.reset()

        controller.click()

        XCTAssertTrue(performer.movedPoints.isEmpty)
        XCTAssertEqual(performer.clickedPoints, [GridPoint(x: 38, y: 2.5)])
    }
}

private final class StubMouseActionPerformer: MouseActionPerforming {
    private(set) var movedPoints: [GridPoint] = []
    private(set) var clickedPoints: [GridPoint] = []

    func moveCursor(to point: GridPoint) {
        movedPoints.append(point)
    }

    func click(at point: GridPoint) {
        clickedPoints.append(point)
    }

    func reset() {
        movedPoints.removeAll()
        clickedPoints.removeAll()
    }
}
