import XCTest
@testable import AsdfghjklCore

final class InputManagerTests: XCTestCase {
    func testDoubleTapActivatesOverlay() {
        let controller = OverlayController()
        let manager = InputManager(overlayController: controller)

        manager.handleCommandDown()
        manager.handleCommandUp()

        manager.handleCommandDown()
        manager.handleCommandUp()

        XCTAssertTrue(controller.isActive)
    }

    func testModifierUsePreventsImmediateActivation() {
        let controller = OverlayController()
        let manager = InputManager(overlayController: controller)

        manager.handleCommandDown()
        manager.markCommandAsModifier()
        manager.handleCommandUp()

        manager.handleCommandDown()
        manager.handleCommandUp()

        XCTAssertFalse(controller.isActive)
    }

    func testOverlayHandlesGridRefinementWhenActive() {
        let controller = OverlayController(screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] })
        let manager = InputManager(overlayController: controller)

        controller.start()
        let consumed = manager.handleKeyDown("1")

        XCTAssertTrue(consumed)
        XCTAssertEqual(controller.targetRect, GridRect(x: 0, y: 0, width: 10, height: 25))
    }

    func testSpacebarClickConsumesEventAndDeactivatesOverlay() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 40, height: 20)] },
            mouseActionPerformer: performer
        )
        let manager = InputManager(overlayController: controller)

        controller.start()
        controller.handleKey("0")

        let consumed = manager.handleKeyDown(" ")

        XCTAssertTrue(consumed)
        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(performer.clickedPoints, [GridPoint(x: 38, y: 2.5)])
    }

    func testEscapeCancelsOverlay() {
        let controller = OverlayController()
        let manager = InputManager(overlayController: controller)

        controller.start()
        let consumed = manager.handleKeyDown("\u{1b}")

        XCTAssertTrue(consumed)
        XCTAssertFalse(controller.isActive)
    }

    func testCommandHeldMarksModifierUse() {
        let controller = OverlayController()
        let manager = InputManager(overlayController: controller)

        manager.handleCommandDown()
        _ = manager.handleKeyDown("c", commandActive: true)
        manager.handleCommandUp()

        manager.handleCommandDown()
        manager.handleCommandUp()

        XCTAssertFalse(controller.isActive, "Command+key use should suppress double-tap activation")
    }
    
    func testBackspaceZoomsOutOnePreviousLevel() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] },
            mouseActionPerformer: performer
        )
        let manager = InputManager(overlayController: controller)

        controller.start()
        _ = controller.handleKey("q")
        let rectAfterFirstKey = controller.targetRect
        _ = controller.handleKey("w")
        
        let consumed = manager.handleKeyDown("\u{7f}") // Backspace
        
        XCTAssertTrue(consumed)
        XCTAssertEqual(controller.targetRect, rectAfterFirstKey)
    }
    
    func testBackspaceCancelsOverlayWhenNoHistory() {
        let controller = OverlayController(
            screenBoundsProvider: { [GridRect(x: 0, y: 0, width: 100, height: 100)] }
        )
        let manager = InputManager(overlayController: controller)

        controller.start()
        XCTAssertTrue(controller.isActive, "Overlay should be active after start")
        
        let consumed = manager.handleKeyDown("\u{7f}") // Backspace
        
        XCTAssertTrue(consumed, "Backspace should consume event when canceling overlay")
        XCTAssertFalse(controller.isActive, "Overlay should be canceled after backspace with no history")
    }
    
    func testBackspaceDoesNotConsumeWhenInactive() {
        let controller = OverlayController()
        let manager = InputManager(overlayController: controller)
        
        let consumed = manager.handleKeyDown("\u{7f}") // Backspace
        
        XCTAssertFalse(consumed)
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
}
