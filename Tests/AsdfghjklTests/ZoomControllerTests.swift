import XCTest
@testable import AsdfghjklCore

final class ZoomControllerTests: XCTestCase {
    func testTargetRectUpdatesOnRefinement() {
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 100, height: 100))

        controller.update(
            targetRect: GridRect(x: 10, y: 20, width: 30, height: 40),
            screenRect: GridRect(x: 0, y: 0, width: 100, height: 100),
            desiredZoomFactor: 2.0
        )

        XCTAssertEqual(controller.targetRect, GridRect(x: 10, y: 20, width: 30, height: 40))
        XCTAssertEqual(controller.screenRect, GridRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(controller.zoomScale, 2.0)
    }

    func testZoomOffsetCentersOnTarget() {
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 100, height: 100))

        // Target rect centered at (50, 50) in a 100x100 screen with 2x zoom
        controller.update(
            targetRect: GridRect(x: 25, y: 25, width: 50, height: 50),
            screenRect: GridRect(x: 0, y: 0, width: 100, height: 100),
            desiredZoomFactor: 2.0
        )

        // Center of target is at (50, 50) in screen coordinates
        // With 2x zoom, offset should be (50 * 1.0, 50 * 1.0) = (50, 50)
        XCTAssertEqual(controller.zoomOffset.x, 50.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 50.0, accuracy: 0.01)
    }

    #if os(macOS)
    func testSnapshotProviderInvokedWhenPresent() {
        let provider = StubSnapshotProvider()
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 50, height: 50), snapshotProvider: provider)

        let targetRect = GridRect(x: 5, y: 6, width: 10, height: 12)
        let screenRect = GridRect(x: 0, y: 0, width: 50, height: 50)
        controller.update(targetRect: targetRect, screenRect: screenRect, desiredZoomFactor: 1.5)

        XCTAssertEqual(provider.requestedRect, screenRect)
        XCTAssertNotNil(controller.latestSnapshot)
    }
    #endif
}

#if os(macOS)
private final class StubSnapshotProvider: ZoomSnapshotProviding {
    private let image: CGImage
    private(set) var requestedRect: GridRect?

    init() {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 1,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        self.image = context!.makeImage()!
    }

    func capture(screen: GridRect) -> CGImage? {
        requestedRect = screen
        return image
    }
}
#endif
