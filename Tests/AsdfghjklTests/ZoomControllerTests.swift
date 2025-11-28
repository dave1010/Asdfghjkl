import XCTest
@testable import AsdfghjklCore

final class ZoomControllerTests: XCTestCase {
    func testObservedRectUpdatesOnRefinement() {
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 100, height: 100))

        controller.update(rect: GridRect(x: 10, y: 20, width: 30, height: 40), zoomScale: 2.0)

        XCTAssertEqual(controller.observedRect, GridRect(x: 10, y: 20, width: 30, height: 40))
        XCTAssertEqual(controller.zoomScale, 2.0)
    }

    #if os(macOS)
    func testSnapshotProviderInvokedWhenPresent() {
        let provider = StubSnapshotProvider()
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 50, height: 50), snapshotProvider: provider)

        let rect = GridRect(x: 5, y: 6, width: 10, height: 12)
        controller.update(rect: rect, zoomScale: 1.5)

        XCTAssertEqual(provider.requestedRect, rect)
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

    func capture(rect: GridRect) -> CGImage? {
        requestedRect = rect
        return image
    }
}
#endif
