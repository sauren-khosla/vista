import CoreGraphics
import Foundation

/// A normalized dot center survives resolution, Dock, and display-layout changes.
public struct WidgetPosition: Codable, Equatable {
    public var screenID: UInt32
    public var x: Double
    public var y: Double

    public init(screenID: UInt32, center: CGPoint, visibleFrame: CGRect) {
        self.screenID = screenID
        x = min(1, max(0, (center.x - visibleFrame.minX) / max(1, visibleFrame.width)))
        y = min(1, max(0, (center.y - visibleFrame.minY) / max(1, visibleFrame.height)))
    }

    public func frame(size: CGSize, visibleFrame: CGRect) -> CGRect {
        let center = CGPoint(x: visibleFrame.minX + x * visibleFrame.width,
                             y: visibleFrame.minY + y * visibleFrame.height)
        // Expand toward the center of the screen, keeping the dot's corner anchored.
        let origin = CGPoint(x: x >= 0.5 ? center.x + 24 - size.width : center.x - 24,
                             y: y >= 0.5 ? center.y + 24 - size.height : center.y - 24)
        let safe = visibleFrame.insetBy(dx: 8, dy: 8)
        return CGRect(x: min(max(safe.minX, origin.x), max(safe.minX, safe.maxX - size.width)),
                      y: min(max(safe.minY, origin.y), max(safe.minY, safe.maxY - size.height)),
                      width: size.width, height: size.height)
    }
}
