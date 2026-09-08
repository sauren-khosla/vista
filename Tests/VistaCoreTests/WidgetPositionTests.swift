import CoreGraphics
import XCTest
@testable import VistaCore

final class WidgetPositionTests: XCTestCase {
    let screen = CGRect(x: 0, y: 40, width: 1440, height: 830)
    func testExpandedCardStaysVisibleAtEveryCorner() {
        for x in [0.0, 720, 1440] {
            for y in [40.0, 450, 870] {
                let position = WidgetPosition(screenID: 1, center: CGPoint(x: x, y: y), visibleFrame: screen)
                let card = position.frame(size: CGSize(width: 332, height: 338), visibleFrame: screen)
                XCTAssertTrue(screen.contains(card))
            }
        }
    }
    func testExpansionDoesNotChangeCollapsedLocation() throws {
        let center = CGPoint(x: 400, y: 500)
        let position = WidgetPosition(screenID: 12, center: center, visibleFrame: screen)
        let data = try JSONEncoder().encode(position)
        let restored = try JSONDecoder().decode(WidgetPosition.self, from: data)
        XCTAssertEqual(restored, position)
        let dot = restored.frame(size: CGSize(width: 48, height: 48), visibleFrame: screen)
        XCTAssertEqual(dot.midX, center.x, accuracy: 0.001)
        XCTAssertEqual(dot.midY, center.y, accuracy: 0.001)
        _ = restored.frame(size: CGSize(width: 332, height: 338), visibleFrame: screen)
        XCTAssertEqual(dot, restored.frame(size: CGSize(width: 48, height: 48), visibleFrame: screen))
    }
    func testPositionAdaptsToAnotherDisplaySizeAndOrigin() {
        let position = WidgetPosition(screenID: 1, center: CGPoint(x: 1200, y: 700), visibleFrame: screen)
        let smaller = CGRect(x: -1024, y: -100, width: 1024, height: 700)
        XCTAssertTrue(smaller.contains(position.frame(size: CGSize(width: 332, height: 338), visibleFrame: smaller)))
    }
}
