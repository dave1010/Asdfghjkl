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

    func testFirstRefinementMovesCursor() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            mouseActionPerformer: performer
        )

        controller.start()

        let refined = controller.handleKey("q")

        XCTAssertEqual(refined, GridRect(x: 0, y: 25, width: 10, height: 25))
        XCTAssertEqual(performer.movedPoints.last, GridPoint(x: 5, y: 37.5))
    }

    func testSubsequentRefinementsMovesCursor() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            mouseActionPerformer: performer
        )

        controller.start()
        _ = controller.handleKey("q")
        _ = controller.handleKey("w")

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
    
    func testZoomOutRestoresPreviousLevel() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            mouseActionPerformer: performer
        )

        controller.start()
        let firstRect = controller.targetRect
        
        _ = controller.handleKey("q")
        let secondRect = controller.targetRect
        
        _ = controller.handleKey("w")
        let thirdRect = controller.targetRect
        
        XCTAssertNotEqual(firstRect, secondRect)
        XCTAssertNotEqual(secondRect, thirdRect)
        
        let zoomed = controller.zoomOut()
        
        XCTAssertTrue(zoomed)
        XCTAssertEqual(controller.targetRect, secondRect)
        
        let zoomedAgain = controller.zoomOut()
        
        XCTAssertTrue(zoomedAgain)
        XCTAssertEqual(controller.targetRect, firstRect)
        
        // One more zoom out should cancel the overlay
        let zoomedToCancel = controller.zoomOut()
        
        XCTAssertTrue(zoomedToCancel)
        XCTAssertFalse(controller.isActive, "Final zoom out should cancel overlay")
    }
    
    func testZoomOutCancelsOverlayWhenNoHistory() {
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] }
        )

        controller.start()
        XCTAssertTrue(controller.isActive, "Overlay should be active after start")
        
        let result = controller.zoomOut()
        
        XCTAssertTrue(result, "zoomOut should return true when canceling")
        XCTAssertFalse(controller.isActive, "Overlay should be deactivated after zoom out with no history")
    }
    
    func testZoomOutReturnsFalseWhenInactive() {
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] }
        )

        let result = controller.zoomOut()
        
        XCTAssertFalse(result)
    }
    
    func testZoomOutMovesCursor() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            mouseActionPerformer: performer
        )

        controller.start()
        _ = controller.handleKey("q")
        _ = controller.handleKey("w")
        
        performer.reset()
        _ = controller.zoomOut()
        
        XCTAssertEqual(performer.movedPoints.count, 1)
        XCTAssertEqual(performer.movedPoints.last, GridPoint(x: 5, y: 37.5))
    }
    
    func testGridHiddenAfterThreeRefinements() {
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] }
        )

        controller.start()
        XCTAssertTrue(controller.stateSnapshot.isGridVisible)
        
        _ = controller.handleKey("q")
        XCTAssertTrue(controller.stateSnapshot.isGridVisible, "Grid should be visible after 1 refinement")
        
        _ = controller.handleKey("w")
        XCTAssertTrue(controller.stateSnapshot.isGridVisible, "Grid should be visible after 2 refinements")
        
        _ = controller.handleKey("a")
        XCTAssertFalse(controller.stateSnapshot.isGridVisible, "Grid should be hidden after 3 refinements")
        
        _ = controller.handleKey("s")
        XCTAssertFalse(controller.stateSnapshot.isGridVisible, "Grid should remain hidden after 4 refinements")
    }
    
    func testGridReappearsWhenZoomingOutFromHidden() {
        let controller = OverlayController(
            gridLayout: GridLayout(),
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] }
        )

        controller.start()
        _ = controller.handleKey("q")
        _ = controller.handleKey("w")
        _ = controller.handleKey("a")
        
        XCTAssertFalse(controller.stateSnapshot.isGridVisible, "Grid should be hidden after 3 refinements")
        
        _ = controller.zoomOut()
        XCTAssertTrue(controller.stateSnapshot.isGridVisible, "Grid should reappear when zooming back to 2 refinements")
        
        _ = controller.zoomOut()
        XCTAssertTrue(controller.stateSnapshot.isGridVisible, "Grid should remain visible at 1 refinement")
        
        _ = controller.zoomOut()
        XCTAssertTrue(controller.stateSnapshot.isGridVisible, "Grid should remain visible at 0 refinements")
    }
    
    func testZoomOutToFullScreenRestoresBothScreens() {
        let screens = [
            GridRect(x: 0, y: 0, width: 100, height: 100),
            GridRect(x: 200, y: 0, width: 100, height: 100)
        ]
        let combinedBounds = GridRect(x: 0, y: 0, width: 300, height: 100)
        let controller = OverlayController(screenBoundsProvider: { screens })

        controller.start()
        XCTAssertEqual(controller.targetRect, combinedBounds, "Should start with combined bounds of both screens")
        
        // Select second screen and refine
        _ = controller.handleKey("y")
        XCTAssertEqual(controller.targetRect, GridRect(x: 200, y: 25, width: 20, height: 25))
        
        _ = controller.handleKey("h")
        XCTAssertEqual(controller.targetRect, GridRect(x: 200, y: 37.5, width: 4, height: 6.25))
        
        // Zoom out once
        _ = controller.zoomOut()
        XCTAssertEqual(controller.targetRect, GridRect(x: 200, y: 25, width: 20, height: 25))
        
        // Zoom out again - should restore to full screen overlay on both screens
        _ = controller.zoomOut()
        XCTAssertEqual(controller.targetRect, combinedBounds, "Should restore combined bounds of both screens")
        
        // One more zoom out should cancel the overlay
        _ = controller.zoomOut()
        XCTAssertFalse(controller.isActive, "Should cancel overlay after zooming out from full screen")
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
