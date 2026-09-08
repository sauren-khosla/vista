import AppKit
import SwiftUI

/// Native mouse handling distinguishes a click from a drag without moving the
/// SwiftUI gesture coordinate space underneath the pointer.
struct DragHandle: NSViewRepresentable {
    var label: String
    var onClick: () -> Void
    var onMove: () -> Void

    func makeNSView(context: Context) -> DragHandleView { DragHandleView() }
    func updateNSView(_ view: DragHandleView, context: Context) {
        view.onClick = onClick
        view.onMove = onMove
        view.setAccessibilityLabel(label)
        view.toolTip = "Click to open. Drag to move."
    }
}

final class DragHandleView: NSView {
    var onClick: (() -> Void)?
    var onMove: (() -> Void)?
    private var startMouse = NSPoint.zero
    private var startOrigin = NSPoint.zero
    private var dragging = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
    override func mouseDown(with event: NSEvent) {
        startMouse = window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
        startOrigin = window?.frame.origin ?? .zero
        dragging = false
    }
    override func mouseDragged(with event: NSEvent) {
        updatePosition(with: event)
    }
    private func updatePosition(with event: NSEvent) {
        let mouse = window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
        let delta = NSPoint(x: mouse.x - startMouse.x, y: mouse.y - startMouse.y)
        guard dragging || hypot(delta.x, delta.y) >= 3 else { return }
        dragging = true
        window?.setFrameOrigin(NSPoint(x: startOrigin.x + delta.x, y: startOrigin.y + delta.y))
    }
    override func mouseUp(with event: NSEvent) {
        updatePosition(with: event)
        if dragging { onMove?() } else { onClick?() }
        dragging = false
    }
    override func accessibilityPerformPress() -> Bool {
        onClick?()
        return true
    }
}
