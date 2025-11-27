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
}
