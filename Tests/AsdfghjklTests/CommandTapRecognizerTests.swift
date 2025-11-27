import XCTest
@testable import AsdfghjklCore

final class CommandTapRecognizerTests: XCTestCase {
    func testDoubleTapTriggersCallback() {
        var fired = false
        var recognizer = CommandTapRecognizer()

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { fired = true }

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { fired = true }

        XCTAssertTrue(fired)
    }

    func testUsingModifierCancelsDoubleTap() {
        var fired = false
        var recognizer = CommandTapRecognizer()

        recognizer.handleCommandDown()
        recognizer.handleCommandModifierUse()
        recognizer.handleCommandUp { fired = true }

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { fired = true }

        XCTAssertFalse(fired)
    }
}
