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

    func testZoomOffsetKeepsTargetFixed() {
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 100, height: 100))

        // Target rect centered at (50, 50) in a 100x100 screen with 2x zoom
        controller.update(
            targetRect: GridRect(x: 25, y: 25, width: 50, height: 50),
            screenRect: GridRect(x: 0, y: 0, width: 100, height: 100),
            desiredZoomFactor: 2.0
        )

        // True pinch-to-zoom: target center at (50, 50) stays at (50, 50)
        // When scaling from top-left by 2x, (50, 50) moves to (100, 100)
        // So offset = 50 * (2 - 1) = 50 to bring it back
        XCTAssertEqual(controller.zoomOffset.x, 50.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 50.0, accuracy: 0.01)
    }
    
    func testZoomBehavesLikePinchToZoom() {
        // True pinch-to-zoom: the target point stays at its original screen position
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 1000, height: 800))
        
        // Small target in top-left quadrant
        controller.update(
            targetRect: GridRect(x: 100, y: 100, width: 100, height: 100),
            screenRect: GridRect(x: 0, y: 0, width: 1000, height: 800),
            desiredZoomFactor: 3.0
        )
        
        // Target center at (150, 150) should stay at (150, 150)
        // When scaling by 3x, (150, 150) moves to (450, 450)
        // Offset = 150 * (3 - 1) = 300 to keep it fixed
        XCTAssertEqual(controller.zoomOffset.x, 300.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 300.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomScale, 3.0)
    }
    
    func testZoomWithOffScreenOrigin() {
        // Screen bounds don't start at origin
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 800, height: 600))
        
        // Screen at x=1920 (second monitor), target in middle
        let screenRect = GridRect(x: 1920, y: 0, width: 800, height: 600)
        let targetRect = GridRect(x: 2120, y: 200, width: 200, height: 200)
        
        controller.update(
            targetRect: targetRect,
            screenRect: screenRect,
            desiredZoomFactor: 2.5
        )
        
        // Target center relative to screen: (2220 - 1920, 300 - 0) = (300, 300)
        // Offset = 300 * (2.5 - 1) = 450 to keep it at screen position (300, 300)
        XCTAssertEqual(controller.zoomOffset.x, 450.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 450.0, accuracy: 0.01)
    }
    
    func testZoomAtEdgeOfScreen() {
        // Target at screen edge gets clamped to prevent content going off-screen
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 1000, height: 1000))
        
        // Target in top-left corner
        controller.update(
            targetRect: GridRect(x: 0, y: 0, width: 100, height: 100),
            screenRect: GridRect(x: 0, y: 0, width: 1000, height: 1000),
            desiredZoomFactor: 4.0
        )
        
        // Ideal offset would be 50 * (4 - 1) = 150
        // But this is clamped to 0 to prevent top-left from going off-screen
        XCTAssertEqual(controller.zoomOffset.x, 0.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 0.0, accuracy: 0.01)
    }

    func testZoomAtBottomRightCorner() {
        // Target at bottom-right corner gets clamped appropriately
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 1000, height: 1000))
        
        // Target in bottom-right corner
        controller.update(
            targetRect: GridRect(x: 900, y: 900, width: 100, height: 100),
            screenRect: GridRect(x: 0, y: 0, width: 1000, height: 1000),
            desiredZoomFactor: 4.0
        )
        
        // Target center at (950, 950), ideal offset = 950 * (4 - 1) = 2850
        // But scaled content is 4000 wide/tall, max offset = 4000 - 1000 = 3000
        // So offset is clamped to 3000
        XCTAssertEqual(controller.zoomOffset.x, 3000.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 3000.0, accuracy: 0.01)
    }
    
    func testZoomAtTopRightCorner() {
        // Target at top-right gets clamped on x but not y
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 1000, height: 1000))
        
        // Target in top-right corner
        controller.update(
            targetRect: GridRect(x: 900, y: 0, width: 100, height: 100),
            screenRect: GridRect(x: 0, y: 0, width: 1000, height: 1000),
            desiredZoomFactor: 2.0
        )
        
        // Target center at (950, 50)
        // Ideal offset: x = 950 * 1 = 950, y = 50 * 1 = 50
        // Clamping constraints:
        // - minOffsetX = targetRightX * scale - screenWidth = 1000 * 2 - 1000 = 1000
        // - maxOffsetX = targetLeftX * scale = 900 * 2 = 1800
        // - minOffsetY = targetBottomY * scale - screenHeight = 100 * 2 - 1000 = -800
        // - maxOffsetY = targetTopY * scale = 0 * 2 = 0
        // So X is clamped to 1000 (to keep right edge on screen), Y is clamped to 0
        XCTAssertEqual(controller.zoomOffset.x, 1000.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 0.0, accuracy: 0.01)
    }
    
    func testZoomCenterStaysUnaffectedByClamping() {
        // When target is in center, no clamping should occur
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 1000, height: 1000))
        
        // Target perfectly centered
        controller.update(
            targetRect: GridRect(x: 450, y: 450, width: 100, height: 100),
            screenRect: GridRect(x: 0, y: 0, width: 1000, height: 1000),
            desiredZoomFactor: 2.0
        )
        
        // Target center at (500, 500), offset = 500 * 1 = 500
        // Max offset = 2000 - 1000 = 1000, so no clamping needed
        XCTAssertEqual(controller.zoomOffset.x, 500.0, accuracy: 0.01)
        XCTAssertEqual(controller.zoomOffset.y, 500.0, accuracy: 0.01)
    }

    #if os(macOS)
    func testSnapshotProviderInvokedWhenPresent() {
        let provider = StubSnapshotProvider()
        let controller = ZoomController(initialRect: GridRect(x: 0, y: 0, width: 50, height: 50), snapshotProvider: provider)

        let targetRect = GridRect(x: 5, y: 6, width: 10, height: 12)
        let screenRect = GridRect(x: 0, y: 0, width: 50, height: 50)
        controller.update(targetRect: targetRect, screenRect: screenRect, desiredZoomFactor: 2.0)

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
