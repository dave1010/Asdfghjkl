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
        let controller = OverlayController(screenBoundsProvider: { GridRect(x: 0, y: 0, width: 100, height: 100) })
        let manager = InputManager(overlayController: controller)

        controller.start()
        let consumed = manager.handleKeyDown("1")

        XCTAssertTrue(consumed)
        XCTAssertEqual(controller.targetRect, GridRect(x: 0, y: 0, width: 10, height: 25))
    }

    func testSpacebarClickConsumesEventAndDeactivatesOverlay() {
        let performer = StubMouseActionPerformer()
        let controller = OverlayController(
            screenBoundsProvider: { GridRect(x: 0, y: 0, width: 40, height: 20) },
            mouseActionPerformer: performer
        )
        let manager = InputManager(overlayController: controller)

        controller.start()
        controller.handleKey("0")

        let consumed = manager.handleKeyDown(" ")

        XCTAssertTrue(consumed)
        XCTAssertFalse(controller.isActive)
        XCTAssertEqual(performer.receivedPoint, GridPoint(x: 38, y: 2.5))
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
}

private final class StubMouseActionPerformer: MouseActionPerforming {
    private(set) var receivedPoint: GridPoint?

    func moveAndClick(at point: GridPoint) {
        receivedPoint = point
    }
}
