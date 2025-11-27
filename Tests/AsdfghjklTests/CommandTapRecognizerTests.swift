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

    func testDoubleTapHonoursThreshold() {
        var timestamps: [Date] = [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 0.2),
            Date(timeIntervalSince1970: 1.0)
        ]

        var firedCount = 0
        var recognizer = CommandTapRecognizer(currentTime: { timestamps.removeFirst() })

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { firedCount += 1 }

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { firedCount += 1 }

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { firedCount += 1 }

        XCTAssertEqual(firedCount, 1, "Only the second tap within the threshold should trigger")
    }

    func testModifierClearsPreviousTapRecord() {
        var timestamps: [Date] = [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 0.1),
            Date(timeIntervalSince1970: 0.2)
        ]

        var fired = false
        var recognizer = CommandTapRecognizer(currentTime: { timestamps.removeFirst() })

        recognizer.handleCommandDown()
        recognizer.handleCommandModifierUse()
        recognizer.handleCommandUp { fired = true }

        recognizer.handleCommandDown()
        recognizer.handleCommandUp { fired = true }

        XCTAssertFalse(fired, "Modifier use should clear the last tap and require a fresh pair of taps")
    }
}
